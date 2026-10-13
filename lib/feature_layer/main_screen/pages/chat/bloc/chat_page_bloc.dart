import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:qb/domain_layer/chat_service.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';

part 'chat_page_event.dart';

part 'chat_page_state.dart';

class ChatPageBloc extends Bloc<ChatPageEvent, ChatPageState> {
  static const _pageSize = 50;

  final ChatService _chat;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  Timer? _markTimer;
  String _uid = '';
  int _limit = _pageSize;
  bool _loadingOlder = false;
  bool _markedOnOpen = false;
  // od rozmówcy przyszło coś przy otwartym oknie — przy zamknięciu
  // jeszcze raz gasimy licznik i wpis w dzwonku (Cloud Function bywa wolniejsza)
  bool _incoming = false;

  ChatPageBloc({
    required ChatService chatService,
    required FirebaseService firebaseService,
    required String id,
  })  : _chat = chatService,
        super(ChatPageLoadingState()) {
    on<InitChatPageEvent>((event, emit) async {
      if (id.isEmpty) {
        emit(ChatPageMainState());
        return;
      }
      if (id == chatService.myUid) {
        showToast(text: 'Nie możesz pisać do samego siebie');
        emit(ChatPageMainState());
        return;
      }
      _uid = id;
      ChatService.activeChatWith = id;
      emit(MessagingPageMainState(userChat: id));
      _subscribe();

      String? name;
      var exists = true;
      try {
        final u = await firebaseService.fetchUser(id);
        if (u == null) {
          exists = false;
        } else {
          name = u.firma == true
              ? (u.companyName ?? 'Firma')
              : '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim();
        }
      } catch (e) {
        debugPrint('Czat: profil rozmówcy: $e');
      }
      if (name == null || name.isEmpty) name = await chatService.nameInChat(id);
      final s = state;
      if (s is MessagingPageMainState) {
        emit(s.copyWith(name: name ?? 'Rozmowa', canWrite: exists));
      }
    });

    on<RetryMessagesChatPageEvent>((event, emit) {
      final s = state;
      if (s is! MessagingPageMainState) return;
      emit(s.copyWith(failed: false));
      _subscribe();
    });

    on<LoadOlderMessagesChatPageEvent>((event, emit) {
      final s = state;
      if (_loadingOlder || s is! MessagingPageMainState || !s.hasMore) return;
      _loadingOlder = true;
      _limit += _pageSize;
      _subscribe();
    });

    on<_MessagesChatPageEvent>((event, emit) {
      _loadingOlder = false;
      final s = state;
      if (s is! MessagingPageMainState) return;
      final msgs = event.messages;
      emit(s.copyWith(
          messages: msgs, failed: false, hasMore: msgs.length >= _limit));

      final unreadIncoming =
          msgs.any((m) => m['from'] == _uid && m['read'] != true);
      if (unreadIncoming) _incoming = true;
      if (unreadIncoming || (!_markedOnOpen && msgs.isNotEmpty)) {
        _markedOnOpen = true;
        _markTimer?.cancel();
        _markTimer = Timer(const Duration(milliseconds: 400), _markRead);
      }
    });

    on<_MessagesFailedChatPageEvent>((event, emit) {
      _loadingOlder = false;
      final s = state;
      if (s is MessagingPageMainState) emit(s.copyWith(failed: true));
    });

    add(InitChatPageEvent());
  }

  void _subscribe() {
    _sub?.cancel();
    try {
      _sub = _chat.getMessages(_uid, limit: _limit).listen(
        (m) => add(_MessagesChatPageEvent(m)),
        onError: (Object e) {
          debugPrint('Czat: nasłuch wiadomości: $e');
          add(_MessagesFailedChatPageEvent());
        },
      );
    } catch (e) {
      debugPrint('Czat: nasłuch wiadomości: $e');
      add(_MessagesFailedChatPageEvent());
    }
  }

  void _markRead() {
    _chat.markAllMessagesFromUserAsRead(_uid).catchError((Object e) {
      debugPrint('Czat: oznaczanie przeczytanych: $e');
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    if (_markTimer?.isActive == true || _incoming) _markRead();
    _markTimer?.cancel();
    if (ChatService.activeChatWith == _uid) ChatService.activeChatWith = null;
    return super.close();
  }
}
