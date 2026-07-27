import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/services/api_service.dart';

class PlayerScreen extends StatefulWidget {
  final Movie movie;
  const PlayerScreen({super.key, required this.movie});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _controller;
  String? _currentUrl;
  String _server = 'player.videasy.net';
  bool _loading = true;
  String? _error;
  bool _isFullscreen = false;
  bool _showDoubleTapLeft = false;
  bool _showDoubleTapRight = false;
  Timer? _doubleTapTimer;

  static const _servers = <String, String>{
    'player.videasy.net': 'Videasy (Recommended)',
    '2embed': '2Embed (Reliable)',
    'vidsrc.me': 'Vidsrc.me (Subtitles)',
    'superembed': 'SuperEmbed (Backup)',
  };

  @override
  void initState() {
    super.initState();
    _initController();
    _loadServer();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
      )
      ..enableZoom(false);

    if (_controller.platform is AndroidWebViewController) {
      final awv = _controller.platform as AndroidWebViewController;
      awv.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          debugPrint('[Player] Page started: $url');
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (url) {
          debugPrint('[Player] Page finished: $url');
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (err) {
          debugPrint('[Player] Web resource error: ${err.description} (${err.errorCode})');
          if (err.errorType == WebResourceErrorType.hostLookup ||
              err.errorType == WebResourceErrorType.timeout ||
              err.errorType == WebResourceErrorType.connect) {
            if (mounted) {
              setState(() {
                _error = 'Connection error: ${err.description}';
                _loading = false;
              });
            }
          }
        },
        onNavigationRequest: (req) {
          debugPrint('[Player] Navigation request: ${req.url}');
          final urlStr = req.url.toLowerCase();

          if (urlStr.startsWith('data:') || urlStr.startsWith('about:') || urlStr.startsWith('blob:')) {
            return NavigationDecision.navigate;
          }

          try {
            final uri = Uri.parse(req.url);
            final host = uri.host.toLowerCase();

            final allowedKeywords = [
              'videasy', '2embed', 'vidsrc', 'multiembed', 'superembed',
              'embed', 'player', 'vidplay', 'cloud', 'stream', 'hls', 'm3u8'
            ];

            bool isAllowed = allowedKeywords.any((keyword) => host.contains(keyword));
            if (isAllowed || req.url == _currentUrl) {
              return NavigationDecision.navigate;
            } else {
              debugPrint('[Player] Preventing popup/ad redirect to: $host');
              return NavigationDecision.prevent;
            }
          } catch (e) {
            debugPrint('[Player] Error parsing URL: $e');
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _togglePlayPause() {
    _controller.runJavaScript('''
      (function() {
        function tryMedia(win) {
          try {
            var v = win.document.querySelector('video');
            if (v) {
              if (v.paused) { v.play(); } else { v.pause(); }
              return true;
            }
          } catch(e) {}
          try {
            for (var i = 0; i < win.frames.length; i++) {
              if (tryMedia(win.frames[i])) return true;
            }
          } catch(e) {}
          return false;
        }
        tryMedia(window);
      })();
    ''');
  }

  void _triggerDoubleTapSkip(bool isRight) {
    _doubleTapTimer?.cancel();
    setState(() {
      _showDoubleTapLeft = !isRight;
      _showDoubleTapRight = isRight;
    });

    final seconds = isRight ? 10 : -10;
    _controller.runJavaScript('''
      (function() {
        function trySeek(win, delta) {
          try {
            var v = win.document.querySelector('video');
            if (v) {
              v.currentTime = Math.max(0, v.currentTime + delta);
              return true;
            }
          } catch(e) {}
          try {
            for (var i = 0; i < win.frames.length; i++) {
              if (trySeek(win.frames[i], delta)) return true;
            }
          } catch(e) {}
          return false;
        }
        trySeek(window, $seconds);
      })();
    ''');

    _doubleTapTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showDoubleTapLeft = false;
          _showDoubleTapRight = false;
        });
      }
    });
  }

  Future<void> _loadServer() async {
    _initController();
    setState(() {
      _loading = true;
      _error = null;
    });
    final type = (widget.movie.mediaType == 'tv') ? 'tv' : 'movie';
    debugPrint('[Player] Loading video: type=$type, id=${widget.movie.id}, server=$_server');

    String? url = await ApiService.getVideoSource(type, widget.movie.id, server: _server);

    if (url == null || url.isEmpty) {
      final idNum = widget.movie.id;
      if (_server == 'player.videasy.net') {
        url = 'https://player.videasy.net/$type/$idNum?ads_behavior=background&popup_mode=quiet';
      } else if (_server == '2embed') {
        url = type == 'tv'
            ? 'https://www.2embed.cc/embedtv/$idNum&s=1&e=1'
            : 'https://www.2embed.cc/embed/$idNum';
      } else if (_server == 'vidsrc.me') {
        url = 'https://vidsrc.me/embed/$type?tmdb=$idNum';
      } else if (_server == 'superembed') {
        url = 'https://multiembed.mov/?video_id=$idNum&tmdb=1';
      }
    }

    if (!mounted) return;

    if (url == null || url.isEmpty) {
      setState(() {
        _error = 'Failed to get video source for this content. Try selecting a different server.';
        _loading = false;
      });
      return;
    }

    debugPrint('[Player] Final video URL: $url');
    _currentUrl = url;

    try {
      await _controller.clearCache();
      await _controller.loadRequest(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
        },
      );
    } catch (e) {
      debugPrint('[Player] Error loading URL: $e');
      final html = _buildEmbedHtml(url);
      await _controller.loadHtmlString(html, baseUrl: ApiService.baseUrl);
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  String _buildEmbedHtml(String url) {
    return '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <style>
      * { margin:0; padding:0; box-sizing:border-box; }
      html, body {
        background: #000;
        width: 100vw;
        height: 100vh;
        overflow: hidden;
      }
      iframe {
        width: 100vw;
        height: 100vh;
        border: 0;
        outline: none;
      }
    </style>
  </head>
  <body>
    <iframe 
      src="$url" 
      allow="autoplay; fullscreen *; encrypted-media; picture-in-picture; accelerometer; gyroscope"
      allowfullscreen="true"
      frameborder="0">
    </iframe>
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    Widget playerWidget = Stack(
      children: [
        if (_currentUrl != null && _error == null)
          WebViewWidget(
            key: ValueKey('$_server|$_currentUrl'),
            controller: _controller,
          ),

        // Animated double tap feedback overlay
        if (_showDoubleTapLeft)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(left: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.replay_10, color: Colors.white, size: 28),
                  SizedBox(width: 4),
                  Text('-10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        if (_showDoubleTapRight)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(right: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('+10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.forward_10, color: Colors.white, size: 28),
                ],
              ),
            ),
          ),

        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          ),

        if (_error != null && !_loading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loadServer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Server'),
                  )
                ],
              ),
            ),
          ),
      ],
    );

    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: playerWidget),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                onPressed: _toggleFullscreen,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.movie.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
            icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: _toggleFullscreen,
          ),
          IconButton(
            tooltip: 'Reload Stream',
            icon: const Icon(Icons.refresh),
            onPressed: _loadServer,
          ),
          if (_currentUrl != null)
            IconButton(
              tooltip: 'Open in Browser',
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                final uri = Uri.parse(_currentUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Responsive 16:9 Video Player Viewport
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: playerWidget,
            ),
          ),

          const SizedBox(height: 12),

          // Server Selector Chips & Native Controls Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SERVER SOURCE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white70, size: 20),
                      onPressed: _toggleFullscreen,
                      tooltip: 'Landscape Fullscreen',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Horizontal Server Selector Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _servers.entries.map((entry) {
                      final isSelected = entry.key == _server;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFE50914),
                          backgroundColor: const Color(0xFF1E1E1E),
                          onSelected: (selected) {
                            if (selected && _server != entry.key) {
                              setState(() => _server = entry.key);
                              _loadServer();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Video info details
                Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFFE50914), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Playing from ${_servers[_server]}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
