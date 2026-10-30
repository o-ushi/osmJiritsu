package com.osamushikubo.osm_jiritsu

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    /** A link that arrived before Dart asked for it (handed over once). */
    private var pendingUrl: String? = null
    private var dartReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Cold start from an `osmjiritsu://` link (not when restored).
        if (savedInstanceState == null) receive(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.osamushikubo.osmjiritsu/incoming_url",
        ).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeInitialUrl" -> {
                        dartReady = true
                        result.success(pendingUrl)
                        pendingUrl = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    // Already running (launchMode singleTop).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        receive(intent)
    }

    private fun receive(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val url = intent.data ?: return
        if (url.scheme?.lowercase() != "osmjiritsu") return
        val text = url.toString()
        val current = channel
        if (dartReady && current != null) {
            current.invokeMethod("onUrl", text)
        } else {
            pendingUrl = text
        }
    }
}
