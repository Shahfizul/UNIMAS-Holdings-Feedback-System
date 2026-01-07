import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// A reusable widget that plays a video from a Network URL.
// It uses 'Chewie' to provide a nice UI (Play/Pause buttons, timeline)
// over the standard Flutter VideoPlayer.
class SimpleVideoPlayer extends StatefulWidget {
  final String videoUrl; // The direct URL link to the MP4 file

  const SimpleVideoPlayer({super.key, required this.videoUrl});

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  // Low-level controller: Handles the actual media decoding and buffering
  late VideoPlayerController _videoPlayerController;

  // High-level controller: Handles the UI overlay (controls, full-screen, etc.)
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  // Asynchronously set up the video controllers
  Future<void> _initializePlayer() async {
    try {
      // 1. Initialize the low-level video controller
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();

      // 2. Initialize the Chewie UI controller
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false, // Do not start playing automatically
        looping: false,  // Do not repeat video when it ends
        aspectRatio: _videoPlayerController.value.aspectRatio, // Use the video's actual dimensions

        // Custom error handling UI
        errorBuilder: (context, errorMessage) {
          return Center(child: Text("Error: $errorMessage", style: const TextStyle(color: Colors.white)));
        },
      );

      // 3. Update UI to show the player now that it is ready
      if (mounted) setState(() {});
    } catch (e) {
      print("Video Initialization Error: $e");
    }
  }

  // Dispose controllers to free up memory when the user leaves this screen
  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the controller is ready and initialized
    if (_chewieController != null && _videoPlayerController.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        // ClipRRect ensures the video corners are rounded like the container
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Chewie(controller: _chewieController!),
        ),
      );
    } else {
      // Show a loading spinner placeholder while the video initializes
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
  }
}