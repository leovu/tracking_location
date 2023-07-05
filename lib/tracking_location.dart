import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TrackingLocation {
  static MethodChannel channel = const MethodChannel("tracking_location");
  static listen(Function(dynamic) action) {
    channel.setMethodCallHandler((call) async {
      if (call.method == "update_location") {
        if (kDebugMode) print("Get location update");
        action(call.arguments);
      } else {
        if (kDebugMode) print("Method not implemented: ${call.method}");
      }
    });
  }
  static Future<int>start() async {
    final int result = await channel.invokeMethod('start');
    return result;
  }
  static saveOffline(dynamic value) {
    channel.invokeMethod('saveOffline',value);
  }
  static Future<int>stop() async  {
    final int result = await channel.invokeMethod('stop');
    return result;
  }
}
