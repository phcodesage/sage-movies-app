import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String title;

  /// Remote mp4 or HLS url. Ignored when [filePath] is set.
  final String url;

  /// Local file to play instead of [url] — used for offline downloads.
  final String? filePath;

  const VideoPlayerPage({
    super.key,
    required this.title,
    this.url = '',
    this.filePath,
  }) : assert(url != '' || filePath != null, 'need a url or a filePath');

  /// Plays a downloaded file from disk.
  const VideoPlayerPage.file({
    super.key,
    required this.title,
    required String path,
  })  : filePath = path,
        url = '';

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _showUi = true;
  String? _error;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.filePath != null
        ? VideoPlayerController.file(File(widget.filePath!))
        : VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller
      ..setLooping(false)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
        _kickAutoHide();
      }).catchError((Object e) {
        if (!mounted) return;
        setState(() => _error = 'This file could not be played.');
      });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _kickAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showUi = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _showUi = !_showUi);
            if (_showUi) _kickAutoHide();
          },
          child: Stack(
            children: [
              Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      )
                    : _ready
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio == 0
                                ? 16 / 9
                                : _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(),
                          ),
              ),
              if (_showUi)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _TopBar(title: widget.title, onBack: () => Navigator.pop(context)),
                ),
              if (_showUi && _ready)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _Controls(controller: _controller, onPlayPause: _togglePlay),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, color: Colors.white)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onPlayPause;
  const _Controls({required this.controller, required this.onPlayPause});

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  @override
  void initState() {
    super.initState();
    // Without this the scrubber and the play/pause icon only repaint when the
    // parent happens to rebuild.
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.controller.value;
    final pos = v.position;
    final dur = v.duration;
    final isPlaying = v.isPlaying;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onPlayPause,
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                  child: Slider(
                    value: dur.inMilliseconds == 0 ? 0 : pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
                    max: (dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds).toDouble(),
                    onChanged: (v) => widget.controller.seekTo(Duration(milliseconds: v.toInt())),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${_format(pos)} / ${_format(dur)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
