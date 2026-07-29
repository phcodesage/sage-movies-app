import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:sagemovies/app_state.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/player_screen.dart';
import 'package:sagemovies/screens/search_screen.dart';
import 'package:sagemovies/screens/my_list_screen.dart';
import 'package:sagemovies/screens/downloads_screen.dart';
import 'package:sagemovies/screens/studio_movies_screen.dart';
import 'package:sagemovies/services/api_service.dart';
import 'package:sagemovies/services/toast_service.dart';
import 'package:sagemovies/services/update_service.dart';
import 'package:sagemovies/widgets/safe_cached_image.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class DetailsScreen extends StatefulWidget {
  final Movie movie;
  const DetailsScreen({super.key, required this.movie});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WebViewController _controller;
  bool _isPlaying = false;
  bool _isLoadingPlayer = false;
  bool _isVideoPlayingState = false;
  String _server = 'player.videasy.net';
  String _lang = 'en';
  bool _isDescExpanded = false;

  String _studioName = '';
  List<Movie> _studioMovies = [];

  static const _servers = <String, String>{
    'player.videasy.net': 'Videasy (Recommended)',
    '2embed': '2Embed (Reliable)',
    'vidsrc.me': 'Vidsrc.me (Subtitles)',
    'superembed': 'SuperEmbed (Backup)',
  };

  static const _languages = <String, String>{
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'tl': 'Tagalog',
    'ja': 'Japanese',
  };

  Map<String, bool> _serverStatus = {};
  bool _isCheckingServers = false;

  Map<String, dynamic>? _fullDetails;
  int _selectedSeason = 1;
  int _selectedEpisode = 1;

  void _precheckServers() async {
    if (!mounted) return;
    setState(() => _isCheckingServers = true);
    final res = await ApiService.checkServers(widget.movie.mediaType, widget.movie.id);
    if (mounted && res != null) {
      final statusMap = res['status'] as Map<String, dynamic>?;
      final bestServer = res['bestServer'] as String?;
      setState(() {
        if (statusMap != null) {
          _serverStatus = statusMap.map((k, v) => MapEntry(k, v == true));
        }
        if (bestServer != null && (_serverStatus[_server] != true)) {
          _server = bestServer;
        }
        _isCheckingServers = false;
      });
    } else if (mounted) {
      setState(() => _isCheckingServers = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setUserAgent('Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36')
      ..enableZoom(false)
      ..addJavaScriptChannel(
        'FlutterPlayerChannel',
        onMessageReceived: (JavaScriptMessage msg) {
          if (msg.message == 'PLAYING') {
            if (mounted && !_isVideoPlayingState) {
              setState(() => _isVideoPlayingState = true);
            }
          } else if (msg.message == 'PAUSED') {
            if (mounted && _isVideoPlayingState) {
              setState(() => _isVideoPlayingState = false);
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted && _isPlaying) {
                _triggerAutoPlayScript();
              }
            });
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (mounted && _isPlaying) {
                _triggerAutoPlayScript();
              }
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            if (url.startsWith('data:') || url.startsWith('about:') || url.startsWith('blob:')) {
              return NavigationDecision.navigate;
            }
            if (url.contains('videasy') ||
                url.contains('2embed') ||
                url.contains('vidsrc') ||
                url.contains('multiembed') ||
                url.contains('superembed') ||
                url.contains('vidplay') ||
                url.contains('cloud') ||
                url.contains('stream') ||
                url.contains('m3u8') ||
                url.contains('mp4')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      final awv = _controller.platform as AndroidWebViewController;
      awv.setMediaPlaybackRequiresUserGesture(false);
      awv.setCustomWidgetCallbacks(
        onShowCustomWidget: (Widget customWidget, OnHideCustomWidgetCallback callback) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        },
        onHideCustomWidget: () {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
        },
      );
    }

    _precheckServers();
    _fetchFullDetails();
  }

  String? _studioLogoPath;
  List<Map<String, dynamic>> _studioCompanies = [];

  Future<void> _fetchFullDetails() async {
    final type = (widget.movie.mediaType == 'tv') ? 'tv' : 'movie';
    final details = await ApiService.fetchFullDetails(type, widget.movie.id);
    if (!mounted) return;

    if (details != null) {
      final comps = details['production_companies'] as List?;
      String sName = '';
      String? sLogo;

      if (comps != null && comps.isNotEmpty) {
        final viva = comps.firstWhere(
          (c) => (c['name'] ?? '').toString().toLowerCase().contains('vivamax'),
          orElse: () => comps[0],
        );
        sName = viva['name'] ?? '';
        sLogo = viva['logo_path'] as String?;
      }

      setState(() {
        _fullDetails = details;
        _studioName = sName;
        _studioLogoPath = sLogo;
        _studioCompanies = comps != null ? List<Map<String, dynamic>>.from(comps) : [];
      });

      final studioId = comps != null && comps.isNotEmpty ? comps[0]['id'] as int? : null;
      if (studioId != null) {
        final studioRes = await ApiService.fetchMoviesByStudio(studioId);
        if (mounted && studioRes.isNotEmpty) {
          setState(() {
            _studioMovies = studioRes.where((m) => m.id != widget.movie.id).toList();
          });
        }
      }
    }

    // Fallback studio movies if none returned
    if (_studioMovies.isEmpty) {
      final fallback = await ApiService.fetchMoviesByGenre(28);
      if (mounted) {
        setState(() {
          _studioName = _studioName.isEmpty ? 'SIMILAR TITLES' : _studioName;
          _studioMovies = fallback.where((m) => m.id != widget.movie.id).toList();
        });
      }
    }
  }

  Future<void> _startWatching() async {
    final type = (widget.movie.mediaType == 'tv' || (_fullDetails != null && (_fullDetails!['first_air_date'] != null || _fullDetails!['number_of_seasons'] != null))) ? 'tv' : 'movie';
    String? url = await ApiService.getVideoSource(
      type,
      widget.movie.id,
      server: _server,
      season: _selectedSeason,
      episode: _selectedEpisode,
    );

    if (url == null || url.isEmpty) {
      final idNum = widget.movie.id;
      final s = _selectedSeason;
      final e = _selectedEpisode;
      if (_server == 'player.videasy.net') {
        url = type == 'tv'
            ? 'https://player.videasy.net/tv/$idNum/$s/$e?ads_behavior=background&popup_mode=quiet'
            : 'https://player.videasy.net/$type/$idNum?ads_behavior=background&popup_mode=quiet';
      } else if (_server == '2embed') {
        url = type == 'tv'
            ? 'https://www.2embed.cc/embedtv/$idNum&s=$s&e=$e'
            : 'https://www.2embed.cc/embed/$idNum';
      } else if (_server == 'vidsrc.me') {
        url = type == 'tv'
            ? 'https://vidsrc.me/embed/tv?tmdb=$idNum&season=$s&episode=$e'
            : 'https://vidsrc.me/embed/$type?tmdb=$idNum&ds_lang=$_lang';
      } else if (_server == 'superembed') {
        url = type == 'tv'
            ? 'https://multiembed.mov/?video_id=$idNum&tmdb=1&s=$s&e=$e'
            : 'https://multiembed.mov/?video_id=$idNum&tmdb=1';
      }
    }

    if (!mounted || url == null) return;

    final targetUrl = url;

    // 1. Mount WebViewWidget into the widget tree FIRST
    setState(() {
      _embedUrl = targetUrl;
      _isPlaying = true;
      _isLoadingPlayer = true;
    });

    // 2. Short delay for Android platform view to attach to native hierarchy
    await Future.delayed(const Duration(milliseconds: 50));

    // 3. Load video source URL on attached WebView
    try {
      await _controller.clearCache();
      await _controller.loadRequest(
        Uri.parse(targetUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
        },
      );
    } catch (e) {
      final html = _buildEmbedHtml(targetUrl);
      await _controller.loadHtmlString(html, baseUrl: ApiService.baseUrl);
    }

    if (mounted) {
      setState(() {
        _isLoadingPlayer = false;
      });
    }
  }

  void _showSkippableAdDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SkippableAdDialog(
        onFinished: () {
          Navigator.of(ctx).pop();
          _startWatching();
          UnityAds.load(placementId: 'Interstitial_Android');
        },
      ),
    );
  }

  void _triggerAdAndWatch() {
    if (_isPlaying) {
      _startWatching();
      return;
    }
    
    // Show 5-second skippable ad dialog or Unity Video Ad
    UnityAds.showVideoAd(
      placementId: 'Interstitial_Android',
      onComplete: (placementId) {
        _startWatching();
        UnityAds.load(placementId: 'Interstitial_Android');
      },
      onFailed: (placementId, error, message) {
        debugPrint('Unity Ad Error: $error $message. Launching Skippable Ad Modal.');
        _showSkippableAdDialog();
      },
      onSkipped: (placementId) {
        _startWatching();
        UnityAds.load(placementId: 'Interstitial_Android');
      },
    );
  }

  void _triggerAutoPlayScript() {
    _controller.runJavaScript('''
      (function() {
        function autoPlay(win) {
          try {
            var doc = win.document;
            var vList = doc.querySelectorAll('video');
            for (var i = 0; i < vList.length; i++) {
              var v = vList[i];
              if (v.paused) {
                var p = v.play();
                if (p && p.catch) { p.catch(function(){}); }
              }
            }
            var selectors = ['.jw-display-icon-container', '.vjs-big-play-button', '.play-btn', '.play-button', '#play-btn', '#play', '[class*="play"]', '[id*="play"]', 'button', 'svg'];
            for (var s = 0; s < selectors.length; s++) {
              var els = doc.querySelectorAll(selectors[s]);
              for (var e = 0; e < els.length; e++) {
                try {
                  els[e].click();
                  var evt = doc.createEvent('MouseEvents');
                  evt.initEvent('click', true, true);
                  els[e].dispatchEvent(evt);
                } catch(err) {}
              }
            }
            var centerEl = doc.elementFromPoint(win.innerWidth / 2, win.innerHeight / 2);
            if (centerEl) {
              try {
                centerEl.click();
                var evt2 = doc.createEvent('MouseEvents');
                evt2.initEvent('click', true, true);
                centerEl.dispatchEvent(evt2);
              } catch(err2) {}
            }
          } catch(e) {}
          try {
            for (var j = 0; j < win.frames.length; j++) {
              autoPlay(win.frames[j]);
            }
          } catch(e) {}
        }
        autoPlay(window);
      })();
    ''');
  }

  void _togglePlayPause() {
    final newState = !_isVideoPlayingState;
    if (mounted) setState(() => _isVideoPlayingState = newState);
    _triggerAutoPlayScript();
    _controller.runJavaScript('''
      (function() {
        function tryMedia(win) {
          try {
            var doc = win.document;
            var v = doc.querySelector('video');
            if (v) {
              if (v.paused) {
                v.play();
                if (window.FlutterPlayerChannel) window.FlutterPlayerChannel.postMessage('PLAYING');
              } else {
                v.pause();
                if (window.FlutterPlayerChannel) window.FlutterPlayerChannel.postMessage('PAUSED');
              }
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

  void _seekVideo(int seconds) {
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
  }

  String _embedUrl = '';

  String _buildEmbedHtml(String url) {
    return '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <style>
      * { margin:0; padding:0; box-sizing:border-box; }
      html, body { background:#000; width:100vw; height:100vh; overflow:hidden; display:flex; align-items:center; justify-content:center; }
      iframe { width:100vw; height:100vh; border:0; outline:none; }
    </style>
  </head>
  <body>
    <iframe src="$url" allow="autoplay; fullscreen *; encrypted-media; picture-in-picture" allowfullscreen="true" frameborder="0"></iframe>
    <script>
      (function() {
        function notify(st) {
          try {
            if (window.FlutterPlayerChannel) {
              window.FlutterPlayerChannel.postMessage(st);
            }
          } catch(e) {}
        }
        function scanFrames(win) {
          try {
            var doc = win.document;
            var vList = doc.querySelectorAll('video');
            var isAnyPlaying = false;
            for (var i = 0; i < vList.length; i++) {
              var v = vList[i];
              if (!v._sageMonitored) {
                v._sageMonitored = true;
                v.addEventListener('play', function() { notify('PLAYING'); });
                v.addEventListener('playing', function() { notify('PLAYING'); });
                v.addEventListener('pause', function() { notify('PAUSED'); });
                v.addEventListener('ended', function() { notify('PAUSED'); });
              }
              if (!v.paused && v.readyState >= 2) {
                isAnyPlaying = true;
                notify('PLAYING');
              } else if (v.paused) {
                notify('PAUSED');
              }
            }
            if (!isAnyPlaying) {
              var selectors = ['.jw-display-icon-container', '.vjs-big-play-button', '.play-btn', '.play-button', '#play-btn', '#play', '[class*="play"]', '[id*="play"]', 'button', 'svg'];
              for (var s = 0; s < selectors.length; s++) {
                var els = doc.querySelectorAll(selectors[s]);
                for (var e = 0; e < els.length; e++) {
                  try { els[e].click(); } catch(err) {}
                }
              }
            }
          } catch(e) {}
          try {
            for (var j = 0; j < win.frames.length; j++) {
              scanFrames(win.frames[j]);
            }
          } catch(e) {}
        }
        setInterval(scanFrames, 600);
      })();
    </script>
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateProvider.of(context);
    final inList = app.isInMyList(widget.movie.id);
    final year = widget.movie.releaseDate != null && widget.movie.releaseDate!.length >= 4
        ? widget.movie.releaseDate!.substring(0, 4)
        : '2023';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F0F11),
      drawerEnableOpenDragGesture: true,
      drawer: _buildLeftNavDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // 1. STICKY TOP PLAYER / BACKDROP (Stays fixed when scrolling lower details)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: _isPlaying
                        ? Stack(
                            children: [
                              WebViewWidget(
                                key: ValueKey('$_server|$_lang|$_embedUrl'),
                                controller: _controller,
                              ),
                              if (_isLoadingPlayer)
                                const Center(
                                  child: CircularProgressIndicator(color: Color(0xFFE50914)),
                                ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                                  onPressed: () {
                                    setState(() => _isPlaying = false);
                                  },
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              SafeCachedImage(
                                imageUrl: widget.movie.backdropUrl.isNotEmpty
                                    ? widget.movie.backdropUrl
                                    : widget.movie.posterUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    Container(color: const Color(0xFF1A1A1A)),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Color(0xFF0F0F11), Colors.transparent],
                                    stops: [0.0, 0.7],
                                  ),
                                ),
                              ),
                              Center(
                                child: GestureDetector(
                                  onTap: _triggerAdAndWatch,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.2),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.8),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          size: 42,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'PLAY NOW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          letterSpacing: 1.2,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // Top Left Action Bar: Draggable Menu & Back Buttons
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 2. STICKY NATIVE PLAYER CONTROL BAR (Directly below video when playing)
            if (_isPlaying)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF16161B),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _seekVideo(-10),
                      icon: const Icon(Icons.replay_10, size: 18),
                      label: const Text('-10s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isVideoPlayingState ? Colors.white24 : const Color(0xFFE50914),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: _togglePlayPause,
                      icon: Icon(_isVideoPlayingState ? Icons.pause : Icons.play_arrow, size: 20),
                      label: Text(
                        _isVideoPlayingState ? 'PAUSE' : 'PLAY',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _seekVideo(10),
                      icon: const Icon(Icons.forward_10, size: 18),
                      label: const Text('+10s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // 3. SCROLLABLE DETAILS & RECOMMENDATIONS CONTENT
            const SizedBox(height: 8),

            // 3. FIXED HEADER TITLE CARD (Stays fixed at top below player)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 70,
                          height: 100,
                          child: SafeCachedImage(
                            imageUrl: widget.movie.posterUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                Container(color: Colors.white10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movie.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // M3 Rating Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB800),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, size: 12, color: Colors.black),
                                        const SizedBox(width: 3),
                                        Text(
                                          widget.movie.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // M3 Year Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF27272A),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      year,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // M3 Media Type Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE50914),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.movie.mediaType == 'tv' ? 'TV SERIES' : 'MOVIE',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // M3 Quality Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'HD / 4K',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  if (_studioName.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3F3F46),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_studioLogoPath != null && _studioLogoPath!.isNotEmpty) ...[
                                            Image.network(
                                              'https://image.tmdb.org/t/p/w200$_studioLogoPath',
                                              height: 12,
                                              fit: BoxFit.contain,
                                              color: Colors.white,
                                              errorBuilder: (context, error, stack) =>
                                                  const SizedBox.shrink(),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            _studioName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Primary Instant Watch CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _triggerAdAndWatch,
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: Text(
                        _isPlaying ? 'REFRESH STREAM' : 'WATCH NOW FREE',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 4. SCROLLABLE DETAILS CONTENT (Episodes, Stream Settings, Storyline, Cast & Recommendations)
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFE50914),
                backgroundColor: const Color(0xFF141414),
                onRefresh: () async {
                  _precheckServers();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                      // EPISODE SELECTOR (For TV Shows)
                      if (widget.movie.mediaType == 'tv' || (_fullDetails != null && (_fullDetails!['first_air_date'] != null || _fullDetails!['number_of_seasons'] != null))) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16161B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF26262D)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE50914),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'EPISODE SELECTOR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Season $_selectedSeason of ${(_fullDetails?['number_of_seasons'] ?? (_fullDetails?['seasons'] as List?)?.length ?? 1)}',
                                    style: const TextStyle(color: Color(0xFFE50914), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 38,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: (_fullDetails?['number_of_seasons'] ?? (_fullDetails?['seasons'] as List?)?.length ?? 1),
                                  itemBuilder: (context, idx) {
                                    final seasonNum = idx + 1;
                                    final isSelected = seasonNum == _selectedSeason;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedSeason = seasonNum;
                                            _selectedEpisode = 1;
                                          });
                                          if (_isPlaying) _startWatching();
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFFE50914) : Colors.white10,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isSelected ? const Color(0xFFE50914) : Colors.white24,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Season $seasonNum',
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.white70,
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SELECT EPISODE',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    'Playing S$_selectedSeason:E$_selectedEpisode',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 42,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: (() {
                                    final seasons = _fullDetails?['seasons'] as List?;
                                    if (seasons != null && seasons.isNotEmpty) {
                                      final sObj = seasons.firstWhere(
                                        (s) => s['season_number'] == _selectedSeason,
                                        orElse: () => seasons[0],
                                      );
                                      return (sObj['episode_count'] as int?) ?? 24;
                                    }
                                    return 24;
                                  })(),
                                  itemBuilder: (context, idx) {
                                    final epNum = idx + 1;
                                    final isSelected = epNum == _selectedEpisode;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() => _selectedEpisode = epNum);
                                          _startWatching();
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 54,
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFFE50914) : const Color(0xFF0F0F11),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected ? const Color(0xFFE50914) : Colors.white24,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'E$epNum',
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.white70,
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // STREAM SETTINGS Card (Expandable)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF16161B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF26262D)),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              'STREAM SETTINGS ($_server)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            iconColor: Colors.white70,
                            collapsedIconColor: Colors.white38,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16).copyWith(top: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'STREAMING SERVER',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F0F11),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _server,
                                          isExpanded: true,
                                          dropdownColor: const Color(0xFF16161B),
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                          items: _servers.entries.map((e) {
                                            final status = _serverStatus[e.key];
                                            String indicator = '';
                                            Color color = Colors.white70;
                                            if (_isCheckingServers) {
                                              indicator = ' (Checking...)';
                                            } else if (status == true) {
                                              indicator = '  🟢 Active';
                                              color = Colors.greenAccent;
                                            } else if (status == false) {
                                              indicator = '  🔴 Offline';
                                              color = Colors.redAccent;
                                            }

                                            return DropdownMenuItem<String>(
                                              value: e.key,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                                  Text(indicator, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setState(() => _server = v);
                                            if (_isPlaying) _startWatching();
                                          },
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    const Text(
                                      'SUBTITLE LANGUAGE',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F0F11),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _lang,
                                          isExpanded: true,
                                          dropdownColor: const Color(0xFF16161B),
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                          items: _languages.entries
                                              .map((e) => DropdownMenuItem<String>(
                                                    value: e.key,
                                                    child: Text(e.value),
                                                  ))
                                              .toList(),
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setState(() => _lang = v);
                                            if (_isPlaying) _startWatching();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // STORYLINE Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, color: Colors.white54, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'STORYLINE',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                          child: Text(
                            _isDescExpanded ? 'LESS' : 'MORE',
                            style: const TextStyle(
                              color: Color(0xFFE50914),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.movie.overview.isNotEmpty
                          ? widget.movie.overview
                          : 'No description available for this title.',
                      maxLines: _isDescExpanded ? null : 4,
                      overflow: _isDescExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),

                    const SizedBox(height: 24),

                    // My List & Share Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              final added = app.toggleMyList(widget.movie);
                              if (added) {
                                ToastService.showSuccess(context, '"${widget.movie.title}" added to My List');
                              } else {
                                ToastService.showInfo(context, '"${widget.movie.title}" removed from My List');
                              }
                            },
                            icon: Icon(inList ? Icons.check : Icons.add, size: 18),
                            label: Text(inList ? 'In My List' : 'Add to My List'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // MORE FROM [STUDIO NAME] Section
                    if (_studioMovies.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.play_arrow, color: Color(0xFFE50914), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'MORE FROM ${_studioName.isNotEmpty ? _studioName : 'STUDIO'}',
                              style: const TextStyle(
                                color: Color(0xFFE50914),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 240,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _studioMovies.length,
                          separatorBuilder: (context, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final m = _studioMovies[i];
                            return SizedBox(
                              width: 130,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DetailsScreen(movie: m),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFE50914).withOpacity(0.6),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              SafeCachedImage(
                                                imageUrl: m.posterUrl,
                                                fit: BoxFit.cover,
                                                memCacheWidth: 300,
                                                errorWidget: (context, url, error) =>
                                                    Container(color: Colors.white10),
                                              ),
                                              // Red STUDIO badge on top right
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE50914),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'STUDIO',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      m.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE50914),
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                      if (_studioCompanies.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'PRODUCTION STUDIOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _studioCompanies.map((c) {
                            final logo = c['logo_path'] as String?;
                            final name = (c['name'] ?? '').toString();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16161B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (logo != null && logo.isNotEmpty) ...[
                                    Image.network(
                                      'https://image.tmdb.org/t/p/w200$logo',
                                      height: 16,
                                      fit: BoxFit.contain,
                                      color: Colors.white,
                                      errorBuilder: (context, error, stack) =>
                                          const Icon(Icons.business, size: 14, color: Colors.white70),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildLeftNavDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121217),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFF8B0000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Row(
                  children: [
                    Icon(Icons.movie_filter, color: Colors.white, size: 30),
                    SizedBox(width: 8),
                    Text(
                      'SAGE MOVIES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Quick Navigation Drawer',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<AppVersionInfo?>(
            valueListenable: UpdateService.availableUpdate,
            builder: (context, updateInfo, child) {
              if (updateInfo == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66E50914), blurRadius: 8, spreadRadius: 1),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.system_update_rounded, color: Colors.white),
                  title: Text(
                    'UPDATE ${updateInfo.latestVersion}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text('Tap to install new features', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.download_rounded, color: Color(0xFFE50914), size: 16),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    UpdateService.showUpdateDialog(context, updateInfo);
                  },
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search, color: Colors.white),
            title: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark, color: Colors.white),
            title: const Text('My List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white),
            title: const Text('Downloads', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DownloadsScreen()));
            },
          ),
          const Divider(color: Colors.white12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'STUDIO NETWORKS',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.movie, color: Color(0xFFE50914)),
            title: const Text('Vivamax', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudioMoviesScreen(
                    studioName: 'Vivamax',
                    logoUrl: 'https://image.tmdb.org/t/p/w92/25oYoXHsfWYlddAzJSBReajN3BM.png',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.tv, color: Color(0xFFE50914)),
            title: const Text('Netflix', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudioMoviesScreen(
                    studioName: 'Netflix',
                    logoUrl: 'https://image.tmdb.org/t/p/w92/pbpMk2JmcoNnQwx5JGpXngfoWtp.jpg',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Color(0xFFE50914)),
            title: const Text('Marvel', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudioMoviesScreen(
                    studioName: 'Marvel',
                    logoUrl: 'https://image.tmdb.org/t/p/w92/hUzeosd33nzE5MStB42PioTJw15.png',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SkippableAdDialog extends StatefulWidget {
  final VoidCallback onFinished;
  const _SkippableAdDialog({required this.onFinished});

  @override
  State<_SkippableAdDialog> createState() => _SkippableAdDialogState();
}

class _SkippableAdDialogState extends State<_SkippableAdDialog> {
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = 5; i >= 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSkip = _countdown == 0;

    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE50914), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ADVERTISEMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Text(
                  canSkip ? 'Ad Ready' : 'Skip in $_countdown s',
                  style: TextStyle(
                    color: canSkip ? Colors.greenAccent : Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_sync_rounded,
                    size: 36,
                    color: Color(0xFFE50914),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Supporting Free High-Speed Servers',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We know ads can be a pain, but 5-second ads help maintain fast servers & keep SageMovies 100% FREE for everyone! Thank you for your support ❤️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSkip ? const Color(0xFFE50914) : Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: canSkip ? widget.onFinished : null,
                icon: Icon(
                  canSkip ? Icons.skip_next : Icons.timer,
                  size: 20,
                ),
                label: Text(
                  canSkip ? 'SKIP AD & WATCH MOVIE' : 'SKIP AD IN $_countdown S',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
