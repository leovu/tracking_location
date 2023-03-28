package com.example.tracking_location

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** TrackingLocationPlugin */
class TrackingLocationPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tracking_location")
    channel.setMethodCallHandler(this)
    TrackingUpdate.context = flutterPluginBinding.applicationContext
  }
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
        "start" -> {
          TrackingUpdate.tracking(true)
          result.success(1)
        }
        "stop" -> {
          TrackingUpdate.tracking(false)
          result.success(0)
        }
        else -> {
          result.notImplemented()
        }
    }
  }
  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
