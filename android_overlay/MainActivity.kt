package com.cobrashield.cobra_shield

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cobra/share")
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialText" -> {
                    result.success(pending)
                    pending = null
                }
                else -> result.notImplemented()
            }
        }
        channel = ch

        // النص اللي فتح التطبيق (لو جاي من مشاركة)
        val text = extractText(intent)
        if (text != null) {
            pending = text
            // نمنع إعادة قراءته لو الـ Activity اتعمل لها restore
            intent.action = Intent.ACTION_MAIN
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val text = extractText(intent) ?: return
        intent.action = Intent.ACTION_MAIN
        val ch = channel
        if (ch != null) {
            ch.invokeMethod("onText", text)
        } else {
            pending = text
        }
    }

    private fun extractText(i: Intent?): String? {
        if (i == null) return null
        return when (i.action) {
            Intent.ACTION_SEND ->
                if (i.type?.startsWith("text/") == true) i.getStringExtra(Intent.EXTRA_TEXT) else null
            Intent.ACTION_PROCESS_TEXT ->
                i.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            else -> null
        }
    }
}
