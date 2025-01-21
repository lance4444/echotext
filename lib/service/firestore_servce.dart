import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:only_audio/model/audio_meta.dart';

class FirestoreService {
  static final MyAudioRef = FirebaseFirestore.instance
      .collection('myaudio')
      .withConverter(
          fromFirestore: AudioMeta.fromFirestore,
          toFirestore: (AudioMeta m, _) => m.toFirestore());

  final storage = FirebaseFirestore.instance;

//add a sample
  static Future<void> addAudioMeta(AudioMeta data) async {
    await MyAudioRef.doc(data.id).set(data);
  }

//get audio once

  static Future<QuerySnapshot<AudioMeta>> getMyAudioOnce() {
    return MyAudioRef.get();
  }

  static Stream<QuerySnapshot<AudioMeta>> searchByKeyword(String keyword) {
    return MyAudioRef.where('keyWord', arrayContains: keyword.trim())
        .snapshots();
  }
}
