import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' hide Query;
import 'package:flutter/widgets.dart';

import '../shared/globals.dart';
import '../shared/moderation.dart';

/// Czat 1:1 na Firestore (kolekcja `chats`), status online na Realtime Database.
///
/// Struktura Firestore:
///   chats/{chatId}                 — chatId = posortowane "uidA_uidB"
///     participants: [uidA, uidB]   (kolejność jak w chatId)
///     names:     {uid: nazwa wyświetlana} — każdy wpisuje tylko swoją
///     isCompany: {uid: bool}
///     lastMessage, lastTimestamp
///     unread:    {uid: liczba nieprzeczytanych}
///   chats/{chatId}/messages/{msgId} — from, content, timestamp, read
class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static const _chatsLimit = 200;

  /// Rozmówca z otwartego okna rozmowy (null, gdy żadne nie jest otwarte).
  static String? activeChatWith;

  final Map<String, Map<String, dynamic>> _profileCache = {};

  String? get myUid => _auth.currentUser?.uid;

  String chatIdWith(String otherUid) {
    final me = _auth.currentUser!.uid;
    if (otherUid.isEmpty || otherUid == me) {
      throw ArgumentError.value(otherUid, 'otherUid', 'Rozmowa z samym sobą');
    }
    final ids = [me, otherUid]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Po zmianie nazwy w profilu — kolejne wiadomości niosą już nową nazwę.
  void clearProfileCache() => _profileCache.clear();

  Future<Map<String, dynamic>> _getProfile(String uid) async {
    final cached = _profileCache[uid];
    if (cached != null) return cached;
    final doc = await _fs.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final isCompany = (data['firma'] ?? data['isCompany'] ?? false) == true;
    final person = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
    final personName = person.isEmpty ? 'Użytkownik' : person;
    final profile = {
      'name': isCompany ? (data['companyName'] as String? ?? 'Firma') : personName,
      'personName': personName,
      'isCompany': isCompany,
    };
    _profileCache[uid] = profile;
    return profile;
  }

  // ───────────────────────── wiadomości ─────────────────────────

  /// Rozmowa i wiadomość w jednym batchu — offline obie trafiają do kolejki
  /// razem, a Future kończy się dopiero po zapisie na serwerze.
  Future<void> sendMessage(String toUid, String content) async {
    final me = _auth.currentUser?.uid;
    if (me == null) throw StateError('Brak zalogowanego użytkownika');
    final chatId = chatIdWith(toUid);
    final myProfile = await _getProfile(me);
    // konto firmowe w trybie użytkownika pisze jako osoba
    final asCompany =
        myProfile['isCompany'] == true && Globals.instance.companyView;
    final chatRef = _fs.collection('chats').doc(chatId);

    final batch = _fs.batch()
      ..set(
          chatRef,
          {
            'participants': chatId.split('_'),
            'names': {
              me: asCompany ? myProfile['name'] : myProfile['personName']
            },
            'isCompany': {me: asCompany},
            'lastMessage': content,
            'lastTimestamp': FieldValue.serverTimestamp(),
            'unread': {toUid: FieldValue.increment(1)},
            // nowa wiadomość wyciąga rozmowę z kosza u obu stron
            'hiddenFor': FieldValue.arrayRemove([me, toUid]),
          },
          SetOptions(merge: true))
      ..set(chatRef.collection('messages').doc(), {
        'from': me,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    await batch.commit();
  }

  /// [limit] najnowszych wiadomości w rozmowie z [otherUid], najnowsze pierwsze.
  /// Mapy: {messageId, from, content, timestamp (ms), read, pending}
  Stream<List<Map<String, dynamic>>> getMessages(String otherUid,
      {required int limit}) {
    return _fs
        .collection('chats')
        .doc(chatIdWith(otherUid))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        // pusta lista z cache (offline, rozmowa jeszcze niewczytana) to nie „brak wiadomości”
        .where((snap) => snap.docs.isNotEmpty || !snap.metadata.isFromCache)
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return <String, dynamic>{
                'messageId': d.id,
                'from': data['from'] ?? '',
                'content': data['content'] ?? '',
                'timestamp': _millis(data['timestamp']),
                'read': data['read'] ?? false,
                'pending': d.metadata.hasPendingWrites,
              };
            }).toList());
  }

  // snapshots() w FlutterFire nie przyjmuje ServerTimestampBehavior.estimate —
  // znacznik czekający na serwer (null) szacujemy zegarem urządzenia
  static int _millis(Object? ts) => ts is Timestamp
      ? ts.millisecondsSinceEpoch
      : DateTime.now().millisecondsSinceEpoch;

  /// Zeruje mój licznik, oznacza wiadomości rozmówcy jako przeczytane
  /// i gasi wpis rozmowy w dzwonku. Rozmowa musi już istnieć.
  Future<void> markAllMessagesFromUserAsRead(String otherUid) async {
    final me = _auth.currentUser?.uid;
    if (me == null) return;
    final chatRef = _fs.collection('chats').doc(chatIdWith(otherUid));

    // wpisu może nie być (odbiorca był w apce) — błąd ignorujemy
    _fs
        .collection('notifications')
        .doc('chat_${me}_$otherUid')
        .update({'read': true}).catchError((_) {});

    final unreadMsgs = await chatRef
        .collection('messages')
        .where('from', isEqualTo: otherUid)
        .where('read', isEqualTo: false)
        .get();
    final batch = _fs.batch()..update(chatRef, {'unread.$me': 0});
    for (final d in unreadMsgs.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Nazwa rozmówcy zapisana w dokumencie rozmowy (gdy profil niedostępny).
  Future<String?> nameInChat(String otherUid) async {
    try {
      final doc = await _fs.collection('chats').doc(chatIdWith(otherUid)).get();
      final name = (doc.data()?['names'] as Map?)?[otherUid];
      return name is String && name.isNotEmpty ? name : null;
    } catch (_) {
      return null;
    }
  }

  /// Rozmowa do kosza (tylko u mnie; druga strona widzi ją nadal).
  Future<void> hideChat(String otherUid) async {
    final me = _auth.currentUser?.uid;
    if (me == null) return;
    await _fs.collection('chats').doc(chatIdWith(otherUid)).update({
      'hiddenFor': FieldValue.arrayUnion([me])
    });
  }

  Future<void> unhideChat(String otherUid) async {
    final me = _auth.currentUser?.uid;
    if (me == null) return;
    await _fs.collection('chats').doc(chatIdWith(otherUid)).update({
      'hiddenFor': FieldValue.arrayRemove([me])
    });
  }

  Query<Map<String, dynamic>> _myChats(String me) => _fs
      .collection('chats')
      .where('participants', arrayContains: me)
      .orderBy('lastTimestamp', descending: true)
      .limit(_chatsLimit);

  /// uid rozmówcy, jeśli rozmowa należy do listy ([hidden] = kosz);
  /// null dla rozmowy z samym sobą albo z drugiej listy.
  static String? _listedOther(
      Map<String, dynamic> data, String me, bool hidden) {
    final participants = List<String>.from(data['participants'] ?? []);
    final other = participants.firstWhere((p) => p != me, orElse: () => '');
    final hiddenFor = List<String>.from(data['hiddenFor'] ?? []);
    if (other.isEmpty || hiddenFor.contains(me) != hidden) return null;
    return other;
  }

  /// Lista rozmów, najnowsze pierwsze. [hidden] = false → aktywne, true → kosz.
  /// Mapy: {from (uid rozmówcy), name, isCompany, lastMessage, timestamp (ms), unreadCount}
  Stream<List<Map<String, dynamic>>> getChatOverviews({bool hidden = false}) {
    final me = _auth.currentUser?.uid;
    if (me == null) return Stream.value(const []);

    return _myChats(me).snapshots().asyncMap((snap) async {
      final overviews = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        final otherUid = _listedOther(data, me, hidden);
        if (otherUid == null || BlockedUsers.contains(otherUid)) continue;
        final names = Map<String, dynamic>.from(data['names'] ?? {});
        final isCompany = Map<String, dynamic>.from(data['isCompany'] ?? {});
        final unread = Map<String, dynamic>.from(data['unread'] ?? {});
        var name = names[otherUid] as String? ?? '';
        var company = isCompany[otherUid] == true;
        if (name.isEmpty) {
          // rozmówca jeszcze nie odpisał, więc nie wpisał swojej nazwy
          try {
            final p = await _getProfile(otherUid);
            name = p['name'] as String;
            company = p['isCompany'] as bool;
          } catch (_) {}
        }

        String lastMessage = data['lastMessage'] ?? '';
        if (lastMessage.characters.length > 40) {
          lastMessage = '${lastMessage.characters.take(37)}...';
        }

        overviews.add(<String, dynamic>{
          'from': otherUid,
          'name': name,
          'isCompany': company,
          'lastMessage': lastMessage,
          'timestamp': _millis(data['lastTimestamp']),
          'unreadCount': (unread[me] as num?)?.toInt() ?? 0,
        });
      }
      return overviews;
    });
  }

  /// Suma moich nieprzeczytanych w rozmowach poza koszem.
  Stream<int> unreadTotalStream() {
    final me = _auth.currentUser?.uid;
    if (me == null) return Stream.value(0);
    return _myChats(me).snapshots().map((snap) {
      var sum = 0;
      for (final d in snap.docs) {
        final data = d.data();
        if (_listedOther(data, me, false) == null) continue;
        sum += ((data['unread'] as Map?)?[me] as num?)?.toInt() ?? 0;
      }
      return sum;
    }).distinct();
  }

  // ───────────────────────── wskaźnik pisania (RTDB) ──────────────────────

  void setTyping(String otherUid, bool typing) {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _db.child('typing/${chatIdWith(otherUid)}/${user.uid}');
    if (typing) {
      ref.set(true).catchError((_) {});
      ref.onDisconnect().remove().catchError((_) {});
    } else {
      ref.remove().catchError((_) {});
    }
  }

  Stream<bool> typingStream(String otherUid) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    return _db
        .child('typing/${chatIdWith(otherUid)}/$otherUid')
        .onValue
        .map((e) => e.snapshot.value == true);
  }

  // ───────────────────────── status online (RTDB) ─────────────────────────
  // Cloud Function uznaje odbiorcę za obecnego, gdy online == true
  // i last_seen młodszy niż 5 min — stąd heartbeat co 3 min.

  AppLifecycleListener? _lifecycle;
  StreamSubscription<DatabaseEvent>? _connectedSub;
  Timer? _heartbeat;
  String? _presenceUid;

  static bool get _foreground {
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null ||
        s == AppLifecycleState.resumed ||
        s == AppLifecycleState.inactive;
  }

  void startPresence() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid == _presenceUid) return;
    _stopPresenceListeners();
    _presenceUid = uid;
    final ref = _db.child('users/$uid');

    _lifecycle = AppLifecycleListener(onStateChange: (s) {
      if (s == AppLifecycleState.resumed) {
        _setOnline(ref, true);
      } else if (s == AppLifecycleState.paused ||
          s == AppLifecycleState.detached) {
        _setOnline(ref, false);
      }
    });

    // po każdym (ponownym) połączeniu: najpierw onDisconnect, potem online
    _connectedSub =
        FirebaseDatabase.instance.ref('.info/connected').onValue.listen((e) {
      if (e.snapshot.value != true) return;
      ref
          .onDisconnect()
          .update({'online': false, 'last_seen': ServerValue.timestamp})
          .then((_) {
        if (_foreground && _presenceUid == uid) _setOnline(ref, true);
      }).catchError((_) {});
    }, onError: (_) {});
  }

  void _setOnline(DatabaseReference ref, bool online) {
    _heartbeat?.cancel();
    _heartbeat = null;
    ref.update({'online': online, 'last_seen': ServerValue.timestamp})
        .catchError((_) {});
    if (online) {
      _heartbeat = Timer.periodic(const Duration(minutes: 3), (_) {
        ref.update({'online': true, 'last_seen': ServerValue.timestamp})
            .catchError((_) {});
      });
    }
  }

  void _stopPresenceListeners() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _connectedSub?.cancel();
    _connectedSub = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _presenceUid = null;
  }

  /// Przed wylogowaniem (póki reguły RTDB jeszcze wpuszczają ten uid).
  Future<void> stopPresence() async {
    final uid = _presenceUid;
    _stopPresenceListeners();
    _profileCache.clear();
    activeChatWith = null;
    if (uid == null) return;
    final ref = _db.child('users/$uid');
    try {
      await Future.wait([
        ref.update({'online': false, 'last_seen': ServerValue.timestamp}),
        ref.onDisconnect().cancel(),
      ]).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Stream<Map<String, dynamic>?> getUserStatus(String firebaseUID) {
    return _db.child("users/$firebaseUID").onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }
}
