import Flutter
import UIKit

public class SwiftTrackingLocationPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "tracking_location", binaryMessenger: registrar.messenger())
    LocationUpdate.shared.methodChannel = channel
    let instance = SwiftTrackingLocationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if call.method == "start" {
          LocationUpdate.shared.tracking(action: true)
          result(1)
      }
      else if call.method == "stop" {
          LocationUpdate.shared.tracking(action: false)
          result(0)
      }
      else if call.method == "saveOffline" {
          UserDefaults.standard.set(call.arguments, forKey: "flutter.tracking_offline")
          result(0)
      }
  }
}
