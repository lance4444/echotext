import 'package:cloud_firestore/cloud_firestore.dart';

class AudioMeta {
  final String userId;
  final String mp4Url;
  final String duration;
  final String txtMsg;
  final String id;
  final DateTime? createdAt;

  AudioMeta({
    required this.userId,
    required this.mp4Url,
    required this.duration,
    required this.txtMsg,
    required this.id,
    this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mp4Url': mp4Url,
      'duration': duration,
      'txtMsg': txtMsg,
      'id': id,
      'createdAt': createdAt ?? DateTime.now(),
    };
  }

  static AudioMeta fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return AudioMeta(
      userId: data['userId'] ?? '',
      mp4Url: data['mp4Url'] ?? '',
      duration: data['duration'] ?? '',
      txtMsg: data['txtMsg'] ?? '',
      id: snapshot.id,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
