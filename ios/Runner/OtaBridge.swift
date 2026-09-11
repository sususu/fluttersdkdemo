import Flutter
import UIKit
import HwBluetoothSDK
import WatchfaceSDK
import SifliOTAManagerSDK
import SSZipArchive
import CryptoKit

// One session owns the download, unpacking and DFU callbacks through completion.
final class OtaBridge: NSObject, FlutterStreamHandler {
  private let sdk = HwBluetoothSDK.sharedInstance()
  private let manager = SFOTAManager.share
  private var sink: FlutterEventSink?
  private var state: [String: Any] = ["phase": "idle", "progress": 0.0]
  private var session: UUID?
  private var result: FlutterResult?
  private var task: URLSessionTask?
  private var observation: NSKeyValueObservation?
  private var root: URL?
  private var target = ""
  private var jieli = false
  private var device: [String: Any] = [:]
  private var upgrade: OtaUpgradeInfo?
  private var callbacks: OtaCallbacks?
  private var dfu = false
  private var handingOff = false
  private var progress = 0.0
  private var idleTimerWasDisabled: Bool?
  private let queue = DispatchQueue(label: "sdkdemo.otaPreparation", qos: .userInitiated)
  var busy: Bool { session != nil }

  func register(with registrar: FlutterPluginRegistrar) {
    FlutterEventChannel(name: "sdkdemo/hw_ble/ota", binaryMessenger: registrar.messenger()).setStreamHandler(self)
  }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events; events(state); return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? { sink = nil; return nil }
  private func emit(_ phase: String, _ value: Double = 0, message: String = "") {
    state = ["phase": phase, "progress": value, "message": message]
    sink?(state)
  }
  private func fail(_ id: UUID, _ error: Error) { finish(id, failure: FlutterError(code: "OTA_ERROR", message: error.localizedDescription, details: nil)) }
  private func connectedToTarget() -> Bool { sdk.connected() && sdk.connectedDevice()?.peripheral?.identifier.uuidString == target }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "cancelOta" { cancel(); result(nil); return }
    guard !busy, sdk.connected(), let uuid = sdk.connectedDevice()?.peripheral?.identifier.uuidString else {
      result(FlutterError(code: "OTA_UNAVAILABLE", message: "请连接手表并等待当前操作完成", details: nil)); return
    }
    let requestedJieli = (call.arguments as? [String: Any])?["jieli"] as? Bool ?? false
    let id = UUID()
    session = id; self.result = result
    DispatchQueue.main.asyncAfter(deadline: .now() + 35) {
      if self.session == id, self.root == nil, self.task == nil { self.fail(id, otaError("设备响应超时")) }
    }
    if call.method == "startOta" {
      guard uuid == target, requestedJieli == jieli, let info = upgrade else { fail(id, otaError("请先检查更新")); return }
      idleTimerWasDisabled = UIApplication.shared.isIdleTimerDisabled
      UIApplication.shared.isIdleTimerDisabled = true
      emit("preparing", message: "正在检查电量…")
      sdk.getBatteryWithCallback { battery, error in
        DispatchQueue.main.async {
          guard self.session == id else { return }
          if let error = error { self.fail(id, error); return }
          guard battery >= 30 else { self.fail(id, otaError("电量不足 30%，请先充电")); return }
          if self.jieli {
            // The native Jieli screen uses OTA V2's own readiness handshake.
            self.prepareJieli(info, id: id)
            return
          }
          self.sdk.getDeviceUpgradeStatus { status, error in
            DispatchQueue.main.async {
              guard self.session == id else { return }
              if let error = error { self.fail(id, error); return }
              guard status == .none else { self.fail(id, otaError("设备当前不可升级（状态 \(status.rawValue)）")); return }
              self.prepare(info, id: id)
            }
          }
        }
      }
    } else {
      jieli = requestedJieli
      target = uuid; upgrade = nil; device = [:]
      readDevice(id: id, check: call.method == "checkOta")
    }
  }

  private func readDevice(id: UUID, check: Bool) {
    sdk.getDeviceInfo { info, error in
      DispatchQueue.main.async {
        guard self.session == id else { return }
        if let error = error { self.fail(id, error); return }
        guard let info = info, self.connectedToTarget() else { self.fail(id, otaError("设备连接已变化")); return }
        self.device = ["mac": info.mac ?? "", "firmware": info.firmwareVersion ?? "", "productCode": info.type ?? "", "deviceId": info.id ?? ""]
        if (info.firmwareVersion ?? "").isEmpty {
          self.sdk.getFirmwareVersion { firmware, error in
            DispatchQueue.main.async {
              guard self.session == id else { return }
              if let error = error { self.fail(id, error); return }
              self.device["firmware"] = firmware ?? ""
              self.deviceReady(id: id, check: check)
            }
          }
        } else { self.deviceReady(id: id, check: check) }
      }
    }
  }

  private func deviceReady(id: UUID, check: Bool) {
    guard connectedToTarget() else { fail(id, otaError("设备连接已变化")); return }
    guard check else { finish(id, value: device); return }
    let raw = device["firmware"] as? String ?? ""
    let version = FirmwareVersionUtils.extractV(raw)
    guard !version.isEmpty, let build = FirmwareVersionUtils.extractB(raw),
          let product = device["productCode"] as? String, !product.isEmpty,
          let deviceId = device["deviceId"] as? String, !deviceId.isEmpty else {
      fail(id, otaError("设备型号、ID 或固件版本不完整，无法检查更新")); return
    }
    var request = URLRequest(url: URL(string: "https://test.huawo-wear.com/api/v1/devices/upgrades")!, timeoutInterval: 30)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(Bundle.main.bundleIdentifier, forHTTPHeaderField: "appId")
    request.setValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", forHTTPHeaderField: "appVersion")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["currentVersion": version, "currentBuild": build, "productCode": product, "customerCode": "Huawo", "deviceId": deviceId])
    task = URLSession.shared.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        guard self.session == id else { return }
        do {
          if let error = error { throw error }
          guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                let data = data, let json = String(data: data, encoding: .utf8) else { throw otaError("检查更新请求失败") }
          guard self.connectedToTarget() else { throw otaError("设备连接已变化，请重新检查更新") }
          let info = try OtaFirmware.parseUpgradeResponse(json)
          let newer = !info.firmwares.isEmpty && FirmwareVersionUtils.canUpgrade(currentVersion: version, currentBuild: build, destVersion: info.version, destBuild: info.build)
          self.upgrade = newer ? info : nil
          var value = self.device
          value["available"] = newer
          value["version"] = info.version ?? ""
          value["build"] = info.build ?? 0
          value["content"] = info.updateContent ?? ""
          self.finish(id, value: value)
        } catch { self.fail(id, error) }
      }
    }
    task?.resume()
  }

  private func download(_ file: OtaFirmwareItem, to destination: URL, id: UUID,
                        base: Double, span: Double, done: @escaping () -> Void) {
    let path = file.url
    guard let url = URL(string: path.lowercased().hasPrefix("http") ? path : "https://test.huawo-wear.com/files/" + path),
          url.scheme == "https", url.host != nil else { fail(id, otaError("固件下载地址无效或不是 HTTPS")); return }
    emit("downloading", base, message: "正在下载固件…")
    let request = URLRequest(url: url, timeoutInterval: 120)
    let download = URLSession.shared.downloadTask(with: request) { location, response, error in
      // URLSession deletes its temporary file when this callback returns.
      var failure = error
      do {
        if let error = error { throw error }
        guard let location = location, let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw otaError("固件下载失败") }
        try FileManager.default.moveItem(at: location, to: destination)
        let data = try Data(contentsOf: destination, options: .mappedIfSafe)
        guard !data.isEmpty else { throw otaError("固件文件为空") }
        if let expected = file.md5, !expected.isEmpty {
          let actual = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
          guard actual.caseInsensitiveCompare(expected) == .orderedSame else { throw otaError("固件 MD5 校验失败") }
        }
      } catch { failure = error }
      DispatchQueue.main.async {
        guard self.session == id else { try? FileManager.default.removeItem(at: destination.deletingLastPathComponent()); return }
        self.observation = nil; self.task = nil
        if let failure = failure { self.fail(id, failure); return }
        done()
      }
    }
    task = download
    observation = download.progress.observe(\.fractionCompleted, options: [.new]) { [weak download] progress, _ in
      let fraction = progress.fractionCompleted
      DispatchQueue.main.async {
        guard self.session == id, let download = download, self.task === download else { return }
        self.emit("downloading", base + min(1, max(0, fraction)) * span, message: "正在下载固件…")
      }
    }
    download.resume()
  }

  private func prepareJieli(_ info: OtaUpgradeInfo, id: UUID) {
    guard connectedToTarget(), !info.firmwares.isEmpty else { fail(id, otaError("连接已断开或没有升级包")); return }
    guard let service = sdk.otaV2Service, !service.isRunning else { fail(id, otaError("杰里 OTA 服务不可用或正在升级")); return }
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("jieli-ota-\(id.uuidString)")
    do { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
    catch { fail(id, error); return }
    root = directory
    func next(_ index: Int, files: [URL]) {
      guard session == id else { return }
      if index < info.firmwares.count {
        let file = directory.appendingPathComponent("\(index).bin")
        let span = 0.4 / Double(info.firmwares.count)
        download(info.firmwares[index], to: file, id: id, base: Double(index) * span, span: span) {
          next(index + 1, files: files + [file])
        }
        return
      }
      emit("preparing", 0.4, message: "正在合并固件…")
      queue.async {
        do {
          let data = try OtaFirmware.jieliBin(files: files)
          DispatchQueue.main.async {
            guard self.session == id else { return }
            guard self.connectedToTarget(), !service.isRunning else { self.fail(id, otaError("设备连接已变化或 OTA 正在进行")); return }
            self.dfu = true
            self.handingOff = true
            self.progress = 0.4
            self.emit("preparing", 0.4, message: "正在检查升级就绪状态…")
            service.start(withBinData: data, readyCallback: { ok, error in
              DispatchQueue.main.async {
                guard self.session == id else { return }
                if let error = error { self.fail(id, error) }
                else if !ok { self.fail(id, otaError("杰里 OTA 准备失败")) }
                else { self.emit("transferring", self.progress, message: "正在升级…") }
              }
            }, progressCallback: { value, error in
              DispatchQueue.main.async {
                guard self.session == id else { return }
                if let error = error { self.fail(id, error); return }
                guard value.isFinite else { return }
                self.progress = max(self.progress, 0.4 + min(1, max(0, Double(value))) * 0.6)
                self.emit("transferring", self.progress, message: "正在升级…")
              }
            }, finishCallback: { ok, error in
              DispatchQueue.main.async {
                guard self.session == id else { return }
                if let error = error { self.fail(id, error) }
                else if !ok { self.fail(id, otaError("杰里 OTA 升级失败")) }
                else { self.finish(id) }
              }
            })
          }
        } catch { DispatchQueue.main.async { self.fail(id, error) } }
      }
    }
    next(0, files: [])
  }

  private func prepare(_ info: OtaUpgradeInfo, id: UUID) {
    guard connectedToTarget(), let firmware = info.firmwares.first(where: { $0.type == 1 }) ?? info.firmwares.first else {
      fail(id, otaError("连接已断开或没有升级包")); return
    }
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ota-\(id.uuidString)")
    do { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
    catch { fail(id, error); return }
    root = directory
    let zip = directory.appendingPathComponent("firmware.zip")
    download(firmware, to: zip, id: id, base: 0, span: 0.3) {
      self.emit("preparing", 0.3, message: "正在校验升级包…")
      self.queue.async {
        do {
          let unpacked = directory.appendingPathComponent("unpacked")
          guard SSZipArchive.unzipFile(atPath: zip.path, toDestination: unpacked.path) else { throw otaError("固件解压失败") }
          let paths = try FileManager.default.subpathsOfDirectory(atPath: unpacked.path).sorted()
          var bins: [String: URL] = [:]
          for path in paths where path.lowercased().hasSuffix(".bin") {
            let url = unpacked.appendingPathComponent(path)
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
            guard values.isRegularFile == true, values.isSymbolicLink != true, (values.fileSize ?? 0) > 0,
                  url.resolvingSymlinksInPath().path.hasPrefix(unpacked.path + "/") else { throw otaError("升级包包含无效文件") }
            let name = url.lastPathComponent
            let key: String?
            if name.hasPrefix("diff_ctrl") { key = "diff_ctrl" }
            else if name.hasPrefix("ctrl") { key = "ctrl" }
            else if name.hasPrefix("hcpu") { key = "hcpu" }
            else if name.hasPrefix("patch") { key = "patch" }
            else if name.hasPrefix("lcpu") { key = "lcpu" }
            else if name.hasPrefix("outdyn") { key = "outdyn" }
            else if name.hasPrefix("outroot") { key = "outroot" }
            else { key = nil }
            if let key = key {
              guard bins[key] == nil else { throw otaError("升级包包含重复的 \(key) 文件") }
              bins[key] = url
            }
          }
          guard let control = bins["diff_ctrl"] ?? bins["ctrl"] else { throw otaError("升级包缺少控制文件") }
          var images: [SFNandImageFileInfo] = []
          if let url = bins["hcpu"] { images.append(SFNandImageFileInfo(path: url, imageID: .HCPU)) }
          if let url = bins["lcpu"] { images.append(SFNandImageFileInfo(path: url, imageID: .LCPU)) }
          if let url = bins["patch"] { images.append(SFNandImageFileInfo(path: url, imageID: .LCPU_PATCH)) }
          let diff = bins["diff_ctrl"] != nil
          if !diff {
            if let url = bins["outdyn"] { images.append(SFNandImageFileInfo(path: url, imageID: .DYN)) }
            if let url = bins["outroot"] { images.append(SFNandImageFileInfo(path: url, imageID: .RES)) }
          }
          DispatchQueue.main.async {
            guard self.session == id else { try? FileManager.default.removeItem(at: directory); return }
            if diff {
              let resource: OtaFirmwareItem?
              if let value = info.resource, let url = value.url, !url.isEmpty {
                resource = OtaFirmwareItem(url: url, md5: value.md5)
              } else { resource = info.firmwares.first(where: { $0.type != 1 && $0.type != 0 }) }
              guard let resource = resource else { self.fail(id, otaError("差分升级缺少资源包")); return }
              let path = directory.appendingPathComponent("resource.zip")
              self.download(resource, to: path, id: id, base: 0.3, span: 0.1) {
                self.startDFU(id, control: control, images: images, resource: path)
              }
            } else { self.startDFU(id, control: control, images: images, resource: nil) }
          }
        } catch {
          DispatchQueue.main.async {
            if self.session == id { self.fail(id, error) }
            else { try? FileManager.default.removeItem(at: directory) }
          }
        }
      }
    }
  }

  private func startDFU(_ id: UUID, control: URL, images: [SFNandImageFileInfo], resource: URL?) {
    guard connectedToTarget() else { fail(id, otaError("设备连接已变化，请重新检查更新")); return }
    handingOff = true
    SifliWatchfaceSDK.getInstance().stop()
    manager.initSDK()
    let callbacks = OtaCallbacks()
    callbacks.onProgress = { [weak self] stage, total, completed in
      DispatchQueue.main.async {
        guard let self = self, self.session == id, self.dfu, total > 0 else { return }
        let ratio = min(1, max(0, Double(completed) / Double(total)))
        let mapped = stage == .nand_res ? ratio * 0.5 : stage == .nand_image ? 0.5 + ratio * 0.5 : ratio
        self.progress = max(self.progress, 0.4 + mapped * 0.6)
        self.emit("transferring", self.progress, message: "正在升级…")
      }
    }
    callbacks.onComplete = { [weak self] error in
      DispatchQueue.main.async {
        self?.finish(id, failure: error.map { FlutterError(code: String($0.errorType.rawValue), message: $0.errorDes, details: nil) })
      }
    }
    self.callbacks = callbacks
    manager.delegate = callbacks
    emit("preparing", 0.4, message: "正在准备升级连接…")
    func attempt(_ remaining: Int) {
      guard session == id else { return }
      if manager.bleState == .poweredOn {
        dfu = true; progress = 0.4
        emit("transferring", progress, message: "正在升级…")
        manager.startOTANand(targetDeviceIdentifier: target, resourcePath: resource,
          controlImageFilePath: control, imageFileInfos: images, tryResume: true, imageResponseFrequnecy: 4)
      } else if remaining > 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { attempt(remaining - 1) }
      } else { fail(id, otaError("OTA 蓝牙未就绪")) }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { attempt(20) }
  }

  func cancel() {
    if let id = session { finish(id, failure: FlutterError(code: "CANCELLED", message: "已取消升级", details: nil)) }
  }
  func disconnected() {
    // DFU owns its BLE connection and may deliberately disconnect the normal SDK.
    if !handingOff, let id = session { fail(id, otaError("连接断开，操作已停止")) }
  }
  private func finish(_ id: UUID, value: Any? = nil, failure: FlutterError? = nil) {
    guard session == id else { return }
    session = nil
    task?.cancel(); task = nil; observation = nil
    let wasDFU = dfu; dfu = false; handingOff = false
    manager.delegate = nil; callbacks = nil
    if wasDFU {
      if jieli { sdk.otaV2Service?.stop() } else { manager.stop() }
      upgrade = nil
    }
    if let root = root {
      // Queue cleanup behind unpacking, so a cancelled package cannot leave files behind.
      queue.async { try? FileManager.default.removeItem(at: root) }
    }
    root = nil
    if let previous = idleTimerWasDisabled { UIApplication.shared.isIdleTimerDisabled = previous }
    idleTimerWasDisabled = nil
    let completion = result; result = nil
    emit(failure == nil ? "completed" : "failed", failure == nil ? 1 : 0)
    completion?(failure ?? value)
  }
}

private final class OtaCallbacks: NSObject, SFOTAManagerDelegate {
  var onProgress: ((SFOTAProgressStage, Int, Int) -> Void)?
  var onComplete: ((SFOTAError?) -> Void)?
  func otaManager(manager: SFOTAManager, updateBleState state: BleCoreManagerState) {}
  func otaManager(manager: SFOTAManager, stage: SFOTAProgressStage, totalBytes: Int, completedBytes: Int) {
    onProgress?(stage, totalBytes, completedBytes)
  }
  func otaManager(manager: SFOTAManager, complete error: SFOTAError?) { onComplete?(error) }
}
