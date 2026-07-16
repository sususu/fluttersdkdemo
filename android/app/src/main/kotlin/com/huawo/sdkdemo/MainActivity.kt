package com.huawo.sdkdemo

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        HwBleBridge.register(this, flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "sdkdemo/bound_device",
        ).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences("bound_device", Context.MODE_PRIVATE)
            when (call.method) {
                "save" -> {
                    val mac = call.argument<String>("macAddress") ?: ""
                    val name = call.argument<String>("name") ?: ""
                    val deviceInfoJson = call.argument<String>("deviceInfoJson") ?: ""
                    prefs.edit()
                        .putString("macAddress", mac)
                        .putString("name", name)
                        .putString("deviceInfoJson", deviceInfoJson)
                        .apply()
                    result.success(null)
                }
                "load" -> {
                    val mac = prefs.getString("macAddress", null)
                    if (mac.isNullOrEmpty()) {
                        result.success(null)
                    } else {
                        result.success(
                            mapOf(
                                "macAddress" to mac,
                                "name" to (prefs.getString("name", "") ?: ""),
                                "deviceInfoJson" to
                                    (prefs.getString("deviceInfoJson", "") ?: ""),
                            ),
                        )
                    }
                }
                "clear" -> {
                    prefs.edit().clear().apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
