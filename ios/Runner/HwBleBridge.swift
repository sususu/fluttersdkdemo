import Flutter
import UIKit
import HwBluetoothSDK

enum HwBleBridge {
  private static let impl = HwBleBridgeImpl()

  static func register(with registrar: FlutterPluginRegistrar) {
    impl.register(with: registrar)
  }
}

private final class HwBleBridgeImpl: NSObject {
  private var methodChannel: FlutterMethodChannel?
  private var scanEventSink: FlutterEventSink?
  private var connectionEventSink: FlutterEventSink?
  private var initialized = false
  private var connectionCallbackRegistered = false
  private var lastScanDevices: [HwBluetoothDevice] = []
  private var seenScanKeys: Set<String> = []

  func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "sdkdemo/hw_ble",
      binaryMessenger: registrar.messenger()
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    self.methodChannel = methodChannel

    let scanChannel = FlutterEventChannel(
      name: "sdkdemo/hw_ble/scan",
      binaryMessenger: registrar.messenger()
    )
    scanChannel.setStreamHandler(ScanStreamHandler(bridge: self))

    let connectionChannel = FlutterEventChannel(
      name: "sdkdemo/hw_ble/connection",
      binaryMessenger: registrar.messenger()
    )
    connectionChannel.setStreamHandler(ConnectionStreamHandler(bridge: self))
  }

  private var sdk: HwBluetoothSDK { HwBluetoothSDK.sharedInstance() }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "init":
      let args = call.arguments as? [String: Any]
      _ = args?["maxMtu"]
      if !initialized {
        sdk.initSDK()
        initialized = true
        registerConnectionCallback()
      }
      result(nil)
    case "destroy":
      if initialized {
        sdk.destroy()
        initialized = false
        connectionCallbackRegistered = false
      }
      result(nil)
    case "getVersion":
      result(sdk.version())
    case "stopScan":
      sdk.stopScan()
      result(nil)
    case "connect":
      handleConnect(call: call, result: result)
    case "disconnect":
      sdk.disconnect { [weak self] error in
        guard let self = self else { return }
        if let error = error {
          result(self.flutterError(error))
        } else {
          self.emitConnectionEvent(connected: false)
          result(nil)
        }
      }
    case "isConnected":
      result(sdk.connected())
    case "startBind":
      sdk.startBindDevice { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "startSifliBind":
      sdk.startBindSifliDevice { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "startQRCodeBind":
      sdk.startQRBindDevice { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "endBind":
      sdk.endBindDevice { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "setBind":
      result(nil)
    case "isBind":
      sdk.getBindState { bindState, error in
        if let error = error {
          result(self.flutterError(error))
        } else {
          result(bindState.rawValue == HwBindState.done.rawValue)
        }
      }
    case "isBonded":
      result(false)
    case "createBond", "removeBond":
      result(nil)
    case "getPairState":
      sdk.getPairState { paired, error in
        if let error = error {
          result(self.flutterError(error))
        } else {
          result(paired)
        }
      }
    case "requestDeviceToPair":
      sdk.requestDeviceToPair { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "getBtConnectionState":
      sdk.getBtConnectionState { connected, error in
        if let error = error {
          result(self.flutterError(error))
        } else {
          result(connected)
        }
      }
    case "setBtSwitchWithAutoConnect":
      let args = call.arguments as? [String: Any] ?? [:]
      let on = args["on"] as? Bool ?? false
      let autoConnect = args["autoConnect"] as? Bool ?? false
      sdk.setBtSwitch(on, autoConnect: autoConnect) { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "unbindDevice":
      sdk.unbindDevice { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "removeConnectionCache":
      sdk.removeConnectionCache()
      result(nil)
    case "setDeviceTime":
      handleSetDeviceTime(call: call, result: result)
    case "setUserInfo":
      handleSetUserInfo(call: call, result: result)
    case "setUnit":
      let unitValue = (call.arguments as? [String: Any])?["unit"] as? Int ?? 0
      let unit = HwUnit(rawValue: unitValue) ?? .metric
      sdk.setUnit(unit) { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "setLanguage":
      let args = call.arguments as? [String: Any] ?? [:]
      let languageCode = args["language"] as? Int ?? args["languageCode"] as? Int ?? 0
      let language = HwLanguage(rawValue: languageCode) ?? .english
      sdk.setLanguage(language) { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "getDeviceInfo":
      sdk.getDeviceInfo { info, error in
        if let error = error {
          result(self.flutterError(error))
        } else if let info = info {
          result(self.deviceInfoMap(info))
        } else {
          result([String: Any]())
        }
      }
    case "getBindState":
      sdk.getBindState { bindState, error in
        if let error = error {
          result(self.flutterError(error))
        } else {
          result(bindState.rawValue)
        }
      }
    case "getHealthDataCount":
      sdk.getHealthDataCount { activityCount, sleepPointCount, heartrateCount, hrfCount, error in
        if let error = error {
          result(self.flutterError(error))
        } else {
          result([
            "activityCount": activityCount,
            "sleepCount": sleepPointCount,
            "heartrateCount": heartrateCount,
            "hrfCount": hrfCount,
          ])
        }
      }
    case "getActivities":
      let count = (call.arguments as? [String: Any])?["activityCount"] as? Int ?? 0
      if count <= 0 {
        result([])
        break
      }
      sdk.getActivities(UInt(count)) { activities, error in
        if let error = error {
          result(self.flutterError(error))
        } else {
          result((activities ?? []).map { self.activityMap($0) })
        }
      }
    case "deleteSports":
      sdk.deleteActivities { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "getHeartrates":
      handleGetHeartrates(result: result)
    case "deleteHeartrates":
      sdk.deleteHeartrates { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    case "getSleeps":
      handleGetSleeps(result: result)
    case "deleteSleeps":
      sdk.deleteSleeps { success, error in
        self.boolResult(success: success, error: error, result: result)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  fileprivate func setScanEventSink(_ sink: FlutterEventSink?) {
    scanEventSink = sink
  }

  fileprivate func setConnectionEventSink(_ sink: FlutterEventSink?) {
    connectionEventSink = sink
    if sink != nil {
      registerConnectionCallback()
      emitConnectionEvent(connected: sdk.connected())
    }
  }

  fileprivate func startScan(timeoutMs: Int) {
    guard initialized else {
      scanEventSink?(FlutterError(
        code: "NOT_INITIALIZED", message: "Call init() first", details: nil))
      return
    }
    let seconds = Double(timeoutMs) / 1000.0
    lastScanDevices = []
    seenScanKeys = []
    scanEventSink?(["event": "scanStarted", "success": true])

    sdk.scan(
      callback: { [weak self] devices, error in
        guard let self = self else { return }
        if let error = error {
          self.scanEventSink?(self.flutterError(error))
          return
        }
        guard let devices = devices else { return }
        self.lastScanDevices = devices
        for device in devices {
          let key = device.macAddress ?? device.uuid ?? device.name ?? UUID().uuidString
          if self.seenScanKeys.contains(key) { continue }
          self.seenScanKeys.insert(key)
          self.scanEventSink?([
            "event": "scanResult",
            "device": self.deviceMap(device),
          ])
        }
      },
      stopAfter: seconds,
      stopCallback: { [weak self] in
        guard let self = self else { return }
        let deviceMaps = self.lastScanDevices.map { self.deviceMap($0) }
        self.scanEventSink?([
          "event": "scanFinished",
          "devices": deviceMaps,
        ])
        self.scanEventSink?(FlutterEndOfEventStream)
        self.scanEventSink = nil
      }
    )
  }

  private func registerConnectionCallback() {
    guard !connectionCallbackRegistered else { return }
    sdk.addBluetoothConnectionStateChangedCallback { [weak self] _ in
      guard let self = self else { return }
      self.emitConnectionEvent(connected: self.sdk.connected())
    }
    connectionCallbackRegistered = true
  }

  private func emitConnectionEvent(connected: Bool) {
    guard let sink = connectionEventSink else { return }
    var payload: [String: Any] = [
      "event": connected ? "connected" : "disconnected",
    ]
    if connected, let device = sdk.connectedDevice() {
      if let name = device.name { payload["deviceName"] = name }
      if let mac = device.macAddress { payload["macAddress"] = mac }
    }
    DispatchQueue.main.async { sink(payload) }
  }

  private func handleConnect(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let mac = args["macAddress"] as? String
    let bleName = args["bleName"] as? String
    let timeout = args["timeoutSeconds"] as? Int ?? 30
    let callback: HwConnectCallback = { [weak self] error in
      guard let self = self else { return }
      if let error = error {
        result(self.flutterError(error))
      } else {
        self.emitConnectionEvent(connected: true)
        if let device = self.sdk.connectedDevice() {
          result(self.deviceMap(device))
        } else if let mac = mac, !mac.isEmpty {
          result(["macAddress": mac, "name": bleName as Any])
        } else {
          result(["name": bleName as Any])
        }
      }
    }
    if let mac = mac, !mac.isEmpty {
      sdk.connect(withMac: mac, timeout: timeout, callback: callback)
    } else if let bleName = bleName, !bleName.isEmpty {
      sdk.connect(withBleName: bleName, timeout: timeout, callback: callback)
    } else {
      result(FlutterError(
        code: "INVALID_ARGS", message: "macAddress or bleName required", details: nil))
    }
  }

  private func handleSetUserInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let map = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
      return
    }
    let userInfo = HwUserInfo()
    userInfo.id = (map["id"] as? String) ?? ""
    userInfo.gender = HwSex(rawValue: map["gender"] as? Int ?? 0) ?? .male
    userInfo.age = map["age"] as? Int ?? 0
    userInfo.height = map["height"] as? Int ?? 0
    userInfo.weight = map["weight"] as? Int ?? 0
    if let year = map["birthdayYear"] as? Int { userInfo.birthdayYear = year }
    if let month = map["birthdayMonth"] as? Int { userInfo.birthdayMonth = month }
    if let day = map["birthdayDay"] as? Int { userInfo.birthdayDay = day }
    sdk.setUserInfo(userInfo) { success, error in
      self.boolResult(success: success, error: error, result: result)
    }
  }

  private func handleSetDeviceTime(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let map = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
      return
    }
    let timeMs: Double
    if let ms = map["timeMs"] as? Int64 {
      timeMs = Double(ms)
    } else if let ms = map["timeMs"] as? Int {
      timeMs = Double(ms)
    } else {
      result(FlutterError(code: "INVALID_ARGS", message: "timeMs required", details: nil))
      return
    }
    let use24 = (map["use24HourFormat"] as? Int ?? 1) != 0
    let date = Date(timeIntervalSince1970: timeMs / 1000.0)
    sdk.setDeviceTime(date, is24H: use24) { success, error in
      self.boolResult(success: success, error: error, result: result)
    }
  }

  private func handleGetHeartrates(result: @escaping FlutterResult) {
    sdk.getHealthDataCount { [weak self] _, _, heartrateCount, _, error in
      guard let self = self else { return }
      if let error = error {
        result(self.flutterError(error))
        return
      }
      if heartrateCount <= 0 {
        result([])
        return
      }
      self.sdk.getHeartrates(UInt(heartrateCount)) { heartRates, error in
        if let error = error {
          result(self.flutterError(error))
        } else {
          result((heartRates ?? []).map { self.heartrateMap($0) })
        }
      }
    }
  }

  private func handleGetSleeps(result: @escaping FlutterResult) {
    sdk.getHealthDataCount { [weak self] _, sleepPointCount, _, _, error in
      guard let self = self else { return }
      if let error = error {
        result(self.flutterError(error))
        return
      }
      if sleepPointCount <= 0 {
        result([])
        return
      }
      self.sdk.getSleeps(UInt(sleepPointCount)) { sleeps, error in
        if let error = error {
          result(self.flutterError(error))
        } else {
          result((sleeps ?? []).enumerated().map { self.sleepSummaryMap($0.offset, $0.element) })
        }
      }
    }
  }

  private func boolResult(success: Bool, error: (any Error)?, result: @escaping FlutterResult) {
    if let error = error {
      result(flutterError(error))
    } else if success {
      result(nil)
    } else {
      result(FlutterError(code: "-1", message: "operation failed", details: nil))
    }
  }

  private func flutterError(_ error: any Error) -> FlutterError {
    let nsError = error as NSError
    return FlutterError(code: "\(nsError.code)", message: nsError.localizedDescription, details: nil)
  }

  private func deviceMap(_ device: HwBluetoothDevice) -> [String: Any] {
    var map: [String: Any] = [
      "name": device.name as Any,
      "macAddress": device.macAddress ?? "",
    ]
    if let rssi = device.rssi { map["rssi"] = rssi.intValue }
    if let uuid = device.uuid { map["uuid"] = uuid }
    return map
  }

  private func deviceInfoMap(_ info: HwDeviceInfo) -> [String: Any] {
    var map: [String: Any] = [
      "id": info.id as Any,
      "type": info.type as Any,
      "firmwareVersion": info.firmwareVersion as Any,
      "mac": info.mac as Any,
      "bindState": info.bindState.rawValue,
      "language": info.language.rawValue,
      "battery": info.battery,
      "displayingWatchfaceId": info.displayingWatchfaceId as Any,
      "watchfaceVersion": info.watchfaceVersion,
      "protocolVersion": info.protocolVersion,
      "mapUuid": info.mapUUID as Any,
      "mapAuthorized": info.mapAuthorized,
      "features": [UInt8](info.features).map { Int($0) },
    ]
    if let langs = info.supportedLanguages as? [NSNumber] {
      map["supportedLanguages"] = langs.map { $0.intValue }
    }
    return map
  }

  private func activityMap(_ activity: HwActivity) -> [String: Any] {
    [
      "index": activity.index,
      "timeMs": Int(activity.time * 1000),
      "step": activity.step,
      "calorie": activity.calorie,
      "staticCalorie": activity.staticCalorie,
      "distance": activity.distance,
      "duration": activity.duration,
      "avgBpm": activity.avgBpm,
    ]
  }

  private func heartrateMap(_ hr: HwHeartRate) -> [String: Any] {
    [
      "index": hr.index,
      "timeMs": Int(hr.time * 1000),
      "bpm": hr.bmp,
    ]
  }

  private func sleepSummaryMap(_ index: Int, _ sleep: HwSleep) -> [String: Any] {
    [
      "index": index,
      "timeMs": Int(sleep.startTime),
      "deep": sleep.deepDuration,
      "light": sleep.lightDuration,
      "awake": sleep.awakeDuration,
      "rem": sleep.remDuration,
    ]
  }
}

private final class ScanStreamHandler: NSObject, FlutterStreamHandler {
  private weak var bridge: HwBleBridgeImpl?

  init(bridge: HwBleBridgeImpl) {
    self.bridge = bridge
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    bridge?.setScanEventSink(events)
    let timeoutMs = (arguments as? [String: Any])?["timeoutMs"] as? Int ?? 8000
    bridge?.startScan(timeoutMs: timeoutMs)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    HwBluetoothSDK.sharedInstance().stopScan()
    bridge?.setScanEventSink(nil)
    return nil
  }
}

private final class ConnectionStreamHandler: NSObject, FlutterStreamHandler {
  private weak var bridge: HwBleBridgeImpl?

  init(bridge: HwBleBridgeImpl) {
    self.bridge = bridge
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    bridge?.setConnectionEventSink(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    bridge?.setConnectionEventSink(nil)
    return nil
  }
}
