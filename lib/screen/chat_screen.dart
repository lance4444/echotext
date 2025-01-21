import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:only_audio/model/audio_meta.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:only_audio/service/firestore_servce.dart';

typedef _Fn = void Function();

const audioIn = AudioSource.microphone;

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Codec _codec = Codec.aacMP4;
  String? _mPath;
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = true;
  bool _mRecorderIsInited = true;
  bool _mplaybackReady = true;
  bool _isRecording = false;
  bool _isSearching = false;
  bool _isPlaying = false;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription? _streamSubscription;
  //create a reference to the firebase storage
  final storageRef = FirebaseStorage.instance.ref();
  late final audioRef = storageRef.child("audio/");

  //capture the recrod time
  DateTime? startTime;
  DateTime? endTime;

  // init dash_chat
  String? _uniqueId;
  ChatUser user = ChatUser(
    id: '',
    firstName: '',
    lastName: '',
    profileImage: 'assets/images/icon1.png',
  );
  List<ChatMessage> messages = [];
  Map<String, ChatMessage> messageMap = {};

  get audioList => _audioList;
  final List<AudioMeta> _audioList = [];

  void toggleplayer(String downLoadUrl) {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      play(downLoadUrl);
    } else {
      stopPlayer();
    }
  }

  void toggleSearch(String searchTerm) {
    if (searchTerm.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      listenToAudioChanges();
    }
    setState(() {
      _isSearching = true;
      messages.clear();
      _audioList.clear();
    });
    _streamSubscription?.cancel();
    _streamSubscription =
        FirestoreService.searchByKeyword(searchTerm).listen((snapshots) {
      if (snapshots.docs.isEmpty) {
        setState(() {
          messages.clear();
          _audioList.clear();
        });
        listenToAudioChanges();
        return;
      }
      setState(() {
        messages.clear();
        _audioList.clear();
        // Add search results
        for (var doc in snapshots.docs.reversed) {
          var audioMeta = doc.data();
          _audioList.add(audioMeta);
          var msg = ChatMessage(
            text: 'Playback...... ${audioMeta.duration}\n ${audioMeta.txtMsg}',
            createdAt: DateTime.now(),
            user: user,
            playBackUrl: audioMeta.mp4Url,
          );

          messages.add(msg);
          messageMap[audioMeta.mp4Url] = msg;
        }
      });
    });
  }

  void toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    if (_isRecording) {
      record();
    } else {
      stopRecorder();
    }
  }

  Future<void> submitAudio(String uniqueId) async {
    if (startTime != null && endTime != null) {
      final duration = endTime!.difference(startTime!);
      final formattedTime = formatDuration(duration);

      // Get the audio file's url from Cloud Storage
      final downloadUrl = await audioRef.child(uniqueId).getDownloadURL();

      const txtMsg = "transcripting.....";

      // Init audio meta
      AudioMeta data = AudioMeta(
        userId: widget.userId, // Use the authenticated user's ID
        mp4Url: downloadUrl.toString(),
        duration: formattedTime,
        txtMsg: txtMsg,
        id: uniqueId,
        createdAt: DateTime.now(), // Add timestamp
      );

      try {
        // Add directly to Firestore
        await FirebaseFirestore.instance
            .collection('myaudio')
            .doc(uniqueId)
            .set(data.toFirestore());
            
        print('Audio meta added successfully to db!');
      } catch (e) {
        print('Error adding audio meta to db: $e');
      }
    }
  }

  @override
  void initState() {
    user = ChatUser(
      id: widget.userId,
      firstName: widget.userName,
      profileImage: 'assets/images/icon1.png',
    );

    if (_mPlayer != null) {
      _mPlayer!.openPlayer().then((value) {
        setState(() {
          _mPlayerIsInited = true;
        });
      });
    }

    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
    super.initState();

    listenToAudioChanges();
  }

  void listenToAudioChanges() {
    _streamSubscription?.cancel();
    _streamSubscription = FirebaseFirestore.instance
        .collection('myaudio')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        messages.clear();
        _audioList.clear();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final audioMeta = AudioMeta(
            userId: data['userId'] ?? '',
            mp4Url: data['mp4Url'] ?? '',
            duration: data['duration'] ?? '',
            txtMsg: data['txtMsg'] ?? '',
            id: doc.id,
          );

          _audioList.add(audioMeta);
          
          final msg = ChatMessage(
            text: 'Playback...... ${audioMeta.duration}\n ${audioMeta.txtMsg}',
            createdAt: DateTime.now(),
            user: ChatUser(
              id: audioMeta.userId,
              firstName: audioMeta.userId == widget.userId ? widget.userName : 'Other User',
            ),
            playBackUrl: audioMeta.mp4Url,
          );

          messages.add(msg);
          messageMap[audioMeta.mp4Url] = msg;
        }
      });
    });
  }

  void _generateUniqueId() async {
    final now = DateTime.now();
    String timestamp = now.toIso8601String();
    String uniqueSuffix = _generateRandomString(6);
    _uniqueId = timestamp + uniqueSuffix;
  }

  String _generateRandomString(int length) {
    const _randomChars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random random = Random();
    return List.generate(length,
        (index) => _randomChars[random.nextInt(_randomChars.length)]).join('');
  }

  Future<void> sendAudio(String uniquedId) async {
    final directory = await getApplicationCacheDirectory();
    final file = File('${directory.path}/$uniquedId.mp4');
    try {
      await audioRef.child(uniquedId).putFile(file);
    } on FirebaseException catch (e) {
      print(e);
    }
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder!.openRecorder();
    if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
      _mPath = 'tmp.webm';
      if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
        _mRecorderIsInited = true;
        return;
      }
    }
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _mRecorderIsInited = true;
  }

  void record() async {
    _generateUniqueId();
    startTime = DateTime.now();
    _mPath = '${(await getApplicationCacheDirectory()).path}/$_uniqueId.mp4';
    _mRecorder!
        .startRecorder(
      toFile: _mPath,
      codec: _codec,
      audioSource: audioIn,
    )
        .then((value) {
      setState(() {});
    });
  }

  void stopRecorder() async {
    await _mRecorder!.stopRecorder().then((value) async {
      setState(() {
        //var url = value;
        _mplaybackReady = true;
      });
      endTime = DateTime.now();

      await sendAudio(_uniqueId!);
      await submitAudio(_uniqueId!);
    });
  }

  String formatDuration(Duration duration) {
    final minute = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final second = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minute:$second'; // Format as MM:SS
  }

  void play(String downLoadUrl) async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);

    print('Downloaded file url: $downLoadUrl');

    try {
      await _mPlayer!.startPlayer(
        fromURI: downLoadUrl,
        whenFinished: () {
          setState(() {});
        },
      );

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  void stopPlayer() {
    _mPlayer!.stopPlayer().then((value) {
      setState(() {});
    });
  }

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer!.isStopped) {
      return null;
    }
    return _mRecorder!.isStopped ? record : stopRecorder;
  }

  @override
  void dispose() {
    _mPlayer!.closePlayer();
    _mPlayer = null;
    _searchController.dispose();
    _streamSubscription?.cancel();

    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: toggleSearch,
                autofocus: true,
              )
            : const Text('Echo Text'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (_isSearching) {
                  _searchController.clear();
                  toggleSearch('');
                }
                listenToAudioChanges();
                return;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DashChat(
              currentUser: user,
              onSend: (
                ChatMessage message,
              ) {}, // handle sending a message
              messages: messages,

              messageOptions: MessageOptions(
                showCurrentUserAvatar: true,
                onPressMessage: (msg) => {
                  // Playback the audio from here

                  toggleplayer(msg.playBackUrl!),
                },
              ),
              inputOptions: const InputOptions(
                inputDisabled: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: SizedBox(
              // width: double.infinity,
              child: ClipOval(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(255, 15, 14, 14),
                        const Color.fromARGB(255, 241, 54, 185),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: toggleRecording, // Keep your original function
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors
                          .transparent, // Make background transparent for gradient
                      shadowColor: Colors.transparent,
                      shape: const CircleBorder(), // Remove shadow
                    ),
                    child: Icon(
                      !_isRecording ? Icons.mic : Icons.stop,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
