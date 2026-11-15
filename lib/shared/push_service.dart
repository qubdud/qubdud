import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain_layer/chat_service.dart';
import '../domain_layer/firebase_service.dart';
import 'functions/show_toast.dart';

/// Rejestracja urządzenia do push (FCM) i reakcja na powiadomienia.
/// Wysyłką zajmują się Cloud Functions (functions/index.js).
class PushService {
  static StreamSubscription<RemoteMessage>? _onMessage;
  static StreamSubscription<RemoteMessage>? _onOpened;
  static StreamSubscription<String>? _onToken;
  static String? _uid;
  static void Function(Map<String, dynamic> data)? _onOpen;

  // Android po onNewIntent zwraca tę samą wiadomość z getInitialMessage
  // jeszcze raz — pytamy o nią tylko raz na proces
  static bool _initialHandled = false;

  static const _deletePendingKey = 'fcm_delete_pending';
  static Future<void>? _deleting;
  static Timer? _deleteRetry;

  /// Rośnie przy pushu o zgłoszeniu w foreground — lista zgłoszeń firmy się odświeża.
  static final requestsChanged = ValueNotifier<int>(0);

  static Future<void> register(
    String uid,
    FirebaseService firebase,
    void Function(Map<String, dynamic> data) onOpen,
  ) async {
    _onOpen = onOpen;
    if (_uid == uid) return;
    _uid = uid;
    // token tego konta nie może zniknąć przez spóźnione usunięcie poprzedniego
    _deleteRetry?.cancel();
    await _deleting;
    final m = FirebaseMessaging.instance;
    try {
      final perm = await m.requestPermission(alert: true, badge: true, sound: true);
      debugPrint('PUSH: zgoda=${perm.authorizationStatus}');
      final token = await m.getToken();
      debugPrint('PUSH: token=${token == null ? 'BRAK' : '${token.substring(0, 12)}…'}');
      // bez await — offline zapis czeka w kolejce, a nasłuchy mają ruszyć od razu
      if (token != null) {
        firebase.addFcmToken(uid, token).catchError(
            (Object e) => debugPrint('PUSH: zapis tokenu: $e'));
      }
    } catch (e) {
      debugPrint('PUSH: błąd rejestracji: $e');
    }

    await _onToken?.cancel();
    _onToken = m.onTokenRefresh.listen((t) {
      final current = _uid;
      if (current == null) return;
      firebase.addFcmToken(current, t).catchError(
          (Object e) => debugPrint('PUSH: zapis nowego tokenu: $e'));
    });

    // apka na wierzchu — system nie pokazuje bannera, więc pokazujemy toast
    await _onMessage?.cancel();
    _onMessage = FirebaseMessaging.onMessage.listen((msg) {
      if (const ['new_request', 'urgent_request', 'offer_decision', 'request_deleted']
          .contains(msg.data['type'])) {
        requestsChanged.value++;
      }
      final n = msg.notification;
      if (n == null) return;
      final data = msg.data;
      if (data['type'] == 'chat' &&
          data['senderId'] != null &&
          data['senderId'] == ChatService.activeChatWith) {
        return;
      }
      showToast(text: [n.title, n.body].whereType<String>().join('\n'));
    });

    await _onOpened?.cancel();
    _onOpened =
        FirebaseMessaging.onMessageOpenedApp.listen((msg) => _onOpen?.call(msg.data));

    // apka uruchomiona z powiadomienia
    if (_initialHandled) return;
    _initialHandled = true;
    final initial = await m.getInitialMessage();
    if (initial != null) _onOpen?.call(initial.data);
  }

  /// Przy wylogowaniu: to urządzenie przestaje dostawać push tego konta.
  /// Czeka na serwer najwyżej kilka sekund — offline wylogowanie nie może wisieć.
  static Future<void> unregister(FirebaseService firebase) async {
    // wylogowanie przed końcem startu konta: register się nie wykonał, a token jest w profilu
    final user = FirebaseAuth.instance.currentUser;
    final uid = _uid ?? (user == null || user.isAnonymous ? null : user.uid);
    _uid = null;
    _onOpen = null;
    await _onToken?.cancel();
    await _onMessage?.cancel();
    await _onOpened?.cancel();
    String? token;
    if (uid != null) {
      try {
        token = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('PUSH: token przy wylogowaniu: $e');
      }
    }
    // zapis, który nie zdąży przed signOut, utknie w kolejce tego konta —
    // dlatego token wyłączamy też w FCM (nowy token dla następnego konta)
    await Future.wait([
      if (uid != null && token != null)
        firebase.removeFcmToken(uid, token).timeout(const Duration(seconds: 3)).catchError(
            (Object e) => debugPrint('PUSH: usunięcie tokenu: $e')),
      _deleteToken(),
    ]);
  }

  /// Start bez konta: dokończenie wyłączenia tokenu po wylogowaniu offline.
  /// Po wylogowaniu w tym procesie ponawia już timer.
  static Future<void> retryPendingDelete() async {
    if (_deleting != null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_deletePendingKey) == true) await _deleteToken();
  }

  static Future<void> _deleteToken() {
    _deleteRetry?.cancel();
    return _deleting = _tryDelete();
  }

  // bez sieci deleteToken się nie uda: ponawiamy co minutę i przy starcie apki, aż do
  // skutku albo do zalogowania konta (jego zapis tokenu zabierze go poprzedniemu)
  static Future<void> _tryDelete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_deletePendingKey, true);
      await FirebaseMessaging.instance.deleteToken().timeout(const Duration(seconds: 3));
      await prefs.remove(_deletePendingKey);
    } catch (e) {
      debugPrint('PUSH: usunięcie tokenu FCM: $e');
      if (_uid == null) _deleteRetry = Timer(const Duration(minutes: 1), _deleteToken);
    }
  }
}
