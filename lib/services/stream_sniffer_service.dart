import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// A media URL observed being fetched by the embedded player, with the headers
/// the WebView sent alongside it.
class StreamHit {
  final String url;
  final Map<String, String> headers;

  const StreamHit({required this.url, required this.headers});

  bool get isPlaylist => _path.endsWith('.m3u8');
  bool get isProgressive => _path.endsWith('.mp4');

  String get _path {
    final noFragment = url.split('#').first;
    return noFragment.split('?').first.toLowerCase();
  }
}

/// Observes the media requests the third-party embed makes, so a download can
/// replay them.
///
/// JS injection cannot do this: `runJavaScript` only reaches the main frame,
/// while the player lives in a cross-origin iframe where `frames[i].document`
/// throws SecurityError. The interception happens natively instead, in
/// `shouldInterceptRequest`, which sees every frame.
///
/// Android API 26+ only — wrapping the plugin's WebViewClient needs
/// `WebView.getWebViewClient()`.
class StreamSnifferService {
  StreamSnifferService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.sagemovies/streamsniffer');

  static bool _handlerAttached = false;

  /// Latest hit for the page currently loaded. Cleared by [reset].
  static final ValueNotifier<StreamHit?> lastHit = ValueNotifier<StreamHit?>(null);

  static Future<bool> isSupported() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (e) {
      debugPrint('[StreamSniffer] isSupported failed: $e');
      return false;
    }
  }

  /// Clear the last hit — call when switching title, server, or episode.
  static void reset() => lastHit.value = null;

  /// Wrap the native WebViewClient behind [controller].
  ///
  /// Must be called after the WebViewWidget is mounted, so the plugin's own
  /// client is already installed and available to delegate to.
  static Future<bool> attach(WebViewController controller) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;

    final platform = controller.platform;
    if (platform is! AndroidWebViewController) return false;

    _attachHandler();

    try {
      final id = platform.webViewIdentifier;
      return await _channel.invokeMethod<bool>('attachSniffer', {'webViewId': id}) ?? false;
    } catch (e) {
      debugPrint('[StreamSniffer] attach failed: $e');
      return false;
    }
  }

  static void _attachHandler() {
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onStreamFound') return null;
      try {
        final args = (call.arguments as Map).cast<dynamic, dynamic>();
        final url = args['url'] as String?;
        if (url == null || url.isEmpty) return null;

        final rawHeaders = args['headers'] as Map?;
        final headers = <String, String>{};
        rawHeaders?.forEach((k, v) {
          if (k is String && v is String) headers[k] = v;
        });

        final hit = StreamHit(url: url, headers: headers);
        // A playlist beats a progressive file: it carries the quality variants,
        // and an .mp4 seen alongside HLS is usually an ad or a preview clip.
        final current = lastHit.value;
        if (current == null || (hit.isPlaylist && !current.isPlaylist)) {
          lastHit.value = hit;
        }
      } catch (e) {
        debugPrint('[StreamSniffer] bad onStreamFound payload: $e');
      }
      return null;
    });
  }
}
