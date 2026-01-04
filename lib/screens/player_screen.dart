import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  String _server = 'vidsrc.cc';
  bool _loading = true;
  String? _error;

  static const _servers = <String, String>{
    'vidsrc.cc': 'VidSrc.cc',
    'vidsrc.me': 'VidSrc.me',
    'vidsrc.pro': 'VidSrc.pro',
    'embedsu': 'Embed.su',
    '2embed': '2Embed',
    'moviesapi': 'MoviesAPI',
    'superembed': 'SuperEmbed',
    'player.videasy.net': 'Videasy',
  };

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setUserAgent('Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36')
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('[Player] Page started: $url');
            setState(() => _loading = true);
          },
          onPageFinished: (url) {
            print('[Player] Page finished: $url');
            setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            print('[Player] Web resource error: ${err.description} (${err.errorCode})');
            // Only show error for main frame errors, not subresource errors
            if (err.errorType == WebResourceErrorType.hostLookup ||
                err.errorType == WebResourceErrorType.timeout ||
                err.errorType == WebResourceErrorType.connect) {
              setState(() {
                _error = 'Connection error: ${err.description}';
                _loading = false;
              });
            }
          },
          onHttpError: (err) {
            print('[Player] HTTP error: ${err.response?.statusCode}');
          },
          onNavigationRequest: (req) {
            print('[Player] Navigation request: ${req.url}');
            // Expanded list of allowed hosts for video sources
            final allowHosts = <String>{
              // VidSrc variants
              'vidsrc.cc', 'vidsrc.net', 'vidsrc.pro', 'vidsrc.me', 'vidsrc.xyz',
              'vidsrc.in', 'vidsrc.to', 'vidsrc.pm',
              // Embed services
              'embed.su', 'embedsu.net', '2embed.cc', '2embed.org', '2embed.to',
              'moviesapi.club', 'multiembed.mov', 'superembed.stream',
              'player.videasy.net', 'videasy.net',
              // CDN and streaming domains
              'vidplay.online', 'vidplay.site', 'vidstream.pro',
              'upstream.to', 'mixdrop.co', 'doodstream.com',
              // Allow localhost for development
              'localhost', '127.0.0.1',
            };
            try {
              final uri = Uri.parse(req.url);
              final host = uri.host.toLowerCase();
              
              // Check if host is in allowlist (including subdomains)
              bool allowed = allowHosts.any((h) => 
                host == h || 
                host.endsWith('.$h') || 
                host == 'www.$h'
              );
              
              if (allowed) {
                print('[Player] Allowing navigation to: $host');
                return NavigationDecision.navigate;
              } else {
                print('[Player] Blocking navigation to: $host');
              }
            } catch (e) {
              print('[Player] Error parsing URL: $e');
            }
            return NavigationDecision.prevent;
          },
        ),
      );
    _loadServer();
  }

  Future<void> _loadServer() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final type = (widget.movie.mediaType == 'tv') ? 'tv' : 'movie';
    print('[Player] Loading video: type=$type, id=${widget.movie.id}, server=$_server');
    
    final url = await ApiService.getVideoSource(type, widget.movie.id, server: _server);
    if (!mounted) return;
    
    if (url == null || url.isEmpty) {
      print('[Player] ERROR: No URL returned from API for id=${widget.movie.id}');
      setState(() {
        _error = 'Failed to get video source for this content. Try a different server.';
        _loading = false;
      });
      return;
    }
    
    print('[Player] Got video URL: $url');
    _currentUrl = url;
    
    // Load the embed HTML
    final html = _buildEmbedHtml(url);
    await _controller.loadHtmlString(html, baseUrl: ApiService.baseUrl);
    setState(() {
      _loading = false;
    });
  }

  String _buildEmbedHtml(String url) {
    // Build a minimal page with iframe and fullscreen support
    // Note: Removed overly restrictive sandbox to allow video sources to work properly
    return '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0" />
    <style>
      html, body { margin:0; padding:0; background:#000; height:100%; overflow:hidden; }
      .wrap { position:fixed; inset:0; background:#000; }
      iframe { width:100%; height:100%; border:0; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <iframe 
        src="$url" 
        allow="autoplay; fullscreen; encrypted-media; picture-in-picture; accelerometer; gyroscope"
        allowfullscreen
        frameborder="0"
        scrolling="no">
      </iframe>
    </div>
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.movie.title),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _server,
              dropdownColor: const Color(0xFF121212),
              iconEnabledColor: Colors.white,
              items: _servers.entries
                  .map((e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _server = v);
                _loadServer();
              },
            ),
          ),
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: _loadServer,
          ),
          if (_currentUrl != null)
            IconButton(
              tooltip: 'Open externally',
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                // Open in the platform browser as a fallback
                // Using Navigator to push a new simple WebView without sandbox
                final url = _currentUrl!;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) {
                      final ctrl = WebViewController()
                        ..setJavaScriptMode(JavaScriptMode.unrestricted)
                        ..loadRequest(Uri.parse(url));
                      return Scaffold(
                        appBar: AppBar(title: const Text('External Player')),
                        body: WebViewWidget(controller: ctrl),
                      );
                    },
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          if (_currentUrl != null && _error == null)
            WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_error != null && !_loading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadServer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
