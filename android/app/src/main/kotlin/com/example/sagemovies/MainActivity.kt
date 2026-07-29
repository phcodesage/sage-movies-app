package com.example.sagemovies

import android.app.PictureInPictureParams
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.util.Log
import android.util.Rational
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.webviewflutter.WebViewFlutterAndroidExternalApi
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.sagemovies/installer"
    private val PIP_CHANNEL = "com.example.sagemovies/pip"
    private val SNIFFER_CHANNEL = "com.example.sagemovies/streamsniffer"

    private var pipChannel: MethodChannel? = null
    private var snifferChannel: MethodChannel? = null

    /** WebView ids we have already wrapped, so a re-attach is a no-op. */
    private val sniffedWebViews = HashSet<Long>()

    /** Set from Dart. Gates auto-PiP so backgrounding outside playback stays normal. */
    private var playbackActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    try {
                        val file = File(filePath)
                        val intent = Intent(Intent.ACTION_VIEW)
                        val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            FileProvider.getUriForFile(
                                context,
                                context.packageName + ".fileprovider",
                                file
                            )
                        } else {
                            Uri.fromFile(file)
                        }
                        intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                        context.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_PATH", "File path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
        pipChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPipSupported" -> result.success(isPipSupported())
                "setPlaybackActive" -> {
                    playbackActive = call.arguments as? Boolean ?: false
                    result.success(true)
                }
                "enterPip" -> result.success(enterPipMode())
                else -> result.notImplemented()
            }
        }

        snifferChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SNIFFER_CHANNEL)
        snifferChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                "attachSniffer" -> {
                    val id = (call.argument<Number>("webViewId"))?.toLong()
                    if (id == null) {
                        result.error("INVALID_ID", "webViewId is null", null)
                    } else {
                        result.success(attachSniffer(flutterEngine, id))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Wraps the plugin's WebViewClient so media requests become visible.
     *
     * Requires API 26 for [WebView.getWebViewClient] — without it we cannot read
     * the plugin's client to delegate to, and replacing it outright would break
     * autoplay and navigation filtering.
     */
    private fun attachSniffer(flutterEngine: FlutterEngine, webViewId: Long): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        if (sniffedWebViews.contains(webViewId)) return true

        val webView = WebViewFlutterAndroidExternalApi.getWebView(flutterEngine, webViewId)
            ?: return false

        var attached = false
        runOnUiThread {
            try {
                val original = webView.webViewClient
                if (original is SniffingWebViewClient) {
                    attached = true
                } else {
                    webView.webViewClient = SniffingWebViewClient(original) { url, headers ->
                        snifferChannel?.invokeMethod(
                            "onStreamFound",
                            mapOf("url" to url, "headers" to headers)
                        )
                    }
                    sniffedWebViews.add(webViewId)
                    attached = true
                }
            } catch (e: Exception) {
                Log.w("StreamSniffer", "attach failed: ${e.message}")
            }
        }
        return attached
    }

    private fun isPipSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    private fun enterPipMode(): Boolean {
        if (!isPipSupported()) return false
        return try {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
        } catch (e: Exception) {
            // IllegalStateException when the activity is not resumed (racing a
            // dialog), IllegalArgumentException for a rejected aspect ratio.
            false
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (playbackActive) {
            enterPipMode()
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }
}
