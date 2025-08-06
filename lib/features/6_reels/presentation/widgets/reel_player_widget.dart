// FILE: lib/features/6_reels/presentation/widgets/reel_player_widget.dart
// Înlocuiește conținutul fișierului existent cu acest cod.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../data/models/reel_model.dart';
import '../screens/reel_comments_screen.dart';

class ReelPlayer extends StatefulWidget {
  final ReelModel reel;
  const ReelPlayer({super.key, required this.reel});

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  late VideoPlayerController _videoController;
  final _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
  bool _isInitialized = false;
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = _currentUser != null ? widget.reel.likes.contains(_currentUser!.uid) : false;
    _likeCount = widget.reel.likeCount;

    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
      ..initialize().then((_) {
        setState(() { _isInitialized = true; });
        _videoController.setLooping(true);
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_currentUser == null) return;

    final reelRef = FirebaseFirestore.instance.collection('reels').doc(widget.reel.id);
    final newIsLiked = !_isLiked;

    setState(() {
      _isLiked = newIsLiked;
      if (newIsLiked) _likeCount++; else _likeCount--;
    });

    if (newIsLiked) {
      await reelRef.update({
        'likes': FieldValue.arrayUnion([_currentUser!.uid]),
        'likeCount': FieldValue.increment(1),
      });
    } else {
      await reelRef.update({
        'likes': FieldValue.arrayRemove([_currentUser!.uid]),
        'likeCount': FieldValue.increment(-1),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.reel.id),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.8) {
          _videoController.play();
        } else {
          _videoController.pause();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized)
            GestureDetector(
              onTap: () => setState(() {
                if (_videoController.value.isPlaying) _videoController.pause();
                else _videoController.play();
              }),
              child: Center(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.4), Colors.transparent],
          begin: Alignment.bottomCenter,
          end: Alignment.center,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0).copyWith(bottom: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // MODIFICAT: Afișăm poza grupului
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: widget.reel.groupPhotoUrl != null ? NetworkImage(widget.reel.groupPhotoUrl!) : null,
                            ),
                            const SizedBox(width: 8),
                            // MODIFICAT: Afișăm numele grupului
                            Text(
                              widget.reel.groupName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.reel.caption,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(_isLiked ? Iconsax.heart5 : Iconsax.heart, color: _isLiked ? Colors.red : Colors.white, size: 32),
                        onPressed: _toggleLike,
                      ),
                      Text(_likeCount.toString(), style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 20),
                      IconButton(
                        icon: const Icon(Iconsax.message_text, color: Colors.white, size: 32),
                        onPressed: () {
                          _videoController.pause();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.75,
                              child: ReelCommentsScreen(reelId: widget.reel.id),
                            ),
                          ).whenComplete(() => _videoController.play());
                        },
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('reels').doc(widget.reel.id).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Text('0', style: TextStyle(color: Colors.white));
                          final count = snapshot.data!['commentCount'] ?? 0;
                          return Text(count.toString(), style: const TextStyle(color: Colors.white));
                        }
                      ),
                      const SizedBox(height: 20),
                      IconButton(
                        icon: const Icon(Iconsax.send_1, color: Colors.white, size: 32),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
