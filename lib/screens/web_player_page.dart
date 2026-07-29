import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class WebPlayerPage extends StatefulWidget {
  final String title;
  final String url; // e.g. https://vidsrc.cc/v2/embed/movie/1197137
  const WebPlayerPage({super.key, required this.title, required this.url});

  @override
  State<WebPlayerPage> createState() => _WebPlayerPageState();
}

String _embedHtml(String src) => '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="initial-scale=1, maximum-scale=1, user-scalable=no, width=device-width">
    <style>
      html, body { margin:0; padding:0; height:100%; background:#000; }
      iframe { border:0; position:fixed; top:0; left:0; width:100%; height:100%; }
    </style>
  </head>
  <body>
    <iframe src="$src" allow="autoplay; encrypted-media; picture-in-picture; fullscreen; clipboard-write; gyroscope; accelerometer" allowfullscreen></iframe>
  </body>
</html>
''';

class _WebPlayerPageState extends State<WebPlayerPage> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();

    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction:
            const {PlaybackMediaTypes.audio, PlaybackMediaTypes.video},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() => _progress = 0),
          onPageFinished: (_) => setState(() => _progress = 100),
          onNavigationRequest: (request) {
            // Always allow in-place navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125 Safari/537.36')
      ..enableZoom(false)
..loadRequest(
        Uri.parse(widget.url),
        headers: <String, String>{
          'Referer': 'https://sagemovies.netlify.app/',
          'Origin': 'https://sagemovies.netlify.app',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );
    debugPrint('WebPlayer load: url=${widget.url}');

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(kDebugMode);
      final awv = (controller.platform as AndroidWebViewController);
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

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              // Fallback: open in external browser
              final uri = Uri.parse(widget.url);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            tooltip: 'Open in browser',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          if (_progress < 100)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 18, bottom: 18),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _progress == 0 ? null : _progress / 100,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
