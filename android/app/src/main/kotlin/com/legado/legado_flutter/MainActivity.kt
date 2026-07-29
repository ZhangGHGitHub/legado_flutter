package com.legado.legado_flutter

import android.app.SearchManager
import android.content.Intent
import android.net.Uri
import android.webkit.CookieManager
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "legado_flutter/source_login_cookies"
        ).setMethodCallHandler { call, result ->
            if (call.method != "clearForSource") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val sourceUrl = call.argument<String>("sourceUrl")?.trim().orEmpty()
            val registrableDomain = call.argument<String>("registrableDomain")
                ?.trim()
                ?.trimStart('.')
                ?.lowercase()
                .orEmpty()
            val sourceUri = Uri.parse(sourceUrl)
            val scheme = sourceUri.scheme?.lowercase()
            val sourceHost = sourceUri.host?.lowercase()
            if (
                sourceUrl.isEmpty() ||
                scheme !in setOf("http", "https") ||
                sourceHost.isNullOrEmpty() ||
                registrableDomain.isEmpty() ||
                (sourceHost != registrableDomain && !sourceHost.endsWith(".$registrableDomain"))
            ) {
                result.error(
                    "invalid_arguments",
                    "sourceUrl or registrableDomain is invalid",
                    null
                )
                return@setMethodCallHandler
            }

            val domainAuthority = if (registrableDomain.contains(':')) {
                "[$registrableDomain]"
            } else {
                registrableDomain
            }
            val domainUrl = "$scheme://$domainAuthority/"
            val cookieManager = CookieManager.getInstance()
            val cookieNames = sequenceOf(
                cookieManager.getCookie(sourceUrl),
                cookieManager.getCookie(domainUrl)
            ).filterNotNull()
                .flatMap { cookies -> cookies.split(';').asSequence() }
                .mapNotNull { cookie ->
                    cookie.substringBefore('=').trim().takeIf { it.isNotEmpty() }
                }
                .toSet()

            cookieNames.forEach { name ->
                val expired =
                    "$name=; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Path=/"
                cookieManager.setCookie(sourceUrl, expired)
                cookieManager.setCookie(
                    domainUrl,
                    "$expired; Domain=$registrableDomain"
                )
            }
            cookieManager.flush()
            result.success(null)
        }
    }
}
