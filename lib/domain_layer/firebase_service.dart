import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'domain_models/app_user.dart';
import 'domain_models/company_info.dart';
import 'domain_models/promoVideo.dart';
import 'domain_models/relation_link.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();



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
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
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
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<AppUser?> fetchUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;// Map<String, dynamic>?
      return AppUser.fromDoc(doc);
    } catch (e) {
      rethrow;
    }
  }




  Future<UploadTask> uploadWithProgress({
    required File file,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref().child('files/$fileName');
      final uploadTask = ref.putFile(file);

      return uploadTask; // zwracamy task, żeby kontrolować postęp z UI
    } catch (e) {
      print (e);
      rethrow;
    }
  }

  Future<UploadTask> uploadThumb({
    required File file,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref().child('thumbs/$fileName');
      final uploadTask = ref.putFile(file);
      return uploadTask; // zwracamy task, żeby kontrolować postęp z UI
    } catch (e) {
      rethrow;
    }
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

  Future<void> saveReviewMetadata(Review rev) async {
    await _firestore.collection('reviews').add(rev.toMap());
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

    final promosSnapshot = await FirebaseFirestore.instance
        .collection('promos')
        .where(FieldPath.documentId, whereIn: promoIds)
        .get();

    return promosSnapshot.docs
        .map((doc) => Promo.fromDoc(doc))
        .toList();
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

    final promos = querySnapshot.docs.map((doc) => Promo.fromDoc(doc)).toList();

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

  Future<List<Request>> getNearbyRequests({
    required String userId, // Dodajemy userId, by wiedzieć co ukryć
    required String category,
    required String sector,
    required LatLng myLocation,
    int limit = 10,
  }) async {
    // 1. Pobierz ID pominiętych zgłoszeń
    final skippedSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('skippedRequests')
        .get();

    final skippedIds = skippedSnapshot.docs.map((doc) => doc.id).toSet();

    // 2. Pobierz zgłoszenia (tak jak wcześniej)
    final querySnapshot = await _firestore
        .collection('requests')
        .where('category', isEqualTo: category)
        .where('sector', isEqualTo: sector)
        .get();

    // 3. Konwersja i FILTROWANIE
    final requests = querySnapshot.docs
        .map((doc) => Request.fromDoc(doc))
        .where((req) => !skippedIds.contains(req.id)) // Usuwamy te, które są na liście skipped
        // zadania podjęte (obustronnie potwierdzone) widzi tylko firma, która je wzięła
        .where((req) => req.status != 'closed')
        .where((req) => req.status != 'taken' || req.takenBy == userId)
        .toList();

    // 4. Obliczanie dystansu i sortowanie: pilne (24h) na górze, potem dystans
    for (var req in requests) {
      req.distance = Geolocator.distanceBetween(
        myLocation.latitude,
        myLocation.longitude,
        req.location.latitude,
        req.location.longitude,
      );
    }

    requests.sort((a, b) {
      if (a.is24 != b.is24) return a.is24 ? -1 : 1;
      return (a.distance ?? 0).compareTo(b.distance ?? 0);
    });

    return requests.take(limit).toList();
  }



  Future<List<Request>> getNearbyRequestsOld({
    required String category,
    required String sector,
    required LatLng myLocation,
    int limit = 10, // opcjonalnie ograniczenie liczby wyników
  }) async {
    // Pobranie requestów z danej kategorii i sektora
    final querySnapshot = await FirebaseFirestore.instance
        .collection('requests')
        .where('category', isEqualTo: category)
        .where('sector', isEqualTo: sector)
        .get();

    // Konwersja dokumentów na obiekty Request
    final requests = querySnapshot.docs.map((doc) => Request.fromDoc(doc)).toList();

    // Obliczenie odległości i zapisanie w polu distance
    for (var req in requests) {
      req.distance = Geolocator.distanceBetween(
        myLocation.latitude,
        myLocation.longitude,
        req.location.latitude,
        req.location.longitude,
      );
    }

    // Posortowanie po odległości (najbliższe pierwsze)
    requests.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

    // Zwrócenie ograniczonej liczby wyników, jeśli podano limit
    return requests.take(limit).toList();
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
    final promos = querySnapshot.docs.map((doc) => Promo.fromDoc(doc)).toList();

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




  Future<void> saveProfile(ProfileInfo profile) async {
    // Używamy userId jako ID dokumentu (czyli 1 profil = 1 użytkownik)
    await _firestore.collection('profile').doc(profile.userId).set(profile.toMap());
  }

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







  Future<void> addFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).set(
        {'fcmTokens': FieldValue.arrayUnion([token])}, SetOptions(merge: true));
  }

  Future<void> removeFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).set(
        {'fcmTokens': FieldValue.arrayRemove([token])}, SetOptions(merge: true));
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<void> incrementPromoViews(String promoId) async {
    try {
      await _firestore
          .collection('promos')
          .doc(promoId)
          .update({'views': FieldValue.increment(1)});
    } catch (_) {}
  }

  /// Liczba zleceń zrealizowanych przez firmę (obustronnie potwierdzonych).
  Future<int> getCompletedJobsCount(String companyId) async {
    final snap = await _firestore
        .collection('requests')
        .where('takenBy', isEqualTo: companyId)
        .where('status', isEqualTo: 'taken')
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
  //   {start: Timestamp, status: 'free'|'pending'|'accepted'|'rejected',
  //    bookedBy, bookedByName}

  Future<List<Map<String, dynamic>>> getSlots(String companyId) async {
    final now = DateTime.now();
    final weekAhead = now.add(const Duration(days: 7));
    final snap = await _firestore
        .collection('users')
        .doc(companyId)
        .collection('slots')
        .orderBy('start')
        .get();

    final slots = <Map<String, dynamic>>[];
    for (final d in snap.docs) {
      final data = d.data();
      final start = (data['start'] as Timestamp?)?.toDate();
      if (start == null) continue;
      if (start.isBefore(now) || start.isAfter(weekAhead)) continue;
      slots.add({
        'id': d.id,
        'start': start,
        'status': data['status'] ?? 'free',
        'bookedBy': data['bookedBy'] ?? '',
        'bookedByName': data['bookedByName'] ?? '',
      });
    }
    return slots;
  }

  DocumentReference<Map<String, dynamic>> _myBookingRef(
          String myUid, String companyId, String slotId) =>
      _firestore
          .collection('users')
          .doc(myUid)
          .collection('myBookings')
          .doc('${companyId}_$slotId');

  /// User rezerwuje slot — tylko wolny (transakcja chroni przed wyścigiem).
  /// Kopia rezerwacji trafia do users/{ja}/myBookings (lista „Rezerwacje").
  Future<void> bookSlot({
    required String companyId,
    required String slotId,
    required String myUid,
    required String myName,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(companyId)
        .collection('slots')
        .doc(slotId);
    DateTime? start;
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final status = doc.data()?['status'] ?? 'free';
      if (status != 'free') {
        throw Exception('Termin jest już zajęty');
      }
      start = (doc.data()?['start'] as Timestamp?)?.toDate();
      tx.update(ref, {
        'status': 'pending',
        'bookedBy': myUid,
        'bookedByName': myName,
        'bookedAt': FieldValue.serverTimestamp(),
      });
    });

    final companyDoc =
        await _firestore.collection('users').doc(companyId).get();
    await _myBookingRef(myUid, companyId, slotId).set({
      'companyId': companyId,
      'companyName': companyDoc.data()?['companyName'] ?? 'Firma',
      'slotId': slotId,
      if (start != null) 'start': Timestamp.fromDate(start!),
      'status': 'pending',
      'bookedAt': FieldValue.serverTimestamp(),
    });

    // rezerwacja też buduje relację: klient u firmy i firma u klienta
    await _linkClient(
        companyId: companyId, userId: myUid, requestId: 'slot_$slotId');
  }

  /// Rezerwacje usera (firma + godzina + status). Czyści przeszłe
  /// i wygasłe żółte (>1h bez decyzji firmy).
  Future<List<Map<String, dynamic>>> getMyBookings(String myUid) async {
    final snap = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('myBookings')
        .get();
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 1));
    final out = <Map<String, dynamic>>[];
    final toDelete = <DocumentReference>[];
    for (final d in snap.docs) {
      final data = d.data();
      final start = (data['start'] as Timestamp?)?.toDate();
      final bookedAt = (data['bookedAt'] as Timestamp?)?.toDate();
      final status = data['status'] ?? 'pending';
      final expired = status == 'pending' &&
          bookedAt != null &&
          bookedAt.isBefore(cutoff);
      if (start == null || start.isBefore(now) || expired) {
        toDelete.add(d.reference);
        continue;
      }
      out.add({...data, 'start': start});
    }
    if (toDelete.isNotEmpty) {
      final batch = _firestore.batch();
      for (final r in toDelete) {
        batch.delete(r);
      }
      batch.commit();
    }
    out.sort(
        (a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime));
    return out;
  }

  /// Live-podgląd slotów (7 dni). Żółte (pending) starsze niż 1h są
  /// pokazywane jako wolne — fizyczne czyszczenie robi cleanupOldSlots.
  Stream<List<Map<String, dynamic>>> slotsStream(String companyId) {
    return _firestore
        .collection('users')
        .doc(companyId)
        .collection('slots')
        .orderBy('start')
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      final weekAhead = now.add(const Duration(days: 7));
      final slots = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        final start = (data['start'] as Timestamp?)?.toDate();
        if (start == null) continue;
        if (start.isBefore(now) || start.isAfter(weekAhead)) continue;

        var status = (data['status'] ?? 'free') as String;
        var bookedBy = (data['bookedBy'] ?? '') as String;
        var bookedByName = (data['bookedByName'] ?? '') as String;
        final bookedAt = (data['bookedAt'] as Timestamp?)?.toDate();
        // żółta rezerwacja wygasa po godzinie
        if (status == 'pending' &&
            bookedAt != null &&
            now.difference(bookedAt).inMinutes >= 60) {
          status = 'free';
          bookedBy = '';
          bookedByName = '';
        }
        slots.add({
          'id': d.id,
          'start': start,
          'status': status,
          'bookedBy': bookedBy,
          'bookedByName': bookedByName,
        });
      }
      return slots;
    });
  }

  /// User odwołuje własną rezerwację → slot wraca do puli.
  Future<void> cancelSlotBooking({
    required String companyId,
    required String slotId,
    String? myUid,
  }) async {
    final batch = _firestore.batch();
    batch.update(
        _firestore
            .collection('users')
            .doc(companyId)
            .collection('slots')
            .doc(slotId),
        {'status': 'free', 'bookedBy': '', 'bookedByName': ''});
    if (myUid != null && myUid.isNotEmpty) {
      batch.delete(_myBookingRef(myUid, companyId, slotId));
    }
    await batch.commit();
  }

  /// Firma akceptuje/odrzuca rezerwację (aktualizuje też kopię u klienta).
  Future<void> setSlotStatus({
    required String companyId,
    required String slotId,
    required String status,
    String? bookedBy,
  }) async {
    final batch = _firestore.batch();
    batch.update(
        _firestore
            .collection('users')
            .doc(companyId)
            .collection('slots')
            .doc(slotId),
        {'status': status});
    if (bookedBy != null && bookedBy.isNotEmpty) {
      // set+merge — stare rezerwacje mogą nie mieć kopii u klienta
      batch.set(
          _myBookingRef(bookedBy, companyId, slotId),
          {'status': status, 'decidedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
    }
    await batch.commit();
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

  Future<void> removeSlot(String companyId, String slotId) async {
    await _firestore
        .collection('users')
        .doc(companyId)
        .collection('slots')
        .doc(slotId)
        .delete();
  }

  /// Sprzątanie: kasuje przeterminowane sloty i zwalnia żółte rezerwacje
  /// starsze niż 1h (wołane przy wejściu właściciela w kalendarz).
  Future<void> cleanupOldSlots(String companyId) async {
    final col =
        _firestore.collection('users').doc(companyId).collection('slots');

    final old = await col.where('start', isLessThan: Timestamp.now()).get();
    final pending = await col.where('status', isEqualTo: 'pending').get();
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final expiredPending = pending.docs.where((d) {
      final bookedAt = (d.data()['bookedAt'] as Timestamp?)?.toDate();
      return bookedAt != null && bookedAt.isBefore(cutoff);
    }).toList();

    if (old.docs.isEmpty && expiredPending.isEmpty) return;
    final batch = _firestore.batch();
    for (final d in old.docs) {
      batch.delete(d.reference);
    }
    for (final d in expiredPending) {
      if (old.docs.any((o) => o.id == d.id)) continue;
      batch.update(d.reference,
          {'status': 'free', 'bookedBy': '', 'bookedByName': ''});
    }
    await batch.commit();
  }

  // ── OFERTY DO ZGŁOSZEŃ (firma pisze, user daje ✔ / ? / ✖) ────────────────
  // requests/{id}/offers/{companyId}: {companyId, companyName, message,
  //   status: 'pending'|'maybe'|'accepted'|'rejected', timestamp}

  Future<void> sendOffer({
    required String requestId,
    required String companyId,
    required String companyName,
    required String message,
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

  /// Statusy MOICH ofert dla listy zgłoszeń (none = brak oferty).
  Future<Map<String, String>> getMyOfferStatuses(
      List<String> requestIds, String companyId) async {
    final entries = await Future.wait(requestIds.map((id) async {
      final o = await getMyOffer(id, companyId);
      return MapEntry(id, (o?['status'] ?? 'none') as String);
    }));
    return Map.fromEntries(entries);
  }

  Future<List<Map<String, dynamic>>> getOffers(String requestId) async {
    final snap = await _firestore
        .collection('requests')
        .doc(requestId)
        .collection('offers')
        .orderBy('timestamp')
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// ✔ accept — blokuje zgłoszenie na tę firmę i tworzy relację klient↔firma.
  /// ? maybe — znacznik „klient się zastanawia".
  /// ✖ reject — całkowite odrzucenie firmy (nie może ofertować ponownie).
  Future<void> setOfferStatus({
    required Request request,
    required String companyId,
    required String companyName,
    required String status,
  }) async {
    await _firestore
        .collection('requests')
        .doc(request.id)
        .collection('offers')
        .doc(companyId)
        .update({'status': status, 'decidedAt': FieldValue.serverTimestamp()});

    if (status == 'accepted') {
      await _firestore.collection('requests').doc(request.id).update({
        'takenBy': companyId,
        'takenByName': companyName,
        'confirmedByCompany': true,
        'confirmedByUser': true,
        'status': 'taken',
        'takenAt': FieldValue.serverTimestamp(),
      });
      await _linkClient(
          companyId: companyId, userId: request.userId, requestId: request.id);
    }
  }

  /// Odblokowanie zadania przez usera — wraca do puli, oferta firmy do
  /// 'pending', relacja klient↔firma z tego zadania jest usuwana.
  Future<void> unlockRequest(Request request) async {
    final companyId = request.takenBy;
    await _firestore.collection('requests').doc(request.id).update({
      'takenBy': '',
      'takenByName': '',
      'confirmedByCompany': false,
      'confirmedByUser': false,
      'status': 'open',
    });
    if (companyId.isEmpty) return;
    try {
      await _firestore
          .collection('requests')
          .doc(request.id)
          .collection('offers')
          .doc(companyId)
          .update({'status': 'pending'});
    } catch (_) {}

    // zerwana realizacja: kasujemy prośby o potwierdzenie i zdjęcia tej firmy
    try {
      final photos = await _firestore
          .collection('realizations')
          .where('requestId', isEqualTo: request.id)
          .where('companyId', isEqualTo: companyId)
          .get();
      for (final d in photos.docs) {
        await d.reference.delete();
      }
    } catch (_) {}

    // i powiadomienia o tej realizacji, żeby nie wisiały w dzwonku
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
    final batch = _firestore.batch();
    batch.delete(_firestore
        .collection('users')
        .doc(companyId)
        .collection('clients')
        .doc(request.userId));
    batch.delete(_firestore
        .collection('users')
        .doc(request.userId)
        .collection('myCompanies')
        .doc(companyId));
    await batch.commit();
  }

  Future<void> _linkClient({
    required String companyId,
    required String userId,
    required String requestId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final companyDoc = await _firestore.collection('users').doc(companyId).get();
    final userData = userDoc.data() ?? {};
    final companyData = companyDoc.data() ?? {};

    // rezerwacje przychodzą jako 'slot_<id>' — trzymamy osobno, żeby lista
    // klientów mogła pokazać „skąd ta osoba" i dać odnośnik
    final isSlot = requestId.startsWith('slot_');
    final linkFields = <String, dynamic>{
      if (isSlot)
        'slotIds': FieldValue.arrayUnion([requestId.substring(5)])
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

    final batch = _firestore.batch();
    batch.set(
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
    batch.set(
      companyRef,
      {
        'companyId': companyId,
        'name': companyData['companyName'] ?? 'Firma',
        if (firstTime) 'addedAt': FieldValue.serverTimestamp(),
        ...linkFields,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Zgłoszenie po id (do odnośników z listy klientów).
  Future<Request?> getRequestById(String id) async {
    final doc = await _firestore.collection('requests').doc(id).get();
    if (!doc.exists) return null;
    return Request.fromDoc(doc);
  }

  /// Pojedynczy slot firmy (start + status) — do odnośnika „Rezerwacja".
  Future<SlotRef?> getSlotRef(String companyId, String slotId) async {
    final doc = await _firestore
        .collection('users')
        .doc(companyId)
        .collection('slots')
        .doc(slotId)
        .get();
    final d = doc.data();
    if (d == null || d['start'] == null) return null;
    return SlotRef(
      id: doc.id,
      companyId: companyId,
      start: (d['start'] as Timestamp).toDate(),
      status: (d['status'] as String?) ?? 'free',
    );
  }

  /// Zbiera relację z dokumentu clients/myCompanies: nowe pola tablicowe
  /// + stare pojedyncze `requestId` (może być 'slot_<id>').
  Future<RelationLink?> _linkFromDoc(
      DocumentSnapshot<Map<String, dynamic>> d, String personId, String companyId) async {
    final u = await fetchUser(personId);
    if (u == null) return null;
    final data = d.data() ?? {};
    final reqIds = <String>{
      ...((data['requestIds'] as List?)?.cast<String>() ?? const []),
    };
    final slotIds = <String>{
      ...((data['slotIds'] as List?)?.cast<String>() ?? const []),
    };
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
      final s = await getSlotRef(companyId, id);
      if (s != null) slots.add(s);
    }
    slots.sort((a, b) => b.start.compareTo(a.start));
    return RelationLink(
      user: u,
      requests: requests,
      slots: slots,
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
      final l = await _linkFromDoc(d, d.id, companyId);
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
      final l = await _linkFromDoc(d, d.id, d.id);
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

  Future<int> getUrgentNearbyCount({
    required String companyId,
    required String category,
    required LatLng myLocation,
    double radiusKm = 30,
  }) async {
    final since = DateTime.now().subtract(const Duration(hours: 24));
    final snap = await _firestore
        .collection('requests')
        .where('category', isEqualTo: category)
        .where('is24', isEqualTo: true)
        .get();

    int count = 0;
    for (final d in snap.docs) {
      final req = Request.fromDoc(d);
      if (req.status == 'taken') continue;
      if (req.userId == companyId) continue;
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
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('realizations/$ts.jpg');
    await ref.putFile(image);
    final url = await ref.getDownloadURL();

    String? beforeUrl;
    if (beforeImage != null) {
      final beforeRef = _storage.ref().child('realizations/${ts}_before.jpg');
      await beforeRef.putFile(beforeImage);
      beforeUrl = await beforeRef.getDownloadURL();
    }

    await _firestore.collection('realizations').add({
      'companyId': companyId,
      'requestId': requestId,
      'userId': requestOwnerId,
      'category': category,
      'imageUrl': url,
      if (beforeUrl != null) 'beforeUrl': beforeUrl,
      'addedByRole': addedByRole,
      // zdjęcia firmy czekają na potwierdzenie klienta; zdjęcia klienta są
      // od razu „jego", ale na profil firmy trafiają dopiero po publikacji
      'status': addedByRole == 'company' ? 'pending' : 'approved',
      'publishedByCompany': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Firma publikuje w portfolio zdjęcia dodane przez klienta.
  Future<void> setRealizationPublished(String id, bool published) async {
    await _firestore
        .collection('realizations')
        .doc(id)
        .update({'publishedByCompany': published});
  }

  // ── POWIADOMIENIA (dzwonek) ───────────────────────────────────────────────

  /// [companyMode] filtruje alerty do aktualnego trybu konta
  /// (firma widzi swoje, klient swoje; rozmowy widać zawsze).
  Stream<List<Map<String, dynamic>>> notificationsStream(String uid,
      {bool? companyMode}) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .where((n) {
            if (companyMode == null) return true;
            final aud = (n['audience'] as String?) ?? 'both';
            if (aud == 'both') return true;
            return companyMode ? aud == 'company' : aud == 'user';
          })
          .toList();
      list.sort((a, b) {
        final ta = a['createdAt'], tb = b['createdAt'];
        if (ta is! Timestamp || tb is! Timestamp) return 0;
        return tb.compareTo(ta);
      });
      return list.take(60).toList();
    });
  }

  Future<void> markNotificationRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({'read': true});
  }

  Future<void> markAllNotificationsRead(String uid, {bool? companyMode}) async {
    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final d in snap.docs) {
      if (companyMode != null) {
        final aud = (d.data()['audience'] as String?) ?? 'both';
        if (aud != 'both' &&
            (companyMode ? aud != 'company' : aud != 'user')) continue;
      }
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }

  /// Klient zamyka zgłoszenie ręcznie (bez usuwania historii).
  Future<void> closeRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      'closedReason': 'byUser',
    });
  }

  /// Decyzja klienta o zdjęciach: 'approved' | 'rejected'.
  /// Każda decyzja zamyka zlecenie definitywnie (znika z list aktywnych).
  Future<void> setRealizationStatus(String id, String status,
      {required String requestId}) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('realizations').doc(id), {
      'status': status,
      'decidedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('requests').doc(requestId), {
      'status': 'closed',
      'realizationStatus': status,
      'closedAt': FieldValue.serverTimestamp(),
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

  Future<List<Map<String, dynamic>>> getRealizationsForRequest(
      String requestId) async {
    final snap = await _firestore
        .collection('realizations')
        .where('requestId', isEqualTo: requestId)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
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

  Future<void> addComment(ReviewComment comment) async {
    await _firestore
        .collection('reviews')
        .doc(comment.reviewId)
        .collection('comments')
        .add(comment.toMap());
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