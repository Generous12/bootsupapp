import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoTrimmerPage extends StatefulWidget {
  final File videoFile;

  const VideoTrimmerPage({Key? key, required this.videoFile}) : super(key: key);

  @override
  State<VideoTrimmerPage> createState() => _VideoTrimmerPageState();
}

class _VideoTrimmerPageState extends State<VideoTrimmerPage> {
  final Trimmer _trimmer = Trimmer();

  bool _isTrimming = false;
  double _startValue = 0.0;
  double _endValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    await _trimmer.loadVideo(videoFile: widget.videoFile);
    setState(() {});
  }

  Future<void> _saveTrimmedVideo() async {
    setState(() => _isTrimming = true);

    _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (String? outputPath) {
        setState(() => _isTrimming = false);
        if (outputPath != null) {
          Navigator.pop(context, File(outputPath));
        }
      },
    );
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final naranja = const Color(0xFFFFAF00);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  _isTrimming
                      ? const CircularProgressIndicator(color: Colors.white)
                      : CircleAvatar(
                          backgroundColor: naranja,
                          child: IconButton(
                            icon: const Icon(Icons.save, color: Colors.white),
                            onPressed: _saveTrimmedVideo,
                          ),
                        ),
                ],
              ),
            ),
            Expanded(
              child: VideoViewer(trimmer: _trimmer),
            ),
            TrimViewer(
              trimmer: _trimmer,
              viewerHeight: 50,
              viewerWidth: MediaQuery.of(context).size.width,
              maxVideoLength: const Duration(seconds: 30),
              onChangeStart: (value) => _startValue = value,
              onChangeEnd: (value) => _endValue = value,
              onChangePlaybackState: (value) {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
