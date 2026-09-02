import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain_layer/firebase_service.dart';
import 'functions/show_toast.dart';

/// Rejestracja urządzenia do push (FCM) i reakcja na powiadomienia.
/// Wysyłką zajmują się Cloud Functions (functions/index.js).
class PushService {
  static StreamSubscription<RemoteMessage>? _onMessage;
  static StreamSubscription<RemoteMessage>? _onOpened;
  static StreamSubscription<String>? _onToken;
  static String? _uid;

  static Future<void> register(
    String uid,
    FirebaseService firebase,
    void Function(Map<String, dynamic> data) onOpen,
  ) async {
    _uid = uid;
    final m = FirebaseMessaging.instance;
    try {
      await m.requestPermission(alert: true, badge: true, sound: true);
      final token = await m.getToken();
      if (token != null) await firebase.addFcmToken(uid, token);
    } catch (_) {}

    await _onToken?.cancel();
    _onToken = m.onTokenRefresh.listen((t) {
      if (_uid != null) firebase.addFcmToken(_uid!, t);
    });

    // apka na wierzchu — system nie pokazuje bannera, więc pokazujemy toast
    await _onMessage?.cancel();
    _onMessage = FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      showToast(text: [n.title, n.body].whereType<String>().join('\n'));
    });

    await _onOpened?.cancel();
    _onOpened =
        FirebaseMessaging.onMessageOpenedApp.listen((msg) => onOpen(msg.data));

    // apka uruchomiona z powiadomienia
    final initial = await m.getInitialMessage();
    if (initial != null) onOpen(initial.data);
  }

  /// Przy wylogowaniu: to urządzenie przestaje dostawać push tego konta.
  static Future<void> unregister(FirebaseService firebase) async {
    final uid = _uid;
    _uid = null;
    await _onToken?.cancel();
    await _onMessage?.cancel();
    await _onOpened?.cancel();
    if (uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await firebase.removeFcmToken(uid, token);
    } catch (_) {}
  }
}
