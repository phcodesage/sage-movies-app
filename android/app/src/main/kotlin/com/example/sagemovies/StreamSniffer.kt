package com.example.sagemovies

import android.graphics.Bitmap
import android.net.http.SslError
import android.os.Message
import android.util.Log
import android.webkit.ClientCertRequest
import android.webkit.CookieManager
import android.webkit.HttpAuthHandler
import android.webkit.SslErrorHandler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import android.view.KeyEvent

/**
 * Wraps the WebViewClient that webview_flutter_android installs, adding
 * shouldInterceptRequest so we can see the media URLs the embedded player
 * fetches. Everything else is forwarded verbatim to [delegate].
 *
 * Wrapping rather than replacing is mandatory: the plugin's own client drives
 * onPageFinished (autoplay) and shouldOverrideUrlLoading (navigation filtering).
 * Dropping any of these silently breaks playback or fullscreen, so every method
 * the plugin overrides is forwarded below.
 *
 * We never intercept the response body — shouldInterceptRequest always returns
 * null so the WebView performs the request itself as normal.
 */
class SniffingWebViewClient(
    private val delegate: WebViewClient,
    private val onHit: (url: String, headers: Map<String, String>) -> Unit
) : WebViewClient() {

    companion object {
        private const val TAG = "StreamSniffer"
    }

    private val seen = HashSet<String>()

    /** Set once a playlist is found; further plain .mp4 hits are then ignored. */
    private var foundPlaylist = false

    override fun shouldInterceptRequest(
        view: WebView,
        request: WebResourceRequest
    ): WebResourceResponse? {
        try {
            val url = request.url?.toString()
            if (url != null && isMediaUrl(url)) {
                val isPlaylist = pathOf(url).endsWith(".m3u8")
                // A single HLS playback fires hundreds of segment requests; only
                // the playlist and direct progressive files are worth reporting.
                if ((isPlaylist || !foundPlaylist) && seen.add(url)) {
                    if (isPlaylist) foundPlaylist = true
                    val headers = buildHeaders(url, request)
                    Log.d(TAG, "onStreamFound: $url")
                    // shouldInterceptRequest runs off the main thread; MethodChannel
                    // calls must not.
                    view.post { onHit(url, headers) }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "intercept failed: ${e.message}")
        }
        return delegate.shouldInterceptRequest(view, request)
    }

    private fun pathOf(url: String): String {
        val noFragment = url.substringBefore('#')
        return noFragment.substringBefore('?').lowercase()
    }

    private fun isMediaUrl(url: String): Boolean {
        val path = pathOf(url)
        return path.endsWith(".m3u8") || path.endsWith(".mp4")
    }

    private fun buildHeaders(url: String, request: WebResourceRequest): Map<String, String> {
        val headers = HashMap<String, String>()
        try {
            request.requestHeaders?.let { headers.putAll(it) }
        } catch (e: Exception) {
            Log.w(TAG, "requestHeaders unavailable: ${e.message}")
        }
        // Cookies are never present in requestHeaders, and most of these CDNs
        // 403 a replay without them.
        try {
            val cookie = CookieManager.getInstance().getCookie(url)
            if (!cookie.isNullOrEmpty()) headers["Cookie"] = cookie
        } catch (e: Exception) {
            Log.w(TAG, "cookie lookup failed: ${e.message}")
        }
        return headers
    }

    // --- Forwarded verbatim below this line -------------------------------

    override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
        seen.clear()
        foundPlaylist = false
        delegate.onPageStarted(view, url, favicon)
    }

    override fun onPageFinished(view: WebView, url: String) {
        delegate.onPageFinished(view, url)
    }

    override fun onReceivedHttpError(
        view: WebView,
        request: WebResourceRequest,
        errorResponse: WebResourceResponse
    ) {
        delegate.onReceivedHttpError(view, request, errorResponse)
    }

    override fun onReceivedError(
        view: WebView,
        request: WebResourceRequest,
        error: WebResourceError
    ) {
        delegate.onReceivedError(view, request, error)
    }

    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
        return delegate.shouldOverrideUrlLoading(view, request)
    }

    override fun doUpdateVisitedHistory(view: WebView, url: String, isReload: Boolean) {
        delegate.doUpdateVisitedHistory(view, url, isReload)
    }

    override fun onReceivedHttpAuthRequest(
        view: WebView,
        handler: HttpAuthHandler,
        host: String,
        realm: String
    ) {
        delegate.onReceivedHttpAuthRequest(view, handler, host, realm)
    }

    override fun onFormResubmission(view: WebView, dontResend: Message, resend: Message) {
        delegate.onFormResubmission(view, dontResend, resend)
    }

    override fun onLoadResource(view: WebView, url: String) {
        delegate.onLoadResource(view, url)
    }

    override fun onPageCommitVisible(view: WebView, url: String) {
        delegate.onPageCommitVisible(view, url)
    }

    override fun onReceivedClientCertRequest(view: WebView, request: ClientCertRequest) {
        delegate.onReceivedClientCertRequest(view, request)
    }

    override fun onReceivedLoginRequest(
        view: WebView,
        realm: String,
        account: String?,
        args: String
    ) {
        delegate.onReceivedLoginRequest(view, realm, account, args)
    }

    override fun onReceivedSslError(
        view: WebView,
        handler: SslErrorHandler,
        error: SslError
    ) {
        delegate.onReceivedSslError(view, handler, error)
    }

    override fun onScaleChanged(view: WebView, oldScale: Float, newScale: Float) {
        delegate.onScaleChanged(view, oldScale, newScale)
    }

    override fun onUnhandledKeyEvent(view: WebView, event: KeyEvent) {
        delegate.onUnhandledKeyEvent(view, event)
    }
}
