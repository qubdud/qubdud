import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Import tylko na Web

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// 🔹 Autoryzuje użytkownika (logowanie lub rejestracja)
  Future<User?> authenticateUser(String email, String password) async {
    try {
      // 🔍 Próba logowania
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Błąd logowania: ${e.code}");
      return null;
    }
  }

  /// 🔹 Wylogowuje użytkownika
  Future<void> signOutUser() async {
    try {
      await _auth.signOut();
      print("Użytkownik został wylogowany.");
    } catch (e) {
      print("Błąd podczas wylogowywania: $e");
    }
  }

  /// 🔥 Automatyczna obsługa statusu online w Realtime Database
  void updateUserOnlineStatus() {
    final user = _auth.currentUser;
    if (user == null) return;

    DatabaseReference ref = _db.child("users/${user.uid}");

    // Ustawienie statusu online przy starcie
    ref.update({"online": true, "last_seen": ServerValue.timestamp});

    // Ustawienie statusu offline, gdy aplikacja zostanie zamknięta
    ref.onDisconnect().update({"online": false, "last_seen": ServerValue.timestamp});

    // Obsługa stanu aplikacji (na iOS/Android)
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.paused.toString()) {
        // Aplikacja w tle → offline
        await ref.update({"online": false, "last_seen": ServerValue.timestamp});
      } else if (msg == AppLifecycleState.resumed.toString()) {
        // Aplikacja aktywna → online
        await ref.update({"online": true, "last_seen": ServerValue.timestamp});
      }
      return null;
    });
  }

  /// 🔥
  Stream<Map<String, bool>> getOnlineStatuses() {
    return _db.child("users").onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.map((key, value) => MapEntry(key.toString(), value["online"] as bool? ?? false));
    });
  }

  /// 🔥
  Future<bool> isUserOnline(String userId) async {
    final snapshot = await _db.child("users/$userId/online").get();
    if (snapshot.exists && snapshot.value is bool) {
      return snapshot.value as bool;
    }
    return false;
  }

  /// 🔥 Wysyła wiadomość do użytkownika w Realtime Database
  Future<void> sendMessage(String toFirebaseUID, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final messageId = _db.child("messages/${user.uid}/$toFirebaseUID").push().key;
    final messageData = {
      "from": user.uid,
      "to": toFirebaseUID,
      "content": content,
      "timestamp": ServerValue.timestamp,
      "read": false,
    };
    await _db.child("messages/${user.uid}/$toFirebaseUID/$messageId").set(messageData);
    await _db.child("messages/$toFirebaseUID/${user.uid}/$messageId").set(messageData);
    _db.child("unread_counts/$toFirebaseUID/${user.uid}").set(ServerValue.increment(1));
  }

  /// 🔥 Pobiera wiadomości między dwoma użytkownikami (Realtime Database)
  Stream<List<Map<String, dynamic>>> getMessages(String otherFirebaseUID) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    final messagesRef = _db.child("messages/${user.uid}/$otherFirebaseUID");
    return messagesRef.orderByChild("timestamp").onValue.asyncMap((event) async {
      await markAllMessagesFromUserAsRead(otherFirebaseUID);
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries.map((e) => Map<String, dynamic>.from({...e.value, "messageId": e.key})).toList();
    }).asyncMap((event) async => await event);
  }

  /// 🔥 Resetuje licznik nieprzeczytanych wiadomości
  Future<void> markAllMessagesFromUserAsRead(String otherFirebaseUID) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messagesRef = _db.child("messages/${user.uid}/$otherFirebaseUID");
    final unreadCountRef = _db.child("unread_counts/${user.uid}/$otherFirebaseUID");
    final snapshot = await messagesRef.get();

    if (snapshot.exists) {
      final updates = <String, dynamic>{};
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        if (value["read"] == false) {
          updates["$key/read"] = true;
        }
      });
      if (updates.isNotEmpty) {
        await messagesRef.update(updates);
      }
    }

    await unreadCountRef.remove();
  }

  /// 🔥 Pobiera listę użytkowników, którzy wysłali wiadomości oraz liczbę nieprzeczytanych wiadomości
  Stream<List<Map<String, dynamic>>> getChatOverviews() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .child("messages/${user.uid}")
        .orderByKey() // 🔥 Sortowanie według identyfikatora użytkownika (klucza)
        .limitToLast(30) // 🔥 Pobieramy tylko 30 ostatnich konwersacji
        .onValue
        .asyncMap((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      List<Map<String, dynamic>> chatOverviews = [];

      for (var entry in data.entries) {
        String fromUserId = entry.key;
        int unreadCount = 0;
        final unreadSnapshot = await _db.child("unread_counts/${user.uid}/$fromUserId").get();
        if (unreadSnapshot.exists && unreadSnapshot.value is int) {
          unreadCount = unreadSnapshot.value as int;
        }

        String lastMessage = "";
        int lastMessageTimestamp = 0;

        try {
          final lastMessageSnapshot = await _db.child("messages/${user.uid}/$fromUserId").orderByChild("timestamp").limitToLast(1).get();

          if (lastMessageSnapshot.exists) {
            final lastMessageData = lastMessageSnapshot.value as Map<dynamic, dynamic>;
            if (lastMessageData.isNotEmpty) {
              final lastMessageEntry = lastMessageData.values.first;
              if (lastMessageEntry is Map<dynamic, dynamic>) {
                lastMessage = lastMessageEntry["content"] ?? "";
                lastMessageTimestamp = lastMessageEntry["timestamp"] ?? 0;
              }
            }
          }
        } catch (e) {
          print("Błąd pobierania ostatniej wiadomości: $e");
        }

        if (lastMessage.length > 40) {
          lastMessage = lastMessage.substring(0, 37) + "...";
        }

        chatOverviews.add({
          "from": fromUserId,
          "unreadCount": unreadCount,
          "lastMessage": lastMessage,
          "timestamp": lastMessageTimestamp,
        });
      }

      chatOverviews.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

      return chatOverviews.take(30).toList();
    });
  }

  /// 🔥 Pobiera sumę wszystkich nieprzeczytanych wiadomości
  Future<int> getTotalUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final snapshot = await _db.child("unread_counts/${user.uid}").get();
    final data = snapshot.value as Map<dynamic, dynamic>? ?? {};

    return data.values.fold<int>(0, (sum, count) => sum + (count is int ? count : 0));
  }

  /// 🔥 Pobiera status online użytkownika (Realtime Database)
  Stream<Map<String, dynamic>?> getUserStatus(String firebaseUID) {
    return _db.child("users/$firebaseUID").onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  Future<void> sendGroupMessage(String groupName, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final groupRef = _db.child("group_messages/$groupName");

    // Pobierz aktualny index wiadomości w grupie
    final latestSnapshot = await groupRef.child("latestMessageIndex").get();
    int latestIndex = (latestSnapshot.value as int?) ?? 0;

    final messageId = groupRef.child("messages").push().key;
    final messageData = {
      "messageId": messageId,
      "from": user.uid,
      "content": content,
      "timestamp": ServerValue.timestamp,
      "messageIndex": latestIndex + 1, // Numerujemy wiadomości
    };

    // Zapisz wiadomość w bazie
    await groupRef.child("messages/$messageId").set(messageData);

    // Zaktualizuj najnowszy index wiadomości w grupie
    await groupRef.child("latestMessageIndex").set(latestIndex + 1);
  }

  /// 🔥 Pobiera wiadomości z grupy (Realtime) + Resetuje licznik nieprzeczytanych
  Stream<List<Map<String, dynamic>>> getGroupMessages(String groupName) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final groupMessagesRef = _db.child("group_messages/$groupName/messages");

    return groupMessagesRef.orderByChild("timestamp").onValue.map((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final messages = data.entries.map((e) => Map<String, dynamic>.from({...e.value, "messageId": e.key})).toList();

      // 🔥 Po pobraniu wiadomości automatycznie resetujemy licznik nieprzeczytanych
      await _resetUnreadCount(groupName);

      return messages;
    }).asyncMap((event) async => await event); // Obsługa Future w map()
  }

  /// 🔥 Resetuje licznik nieprzeczytanych po wejściu do czatu
  Future<void> _resetUnreadCount(String groupName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final latestSnapshot = await _db.child("group_messages/$groupName/latestMessageIndex").get();
    int latestIndex = (latestSnapshot.value as int?) ?? 0;

    // Zapisz, do której wiadomości użytkownik doszedł
    await _db.child("group_last_read/${user.uid}/$groupName").set(latestIndex);
    print(latestIndex);
    print(user.uid);
  }

  /// 🔥 Pobiera liczbę nieprzeczytanych wiadomości w grupie
  Future<int> getGroupUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    // Pobranie listy grup użytkownika
    final userGroupsSnapshot = await _db.child("group_last_read/${user.uid}").get();
    if (userGroupsSnapshot.value is! Map || userGroupsSnapshot.value == null) return 0;

    // Pobranie pierwszej dostępnej grupy
    String? firstGroup = (userGroupsSnapshot.value as Map).keys.firstOrNull;
    if (firstGroup == null) return 0;

    // Pobranie ostatniego przeczytanego indeksu dla tej grupy
    final lastReadSnapshot = await _db.child("group_last_read/${user.uid}/$firstGroup").get();
    int lastReadIndex = (lastReadSnapshot.value as int?) ?? 0;

    // Pobranie najnowszego indeksu wiadomości
    final latestSnapshot = await _db.child("group_messages/$firstGroup/latestMessageIndex").get();
    int latestIndex = (latestSnapshot.value as int?) ?? 0;

    return latestIndex - lastReadIndex;
  }

  /// 🔥🔥🔥🔥🔥🔥🔥TEAM CHAT
  Stream<int> getUnreadCountStream(String groupName) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final lastReadRef = _db.child("group_last_read/${user.uid}/$groupName");
    final latestRef = _db.child("group_messages/$groupName/latestMessageIndex");

    return latestRef.onValue.asyncMap((event) async {
      final lastReadIndex = (event.snapshot.value as int?) ?? 0;

      final latestSnapshot = await lastReadRef.get();
      final latestIndex = (latestSnapshot.value as int?) ?? 0;

      return lastReadIndex - latestIndex;
    });
  }

  Stream<Map<String, dynamic>> getGroupChatSummary(String groupId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final groupRef = _db.child("group_messages/$groupId/messages");

    return groupRef.orderByChild("timestamp").limitToLast(1).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      if (data.isEmpty) {
        return {"lastMessage": "", "lastMessageAuthor": "", "timestamp": 0};
      }

      final lastMessageEntry = data.entries.first.value;
      final lastMessage = lastMessageEntry["content"] ?? "";
      final lastMessageAuthor = lastMessageEntry["from"] ?? "";
      final lastMessageTimestamp = lastMessageEntry["timestamp"] ?? 0;

      return {
        "lastMessage": lastMessage,
        "lastMessageAuthor": lastMessageAuthor,
        "timestamp": lastMessageTimestamp,
      };
    });
  }




}
