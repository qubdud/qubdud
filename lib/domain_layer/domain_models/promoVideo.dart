import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class Promo {
  final String id;
  final String userId;
  final String category;
  final String sector;
  final LatLng location;
  final String fileUrl;
  final String thumbUrl;
  final String fileName;
  final DateTime? timestamp;
  final String description;
  final String companyName; // snapshot nazwy firmy
  final int views;
  double? distance;

  Promo({
    required this.id,
    required this.userId,
    required this.category,
    required this.sector,
    required this.location,
    required this.fileUrl,
    required this.thumbUrl,
    required this.fileName,
    required this.timestamp,
    required this.description,
    this.companyName = '',
    this.views = 0,
    this.distance,
  });

  factory Promo.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final loc = data['location'] ?? {};

    return Promo(
      id: doc.id,
      userId: data['userId'] ?? '',
      category: data['category'] ?? '',
      sector: data['sector'] ?? '',
      location: LatLng(
        (loc['lat'] ?? 0.0).toDouble(),
        (loc['lng'] ?? 0.0).toDouble(),
      ),
      fileUrl: data['fileUrl'] ?? '',
      thumbUrl: data['thumbUrl'] ??'',
      fileName: data['fileName'] ?? '',
      // dokument z błędnym typem nie może wywrócić całej listy (QB-76)
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
      description: data['description'] ?? '',
      companyName: data['companyName'] ?? '',
      views: data['views'] is num ? (data['views'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'sector': sector,
      'location': {
        'lat': location.latitude,
        'lng': location.longitude,
      },
      'fileUrl': fileUrl,
      'thumbUrl': thumbUrl,
      'fileName': fileName,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'description': description,
      'companyName': companyName,
    };
  }
}






/// Etap zgłoszenia — jedno źródło etykiet dla karty klienta i Aktywności.
enum RequestStage {
  open,
  inProgress,
  photosPending,
  photosRejected,
  realized,
  expired,
  closed;

  String label({bool forCompany = false}) => switch (this) {
        open => 'czeka na oferty',
        inProgress => 'w realizacji',
        photosPending => forCompany
            ? 'czeka na potwierdzenie zdjęć'
            : 'zdjęcia do potwierdzenia',
        photosRejected => 'zdjęcia odrzucone',
        realized => 'zrealizowane i potwierdzone',
        expired => 'wygasło',
        closed => 'zamknięte',
      };
}

class Request {
  final String id;
  final String userId;
  final String category;
  final String sector;
  final LatLng location;
  final String city;
  final String fileUrl;
  final String thumbUrl;
  final String fileName;
  final String mediaType; // image | video
  final DateTime? timestamp;
  final DateTime? reopenedAt; // odblokowanie: od niego liczy się 10 dni do wygaśnięcia
  final String closedReason; // '' | expired | byUser | realized
  final String realizationStatus; // '' | pending | approved | rejected
  final bool is24;
  // kreator zgłoszenia (opcjonalne, brak w zgłoszeniach sprzed 1.4.0)
  final String timing; // '' | asap | week | month | flexible
  final int? budget;
  final Map<String, String> answers; // pytanie → odpowiedź
  String description;
  double? distance;

  // Podjęcie zadania: firma deklaruje się (confirmedByCompany),
  // user potwierdza (confirmedByUser) → status 'taken' i zgłoszenie
  // znika z list innych firm.
  String status; // 'open' | 'taken' | 'closed'
  String takenBy; // uid firmy
  String takenByName;
  bool confirmedByCompany;
  bool confirmedByUser;

  Request({
    required this.id,
    required this.userId,
    required this.category,
    required this.sector,
    required this.location,
    required this.city,
    required this.fileUrl,
    required this.thumbUrl,
    required this.fileName,
    required this.mediaType,
    required this.timestamp,
    this.reopenedAt,
    this.closedReason = '',
    this.realizationStatus = '',
    required this.is24,
    this.timing = '',
    this.budget,
    this.answers = const {},
    required this.description,
    this.distance,
    this.status = 'open',
    this.takenBy = '',
    this.takenByName = '',
    this.confirmedByCompany = false,
    this.confirmedByUser = false,
  });

  factory Request.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final loc = data['location'] ?? {};

    return Request(
      id: doc.id,
      closedReason: data['closedReason'] ?? '',
      realizationStatus: data['realizationStatus'] ?? '',
      is24: data['is24'] ?? false,
      timing: data['timing'] as String? ?? '',
      budget: data['budget'] is int ? data['budget'] as int : null,
      answers: (data['answers'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {},
      userId: data['userId'] ?? '',
      category: data['category'] ?? '',
      sector: data['sector'] ?? '',
      city: data['city']??'',
      location: LatLng(
        (loc['lat'] ?? 0.0).toDouble(),
        (loc['lng'] ?? 0.0).toDouble(),
      ),
      fileUrl: data['fileUrl'] ?? '',
      thumbUrl: data['thumbUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      // EXPIRES: po uruchomieniu demo/_seed/migrate_media_type.js
      mediaType: data['mediaType'] ?? _mediaTypeFromName(data['fileName'] ?? ''),
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
      reopenedAt: data['reopenedAt'] is Timestamp
          ? (data['reopenedAt'] as Timestamp).toDate()
          : null,
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      takenBy: data['takenBy'] ?? '',
      takenByName: data['takenByName'] ?? '',
      confirmedByCompany: data['confirmedByCompany'] ?? false,
      confirmedByUser: data['confirmedByUser'] ?? false,
    );
  }

  /// Zgłoszenie widoczne dla firmy: cudze i otwarte albo realizowane przez nią.
  bool isActiveFor(String companyId) =>
      userId != companyId &&
      (status == 'open' || (status == 'taken' && takenBy == companyId));

  RequestStage get stage {
    if (realizationStatus == 'approved') return RequestStage.realized;
    if (status == 'closed') {
      return closedReason == 'expired'
          ? RequestStage.expired
          : RequestStage.closed;
    }
    if (realizationStatus == 'pending') return RequestStage.photosPending;
    if (realizationStatus == 'rejected') return RequestStage.photosRejected;
    if (status == 'taken') return RequestStage.inProgress;
    return RequestStage.open;
  }

  /// 🔸 Metoda konwertująca obiekt na mapę do zapisu w Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'sector': sector,
      'location': {
        'lat': location.latitude,
        'lng': location.longitude,
      },
      'city': city,
      'fileUrl': fileUrl,
      'thumbUrl': thumbUrl,
      'fileName': fileName,
      'mediaType': mediaType,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'is24': is24,
      if (timing.isNotEmpty) 'timing': timing,
      if (budget != null) 'budget': budget,
      if (answers.isNotEmpty) 'answers': answers,
      'description': description,
      'status': status,
      'takenBy': takenBy,
      'takenByName': takenByName,
      'confirmedByCompany': confirmedByCompany,
      'confirmedByUser': confirmedByUser,
    };
  }
}

// EXPIRES: po uruchomieniu demo/_seed/migrate_media_type.js
String _mediaTypeFromName(String name) =>
    RegExp(r'\.(mp4|mov|m4v|3gp|webm|mkv)$', caseSensitive: false)
            .hasMatch(name)
        ? 'video'
        : 'image';



class Review {
  final String id;
  final String promoId;
  final String userId;
  final String reviewedUserId;
  final String authorName; // imię autora (snapshot)
  final int score;
  final String fileUrl;
  final String thumbUrl;
  final String fileName;
  final DateTime? timestamp;
  final String description;

  Review({
    required this.id,
    required this.promoId,
    required this.userId,
    required this.reviewedUserId,
    this.authorName = '',
    required this.score,
    required this.fileUrl,
    required this.thumbUrl,
    required this.fileName,
    required this.timestamp,
    required this.description,
  });

  factory Review.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Review(
      id: doc.id,
      promoId: data['promoId'] ?? '',
      userId: data['userId'] ?? '',
      reviewedUserId: data['reviewedUserId'] ?? '',
      score: data['score'] is num ? (data['score'] as num).toInt() : 0,
      fileUrl: data['fileUrl'] ?? '',
      thumbUrl: data['thumbUrl'] ??'',
      fileName: data['fileName'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
      description: data['description'] ?? '',
      authorName: data['authorName'] ?? '',
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'promoId': promoId,
      'authorName': authorName,
      'reviewedUserId': reviewedUserId,
      'score': score,
      'fileUrl': fileUrl,
      'thumbUrl': thumbUrl,
      'fileName': fileName,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'description': description,
    };
  }


}


class ReviewComment {
  final String id;
  final String reviewId;
  final String authorId;
  final String authorName;
  final bool isOwner; // czy to właściciel firmy której dotyczy recenzja
  final String text;
  final DateTime? timestamp;

  ReviewComment({
    required this.id,
    required this.reviewId,
    required this.authorId,
    required this.authorName,
    required this.isOwner,
    required this.text,
    this.timestamp,
  });

  factory ReviewComment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReviewComment(
      id: doc.id,
      reviewId: data['reviewId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      isOwner: data['isOwner'] ?? false,
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'authorId': authorId,
      'authorName': authorName,
      'isOwner': isOwner,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}