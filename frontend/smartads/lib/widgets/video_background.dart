import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'street_image_background.dart';

class VideoBackground extends StatefulWidget {
  final Widget child;

  const VideoBackground({super.key, required this.child});

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.asset('assets/videos/billboard_street.mp4');
      _controller = controller;
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0.0);
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_hasError || !_isVideoInitialized || controller == null) {
      // Fallback to static street image background if video fails or is loading
      return StreetImageBackground(child: widget.child);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        // Light translucent overlay to keep background video vibrant while ensuring text legibility
        Container(
          color: Colors.black.withValues(alpha: 0.16),
        ),
        widget.child,
      ],
    );
  }
}
