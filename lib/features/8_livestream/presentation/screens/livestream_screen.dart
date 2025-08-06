import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:permission_handler/permission_handler.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/config/agora_config.dart';
import '../../../../data/models/comment_model.dart';

class LivestreamScreen extends StatefulWidget {
  final String channelName;
  final bool isHost;

  const LivestreamScreen({
    super.key,
    required this.channelName,
    required this.isHost,
  });

  @override
  State<LivestreamScreen> createState() => _LivestreamScreenState();
}

class _LivestreamScreenState extends State<LivestreamScreen> {
  late RtcEngine _engine;
  final _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
  final _commentController = TextEditingController();
  List<CommentModel> _comments = []; // CORECTAT: Am scos 'final'
  StreamSubscription? _commentSubscription;
  Set<int> _remoteUids = {};
  bool _localUserJoined = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _listenToComments();
  }

  @override
  void dispose() {
    _commentSubscription?.cancel();
    _engine.leaveChannel().then((_) {
      _engine.release();
    });
    if (widget.isHost) {
      _endLiveStream();
    }
    super.dispose();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: agoraAppId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => _localUserJoined = true);
          if (widget.isHost) _startLiveStream();
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUids.add(remoteUid));
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() => _remoteUids.remove(remoteUid));
        },
        onLeaveChannel: (connection, stats) {
          if (widget.isHost) _endLiveStream();
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: widget.isHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience);
    await _engine.joinChannel(token: '', channelId: widget.channelName, uid: 0, options: const ChannelMediaOptions());
  }

  Future<void> _startLiveStream() async {
    if (_currentUser != null) {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({'isLive': true});
      await FirebaseFirestore.instance.collection('livestreams').doc(_currentUser!.uid).set({'hostId': _currentUser!.uid, 'createdAt': Timestamp.now()});
    }
  }

  Future<void> _endLiveStream() async {
    if (_currentUser != null) {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({'isLive': false});
      await FirebaseFirestore.instance.collection('livestreams').doc(_currentUser!.uid).delete();
    }
  }

  void _listenToComments() {
    _commentSubscription = FirebaseFirestore.instance
        .collection('livestreams')
        .doc(widget.channelName)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _comments = snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
        });
      }
    });
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _currentUser == null) return;
    
    final userData = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    
    await FirebaseFirestore.instance
        .collection('livestreams')
        .doc(widget.channelName)
        .collection('comments')
        .add({
      'authorId': _currentUser!.uid,
      'text': _commentController.text.trim(),
      'createdAt': Timestamp.now(),
      'authorUsername': userData.data()?['username'] ?? 'Utilizator',
      'authorPhotoUrl': userData.data()?['photoUrl'],
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildVideoView(),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    if (!_localUserJoined) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        if (widget.isHost)
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
        ..._remoteUids.map((uid) => AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: widget.channelName),
          ),
        )),
      ],
    );
  }

  Widget _buildOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.5), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 150,
                child: ListView.builder(
                  reverse: true,
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                          children: [
                            TextSpan(text: '${comment.authorUsername}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: comment.text),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Adaugă un comentariu...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Iconsax.send_1, color: Colors.white),
                    onPressed: _postComment,
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.heart, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}