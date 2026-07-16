import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BoundDeviceChannel") {
      BoundDeviceChannel.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HwBleBridge") {
      HwBleBridge.register(with: registrar)
    }
  }
}

enum BoundDeviceChannel {
  static let name = "sdkdemo/bound_device"
  private static let defaultsKey = "bound_device"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: name,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      let defaults = UserDefaults.standard
      switch call.method {
      case "save":
        let args = call.arguments as? [String: Any]
        let mac = args?["macAddress"] as? String ?? ""
        let name = args?["name"] as? String ?? ""
        let deviceInfoJson = args?["deviceInfoJson"] as? String ?? ""
        defaults.set(
          [
            "macAddress": mac,
            "name": name,
            "deviceInfoJson": deviceInfoJson,
          ],
          forKey: defaultsKey
        )
        result(nil)
      case "load":
        guard let map = defaults.dictionary(forKey: defaultsKey),
              let mac = map["macAddress"] as? String,
              !mac.isEmpty else {
          result(nil)
          return
        }
        result([
          "macAddress": mac,
          "name": map["name"] as? String ?? "",
          "deviceInfoJson": map["deviceInfoJson"] as? String ?? "",
        ])
      case "clear":
        defaults.removeObject(forKey: defaultsKey)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
