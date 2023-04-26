import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

class TrackingLocation {
  static MethodChannel channel = const MethodChannel("tracking_location");
  static Function(dynamic)? updateOfflineFunction;
  static listen(Function(dynamic) action) {
    channel.setMethodCallHandler((call) async {
      if (call.method == "update_location") {
        if (kDebugMode) print("Get location update");
        action(call.arguments);
      }
      else if (call.method == "update_location_offline") {
        if (kDebugMode) print("Get location update offline");
        action(call.arguments);
      }
      else {
        if (kDebugMode) print("Method not implemented: ${call.method}");
      }
    });
  }
  static Future<int>start() async {
    final int result = await channel.invokeMethod('start');
    if(Platform.isIOS){
      await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: true
      );
      await Workmanager().registerOneOffTask('task-identifier', 'simpleTask');
    }
    return result;
  }
  static saveOffline(dynamic value) {
    channel.invokeMethod('saveOffline',value);
  }
  static Future<int>stop() async  {
    final int result = await channel.invokeMethod('stop');
    return result;
  }
  @pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) {
      MethodChannel channelOffline = const MethodChannel("tracking_location");
      channelOffline.setMethodCallHandler((call) async {
        if (call.method == "update_location_offline") {
          if (kDebugMode) print("Get location update offline");
          if(updateOfflineFunction != null) {
            updateOfflineFunction!(call.arguments);
          }
          if (kDebugMode) print("Method not implemented: updateOfflineFunction");
        }
        else {
          if (kDebugMode) print("Method not implemented: ${call.method}");
        }
      });
      return Future.value(true);
    });
  }
}
