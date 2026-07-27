import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:sagemovies/app_state.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/player_screen.dart';
import 'package:sagemovies/services/api_service.dart';

class DetailsScreen extends StatefulWidget {
  final Movie movie;
  const DetailsScreen({super.key, required this.movie});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late final WebViewController _controller;
  bool _isPlaying = false;
  bool _isLoadingPlayer = false;
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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setUserAgent('Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36')
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
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
    }

    _loadStudioAndDetails();
  }

  String? _studioLogoPath;
  List<Map<String, dynamic>> _studioCompanies = [];

  Future<void> _loadStudioAndDetails() async {
    final type = (widget.movie.mediaType == 'tv') ? 'tv' : 'movie';
    final data = await ApiService.fetchFullDetails(type, widget.movie.id);

    if (data != null && data['production_companies'] != null) {
      final companies = data['production_companies'] as List;
      if (companies.isNotEmpty) {
        final company = companies.first;
        final name = (company['name'] ?? '').toString().toUpperCase();
        final studioId = company['id'] as int?;
        final logoPath = company['logo_path'] as String?;

        if (mounted) {
          setState(() {
            _studioName = name.isNotEmpty ? name : _studioName;
            _studioLogoPath = logoPath;
            _studioCompanies = companies.map((c) => Map<String, dynamic>.from(c)).toList();
          });
        }

        if (studioId != null) {
          final studioResults = await ApiService.fetchMoviesByStudio(studioId);
          if (mounted) {
            setState(() {
              _studioMovies = studioResults.where((m) => m.id != widget.movie.id).toList();
            });
          }
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
    final type = (widget.movie.mediaType == 'tv') ? 'tv' : 'movie';
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
        url = 'https://vidsrc.me/embed/$type?tmdb=$idNum&ds_lang=$_lang';
      } else if (_server == 'superembed') {
        url = 'https://multiembed.mov/?video_id=$idNum&tmdb=1';
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
      backgroundColor: const Color(0xFF0F0F11),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Player / Backdrop Area
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
                                Image.network(
                                  widget.movie.backdropUrl.isNotEmpty
                                      ? widget.movie.backdropUrl
                                      : widget.movie.posterUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
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
                                    onTap: _startWatching,
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

                  // Back Button
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),

              // Native Player Action Control Bar (Pause, -10s, +10s, Fullscreen)
              if (_isPlaying)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        icon: const Icon(Icons.replay_10, size: 20),
                        label: const Text('-10s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE50914),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: _togglePlayPause,
                        icon: const Icon(Icons.pause, size: 20),
                        label: const Text('PAUSE / PLAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white12,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => _seekVideo(10),
                        icon: const Icon(Icons.forward_10, size: 20),
                        label: const Text('+10s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        tooltip: 'Fullscreen Player',
                        icon: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(movie: widget.movie),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Meta Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact Poster
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 76,
                            height: 110,
                            child: Image.network(
                              widget.movie.posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.movie.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    year,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE50914),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      widget.movie.mediaType == 'tv' ? 'TV SERIES' : 'MOVIE',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'HD / 4K',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (_studioName.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE50914).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: const Color(0xFFE50914).withOpacity(0.5),
                                          width: 1,
                                        ),
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
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // STREAMING SERVER Card
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
                                items: _servers.entries
                                    .map((e) => DropdownMenuItem<String>(
                                          value: e.key,
                                          child: Text(e.value),
                                        ))
                                    .toList(),
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

                          const SizedBox(height: 6),
                          const Text(
                            'This server ignores the language setting — pick Vidsrc.me to preselect subtitles. Audio tracks are chosen inside the player.',
                            style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.3),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _startWatching,
                              child: Text(
                                _isPlaying ? 'REFRESH STREAM' : 'START WATCHING',
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
                            onPressed: () => app.toggleMyList(widget.movie),
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
                                              Image.network(
                                                m.posterUrl,
                                                fit: BoxFit.cover,
                                                cacheWidth: 300,
                                                errorBuilder: (context, error, stack) =>
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
