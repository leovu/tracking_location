import 'package:flutter/services.dart';

class TrackingLocation {
  static MethodChannel channel = const MethodChannel("tracking_location");
  listen() {
    channel.setMethodCallHandler((call) async {
      if (call.method == "update_location") {
        print(call.arguments);
      } else {
        print("Method not implemented: ${call.method}");
      }
    });
  }
  Future<int>start() async {
    final int result = await channel.invokeMethod('start');
    return result;
  }
  Future<int>stop() async  {
    final int result = await channel.invokeMethod('stop');
    return result;
  }
}
