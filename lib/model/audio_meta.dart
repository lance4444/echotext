import 'package:cloud_firestore/cloud_firestore.dart';

class AudioMeta {
  final String userId;
  final String mp4Url;
  // final List<String> keyWord;
  final String txtMsg;
  late final String id;
  final String duration;

  AudioMeta(
      {required this.userId,
      required this.mp4Url,
      // required this.keyWord,
      required this.txtMsg,
      required this.id,
      required this.duration});
  Map<String, dynamic> toFirestore() {
    return {
      'useId': userId,
      'mp4Url': mp4Url,
      // 'keyWord': keyWord,
      'txtMsg': txtMsg,
      'duration': duration
    };
  }

  // audio from firestore
  factory AudioMeta.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    // List<dynamic> rawKeywords = data['keyWord'] ?? [];
    // List<String> keywords = rawKeywords.cast<String>();

    AudioMeta myaudio = AudioMeta(
        userId: data['useId'],
        mp4Url: data['mp4Url'],
        // keyWord: keywords,
        txtMsg: data['txtMsg'],
        duration: data['duration'],
        id: snapshot.id);

    return myaudio;
  }
}
