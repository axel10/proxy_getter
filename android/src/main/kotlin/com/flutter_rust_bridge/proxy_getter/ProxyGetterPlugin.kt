package com.flutter_rust_bridge.proxy_getter

import android.net.Proxy
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.InetSocketAddress
import java.net.ProxySelector
import java.net.URI

class ProxyGetterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSystemProxy" -> result.success(readSystemProxy())
            else -> result.notImplemented()
        }
    }

    private fun readSystemProxy(): Map<String, Any?> {
        val host = sequenceOf(
            System.getProperty("http.proxyHost"),
            findHostFromProxySelector(),
            Proxy.getDefaultHost(),
        ).firstOrNull { !it.isNullOrBlank() }.orEmpty()

        val port = sequenceOf(
            System.getProperty("http.proxyPort")?.toIntOrNull(),
            findPortFromProxySelector(),
            Proxy.getDefaultPort().takeIf { it > 0 },
        ).firstOrNull { it != null } ?: 0

        val bypass = sequenceOf(
            System.getProperty("http.nonProxyHosts"),
        ).firstOrNull { !it.isNullOrBlank() }.orEmpty()

        val enabled = host.isNotBlank() && port > 0
        return mapOf(
            "enable" to enabled,
            "host" to if (enabled) host else "",
            "port" to if (enabled) port else 0,
            "bypass" to bypass,
        )
    }

    private fun findHostFromProxySelector(): String? {
        val proxy = ProxySelector.getDefault()
            ?.select(URI("http://example.com"))
            ?.firstOrNull { it.type() == java.net.Proxy.Type.HTTP }
            ?.address()

        return (proxy as? InetSocketAddress)?.hostString
    }

    private fun findPortFromProxySelector(): Int? {
        val proxy = ProxySelector.getDefault()
            ?.select(URI("http://example.com"))
            ?.firstOrNull { it.type() == java.net.Proxy.Type.HTTP }
            ?.address()

        return (proxy as? InetSocketAddress)?.port?.takeIf { it > 0 }
    }

    companion object {
        private const val CHANNEL_NAME = "proxy_getter/system_proxy"
    }
}
