import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'domain_models/app_user.dart';
import 'domain_models/company_info.dart';
import 'domain_models/promoVideo.dart';
import 'domain_models/relation_link.dart';
import '../shared/moderation.dart';

/// Nieudana operacja na terminie — [message] nadaje się do pokazania.
class SlotException implements Exception {
  final String message;
  const SlotException(this.message);

  @override
  String toString() => message;
}

/// Komunikat dla użytkownika po nieudanej rezerwacji lub decyzji o terminie.
String slotErrorText(Object e) => switch (e) {
      SlotException() => e.message,
      FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
        'Brak połączenia — spróbuj ponownie',
      _ => 'Nie udało się — spróbuj ponownie',
    };

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;



  Future<String?> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    String? bio,
    bool isCompany = false,
    String? nip,
    String? companyName,
    String? companyCategory,
    String? companySector,
    LatLng? companyLocation,
    String? companyCity,
    Map<String, String>? companyAddress,
  }) async {
    final UserCredential userCredential;
    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // kod (np. email-already-in-use) — strona mapuje go na polski komunikat
      return e.code;
    }

    final user = userCredential.user!;
    final userRef = _firestore.collection('users').doc(user.uid);
    try {
      await (_firestore.batch()
        ..set(userRef, {
        // EXPIRES: pusty klucz tylko dla APK ≤1.3.x (`email!` na stronie zgłoszenia)
        'email': '',
        'firstName': firstName,
        'lastName': lastName,
        // telefon firmy jest jawny; klienta tylko w private/contact
        'phone': isCompany ? phone : '',
        if (bio != null && bio.isNotEmpty) 'bio': bio,
        'isCompany': isCompany,
        'firma': isCompany, // kompatybilność wsteczna
        if (isCompany && nip != null) 'nip': nip,
        if (isCompany && companyName != null) 'companyName': companyName,
        if (isCompany && companyCategory != null) 'companyCategory': companyCategory,
        if (isCompany && companySector != null) 'companySector': companySector,
        if (isCompany && companyCity != null) 'companyCity': companyCity,
        if (isCompany && companyLocation != null)
          'companyLocation': {
            'lat': companyLocation.latitude,
            'lng': companyLocation.longitude,
          },
        if (isCompany && companyAddress != null) 'companyAddress': companyAddress,
        'consents': {
          'terms': true,
          'rodo': true,
          'acceptedAt': FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
      })
        ..set(userRef.collection('private').doc('contact'), {
          'email': user.email ?? email,
          if (!isCompany) 'phone': phone,
        }))
          .commit()
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // brak sieci po utworzeniu konta: zapis czeka w lokalnej kolejce i wyśle się po powrocie połączenia
      return null;
    } catch (_) {
      // konto Auth bez profilu kończy się wiecznym spinnerem — wycofujemy je
      try {
        await user.delete();
      } catch (_) {
        await _auth.signOut();
      }
      rethrow;
    }
    return null;
  }

  /// Usuwa konto razem z danymi i plikami (Cloud Function z Admin SDK).
  Future<void> deleteAccount() async {
    await FirebaseFunctions.instanceFor(region: 'europe-central2')
        .httpsCallable('deleteAccount',
            options: HttpsCallableOptions(timeout: const Duration(minutes: 5)))
        .call<void>();
  }

  /// [withContact] dociąga telefon i e-mail z private/contact — dostępne tylko dla
  /// właściciela i firmy, u której ten użytkownik jest klientem (reguły).
  Future<AppUser?> fetchUser(String userId, {bool withContact = false}) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    final contact = withContact ? await privateContact(userId) : null;
    return AppUser.fromDoc(doc,
        contact: contact, contactDenied: withContact && contact == null);
  }

  /// Telefon i e-mail z users/{uid}/private/contact ({} gdy dokumentu jeszcze nie ma);
  /// bez uprawnień albo bez kopii w cache: null.
  Future<Map<String, dynamic>?> privateContact(String uid,
      {Source source = Source.serverAndCache}) async {
    try {
      final d = await _firestore.collection('users').doc(uid)
          .collection('private').doc('contact').get(GetOptions(source: source));
      return d.data() ?? const {};
    } on FirebaseException {
      return null;
    }
  }




  static const _mimeByExt = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.gif': 'image/gif',
    '.heic': 'image/heic',
    '.heif': 'image/heif',
    '.mp4': 'video/mp4',
    '.m4v': 'video/mp4',
    '.mov': 'video/quicktime',
    '.3gp': 'video/3gpp',
    '.webm': 'video/webm',
    '.mkv': 'video/x-matroska',
  };

  static String _ext(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot).toLowerCase();
  }

  /// Wysyła plik do Storage pod ścieżką właściciela; reguły wymagają
  /// jawnego typu image/* lub video/*.
  Future<Reference> _putOwnFile(String folder, File file, String mediaType,
      {String suffix = '', void Function(double progress)? onProgress}) async {
    final uid = _auth.currentUser!.uid;
    final ext = _ext(file.path);
    final ref = _storage.ref(
        '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}$suffix$ext');
    final task = ref.putFile(
        file,
        SettableMetadata(
            contentType: _mimeByExt[ext] ??
                (mediaType == 'video' ? 'video/mp4' : 'image/jpeg')));
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    }, onError: (_) {});
    try {
      await task;
    } finally {
      await sub.cancel();
    }
    return ref;
  }

  /// Plik zgłoszenia/prezentacji/recenzji + miniatura (files/{uid}, thumbs/{uid}).
  Future<({String fileName, String fileUrl, String thumbUrl})> uploadMedia({
    required File file,
    required File thumb,
    required String mediaType,
    void Function(double progress)? onProgress,
  }) async {
    // te same limity co storage.rules — bez wysyłania setek MB tylko po to, by dostać odmowę
    final maxMb = mediaType == 'video' ? 200 : 25;
    if (await file.length() > maxMb * 1024 * 1024) {
      throw FirebaseException(
          plugin: 'firebase_storage', code: 'unauthorized', message: 'Plik > $maxMb MB');
    }
    final thumbRef = await _putOwnFile('thumbs', thumb, 'image');
    final fileRef = await _putOwnFile('files', file, mediaType,
        onProgress: onProgress);
    return (
      fileName: fileRef.name,
      fileUrl: await fileRef.getDownloadURL(),
      thumbUrl: await thumbRef.getDownloadURL(),
    );
  }

  Future<Promo?> getPromoById(String promoId) async {
    final doc = await _firestore.collection('promos').doc(promoId).get();
    if (!doc.exists) return null;
    return Promo.fromDoc(doc);
  }

  Future<void> savePromoVideoMetadata(Promo promo) async {
    await _firestore.collection('promos').add(promo.toMap());
  }

  Future<void> saveRequestMetadata(Request req) async {
    await _firestore.collection('requests').add(req.toMap());
  }

  /// Jedna recenzja klienta na firmę: id = {autor}_{firma} (reguły odrzucą drugą).
  Future<void> saveReviewMetadata(Review rev) async {
    await _firestore
        .collection('reviews')
        .doc('${rev.userId}_${rev.reviewedUserId}')
        .set(rev.toMap());
  }

  Future<void> deletePromoMetadata(String promoId) async {
    await FirebaseFirestore.instance
        .collection('promos')
        .doc(promoId)
        .delete();
  }

  Future<void> deleteRequestMetadata(String requestId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .delete();
  }

  Future<void> deleteReviewMetadata(String reviewId) async {
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .delete();
  }


  Future<List<Promo>> getFavoritePromos(String userId) async {
    final favSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favoritePromos')
        .orderBy('createdAt', descending: true)
        .get();

    final promoIds = favSnapshot.docs.map((d) => d.id).toList();

    if (promoIds.isEmpty) return [];

    // whereIn przyjmuje max 30 wartości
    final byId = <String, Promo>{};
    for (int i = 0; i < promoIds.length; i += 30) {
      final chunk = promoIds.sublist(i, min(i + 30, promoIds.length));
      final snap = await _firestore
          .collection('promos')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        byId[d.id] = Promo.fromDoc(d);
      }
    }

    // ulubione usuniętych prezentacji sprzątamy przy okazji
    final gone = favSnapshot.docs.where((d) => !byId.containsKey(d.id));
    if (gone.isNotEmpty) {
      final batch = _firestore.batch();
      for (final d in gone) {
        batch.delete(d.reference);
      }
      batch.commit().catchError((_) {});
    }

    return [
      for (final id in promoIds)
        if (byId[id] != null) byId[id]!,
    ];
  }


  Future<void> skipRequest({
    required String userId,
    required String requestId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('skippedRequests')
        .doc(requestId)
        .set({
      'skippedAt': FieldValue.serverTimestamp(),
    });
  }


  Future<void> addPromoToFavorites({
    required String userId,
    required String promoId,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favoritePromos')
        .doc(promoId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snapshot = await tx.get(ref);

      if (!snapshot.exists) {
        tx.set(ref, {
          'promoId': promoId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // jeśli istnieje → NIC NIE ROBI
    });
  }


  Future<void> removePromoFromFavorites({
    required String userId,
    required String promoId,
  }) async {
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favoritePromos');

    final snapshot = await collection
        .where('promoId', isEqualTo: promoId)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }






  Future<List<Promo>> getPromosMetadataByUser(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('promos')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Promo.fromDoc(doc))
        .toList();
  }

  Future<List<Promo>> getRandomPromos({int limit = 10}) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('promos')
        .orderBy('timestamp', descending: true)
        .limit(50) // pobieramy np. 50 najnowszych, żeby nie ściągać wszystkiego
        .get();

    final promos = querySnapshot.docs.map((doc) => Promo.fromDoc(doc)).toList()
      ..removeWhere((p) => BlockedUsers.contains(p.userId));

    promos.shuffle(Random());

    return promos.take(limit).toList();
  }

  Future<List<Request>> getRequestsMetadataByUser(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Request.fromDoc(doc))
        .toList();
  }

  Future<Set<String>> _skippedRequestIds(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('skippedRequests')
        .get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// Zgłoszenia z branży firmy: wszystkie z moją ofertą albo realizowane
  /// przeze mnie + [newLimit] nowych (pilne, potem najbliższe).
  /// [myOffers]: requestId → moja oferta.
  Future<({List<Request> requests, Map<String, Map<String, dynamic>> myOffers})>
      getNearbyRequests({
    required String userId,
    required String category,
    required String sector,
    required LatLng myLocation,
    int newLimit = 10,
  }) async {
    final skippedIds = await _skippedRequestIds(userId);
    final snap = await _firestore
        .collection('requests')
        .where('category', isEqualTo: category)
        .where('sector', isEqualTo: sector)
        .get();

    final candidates = snap.docs
        .map((doc) => Request.fromDoc(doc))
        .where((r) => !skippedIds.contains(r.id) && r.isActiveFor(userId)
            && !BlockedUsers.contains(r.userId))
        .toList();

    for (final r in candidates) {
      r.distance = Geolocator.distanceBetween(
        myLocation.latitude,
        myLocation.longitude,
        r.location.latitude,
        r.location.longitude,
      );
    }
    candidates.sort((a, b) {
      if (a.is24 != b.is24) return a.is24 ? -1 : 1;
      return (a.distance ?? 0).compareTo(b.distance ?? 0);
    });

    final offers = await Future.wait(
        candidates.map((r) => getMyOffer(r.id, userId)));
    final myOffers = <String, Map<String, dynamic>>{
      for (var i = 0; i < candidates.length; i++)
        if (offers[i] != null) candidates[i].id: offers[i]!,
    };

    var fresh = 0;
    final requests = <Request>[];
    for (final r in candidates) {
      if (myOffers.containsKey(r.id) || r.takenBy == userId) {
        requests.add(r);
      } else if (fresh < newLimit) {
        fresh++;
        requests.add(r);
      }
    }
    return (requests: requests, myOffers: myOffers);
  }




  Future<List<Promo>> getNearbyPromos({
    required String category,
    required String sector,
    required LatLng myLocation,
    int limit = 10,
  }) async {
    // 🔸 Pobranie promocji z danej kategorii i branży
    final querySnapshot = await FirebaseFirestore.instance
        .collection('promos')
        .where('category', isEqualTo: category)
        .where('sector', isEqualTo: sector)
        .get();

    // 🔸 Konwersja dokumentów na obiekty Promo
    final promos = querySnapshot.docs.map((doc) => Promo.fromDoc(doc)).toList()
      ..removeWhere((p) => BlockedUsers.contains(p.userId));

    // 🔸 Obliczenie odległości i zapisanie w polu distance
    for (var promo in promos) {
      final distanceMeters = Geolocator.distanceBetween(
        myLocation.latitude,
        myLocation.longitude,
        promo.location.latitude,
        promo.location.longitude,
      );

      promo.distance = distanceMeters; // km
    }

    // 🔸 Posortowanie po odległości (najbliższe pierwsze)
    promos.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

    // 🔸 Zwrócenie ograniczonej liczby wyników
    return promos.take(limit).toList();
  }



  Future<List<Review>> getReviewByUser(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Review.fromDoc(doc))
        .toList();
  }


  Future<List<Review>> getReviewsMetadataByReviewedUser(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('reviewedUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Review.fromDoc(doc))
        .toList();
  }




  /// Stary opis firmy z kolekcji `profile` (dziś opis to users.bio).
  // EXPIRES: po uruchomieniu demo/_seed/migrate_profile_bio.js --apply
  Future<ProfileInfo?> getProfileByUser(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('profile')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null; // brak danych
    }

    return ProfileInfo.fromDoc(querySnapshot.docs.first);
  }







  // update, nie set(merge) — token nie może wskrzesić usuniętego profilu
  Future<void> addFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update(
        {'fcmTokens': FieldValue.arrayUnion([token])});
  }

  Future<void> removeFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update(
        {'fcmTokens': FieldValue.arrayRemove([token])});
  }

  /// Zapis pól profilu. Bez sieci nie czeka na serwer w nieskończoność —
  /// zmiana zostaje w kolejce Firestore i wyśle się po powrocie połączenia.
  /// Zwraca false, gdy serwer jeszcze nie potwierdził zapisu.
  /// [privatePhone] trafia do private/contact (telefon klienta nie jest jawny).
  Future<bool> updateUserData(String userId, Map<String, dynamic> data,
      {String? privatePhone}) async {
    final ref = _firestore.collection('users').doc(userId);
    final batch = _firestore.batch()..update(ref, data);
    if (privatePhone != null) {
      batch.set(ref.collection('private').doc('contact'), {'phone': privatePhone},
          SetOptions(merge: true));
    }
    try {
      await batch.commit().timeout(const Duration(seconds: 8));
      return true;
    } on TimeoutException {
      return false;
    }
  }

  /// Profil z lokalnej kopii Firestore (razem z niewysłanymi zmianami);
  /// null, gdy dokumentu nie ma w cache.
  Future<AppUser?> cachedUser(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.cache));
      return doc.exists
          ? AppUser.fromDoc(doc,
              contact: await privateContact(userId, source: Source.cache))
          : null;
    } on FirebaseException {
      return null;
    }
  }

  Future<void> incrementPromoViews(String promoId) async {
    try {
      await _firestore
          .collection('promos')
          .doc(promoId)
          .update({'views': FieldValue.increment(1)});
    } catch (_) {}
  }

  /// Liczba zleceń firmy z realizacją potwierdzoną przez klienta.
  Future<int> getCompletedJobsCount(String companyId) async {
    final snap = await _firestore
        .collection('requests')
        .where('takenBy', isEqualTo: companyId)
        .where('realizationStatus', isEqualTo: 'approved')
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Filmy firmy są wyszukiwane po ich własnym polu location —
  /// po zmianie adresu firmy trzeba je przepiąć na nową lokalizację.
  Future<void> updateCompanyPromosLocation(String userId, LatLng location) async {
    final snap = await _firestore
        .collection('promos')
        .where('userId', isEqualTo: userId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {
        'location': {'lat': location.latitude, 'lng': location.longitude},
      });
    }
    await batch.commit();
  }

  Future<void> updateRequestDescription(String requestId, String description) async {
    await _firestore.collection('requests').doc(requestId).update({'description': description});
  }


  // ── PROŚBA O KONTAKT (klient czeka na telefon od firmy) ─────────────────

  String _contactRequestId(String companyId, String userId) => '${companyId}_$userId';

  Future<Map<String, dynamic>?> getContactRequest(
      {required String myUid, required String companyId}) async {
    final d = await _firestore
        .collection('contactRequests')
        .doc(_contactRequestId(companyId, myUid))
        .get();
    return d.data();
  }

  /// Jedna aktywna prośba na parę klient–firma; ponowna nadpisuje poprzednią.
  /// Obie strony trafiają do siebie w kontakty (Klienci / Moje firmy).
  Future<void> sendContactRequest({
    required String myUid,
    required String companyId,
    required String companyName,
    required String phone,
    required String note,
  }) async {
    final me = await fetchUser(myUid);
    final id = _contactRequestId(companyId, myUid);
    final batch = _firestore.batch()
      ..set(_firestore.collection('contactRequests').doc(id), {
      'userId': myUid,
      'companyId': companyId,
      'userName': '${me?.firstName ?? ''} ${me?.lastName ?? ''}'.trim(),
      'companyName': companyName,
      'phone': phone,
      'note': note,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'doneAt': null,
    });
    // relacja w tym samym zapisie — od niej zależy dostęp firmy do telefonu klienta
    await _linkClient(
        companyId: companyId, userId: myUid, requestId: 'contact_$id', batch: batch);
    await batch.commit();
  }

  Future<void> setContactRequestDone(String id) async {
    await _firestore.collection('contactRequests').doc(id).update({
      'status': 'done',
      'doneAt': FieldValue.serverTimestamp(),
    });
  }

  // ── KONTAKTY ─────────────────────────────────────────────────────────────

  Future<void> addContact({
    required String myUserId,
    required String contactUserId,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(myUserId)
        .collection('contacts')
        .doc(contactUserId);
    await ref.set({
      'userId': contactUserId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeContact({
    required String myUserId,
    required String contactUserId,
  }) async {
    await _firestore
        .collection('users')
        .doc(myUserId)
        .collection('contacts')
        .doc(contactUserId)
        .delete();
  }

  Future<List<String>> getContactIds(String myUserId) async {
    final snap = await _firestore
        .collection('users')
        .doc(myUserId)
        .collection('contacts')
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  Future<bool> isContact({
    required String myUserId,
    required String contactUserId,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(myUserId)
        .collection('contacts')
        .doc(contactUserId)
        .get();
    return doc.exists;
  }


  // ── KOSZ ZGŁOSZEŃ (dla firm) ─────────────────────────────────────────────

  Future<void> trashRequest({
    required String userId,
    required String requestId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('skippedRequests')
        .doc(requestId)
        .set({
      'skippedAt': FieldValue.serverTimestamp(),
      'trashed': true,
    });
  }

  Future<void> restoreRequest({
    required String userId,
    required String requestId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('skippedRequests')
        .doc(requestId)
        .delete();
  }

  /// Usunięcie z kosza: zgłoszenie dalej ukryte w feedzie, ale znika z listy kosza.
  Future<void> purgeFromTrash({
    required String userId,
    required String requestId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('skippedRequests')
        .doc(requestId)
        .set({'skippedAt': FieldValue.serverTimestamp(), 'trashed': false});
  }

  Future<List<Request>> getTrashedRequests({required String userId}) async {
    final skippedSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('skippedRequests')
        .where('trashed', isEqualTo: true)
        .get();

    if (skippedSnap.docs.isEmpty) return [];

    final ids = skippedSnap.docs.map((d) => d.id).toList();
    final results = <Request>[];

    // Firestore whereIn limit to 10 — dzielimy na chunki
    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snap = await _firestore
          .collection('requests')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map((d) => Request.fromDoc(d)));
    }
    return results;
  }


  // ── KALENDARZ FIRMY (sloty na 7 dni do przodu, rezerwacje na kropki) ─────
  // users/{companyId}/slots/{slotId}:
  //   {start: Timestamp, status: 'free'|'pending'|'accepted',
  //    bookedBy, bookedByName, bookedAt,
  //    releasedBy: 'user'|'expired'|'rejected' — kto ostatnio zwolnił termin}
  // users/{uid}/myBookings/{companyId}_{slotId} — kopia rezerwacji klienta,
  //   status: 'pending'|'accepted'|'rejected'|'cancelled' (firma usunęła termin)

  static const _pendingTtl = Duration(hours: 1);

  DocumentReference<Map<String, dynamic>> _slotRef(
          String companyId, String slotId) =>
      _firestore
          .collection('users')
          .doc(companyId)
          .collection('slots')
          .doc(slotId);

  DocumentReference<Map<String, dynamic>> _myBookingRef(
          String myUid, String companyId, String slotId) =>
      _firestore
          .collection('users')
          .doc(myUid)
          .collection('myBookings')
          .doc('${companyId}_$slotId');

  /// Żółta rezerwacja (slot albo kopia w myBookings) bez decyzji firmy
  /// wygasa po godzinie.
  bool _pendingExpired(Map<String, dynamic> d) {
    final bookedAt = (d['bookedAt'] as Timestamp?)?.toDate();
    return d['status'] == 'pending' &&
        bookedAt != null &&
        DateTime.now().difference(bookedAt) >= _pendingTtl;
  }

  /// Pola zwolnionego terminu; po [releasedBy] Cloud Function wie,
  /// kogo powiadomić.
  Map<String, dynamic> _freed(String releasedBy) => {
        'status': 'free',
        'bookedBy': '',
        'bookedByName': '',
        'releasedBy': releasedBy,
      };

  /// Sloty z 7 dni do przodu; wygasła żółta rezerwacja wygląda jak wolna.
  List<Map<String, dynamic>> _slotsFromDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final weekAhead = now.add(const Duration(days: 7));
    final slots = <Map<String, dynamic>>[];
    for (final d in docs) {
      final data = d.data();
      final start = (data['start'] as Timestamp?)?.toDate();
      if (start == null) continue;
      if (start.isBefore(now) || start.isAfter(weekAhead)) continue;
      // 'rejected' z wersji ≤1.3.2 to w praktyce wolny termin
      final expired = _pendingExpired(data) || data['status'] == 'rejected';
      slots.add({
        'id': d.id,
        'start': start,
        'status': expired ? 'free' : (data['status'] ?? 'free'),
        'bookedBy': expired ? '' : (data['bookedBy'] ?? ''),
        'bookedByName': expired ? '' : (data['bookedByName'] ?? ''),
      });
    }
    return slots;
  }

  Future<List<Map<String, dynamic>>> getSlots(String companyId) async {
    final snap = await _firestore
        .collection('users')
        .doc(companyId)
        .collection('slots')
        .orderBy('start')
        .get();
    return _slotsFromDocs(snap.docs);
  }

  /// Live-podgląd slotów (7 dni).
  Stream<List<Map<String, dynamic>>> slotsStream(String companyId) {
    return _firestore
        .collection('users')
        .doc(companyId)
        .collection('slots')
        .orderBy('start')
        .snapshots()
        .map((snap) => _slotsFromDocs(snap.docs));
  }

  /// Zwalnia wygasłą żółtą rezerwację osobnym zapisem, żeby Cloud Function
  /// powiadomiła klienta. Zwraca true, gdy coś zwolniono.
  Future<bool> _releaseIfExpired(DocumentReference<Map<String, dynamic>> ref) =>
      _firestore.runTransaction((tx) async {
        final d = (await tx.get(ref)).data();
        if (d == null || !_pendingExpired(d)) return false;
        tx.update(ref, _freed('expired'));
        return true;
      });

  Future<String> _companyNameTx(Transaction tx, String companyId) async {
    final d = (await tx.get(_firestore.collection('users').doc(companyId))).data();
    return (d?['companyName'] as String?) ?? 'Firma';
  }

  /// Decyzja firmy w kopii rezerwacji klienta — z pełnymi polami, bo kopii
  /// mogło już nie być.
  void _decideBookingTx(Transaction tx, Map<String, dynamic> slot,
      {required String client,
      required String companyId,
      required String companyName,
      required String slotId,
      required String status}) {
    tx.set(
        _myBookingRef(client, companyId, slotId),
        {
          'companyId': companyId,
          'companyName': companyName,
          'slotId': slotId,
          'start': slot['start'],
          'status': status,
          'decidedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
  }

  /// Dokumenty relacji klient↔firma (clients/{klient}, myCompanies/{firma})
  /// — odczyt w transakcji przed zapisami.
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _readRelationTx(
          Transaction tx, String companyId, String userId) async =>
      [
        await tx.get(_firestore
            .collection('users')
            .doc(companyId)
            .collection('clients')
            .doc(userId)),
        await tx.get(_firestore
            .collection('users')
            .doc(userId)
            .collection('myCompanies')
            .doc(companyId)),
      ];

  /// Zdejmuje z relacji termin albo zgłoszenie; relacja bez żadnego źródła
  /// (zgłoszenia, rezerwacji, prośby o kontakt) jest kasowana.
  void _unlinkTx(Transaction tx,
      List<DocumentSnapshot<Map<String, dynamic>>> relation,
      {String? slotId, String? requestId}) {
    for (final s in relation) {
      final d = s.data();
      if (d == null) continue;
      final slotIds = (d['slotIds'] as List?) ?? const [];
      final requestIds = (d['requestIds'] as List?) ?? const [];
      // EXPIRES: po uruchomieniu demo/_seed/migrate_relation_request_id.js --apply
      final legacy = d['requestId'] as String? ?? '';
      if (!slotIds.contains(slotId) &&
          !requestIds.contains(requestId) &&
          (requestId == null || legacy != requestId)) {
        continue;
      }
      final left = slotIds.any((id) => id != slotId) ||
          requestIds.any((id) => id != requestId) ||
          (legacy.isNotEmpty && legacy != requestId) ||
          ((d['contactRequestId'] as String?) ?? '').isNotEmpty;
      if (!left) {
        tx.delete(s.reference);
      } else if (slotId != null) {
        tx.update(s.reference, {
          'slotIds': FieldValue.arrayRemove([slotId])
        });
      } else {
        tx.update(s.reference, {
          'requestIds': FieldValue.arrayRemove([requestId]),
          if (legacy == requestId) 'requestId': FieldValue.delete(),
        });
      }
    }
  }

  /// Klient rezerwuje wolny termin (transakcja chroni przed wyścigiem);
  /// wygasłą żółtą rezerwację przejmuje jak wolny — poprzedniego klienta
  /// powiadamia Cloud Function. Kopia trafia w tej samej transakcji do
  /// users/{ja}/myBookings. Rzuca [SlotException] z komunikatem dla użytkownika.
  Future<void> bookSlot({
    required String companyId,
    required String slotId,
    required String myUid,
    required String myName,
  }) async {
    if (companyId == myUid) {
      throw const SlotException('To Twój termin — nie możesz go zarezerwować');
    }
    final ref = _slotRef(companyId, slotId);
    await _firestore.runTransaction((tx) async {
      final slot = (await tx.get(ref)).data();
      if (slot == null) throw const SlotException('Firma usunęła ten termin');
      final start = (slot['start'] as Timestamp?)?.toDate();
      if (start == null || start.isBefore(DateTime.now())) {
        throw const SlotException('Ten termin już minął');
      }
      if ((slot['status'] ?? 'free') != 'free' && !_pendingExpired(slot)) {
        throw const SlotException('Ten termin jest już zajęty');
      }
      final companyName = await _companyNameTx(tx, companyId);
      tx.update(ref, {
        'status': 'pending',
        'bookedBy': myUid,
        'bookedByName': myName,
        'bookedAt': FieldValue.serverTimestamp(),
      });
      tx.set(_myBookingRef(myUid, companyId, slotId), {
        'companyId': companyId,
        'companyName': companyName,
        'slotId': slotId,
        'start': Timestamp.fromDate(start),
        'status': 'pending',
        'bookedAt': FieldValue.serverTimestamp(),
      });
    });

    // rezerwacja też buduje relację: klient u firmy i firma u klienta
    await _linkClient(
        companyId: companyId, userId: myUid, requestId: 'slot_$slotId');
  }

  /// Nadchodzące rezerwacje usera (firma + godzina + status). Sprząta wpisy
  /// minione i wygasłe żółte; minione przyjęte zostają w bazie — są dowodem
  /// wizyty, który uprawnia do recenzji (canReviewCompany).
  Future<List<Map<String, dynamic>>> getMyBookings(String myUid) async {
    final snap = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('myBookings')
        .get();
    final now = DateTime.now();
    final out = <Map<String, dynamic>>[];
    final toDelete = <DocumentReference>[];
    for (final d in snap.docs) {
      final data = d.data();
      final start = (data['start'] as Timestamp?)?.toDate();
      if (start == null || start.isBefore(now) || _pendingExpired(data)) {
        if (data['status'] != 'accepted') toDelete.add(d.reference);
        continue;
      }
      out.add({...data, 'start': start});
    }
    if (toDelete.isNotEmpty) {
      final batch = _firestore.batch();
      for (final r in toDelete) {
        batch.delete(r);
      }
      // sprzątanie w tle — nieudane powtórzy się przy następnym odczycie
      batch.commit().ignore();
    }
    out.sort(
        (a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime));
    return out;
  }

  /// Klient odwołuje rezerwację albo usuwa z listy wpis odrzucony / odwołany
  /// przez firmę. Termin wraca do puli tylko wtedy, gdy nadal zajmuje go ten
  /// klient; kopia w myBookings znika zawsze (także gdy terminu już nie ma).
  Future<void> cancelSlotBooking({
    required String companyId,
    required String slotId,
    required String myUid,
  }) async {
    final ref = _slotRef(companyId, slotId);
    await _firestore.runTransaction((tx) async {
      final slot = (await tx.get(ref)).data();
      final relation = await _readRelationTx(tx, companyId, myUid);
      if (slot != null &&
          slot['bookedBy'] == myUid &&
          slot['status'] != 'free') {
        tx.update(ref, _freed('user'));
      }
      _unlinkTx(tx, relation, slotId: slotId);
      tx.delete(_myBookingRef(myUid, companyId, slotId));
    });
  }

  /// Firma przyjmuje albo odrzuca rezerwację klienta [bookedBy]. Odrzucenie
  /// zwalnia termin — status 'rejected' zostaje tylko w myBookings klienta.
  /// Rzuca [SlotException], gdy rezerwacja jest już nieaktualna.
  Future<void> setSlotStatus({
    required String companyId,
    required String slotId,
    required String status,
    required String bookedBy,
  }) async {
    final ref = _slotRef(companyId, slotId);
    if (await _releaseIfExpired(ref)) {
      throw const SlotException('Rezerwacja wygasła — minęła godzina bez decyzji');
    }
    await _firestore.runTransaction((tx) async {
      final slot = (await tx.get(ref)).data();
      if (slot == null ||
          slot['status'] != 'pending' ||
          slot['bookedBy'] != bookedBy) {
        throw const SlotException('Ta rezerwacja jest już nieaktualna');
      }
      final companyName = await _companyNameTx(tx, companyId);
      final relation = status == 'rejected'
          ? await _readRelationTx(tx, companyId, bookedBy)
          : null;
      tx.update(ref, status == 'rejected' ? _freed('rejected') : {'status': status});
      _decideBookingTx(tx, slot,
          client: bookedBy,
          companyId: companyId,
          companyName: companyName,
          slotId: slotId,
          status: status);
      if (relation != null) _unlinkTx(tx, relation, slotId: slotId);
    });
  }

  Future<void> addSlot(String companyId, DateTime start) async {
    await _firestore
        .collection('users')
        .doc(companyId)
        .collection('slots')
        .add({'start': Timestamp.fromDate(start)});
  }

  Future<void> addSlotsBatch(
      String companyId, List<DateTime> starts, int durationMin) async {
    if (starts.isEmpty) return;
    final col =
        _firestore.collection('users').doc(companyId).collection('slots');
    final batch = _firestore.batch();
    for (final s in starts) {
      batch.set(col.doc(), {
        'start': Timestamp.fromDate(s),
        'durationMin': durationMin,
      });
    }
    await batch.commit();
  }

  /// Firma usuwa termin. Zajęty (żółty/zielony) trafia do myBookings klienta
  /// jako 'cancelled' — o odwołaniu powiadamia go Cloud Function.
  Future<void> removeSlot(String companyId, String slotId) async {
    final ref = _slotRef(companyId, slotId);
    await _releaseIfExpired(ref);
    await _firestore.runTransaction((tx) async {
      final slot = (await tx.get(ref)).data();
      if (slot == null) return;
      final client = (slot['bookedBy'] as String?) ?? '';
      if (client.isNotEmpty &&
          (slot['status'] == 'pending' || slot['status'] == 'accepted')) {
        final companyName = await _companyNameTx(tx, companyId);
        final relation = await _readRelationTx(tx, companyId, client);
        _decideBookingTx(tx, slot,
            client: client,
            companyId: companyId,
            companyName: companyName,
            slotId: slotId,
            status: 'cancelled');
        _unlinkTx(tx, relation, slotId: slotId);
      }
      tx.delete(ref);
    });
  }

  /// Sprzątanie przy wejściu firmy w kalendarz: kasuje minione sloty
  /// i zwalnia wygasłe żółte rezerwacje.
  Future<void> cleanupOldSlots(String companyId) async {
    final col =
        _firestore.collection('users').doc(companyId).collection('slots');

    final old = await col.where('start', isLessThan: Timestamp.now()).get();
    // batch przyjmuje max 500 zapisów
    for (var i = 0; i < old.docs.length; i += 400) {
      final batch = _firestore.batch();
      for (final d in old.docs.skip(i).take(400)) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }

    final oldIds = {for (final d in old.docs) d.id};
    final pending = await col.where('status', isEqualTo: 'pending').get();
    for (final d in pending.docs) {
      if (oldIds.contains(d.id) || !_pendingExpired(d.data())) continue;
      await _releaseIfExpired(d.reference);
    }
  }

  // ── OFERTY DO ZGŁOSZEŃ (firma pisze, user daje ✔ / ? / ✖) ────────────────
  // requests/{id}/offers/{companyId}: {companyId, companyName, message,
  //   status: 'pending'|'maybe'|'accepted'|'rejected'|'closed', timestamp}
  //   closed = klient wybrał inną ofertę

  Future<void> sendOffer({
    required String requestId,
    required String companyId,
    required String companyName,
    required String message,
    int? price,
    int? priceTo,
    String? when,
  }) async {
    await _firestore
        .collection('requests')
        .doc(requestId)
        .collection('offers')
        .doc(companyId)
        .set({
      'companyId': companyId,
      'companyName': companyName,
      'message': message,
      // pola opcjonalne — bez nich oferta jest taka jak w 1.3.x
      if (price != null) 'price': price,
      if (price != null && priceTo != null) 'priceTo': priceTo,
      if (when != null) 'when': when,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getMyOffer(
      String requestId, String companyId) async {
    final doc = await _firestore
        .collection('requests')
        .doc(requestId)
        .collection('offers')
        .doc(companyId)
        .get();
    return doc.data();
  }

  // ── MODERACJA: zgłoszenia nadużyć i blokowanie użytkowników ──────────────
  // reports/{auto}: {reporterId, targetType, targetId, targetUserId, reason, details, createdAt, status}
  // users/{uid}/blocked/{otherUid}: {createdAt}

  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String targetUserId,
    required String reason,
    String details = '',
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': _auth.currentUser!.uid,
      'targetType': targetType,
      'targetId': targetId,
      'targetUserId': targetUserId,
      'reason': reason,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'new',
    });
  }

  CollectionReference<Map<String, dynamic>> _blocked(String uid) =>
      _firestore.collection('users').doc(uid).collection('blocked');

  Future<Set<String>> getBlockedUsers(String uid) async {
    final snap = await _blocked(uid).get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// Blokada odbiera też zablokowanej firmie dostęp do mojego telefonu i e-maila (relacja).
  Future<void> blockUser(String uid, String otherUid) {
    final users = _firestore.collection('users');
    return (_firestore.batch()
          ..set(_blocked(uid).doc(otherUid), {'createdAt': FieldValue.serverTimestamp()})
          ..delete(users.doc(otherUid).collection('clients').doc(uid))
          ..delete(users.doc(uid).collection('myCompanies').doc(otherUid)))
        .commit();
  }

  Future<void> unblockUser(String uid, String otherUid) =>
      _blocked(uid).doc(otherUid).delete();

  // ── PRYWATNE NOTATKI FIRMY O KLIENCIE ────────────────────────────────────
  // users/{companyId}/clientNotes/{userId}: {note, updatedAt}

  Future<void> setClientNote({
    required String companyId,
    required String userId,
    required String note,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(companyId)
        .collection('clientNotes')
        .doc(userId);
    if (note.trim().isEmpty) {
      await ref.delete();
      return;
    }
    await ref.set({
      'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Wszystkie notatki firmy: {userId: treść}
  Future<Map<String, String>> getClientNotes(String companyId) async {
    final snap = await _firestore
        .collection('users')
        .doc(companyId)
        .collection('clientNotes')
        .get();
    return {
      for (final d in snap.docs) d.id: (d.data()['note'] ?? '') as String
    };
  }

  /// Oferty zgłoszenia na żywo — klient widzi nową ofertę bez wychodzenia z ekranu.
  Stream<List<Map<String, dynamic>>> offersStream(String requestId) => _firestore
      .collection('requests')
      .doc(requestId)
      .collection('offers')
      .orderBy('timestamp')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());

  Future<List<Map<String, dynamic>>> getOffers(String requestId) async {
    final snap = await _firestore
        .collection('requests')
        .doc(requestId)
        .collection('offers')
        .orderBy('timestamp')
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// ✔ accept — blokuje zgłoszenie na tę firmę, pozostałe oferty zamyka
  ///   ('closed') i tworzy relację klient↔firma.
  /// ? maybe — znacznik „klient się zastanawia".
  /// ✖ reject — całkowite odrzucenie firmy (nie może ofertować ponownie).
  Future<void> setOfferStatus({
    required Request request,
    required String companyId,
    required String companyName,
    required String status,
  }) async {
    final reqRef = _firestore.collection('requests').doc(request.id);
    final offersRef = reqRef.collection('offers');
    final batch = _firestore.batch();
    batch.update(offersRef.doc(companyId),
        {'status': status, 'decidedAt': FieldValue.serverTimestamp()});

    if (status == 'accepted') {
      final others =
          await offersRef.where('status', whereIn: ['pending', 'maybe']).get();
      for (final d in others.docs) {
        if (d.id == companyId) continue;
        batch.update(d.reference,
            {'status': 'closed', 'decidedAt': FieldValue.serverTimestamp()});
      }
      batch.update(reqRef, {
        'takenBy': companyId,
        'takenByName': companyName,
        'confirmedByCompany': true,
        'confirmedByUser': true,
        'status': 'taken',
        'takenAt': FieldValue.serverTimestamp(),
      });
      // relacja w tym samym zapisie — od niej zależy dostęp firmy do telefonu klienta
      await _linkClient(
          companyId: companyId, userId: request.userId, requestId: request.id, batch: batch);
    }
    await batch.commit();
  }

  /// Odblokowanie zadania przez klienta — wraca do puli, oferta firmy
  /// i oferty zamknięte przy akceptacji wracają do 'pending', zdjęcia
  /// realizacji tej firmy są kasowane, a z relacji klient↔firma znika
  /// tylko to zgłoszenie.
  Future<void> unlockRequest(Request request) async {
    final companyId = request.takenBy;
    final reqRef = _firestore.collection('requests').doc(request.id);
    final offers = await reqRef
        .collection('offers')
        .where('status', whereIn: ['accepted', 'closed']).get();
    final photos = companyId.isEmpty
        ? null
        : await _firestore
            .collection('realizations')
            .where('requestId', isEqualTo: request.id)
            .where('userId', isEqualTo: request.userId)
            .where('companyId', isEqualTo: companyId)
            .get();
    // relacja znika w tym samym zapisie — od niej zależy dostęp firmy do telefonu klienta
    await _firestore.runTransaction((tx) async {
      final relation = companyId.isEmpty
          ? null
          : await _readRelationTx(tx, companyId, request.userId);
      tx.update(reqRef, {
        'takenBy': '',
        'takenByName': '',
        'confirmedByCompany': false,
        'confirmedByUser': false,
        'status': 'open',
        'realizationStatus': FieldValue.delete(),
      });
      for (final d in offers.docs) {
        tx.update(d.reference, {'status': 'pending'});
      }
      for (final d in photos?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
        if (d.data()['addedByRole'] != 'user') tx.delete(d.reference);
      }
      if (relation != null) _unlinkTx(tx, relation, requestId: request.id);
    });
    if (companyId.isEmpty) return;

    // powiadomienia o tej realizacji, żeby nie wisiały w dzwonku
    try {
      final notifs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: request.userId)
          .where('requestId', isEqualTo: request.id)
          .get();
      for (final d in notifs.docs) {
        final t = d.data()['type'] as String? ?? '';
        if (t.startsWith('realization')) await d.reference.delete();
      }
    } catch (_) {}
  }

  /// Z [batch] relacja zapisuje się razem z resztą operacji (commit robi wywołujący).
  Future<void> _linkClient({
    required String companyId,
    required String userId,
    required String requestId,
    WriteBatch? batch,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final companyDoc = await _firestore.collection('users').doc(companyId).get();
    final userData = userDoc.data() ?? {};
    final companyData = companyDoc.data() ?? {};

    // rezerwacje przychodzą jako 'slot_<id>' — trzymamy osobno, żeby lista
    // klientów mogła pokazać „skąd ta osoba" i dać odnośnik
    final isSlot = requestId.startsWith('slot_');
    final isContact = requestId.startsWith('contact_');
    final linkFields = <String, dynamic>{
      if (isSlot)
        'slotIds': FieldValue.arrayUnion([requestId.substring(5)])
      else if (isContact)
        'contactRequestId': requestId.substring(8)
      else
        'requestIds': FieldValue.arrayUnion([requestId]),
      'lastAt': FieldValue.serverTimestamp(),
    };
    final clientRef = _firestore
        .collection('users')
        .doc(companyId)
        .collection('clients')
        .doc(userId);
    final companyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('myCompanies')
        .doc(companyId);
    final firstTime = !(await clientRef.get()).exists;

    final b = batch ?? _firestore.batch();
    b.set(
      clientRef,
      {
        'userId': userId,
        'name':
            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
        if (firstTime) 'addedAt': FieldValue.serverTimestamp(),
        ...linkFields,
      },
      SetOptions(merge: true),
    );
    b.set(
      companyRef,
      {
        'companyId': companyId,
        'name': companyData['companyName'] ?? 'Firma',
        if (firstTime) 'addedAt': FieldValue.serverTimestamp(),
        ...linkFields,
      },
      SetOptions(merge: true),
    );
    if (batch == null) await b.commit();
  }

  /// Zgłoszenie po id (do odnośników z listy klientów).
  Future<Request?> getRequestById(String id) async {
    final doc = await _firestore.collection('requests').doc(id).get();
    if (!doc.exists) return null;
    return Request.fromDoc(doc);
  }

  /// Aktualna rezerwacja klienta [clientId] w slocie firmy — do odnośnika
  /// „Rezerwacja". Null, gdy termin zniknął, jest wolny, wygasł albo zajął
  /// go ktoś inny (wspólny slot nie mówi nic o dawnych rezerwujących).
  Future<SlotRef?> getSlotRef(
      String companyId, String slotId, String clientId) async {
    final doc = await _slotRef(companyId, slotId).get();
    final d = doc.data();
    if (d == null || d['start'] == null || d['bookedBy'] != clientId) {
      return null;
    }
    final status = d['status'] as String?;
    if (status != 'pending' && status != 'accepted') return null;
    if (_pendingExpired(d)) return null;
    return SlotRef(
      id: doc.id,
      companyId: companyId,
      start: (d['start'] as Timestamp).toDate(),
      status: status!,
    );
  }

  /// Zbiera relację z dokumentu clients/myCompanies: nowe pola tablicowe
  /// + stare pojedyncze `requestId` (może być 'slot_<id>').
  /// [clientId] — klient tej relacji (rezerwacje pokazujemy tylko jego).
  Future<RelationLink?> _linkFromDoc(DocumentSnapshot<Map<String, dynamic>> d,
      String personId, String companyId, String clientId) async {
    final u = await fetchUser(personId, withContact: personId == clientId);
    if (u == null) return null;
    final data = d.data() ?? {};
    final reqIds = <String>{
      ...((data['requestIds'] as List?)?.cast<String>() ?? const []),
    };
    final slotIds = <String>{
      ...((data['slotIds'] as List?)?.cast<String>() ?? const []),
    };
    // EXPIRES: po uruchomieniu demo/_seed/migrate_relation_request_id.js --apply
    final legacy = data['requestId'] as String?;
    if (legacy != null && legacy.isNotEmpty) {
      if (legacy.startsWith('slot_')) {
        slotIds.add(legacy.substring(5));
      } else {
        reqIds.add(legacy);
      }
    }
    final requests = <Request>[];
    for (final id in reqIds) {
      final r = await getRequestById(id);
      if (r != null) requests.add(r);
    }
    final slots = <SlotRef>[];
    for (final id in slotIds) {
      final s = await getSlotRef(companyId, id, clientId);
      if (s != null) slots.add(s);
    }
    slots.sort((a, b) => b.start.compareTo(a.start));
    ContactRef? contact;
    final contactId = data['contactRequestId'] as String?;
    if (contactId != null && contactId.isNotEmpty) {
      final c = await _firestore.collection('contactRequests').doc(contactId).get();
      final cd = c.data();
      if (cd != null) {
        contact = ContactRef(
          id: contactId,
          phone: cd['phone'] as String? ?? '',
          note: cd['note'] as String? ?? '',
          status: cd['status'] as String? ?? 'pending',
          createdAt: (cd['createdAt'] as Timestamp?)?.toDate(),
        );
      }
    }
    return RelationLink(
      user: u,
      requests: requests,
      slots: slots,
      contact: contact,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Klienci firmy wraz ze źródłem relacji (zgłoszenia, rezerwacje).
  Future<List<RelationLink>> getClientLinks(String companyId) async {
    final snap = await _firestore
        .collection('users')
        .doc(companyId)
        .collection('clients')
        .get();
    final out = <RelationLink>[];
    for (final d in snap.docs) {
      final l = await _linkFromDoc(d, d.id, companyId, d.id);
      if (l != null) out.add(l);
    }
    out.sort((a, b) =>
        (b.addedAt ?? DateTime(2000)).compareTo(a.addedAt ?? DateTime(2000)));
    return out;
  }

  /// Firmy użytkownika wraz ze źródłem relacji.
  Future<List<RelationLink>> getMyCompanyLinks(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('myCompanies')
        .get();
    final out = <RelationLink>[];
    for (final d in snap.docs) {
      final l = await _linkFromDoc(d, d.id, d.id, userId);
      if (l != null) out.add(l);
    }
    out.sort((a, b) =>
        (b.addedAt ?? DateTime(2000)).compareTo(a.addedAt ?? DateTime(2000)));
    return out;
  }

  // ── KLIENCI FIRMY / MOJE FIRMY ───────────────────────────────────────────

  Future<List<AppUser>> getClients(String companyId) async {
    final snap = await _firestore
        .collection('users')
        .doc(companyId)
        .collection('clients')
        .orderBy('addedAt', descending: true)
        .get();
    final users = <AppUser>[];
    for (final d in snap.docs) {
      final u = await fetchUser(d.id);
      if (u != null) users.add(u);
    }
    return users;
  }

  Future<List<AppUser>> getMyCompanies(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('myCompanies')
        .orderBy('addedAt', descending: true)
        .get();
    final users = <AppUser>[];
    for (final d in snap.docs) {
      final u = await fetchUser(d.id);
      if (u != null) users.add(u);
    }
    return users;
  }

  // ── PILNE ZGŁOSZENIA W POBLIŻU (powiadomienie in-app) ────────────────────

  /// Pilne zgłoszenia z ostatniej doby — te same, które firma widzi
  /// na liście (branża, bez pominiętych, tylko otwarte).
  Future<int> getUrgentNearbyCount({
    required String companyId,
    required String category,
    required String sector,
    required LatLng myLocation,
    double radiusKm = 30,
  }) async {
    final since = DateTime.now().subtract(const Duration(hours: 24));
    final skippedIds = await _skippedRequestIds(companyId);
    final snap = await _firestore
        .collection('requests')
        .where('category', isEqualTo: category)
        .where('sector', isEqualTo: sector)
        .where('is24', isEqualTo: true)
        .get();

    int count = 0;
    for (final d in snap.docs) {
      final req = Request.fromDoc(d);
      if (req.status != 'open' ||
          !req.isActiveFor(companyId) ||
          skippedIds.contains(req.id)) {
        continue;
      }
      if (req.timestamp == null || req.timestamp!.isBefore(since)) continue;
      final distMeters = Geolocator.distanceBetween(
        myLocation.latitude,
        myLocation.longitude,
        req.location.latitude,
        req.location.longitude,
      );
      if (distMeters <= radiusKm * 1000) count++;
    }
    return count;
  }

  // ── REALIZACJE (zdjęcia wykonanych zleceń) ───────────────────────────────
  // Kolekcja realizations: {companyId, requestId, category, imageUrl, timestamp}
  // requests/{id}.realizationStatus: pending (firma dodała) → approved | rejected

  /// Firma ma przy zgłoszeniu jedną realizację czekającą lub potwierdzoną;
  /// odrzucona jest zastępowana nową.
  Future<void> addRealization({
    required String companyId,
    required String requestId,
    required String requestOwnerId,
    required String category,
    required File image,
    File? beforeImage,
    /// 'company' = wykonawca prosi o potwierdzenie, 'user' = zdjęcia od klienta
    String addedByRole = 'company',
  }) async {
    final realizations = _firestore.collection('realizations');
    final batch = _firestore.batch();
    if (addedByRole == 'company') {
      final existing = await realizations
          .where('requestId', isEqualTo: requestId)
          .where('companyId', isEqualTo: companyId)
          .get();
      for (final d in existing.docs) {
        if (d.data()['addedByRole'] == 'user') continue;
        if ((d.data()['status'] ?? 'approved') != 'rejected') {
          throw StateError('Zdjęcia realizacji są już dodane');
        }
        batch.delete(d.reference);
      }
    }

    final ref = await _putOwnFile('realizations', image, 'image');
    String? beforeUrl;
    if (beforeImage != null) {
      final beforeRef = await _putOwnFile('realizations', beforeImage, 'image',
          suffix: '_before');
      beforeUrl = await beforeRef.getDownloadURL();
    }

    batch.set(realizations.doc(), {
      'companyId': companyId,
      'requestId': requestId,
      'userId': requestOwnerId,
      'category': category,
      'imageUrl': await ref.getDownloadURL(),
      if (beforeUrl != null) 'beforeUrl': beforeUrl,
      'addedByRole': addedByRole,
      // zdjęcia firmy czekają na potwierdzenie klienta; zdjęcia klienta są
      // od razu „jego", ale na profil firmy trafiają dopiero po publikacji
      'status': addedByRole == 'company' ? 'pending' : 'approved',
      'publishedByCompany': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (addedByRole == 'company') {
      batch.update(_firestore.collection('requests').doc(requestId),
          {'realizationStatus': 'pending'});
    }
    await batch.commit();
  }

  /// Firma wycofuje swoje zdjęcia realizacji — zgłoszenie wraca do realizacji.
  Future<void> withdrawRealization(String id, String requestId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('realizations').doc(id));
    batch.update(_firestore.collection('requests').doc(requestId),
        {'realizationStatus': FieldValue.delete()});
    await batch.commit();
  }

  /// Firma publikuje w portfolio zdjęcia dodane przez klienta.
  Future<void> setRealizationPublished(String id, bool published) async {
    await _firestore
        .collection('realizations')
        .doc(id)
        .update({'publishedByCompany': published});
  }

  // ── POWIADOMIENIA (dzwonek) ───────────────────────────────────────────────

  /// Wpis widoczny w danym trybie konta: firma widzi swoje, klient swoje,
  /// 'both' (np. rozmowy) zawsze.
  static bool isNotificationForMode(Map<String, dynamic> n, bool companyMode) {
    final aud = (n['audience'] as String?) ?? 'both';
    return aud == 'both' || aud == (companyMode ? 'company' : 'user');
  }

  /// 60 najnowszych wpisów; [companyMode] zawęża je do trybu konta.
  Stream<List<Map<String, dynamic>>> notificationsStream(String uid,
      {bool? companyMode}) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((n) =>
                companyMode == null || isNotificationForMode(n, companyMode))
            .toList());
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _firestore.collection('notifications').doc(id).update({'read': true});
    } on FirebaseException catch (e) {
      // wpis mógł zostać już usunięty
      if (e.code != 'not-found') rethrow;
    }
  }

  Future<void> markAllNotificationsRead(String uid, {bool? companyMode}) async {
    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final d in snap.docs) {
      if (companyMode != null && !isNotificationForMode(d.data(), companyMode)) {
        continue;
      }
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }

  /// Recenzję może wystawić tylko klient z potwierdzoną realizacją
  /// albo przyjętym terminem w tej firmie (także minionym — getMyBookings
  /// nie kasuje przyjętych).
  Future<bool> canReviewCompany(String myUid, String companyId) async {
    if (myUid.isEmpty) return false;
    final bookings = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('myBookings')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'accepted')
        .limit(1)
        .get();
    if (bookings.docs.isNotEmpty) return true;
    final jobs = await _firestore
        .collection('requests')
        .where('userId', isEqualTo: myUid)
        .where('takenBy', isEqualTo: companyId)
        .where('realizationStatus', isEqualTo: 'approved')
        .limit(1)
        .get();
    return jobs.docs.isNotEmpty;
  }

  /// Klient zamyka zgłoszenie ręcznie (bez usuwania historii).
  Future<void> closeRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      'closedReason': 'byUser',
    });
  }

  /// Decyzja klienta o czekających zdjęciach firmy: 'approved' zamyka
  /// zgłoszenie jako zrealizowane, 'rejected' zostawia je w realizacji
  /// (firma może dodać nowe zdjęcia).
  Future<void> setRealizationStatus(String requestId, String status) async {
    final pending = await _firestore
        .collection('realizations')
        .where('requestId', isEqualTo: requestId)
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .where('status', isEqualTo: 'pending')
        .get();
    final companyPhotos =
        pending.docs.where((d) => d.data()['addedByRole'] != 'user');
    if (companyPhotos.isEmpty) {
      throw StateError('Firma wycofała te zdjęcia');
    }
    final batch = _firestore.batch();
    for (final d in companyPhotos) {
      batch.update(d.reference,
          {'status': status, 'decidedAt': FieldValue.serverTimestamp()});
    }
    batch.update(_firestore.collection('requests').doc(requestId), {
      'realizationStatus': status,
      if (status == 'approved') ...{
        'status': 'closed',
        'closedReason': 'realized',
        'closedAt': FieldValue.serverTimestamp(),
      },
    });
    await batch.commit();
  }

  /// Realizacje firmy. Domyślnie tylko potwierdzone przez klienta
  /// (stare wpisy bez pola `status` traktujemy jako potwierdzone).
  Future<List<Map<String, dynamic>>> getRealizations(String companyId,
      {bool includeUnapproved = false}) async {
    final snap = await _firestore
        .collection('realizations')
        .where('companyId', isEqualTo: companyId)
        .get();
    final list = snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .where((r) {
          if (includeUnapproved) return true;
          // zdjęcia klienta wchodzą do portfolio dopiero po publikacji
          if (r['addedByRole'] == 'user') return r['publishedByCompany'] == true;
          return (r['status'] ?? 'approved') == 'approved';
        })
        .toList();
    list.sort((a, b) {
      final ta = a['timestamp'];
      final tb = b['timestamp'];
      if (ta is! Timestamp || tb is! Timestamp) return 0;
      return tb.compareTo(ta);
    });
    return list.take(30).toList();
  }

  /// Zdjęcia zgłoszenia, najnowsze pierwsze.
  Future<List<Map<String, dynamic>>> getRealizationsForRequest(
      String requestId) async {
    final snap = await _firestore
        .collection('realizations')
        .where('requestId', isEqualTo: requestId)
        .get();
    final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    list.sort((a, b) {
      final ta = a['timestamp'];
      final tb = b['timestamp'];
      if (ta is! Timestamp || tb is! Timestamp) return 0;
      return tb.compareTo(ta);
    });
    return list;
  }

  Future<void> deleteRealization(String id) async {
    await _firestore.collection('realizations').doc(id).delete();
  }

  // ── KOMENTARZE DO RECENZJI ────────────────────────────────────────────────
  // Zasada: każdy może dodać max 1 komentarz; właściciel firmy też max 1

  Future<List<ReviewComment>> getCommentsForReview(String reviewId) async {
    final snap = await _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .orderBy('timestamp')
        .get();
    return snap.docs.map((d) => ReviewComment.fromDoc(d)).toList();
  }

  /// Sprawdza czy dany user już skomentował tę recenzję
  Future<bool> hasUserCommented({
    required String reviewId,
    required String userId,
  }) async {
    final snap = await _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .where('authorId', isEqualTo: userId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Jeden komentarz osoby pod recenzją: id = autor.
  Future<void> addComment(ReviewComment comment) async {
    await _firestore
        .collection('reviews')
        .doc(comment.reviewId)
        .collection('comments')
        .doc(comment.authorId)
        .set(comment.toMap());
  }

  Future<void> deleteComment({
    required String reviewId,
    required String commentId,
  }) async {
    await _firestore
        .collection('reviews')
        .doc(reviewId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

}