import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileInfo {
  final String userId;
  final String description;
  final DateTime? timestamp;

  ProfileInfo({
    required this.userId,
    required this.description,
    required this.timestamp,
  });

  factory ProfileInfo.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProfileInfo(
      userId: data['userId'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'description': description,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }
}