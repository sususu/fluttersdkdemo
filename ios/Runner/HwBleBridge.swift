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
  private let fileTransfer = SifliTransferBridge()
  private let ota = OtaBridge()
  private let aiWatchface = AiWatchfaceBridge()
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
    fileTransfer.register(with: registrar)
    ota.register(with: registrar)
    aiWatchface.register(with: registrar)

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
    if call.method == "stopAiWatchface" { aiWatchface.stop(); result(nil); return }
    if aiWatchface.busy && !["isConnected", "disconnect", "destroy"].contains(call.method) {
      result(FlutterError(code: "BUSY", message: "请先停止 AI 监听", details: nil)); return
    }
    if ota.busy && !["cancelOta", "isConnected", "disconnect", "destroy"].contains(call.method) {
      result(FlutterError(code: "BUSY", message: "请先完成或取消 OTA 操作", details: nil)); return
    }
    if fileTransfer.busy && !["cancelMusicTransfer", "cancelAlbumTransfer", "cancelAgpsUpdate", "cancelWatchfaceTransfer", "isConnected", "disconnect", "destroy"].contains(call.method) {
      result(FlutterError(code: "BUSY", message: "请先完成或取消文件推送", details: nil))
      return
    }
    switch call.method {
    case "startAiWatchface":
      guard !jlHealthBusy, !notificationContactsBusy else {
        result(FlutterError(code: "BUSY", message: "请等待设备操作完成", details: nil)); return
      }
      aiWatchface.start(call.arguments as? [String: Any] ?? [:], result: result)
    case "refreshOtaInfo", "checkOta", "startOta", "cancelOta":
      guard !jlHealthBusy, !notificationContactsBusy else {
        result(FlutterError(code: "BUSY", message: "请等待设备操作完成", details: nil)); return
      }
      ota.handle(call, result: result)
    case "getMusicStorage", "pickMusicFiles", "pushMusicSifli", "cancelMusicTransfer",
         "getAlbumFileIds", "pickAlbumImages", "pushAlbumSifli", "cancelAlbumTransfer", "getDeviceGpsStatus", "updateAgps", "cancelAgpsUpdate",
         "getOnlineWatchfaces", "installOnlineWatchface", "cancelWatchfaceTransfer",
         "pickCustomWatchfaceBackground", "previewCustomWatchface", "pushCustomWatchface":
      if ["pushMusicSifli", "pushAlbumSifli", "updateAgps", "getOnlineWatchfaces", "installOnlineWatchface", "pushCustomWatchface"].contains(call.method) && (jlHealthBusy || notificationContactsBusy) {
        result(FlutterError(code: "BUSY", message: "请等待设备操作完成", details: nil))
        return
      }
      fileTransfer.handle(call, result: result)
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
      aiWatchface.stop()
      ota.cancel()
      fileTransfer.cancel()
      if initialized {
        sdk.destroy()
        initialized = false
        connectionCallbackRegistered = false
      }
      result(nil)
    case "getSocialSwitches", "setSocialSwitch", "setContacts", "setEmergencyContact":
      handleNotificationsAndContacts(call, result: result)
    case "getVersion":
      result(sdk.version())
    case "stopScan":
      sdk.stopScan()
      result(nil)
    case "connect":
      handleConnect(call: call, result: result)
    case "disconnect":
      aiWatchface.stop()
      ota.cancel()
      fileTransfer.cancel()
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
    case "getGoals":
      handleGetGoals(result: result)
    case "setGoal":
      handleSetGoal(call: call, result: result)
    case "getAlarms", "addDemoAlarm", "deleteAllAlarms":
      handleAlarms(method: call.method, result: result)
    case "addJlDemoAlarm":
      handleAddJlDemoAlarm(result: result)
    case "getSedentaryReminder", "setDemoSedentaryReminder", "getDrinkWaterReminder", "setDemoDrinkWaterReminder",
         "getHandwashingReminder", "setDemoHandwashingReminder":
      handleReminders(method: call.method, result: result)
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
    case "getActivitiesV2", "getSleepPointsV2", "getHeartratesV2", "getSpo2sV2", "getStressesV2", "getWorkoutsV2":
      handleGetJlHealth(method: call.method, result: result)
    case "deleteSports", "deleteHeartrates", "deleteSleeps", "deleteSpo2s", "deleteStresses", "deleteWorkouts":
      handleDeleteHealth(method: call.method, result: result)
    case "getHeartrates":
      handleGetHeartrates(result: result)
    case "getSleeps":
      handleGetSleeps(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private var notificationContactsBusy = false

  private func handleNotificationsAndContacts(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard sdk.connected() else {
      result(FlutterError(code: "13", message: "设备未连接", details: nil))
      return
    }
    guard !notificationContactsBusy else {
      result(FlutterError(code: "BUSY", message: "通知或通讯录操作进行中", details: nil))
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    func invalid(_ message: String) {
      result(FlutterError(code: "INVALID_ARGUMENT", message: message, details: nil))
    }
    let complete: HwBoolCallback = { success, error in
      DispatchQueue.main.async {
        self.notificationContactsBusy = false
        self.boolResult(success: success, error: error, result: result)
      }
    }
    if call.method == "getSocialSwitches" {
      notificationContactsBusy = true
      sdk.getSocialSwitches { list, error in
        DispatchQueue.main.async {
          self.notificationContactsBusy = false
          if let error = error { result(self.flutterError(error)); return }
          guard let switches = list as? [HwSocialSwitch] else {
            result(FlutterError(code: "EMPTY_RESULT", message: "未返回有效通知开关列表", details: nil))
            return
          }
          result(switches.map { ["type": $0.type.rawValue, "enabled": $0.s] as [String: Any] })
        }
      }
    } else if call.method == "setSocialSwitch" {
      guard let raw = args["type"] as? Int, (0...255).contains(raw),
            let type = HwSocialSwitchType(rawValue: raw), let enabled = args["enabled"] as? Bool else {
        invalid("通知类型或开关无效"); return
      }
      notificationContactsBusy = true
      sdk.setSocialSwitchWith(type, s: enabled, callback: complete)
    } else {
      let rows: [[String: Any]]
      if call.method == "setContacts" {
        guard let contacts = args["contacts"] as? [[String: Any]], (1...255).contains(contacts.count) else {
          invalid("联系人数量须为 1–255；设备实际容量以手表为准"); return
        }
        rows = contacts
      } else {
        rows = [args]
      }
      var contacts: [HwContact] = []
      for row in rows {
        let name = (row["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = (row["phone"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneLimit = call.method == "setContacts" ? 24 : 20
        guard !name.isEmpty, name.utf8.count <= 60, !phone.isEmpty,
              phone.utf8.count <= phoneLimit,
              phone.range(of: "^[+0-9*# ()-]+$", options: .regularExpression) != nil,
              phone.rangeOfCharacter(from: .decimalDigits) != nil else {
          invalid("姓名最多 60 UTF-8 字节，电话号码最多 \(phoneLimit) 字节且须包含数字"); return
        }
        let contact = HwContact()
        contact.contactName = name
        contact.contactPhone = phone
        contacts.append(contact)
      }
      notificationContactsBusy = true
      if call.method == "setContacts" {
        sdk.setContacts(contacts, callback: complete)
      } else {
        sdk.setSosName(contacts[0].contactName, phoneNumber: contacts[0].contactPhone, callback: complete)
      }
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
          let key = [device.uuid, device.macAddress, device.name]
            .compactMap { $0 }.first { !$0.isEmpty } ?? UUID().uuidString
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
    if !connected { DispatchQueue.main.async { self.aiWatchface.stop()
        self.fileTransfer.disconnected(); self.ota.disconnected() } }
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

  private func handleAlarms(method: String, result: @escaping FlutterResult) {
    guard sdk.connected() else {
      result(FlutterError(code: "13", message: "\(method) failed: device disconnected", details: nil))
      return
    }
    switch method {
    case "getAlarms":
      sdk.getAlarmsWithCallback { alarms, error in
        DispatchQueue.main.async {
          if let error = error {
            result(self.flutterError(error))
          } else {
            guard let alarms = (alarms ?? []) as? [HwAlarm] else {
              result(FlutterError(code: "ALARMS_MAPPING_ERROR", message: "getAlarms returned unexpected models", details: nil))
              return
            }
            result(alarms.map { self.alarmMap($0) })
          }
        }
      }
    case "addDemoAlarm":
      let alarm = HwAlarm()
      alarm.setValue(true, forKey: "S")
      alarm.custom = "起床"
      alarm.times = [HwTimePoint(hour: 7, minute: 30)]
      let weekdays = Int(HwWeek.monday.rawValue) | Int(HwWeek.tuesday.rawValue)
        | Int(HwWeek.wednesday.rawValue) | Int(HwWeek.thursday.rawValue)
        | Int(HwWeek.friday.rawValue)
      alarm.setValue(weekdays, forKey: "week")
      // Standard addAlarm allocates its own ID, matching the native demo.
      sdk.add(alarm) { success, error in
        DispatchQueue.main.async {
          self.boolResult(success: success, error: error, result: result)
        }
      }
    case "deleteAllAlarms":
      sdk.deleteAlarms { success, error in
        DispatchQueue.main.async {
          self.boolResult(success: success, error: error, result: result)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func alarmMap(_ alarm: HwAlarm) -> [String: Any] {
    let week = Int(alarm.week.rawValue)
    var map: [String: Any] = [
      "id": (alarm.value(forKey: "Id") as? NSNumber)?.intValue ?? 0,
      "isOn": (alarm.value(forKey: "S") as? NSNumber)?.boolValue ?? false,
      "content": alarm.custom ?? "",
      "week": week,
      "weekDescription": weekDescription(week),
    ]
    if let time = (alarm.times as? [HwTimePoint])?.first {
      map["hour"] = Int(time.hour)
      map["minute"] = Int(time.minute)
    }
    // Some HwAlarm versions omit snooze; absence keeps the Dart model's default.
    if alarm.responds(to: NSSelectorFromString("snooze")),
       let snooze = alarm.value(forKey: "snooze") as? NSNumber {
      map["snooze"] = snooze.intValue
    }
    return map
  }

  private func weekDescription(_ week: Int) -> String {
    let days: [(HwWeek, String)] = [
      (.monday, "周一"), (.tuesday, "周二"), (.wednesday, "周三"),
      (.thursday, "周四"), (.friday, "周五"), (.saturday, "周六"), (.sunday, "周日"),
    ]
    let names = days.filter { week & Int($0.0.rawValue) != 0 }.map { $0.1 }
    return names.isEmpty ? "不重复" : names.joined(separator: ",")
  }

  private var jlAlarmsBusy = false

  private func handleAddJlDemoAlarm(result: @escaping FlutterResult) {
    let method = "addJlDemoAlarm"
    guard sdk.connected() else {
      result(FlutterError(code: "13", message: "\(method) failed: device disconnected", details: nil))
      return
    }
    // Serialize read/allocate/write so concurrent callers cannot select the same ID.
    guard !jlAlarmsBusy else {
      result(FlutterError(code: "JL_ALARMS_BUSY", message: "杰理闹钟操作尚未完成", details: nil))
      return
    }
    jlAlarmsBusy = true
    let finish: FlutterResult = { value in
      self.jlAlarmsBusy = false
      result(value)
    }
    readJlItems(reminders: false) { response in
      switch response {
      case .failure(let error):
        finish(self.flutterError(error))
      case .success(let alarms):
        self.readJlItems(reminders: true) { response in
          switch response {
          case .failure(let error):
            finish(self.flutterError(error))
          case .success(let reminders):
            let usedIDs = Set((alarms + reminders).map(\.id))
            // Demo range, not a claim about the device's total capacity.
            guard let id = (1...5).first(where: { !usedIDs.contains($0) }) else {
              finish(FlutterError(code: "JL_ALARM_ID_UNAVAILABLE", message: "杰理示例闹钟 ID 1–5 已被闹钟或提醒占用", details: nil))
              return
            }
            let alarm = HwReminder()
            alarm.id = id
            alarm.s = true
            alarm.hour = 7
            alarm.min = 30
            alarm.custom = "起床"
            alarm.type = .awake
            alarm.repeatType = .none
            alarm.repeatValue = 0
            alarm.vib = .stateShortAlways
            alarm.times = [HwTimePoint(hour: 7, minute: 30)]
            let weekdays = Int(HwWeek.monday.rawValue) | Int(HwWeek.tuesday.rawValue)
              | Int(HwWeek.wednesday.rawValue) | Int(HwWeek.thursday.rawValue)
              | Int(HwWeek.friday.rawValue)
            alarm.setValue(weekdays, forKey: "week")
            HwBluetoothCenter.sharedInstance().add(alarm, identify: UInt(id)) { success, error in
              DispatchQueue.main.async {
                self.boolResult(success: success, error: error) { value in
                  finish(success && error == nil ? id : value)
                }
              }
            }
          }
        }
      }
    }
  }

  private func readJlItems(reminders: Bool, completion: @escaping (Result<[HwReminder], Error>) -> Void) {
    guard let center = HwBluetoothCenter.sharedInstance() else {
      completion(.failure(NSError(domain: "HwBleBridge", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "蓝牙中心尚未初始化"])))
      return
    }
    center.getRemindAndAlarmCount { reminderCount, alarmCount, error in
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(error))
          return
        }
        let count = Int(reminders ? reminderCount : alarmCount)
        if count == 0 {
          completion(.success([]))
          return
        }
        let callback: ([Any]?, Error?) -> Void = { list, error in
          DispatchQueue.main.async {
            if let error = error {
              completion(.failure(error))
            } else if let items = list as? [HwReminder], items.count == count,
                      items.allSatisfy({ $0.id > 0 }) {
              completion(.success(items))
            } else {
              // An incomplete list is unsafe for shared-ID allocation.
              completion(.failure(NSError(domain: "HwBleBridge", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "杰理闹钟/提醒列表不完整或 ID 无效，请重新读取"])))
            }
          }
        }
        if reminders {
          center.getRemindersWithCount(count, callback: callback)
        } else {
          center.getAlarmsWithCount(count, callback: callback)
        }
      }
    }
  }

  private func handleReminders(method: String, result: @escaping FlutterResult) {
    guard sdk.connected() else {
      result(FlutterError(code: "13", message: "\(method) failed: device disconnected", details: nil))
      return
    }
    switch method {
    case "getSedentaryReminder":
      sdk.getSedentaryReminder { reminder, error in
        DispatchQueue.main.async {
          if let error = error {
            result(self.flutterError(error))
          } else if let reminder = reminder {
            let week = Int(reminder.week.rawValue)
            var map: [String: Any] = [
              "isOn": reminder.on, "intervalSeconds": Int(reminder.interval),
              "week": week, "weekDescription": self.weekDescription(week),
            ]
            let startTime: HwTimePoint? = reminder.startTime
            let endTime: HwTimePoint? = reminder.endTime
            if let start = startTime {
              map["startHour"] = Int(start.hour)
              map["startMinute"] = Int(start.minute)
            }
            if let end = endTime {
              map["endHour"] = Int(end.hour)
              map["endMinute"] = Int(end.minute)
            }
            result(map)
          } else {
            result(FlutterError(code: "EMPTY_RESULT", message: "getSedentaryReminder returned nil", details: nil))
          }
        }
      }
    case "getDrinkWaterReminder":
      sdk.getDrinkWaterConfig { config, error in
        DispatchQueue.main.async {
          if let error = error {
            result(self.flutterError(error))
          } else if let config = config {
            let week = Int(config.week.rawValue)
            result([
              "isOn": config.eventOn,
              "startHour": Int(config.startHour), "startMinute": Int(config.startMinute),
              "endHour": Int(config.endHour), "endMinute": Int(config.endMinute),
              "intervalSeconds": Int(config.timeInterval), "duration": Int(config.duration),
              "week": week, "weekDescription": self.weekDescription(week),
            ])
          } else {
            result(FlutterError(code: "EMPTY_RESULT", message: "getDrinkWaterReminder returned nil", details: nil))
          }
        }
      }
    case "getHandwashingReminder":
      sdk.getHandwashingConfig { config, error in
        DispatchQueue.main.async {
          if let error = error {
            result(self.flutterError(error))
          } else if let config = config {
            let week = Int(config.week.rawValue)
            result([
              "isOn": config.eventOn,
              "startHour": Int(config.startHour), "startMinute": Int(config.startMinute),
              "endHour": Int(config.endHour), "endMinute": Int(config.endMinute),
              "intervalSeconds": Int(config.timeInterval), "duration": Int(config.duration),
              "week": week, "weekDescription": self.weekDescription(week),
            ])
          } else {
            result(FlutterError(code: "EMPTY_RESULT", message: "getHandwashingReminder returned nil", details: nil))
          }
        }
      }
    case "setDemoSedentaryReminder":
      let reminder = HwSedentaryReminder()
      reminder.on = true
      reminder.startTime = HwTimePoint(hour: 9, minute: 0)
      reminder.endTime = HwTimePoint(hour: 18, minute: 0)
      reminder.interval = 3600
      let weekdays = Int(HwWeek.monday.rawValue) | Int(HwWeek.tuesday.rawValue)
        | Int(HwWeek.wednesday.rawValue) | Int(HwWeek.thursday.rawValue)
        | Int(HwWeek.friday.rawValue)
      reminder.setValue(weekdays, forKey: "week")
      sdk.setSedentaryReminder(reminder) { success, error in
        DispatchQueue.main.async {
          self.boolResult(success: success, error: error, result: result)
        }
      }
    case "setDemoDrinkWaterReminder":
      let config = HwDrinkWaterConfig()
      config.eventOn = true
      config.startHour = 8
      config.startMinute = 0
      config.endHour = 20
      config.endMinute = 0
      config.timeInterval = 3600
      // Preserve the native demo's duration value; its unit is not documented here.
      config.duration = 5
      let everyDay = Int(HwWeek.monday.rawValue) | Int(HwWeek.tuesday.rawValue)
        | Int(HwWeek.wednesday.rawValue) | Int(HwWeek.thursday.rawValue)
        | Int(HwWeek.friday.rawValue) | Int(HwWeek.saturday.rawValue)
        | Int(HwWeek.sunday.rawValue)
      config.setValue(everyDay, forKey: "week")
      sdk.setDrinkWaterConfig(config) { success, error in
        DispatchQueue.main.async {
          self.boolResult(success: success, error: error, result: result)
        }
      }
    case "setDemoHandwashingReminder":
      let config = HwHandwashingConfig()
      config.eventOn = true
      config.startHour = 8
      config.startMinute = 0
      config.endHour = 22
      config.endMinute = 0
      config.timeInterval = 7200
      // Preserve the native demo's duration value without assuming its unit.
      config.duration = 5
      let everyDay = Int(HwWeek.monday.rawValue) | Int(HwWeek.tuesday.rawValue)
        | Int(HwWeek.wednesday.rawValue) | Int(HwWeek.thursday.rawValue)
        | Int(HwWeek.friday.rawValue) | Int(HwWeek.saturday.rawValue)
        | Int(HwWeek.sunday.rawValue)
      config.setValue(everyDay, forKey: "week")
      sdk.setHandwashingConfig(config) { success, error in
        DispatchQueue.main.async {
          self.boolResult(success: success, error: error, result: result)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleGetGoals(result: @escaping FlutterResult) {
    guard sdk.connected() else {
      result(FlutterError(code: "13", message: "getGoals failed: device disconnected", details: nil))
      return
    }
    HwBluetoothCenter.sharedInstance().getGoalInfoModel { goal, error in
      DispatchQueue.main.async {
        if let error = error {
          result(self.flutterError(error))
        } else if let goal = goal {
          // Keep protocol units: step=hundreds of steps, OT distances=tenths.
          result([
            "step": Int(goal.step),
            "calorie": Int(goal.calorie),
            "distance": Int(goal.distance),
            "sleep": Int(goal.sleep),
            "duration": Int(goal.duration),
            "otDistance": self.goalIntValue(goal, keys: ["OTDistance", "otDistance"]),
            "otDistanceMile": self.goalIntValue(goal, keys: ["OTDistanceMile", "otDistanceMile"]),
          ])
        } else {
          result(FlutterError(code: "GOALS_EMPTY", message: "getGoals returned empty result", details: nil))
        }
      }
    }
  }

  private func handleSetGoal(call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Dart BleGoalType values are a channel contract, not native enum raw values.
    let types: [HwGoalType] = [.step, .caloris, .distance, .sleep, .duration]
    guard let args = call.arguments as? [String: Any],
          let type = args["type"] as? Int, types.indices.contains(type),
          let value = args["value"] as? Int, value >= 0 else {
      result(FlutterError(code: "INVALID_ARGS", message: "setGoal requires type 0...4 and a non-negative integer value", details: nil))
      return
    }
    guard sdk.connected() else {
      result(FlutterError(code: "13", message: "setGoal failed: device disconnected", details: nil))
      return
    }
    sdk.setGoalWith(types[type], goal: value) { success, error in
      DispatchQueue.main.async {
        self.boolResult(success: success, error: error, result: result)
      }
    }
  }

  private func goalIntValue(_ goal: HwGoal, keys: [String]) -> Int {
    // The reference iOS demo supports both SDK spellings of optional OT fields.
    for key in keys where goal.responds(to: NSSelectorFromString(key)) {
      if let value = goal.value(forKey: key) as? NSNumber { return value.intValue }
    }
    return 0
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
      "rssi": device.rssi?.intValue ?? 0,
    ]
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

  private var jlHealthBusy = false

  private func handleDeleteHealth(method: String, result: @escaping FlutterResult) {
    guard sdk.connected() else {
      result(FlutterError(code: "13", message: "\(method) failed: device disconnected", details: nil))
      return
    }
    guard !jlHealthBusy else {
      result(FlutterError(code: "JL_HEALTH_BUSY", message: "健康数据操作尚未完成", details: nil))
      return
    }
    guard let center = HwBluetoothCenter.sharedInstance() else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "蓝牙中心尚未初始化", details: nil))
      return
    }
    jlHealthBusy = true
    let complete: (Bool, Error?) -> Void = { success, error in
      DispatchQueue.main.async {
        self.jlHealthBusy = false
        self.boolResult(success: success, error: error, result: result)
      }
    }
    // Same category-specific delete APIs as JieliHealthRepository in the native demo.
    switch method {
    case "deleteSports": sdk.deleteActivities(callback: complete)
    case "deleteSleeps": sdk.deleteSleeps(callback: complete)
    case "deleteHeartrates": sdk.deleteHeartrates(callback: complete)
    case "deleteSpo2s": center.deleteBloodOxygen(callback: complete)
    case "deleteStresses": center.deleteStress(callback: complete)
    case "deleteWorkouts": sdk.deleteWorkouts(callback: complete)
    default:
      jlHealthBusy = false
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleGetJlHealth(method: String, result: @escaping FlutterResult) {
    guard sdk.connected() else {
      result(FlutterError(code: "13", message: "\(method) failed: device disconnected", details: nil))
      return
    }
    guard !jlHealthBusy else {
      result(FlutterError(code: "JL_HEALTH_BUSY", message: "健康数据操作尚未完成", details: nil))
      return
    }
    guard let center = HwBluetoothCenter.sharedInstance() else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "蓝牙中心尚未初始化", details: nil))
      return
    }
    jlHealthBusy = true
    func complete<T>(_ list: [Any]?, error: Error?, map: @escaping (T) -> [String: Any]) {
      DispatchQueue.main.async {
        self.jlHealthBusy = false
        if let error = error {
          result(self.flutterError(error))
        } else if let items = (list ?? []) as? [T] {
          result(items.map(map))
        } else {
          result(FlutterError(code: "HEALTH_MAPPING_ERROR", message: "\(method) returned unexpected models", details: nil))
        }
      }
    }
    // Native demo: activity/workout timestamps are ms; point measurements are seconds.
    switch method {
    case "getActivitiesV2":
      center.getSportDetailBigData { list, error in
        complete(list, error: error) { (item: HwActivity) in
          self.activityMap(item, timeIsMilliseconds: true)
        }
      }
    case "getSleepPointsV2":
      center.getSleepBigData { list, error in
        complete(list, error: error) { (item: HwSleepPoint) in
          ["timeMs": Int(item.time * 1000), "status": Int(item.status.rawValue)]
        }
      }
    case "getHeartratesV2":
      center.getHeartRateBigData { list, error in
        complete(list, error: error, map: self.heartrateMap)
      }
    case "getSpo2sV2":
      center.getBloodOxygenBigData { list, error in
        complete(list, error: error) { (item: HwSpo2) in
          ["timeMs": Int(item.time * 1000), "spo2": Int(item.spo2)]
        }
      }
    case "getStressesV2":
      center.getStressBigData { list, error in
        complete(list, error: error) { (item: HwStress) in
          ["timeMs": Int(item.time * 1000), "stress": Int(item.stress)]
        }
      }
    case "getWorkoutsV2":
      center.getWorkoutsBigData { list, error in
        complete(list, error: error) { (item: HwWorkout) in
          ["startTimeMs": Int(item.startTime), "endTimeMs": Int(item.endTime),
           "type": Int(item.type.rawValue), "step": Int(item.step),
           "distance": Int(item.distance), "calorie": Int(item.calorie),
           "duration": Int(item.duration), "bpm": Int(item.bpm)]
        }
      }
    default:
      jlHealthBusy = false
      result(FlutterMethodNotImplemented)
    }
  }

  private func activityMap(_ activity: HwActivity, timeIsMilliseconds: Bool = false) -> [String: Any] {
    [
      "index": activity.index,
      // The native Jieli demo treats BigData activity.time as milliseconds.
      "timeMs": Int(timeIsMilliseconds ? activity.time : activity.time * 1000),
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
