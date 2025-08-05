import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import '../../../../data/models/story_model.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  const StoryViewerScreen({super.key, required this.stories});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final StoryController _storyController = StoryController();
  final List<StoryItem> _storyItems = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  void _loadStories() {
    for (var story in widget.stories) {
      // CORECTAT: Folosim câmpul mediaType
      if (story.mediaType == 'image') {
        _storyItems.add(
          StoryItem.pageImage(
            url: story.mediaUrl,
            controller: _storyController,
            caption: Text(
              // CORECTAT: Folosim câmpul groupName
              story.groupName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StoryView(
        storyItems: _storyItems,
        controller: _storyController,
        onComplete: () => Navigator.of(context).pop(),
        onVerticalSwipeComplete: (direction) {
          if (direction == Direction.down) {
            Navigator.of(context).pop();
          }
        },
        inline: false,
        repeat: false,
      ),
    );
  }
}
