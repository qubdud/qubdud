import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

/// Czat 1:1 na Firestore (kolekcja `chats`), status online na Realtime Database.
///
/// Struktura Firestore:
///   chats/{chatId}                 — chatId = posortowane "uidA_uidB"
///     participants: [uidA, uidB]
///     names:     {uid: nazwa wyświetlana}
///     isCompany: {uid: bool}
///     lastMessage, lastTimestamp
///     unread:    {uid: liczba nieprzeczytanych}
///   chats/{chatId}/messages/{msgId} — from, content, timestamp, read
class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // cache profili do denormalizacji nazw w dokumencie rozmowy
  final Map<String, Map<String, dynamic>> _profileCache = {};

  String chatIdWith(String otherUid) {
    final me = _auth.currentUser!.uid;
    final ids = [me, otherUid]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<Map<String, dynamic>> _getProfile(String uid) async {
    final cached = _profileCache[uid];
    if (cached != null) return cached;
    final doc = await _fs.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final isCompany = data['firma'] ?? data['isCompany'] ?? false;
    final name = isCompany == true
        ? (data['companyName'] ?? 'Firma')
        : '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
    final profile = {
      'name': (name as String).isEmpty ? 'Użytkownik' : name,
      'isCompany': isCompany == true,
    };
    _profileCache[uid] = profile;
    return profile;
  }

  // ───────────────────────── wiadomości ─────────────────────────

  Future<void> sendMessage(String toUid, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final myProfile = await _getProfile(user.uid);
    final otherProfile = await _getProfile(toUid);

    final chatRef = _fs.collection('chats').doc(chatIdWith(toUid));

    await chatRef.set({
      'participants': [user.uid, toUid],
      'names': {user.uid: myProfile['name'], toUid: otherProfile['name']},
      'isCompany': {
        user.uid: myProfile['isCompany'],
        toUid: otherProfile['isCompany'],
      },
      'lastMessage': content,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unread': {toUid: FieldValue.increment(1)},
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'from': user.uid,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// Wiadomości w rozmowie z [otherUid], najnowsze pierwsze.
  /// Mapy: {messageId, from, content, timestamp (ms), read}
  Stream<List<Map<String, dynamic>>> getMessages(String otherUid) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _fs
        .collection('chats')
        .doc(chatIdWith(otherUid))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final ts = data['timestamp'];
              return <String, dynamic>{
                'messageId': d.id,
                'from': data['from'] ?? '',
                'content': data['content'] ?? '',
                'timestamp': ts is Timestamp
                    ? ts.millisecondsSinceEpoch
                    : DateTime.now().millisecondsSinceEpoch,
                'read': data['read'] ?? false,
              };
            }).toList());
  }

  Future<void> markAllMessagesFromUserAsRead(String otherUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final chatRef = _fs.collection('chats').doc(chatIdWith(otherUid));
    try {
      await chatRef.update({'unread.${user.uid}': 0});
    } catch (_) {
      // rozmowa jeszcze nie istnieje
      return;
    }

    final unreadMsgs = await chatRef
        .collection('messages')
        .where('from', isEqualTo: otherUid)
        .where('read', isEqualTo: false)
        .get();
    if (unreadMsgs.docs.isNotEmpty) {
      final batch = _fs.batch();
      for (final d in unreadMsgs.docs) {
        batch.update(d.reference, {'read': true});
      }
      await batch.commit();
    }
  }

  /// Lista rozmów zalogowanego użytkownika, najnowsze pierwsze.
  /// Mapy: {from (uid rozmówcy), name, isCompany, lastMessage, timestamp (ms), unreadCount}
  Stream<List<Map<String, dynamic>>> getChatOverviews() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _fs
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snap) {
      final overviews = snap.docs.where((d) {
        // odfiltruj czaty "z samym sobą" (brak drugiego uczestnika)
        final participants =
            List<String>.from(d.data()['participants'] ?? []);
        return participants.any((p) => p != user.uid);
      }).map((d) {
        final data = d.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUid = participants.firstWhere((p) => p != user.uid,
            orElse: () => '');
        final names = Map<String, dynamic>.from(data['names'] ?? {});
        final isCompany = Map<String, dynamic>.from(data['isCompany'] ?? {});
        final unread = Map<String, dynamic>.from(data['unread'] ?? {});
        final ts = data['lastTimestamp'];

        String lastMessage = data['lastMessage'] ?? '';
        if (lastMessage.length > 40) {
          lastMessage = '${lastMessage.substring(0, 37)}...';
        }

        return <String, dynamic>{
          'from': otherUid,
          'name': names[otherUid] ?? '',
          'isCompany': isCompany[otherUid] ?? false,
          'lastMessage': lastMessage,
          'timestamp': ts is Timestamp ? ts.millisecondsSinceEpoch : 0,
          'unreadCount': (unread[user.uid] as num?)?.toInt() ?? 0,
        };
      }).toList();

      overviews.sort((a, b) =>
          (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      return overviews.take(30).toList();
    });
  }

  Future<int> getTotalUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final snap = await _fs
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .get();
    int sum = 0;
    for (final d in snap.docs) {
      final unread = Map<String, dynamic>.from(d.data()['unread'] ?? {});
      sum += (unread[user.uid] as num?)?.toInt() ?? 0;
    }
    return sum;
  }

  // ───────────────────────── wskaźnik pisania (RTDB) ──────────────────────

  void setTyping(String otherUid, bool typing) {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _db.child('typing/${chatIdWith(otherUid)}/${user.uid}');
    if (typing) {
      ref.set(true);
      ref.onDisconnect().remove();
    } else {
      ref.remove();
    }
  }

  Stream<bool> typingStream(String otherUid) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .child('typing/${chatIdWith(otherUid)}/$otherUid')
        .onValue
        .map((e) => e.snapshot.value == true);
  }

  // ───────────────────────── status online (RTDB) ─────────────────────────

  void updateUserOnlineStatus() {
    final user = _auth.currentUser;
    if (user == null) return;

    DatabaseReference ref = _db.child("users/${user.uid}");

    ref.update({"online": true, "last_seen": ServerValue.timestamp});
    ref.onDisconnect().update({"online": false, "last_seen": ServerValue.timestamp});

    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.paused.toString()) {
        await ref.update({"online": false, "last_seen": ServerValue.timestamp});
      } else if (msg == AppLifecycleState.resumed.toString()) {
        await ref.update({"online": true, "last_seen": ServerValue.timestamp});
      }
      return null;
    });
  }

  Stream<Map<String, bool>> getOnlineStatuses() {
    return _db.child("users").onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.map((key, value) =>
          MapEntry(key.toString(), value["online"] as bool? ?? false));
    });
  }

  Future<bool> isUserOnline(String userId) async {
    final snapshot = await _db.child("users/$userId/online").get();
    if (snapshot.exists && snapshot.value is bool) {
      return snapshot.value as bool;
    }
    return false;
  }

  Stream<Map<String, dynamic>?> getUserStatus(String firebaseUID) {
    return _db.child("users/$firebaseUID").onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }
}
