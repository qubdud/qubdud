import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
  /// Nie czeka na serwer — offline wylogowanie nie może wisieć.
  static Future<void> unregister(FirebaseService firebase) async {
    final uid = _uid;
    _uid = null;
    _onOpen = null;
    await _onToken?.cancel();
    await _onMessage?.cancel();
    await _onOpened?.cancel();
    if (uid == null) return;
    final m = FirebaseMessaging.instance;
    try {
      final token = await m.getToken().timeout(const Duration(seconds: 3));
      if (token != null) {
        firebase.removeFcmToken(uid, token).catchError(
            (Object e) => debugPrint('PUSH: usunięcie tokenu: $e'));
      }
      // nowy token dla następnego konta; stary przestaje działać w FCM,
      // nawet jeśli usunięcie z profilu utknęło w kolejce offline
      await m.deleteToken().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('PUSH: wyrejestrowanie: $e');
    }
  }
}
