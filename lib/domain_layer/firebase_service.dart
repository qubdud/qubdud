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
        .toList();

    // 4. Obliczanie dystansu i sortowanie (bez zmian)
    for (var req in requests) {
      req.distance = Geolocator.distanceBetween(
        myLocation.latitude,
        myLocation.longitude,
        req.location.latitude,
        req.location.longitude,
      );
    }

    requests.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

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







  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
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