package com.legado.legado_flutter

import android.app.SearchManager
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "legado_flutter/system"
        ).setMethodCallHandler { call, result ->
            if (call.method != "webSearch") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val query = call.argument<String>("query")?.trim().orEmpty()
            if (query.isEmpty()) {
                result.success(false)
                return@setMethodCallHandler
            }
            runCatching {
                startActivity(
                    Intent(Intent.ACTION_WEB_SEARCH).apply {
                        putExtra(SearchManager.QUERY, query)
                    }
                )
            }.onSuccess {
                result.success(true)
            }.onFailure {
                result.success(false)
            }
        }
    }
}
