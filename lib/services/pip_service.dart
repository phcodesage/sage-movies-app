import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android picture-in-picture.
///
/// PiP captures the whole activity surface, so the WebView keeps rendering and
/// audio keeps playing — which is exactly what we want for an embedded player we
/// cannot control directly.
///
/// Android only. iOS PiP cannot be driven for a cross-origin WKWebView embed, so
/// every call here degrades to a safe no-op off Android.
class PipService {
  PipService._();

  static const MethodChannel _channel = MethodChannel('com.example.sagemovies/pip');

  static bool _handlerAttached = false;
  static void Function(bool inPip)? _modeListener;

  /// False on anything below API 26 and on devices without the PiP feature.
  static Future<bool> isSupported() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('isPipSupported') ?? false;
    } catch (e) {
      debugPrint('[PipService] isSupported failed: $e');
      return false;
    }
  }

  /// Tells the activity whether auto-PiP on home-press should happen.
  /// Must be cleared when playback stops or the app will PiP unexpectedly.
  static Future<void> setPlaybackActive(bool active) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<bool>('setPlaybackActive', active);
    } catch (e) {
      debugPrint('[PipService] setPlaybackActive failed: $e');
    }
  }

  static Future<bool> enter() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('enterPip') ?? false;
    } catch (e) {
      debugPrint('[PipService] enter failed: $e');
      return false;
    }
  }

  /// Notified when the activity enters or leaves PiP, so the UI can hide chrome.
  static void setModeListener(void Function(bool inPip)? listener) {
    _modeListener = listener;
    if (_handlerAttached) return;
    _handlerAttached = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPipModeChanged') {
        _modeListener?.call(call.arguments == true);
      }
      return null;
    });
  }
}
