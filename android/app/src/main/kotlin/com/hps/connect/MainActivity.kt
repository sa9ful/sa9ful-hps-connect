package com.hps.connect

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // আপডেট ডায়ালগের "ডাউনলোড" বোতাম: নতুন APK-র লিংক ব্রাউজারে খোলে।
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.hps.connect/update")
            .setMethodCallHandler { call, result ->
                if (call.method != "openUrl") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val url = call.argument<String>("url")
                if (url == null || !url.startsWith("https://")) {
                    result.error("bad_url", "https লিংক লাগবে", null)
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                    result.success(null)
                } catch (e: Exception) {
                    result.error("no_browser", e.message, null)
                }
            }
    }
}
