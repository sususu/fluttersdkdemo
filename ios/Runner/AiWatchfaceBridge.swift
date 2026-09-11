import Flutter
import UIKit
import HwBluetoothSDK
import WatchfaceSDK
import AiSDK
import JLBmpConvertKit

final class AiWatchfaceBridge: NSObject, FlutterStreamHandler, AiSDKCallback {
  private var sink: FlutterEventSink?
  private var session: UUID?
  private var pending: FlutterResult?
  private var state: [String: Any] = ["running": false, "installing": false, "progress": 0.0, "message": "尚未启动"]
  var busy: Bool { session != nil }

  func register(with registrar: FlutterPluginRegistrar) {
    FlutterEventChannel(name: "sdkdemo/hw_ble/aiWatchface", binaryMessenger: registrar.messenger()).setStreamHandler(self)
  }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events; events(state); return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? { stop(); sink = nil; return nil }
  private func emit(_ values: [String: Any]) {
    state.merge(values) { _, new in new }; sink?(state)
  }
  private func error(_ message: String) -> FlutterError { FlutterError(code: "AI_ERROR", message: message, details: nil) }

  func start(_ args: [String: Any], result: @escaping FlutterResult) {
    guard !busy else { result(error("请先停止当前 AI 监听")); return }
    guard let w = args["width"] as? Int, let h = args["height"] as? Int,
          let tw = args["thumbWidth"] as? Int, let th = args["thumbHeight"] as? Int,
          [w,h,tw,th].allSatisfy({ (64...1024).contains($0) }),
          let r = args["corner"] as? Int, (0...min(w,h)/2).contains(r),
          let tr = args["thumbCorner"] as? Int, (0...min(tw,th)/2).contains(tr),
          let style = args["style"] as? Int, [3,9].contains(style) else {
      result(error("表盘尺寸、圆角或风格无效")); return
    }
    let sdk = HwBluetoothSDK.sharedInstance()
    guard sdk.connected(), let uuid = sdk.connectedDevice()?.peripheral?.identifier else { result(error("请先连接手表")); return }
    let id = UUID(); session = id; pending = result
    state = ["running": false, "installing": false, "progress": 0.0, "message": "正在读取设备信息…"]
    sink?(state)
    DispatchQueue.main.asyncAfter(deadline: .now()+30) {
      guard self.session == id, self.pending != nil else { return }
      self.endStart(self.error("读取设备信息超时"))
    }
    sdk.getDeviceInfo { device, failure in
      DispatchQueue.main.async {
        guard self.session == id else { return }
        guard failure == nil, let device = device, sdk.connected(), sdk.connectedDevice()?.peripheral?.identifier == uuid else {
          self.endStart(self.error(failure?.localizedDescription ?? "设备连接已变化")); return
        }
        let deviceId = device.id, type = device.type
        guard !deviceId.isEmpty, !type.isEmpty else {
          self.endStart(self.error("未获取到设备 ID 或型号，请重新连接后再试")); return
        }
        let info = AiDeviceInfo()
        info.setValue(deviceId, forKey: "Id")
        info.type = type; info.mac = device.mac ?? ""; info.name = sdk.connectedDevice()?.name ?? ""
        info.width = w; info.height = h; info.cornerRadius = r
        info.thumbnailWidth = tw; info.thumbnailHeight = th; info.thumbnailCornerRadius = tr
        info.currentLocale = Locale.current.languageCode ?? "en"
        info.platformType = args["jieli"] as? Bool == true || device.protocolVersion >= 100 ? .jieLi : .sifli
        let ai = AiSDK.sharedInstance()
        ai.setJLBmpDataConverter { data in
          let option = JLBmpConvertOption(); option.convertType = .type707N_ARGB; option.pixelformat = ._Auto
          return JLBmpConvert.convert(option, imageData: data).outFileData
        }
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
          for name in ["tempZipFolder", "target.zip", "JW_AIPreview1.bin"] {
            try? FileManager.default.removeItem(at: caches.appendingPathComponent(name))
          }
        }
        ai.callback = self
        ai.aiStyle = AiStyle(rawValue: style)!
        // AiSDK otherwise ignores changed geometry for the same device ID and locale.
        ai.cleanDeviceInfo()
        ai.setDeviceInfo(info)
        ai.startWorking()
        self.emit(["running": true, "deviceId": deviceId, "message": "已启动，请在手表上发起 AI 表盘生成"])
        let callback = self.pending; self.pending = nil; callback?(nil)
      }
    }
  }

  private func endStart(_ failure: FlutterError) {
    let result = pending; pending = nil
    stop()
    emit(["message": failure.message ?? "启动失败"])
    result?(failure)
  }
  func stop() {
    guard session != nil else { return }
    session = nil
    let callback = pending; pending = nil
    let ai = AiSDK.sharedInstance()
    ai.stopWorking()
    ai.cancelAll()
    ai.cleanDeviceInfo()
    emit(["running": false, "installing": false, "message": "已停止 AI 监听"])
    callback?(FlutterError(code: "CANCELLED", message: "已停止 AI 监听", details: nil))
  }
  private func update(_ values: [String: Any]) {
    let id = session
    DispatchQueue.main.async {
      guard let id = id, self.session == id else { return }
      self.emit(values)
    }
  }
  func aiStartRecording(_ type: Int) { if type == 1 { update(["message": "正在接收手表语音…", "progress": 0.0]) } }
  func aiVoiceToTextDone(_ text: String!, type: Int) { if type == 1 { update(["message": "正在生成图片…"]) } }
  func aiImageDone(_ image: UIImage?, code: Int, errorMsg: String?) {
    var values: [String: Any] = ["message": code == 0 ? "图片已生成" : errorMsg ?? "图片生成失败（\(code)）"]
    if let png = image?.pngData() { values["resultImage"] = FlutterStandardTypedData(bytes: png) }
    if code != 0 { values["installing"] = false }
    update(values)
  }
  func aiPreviewDone(_ image: UIImage?, code: Int, errorMsg: String?) {
    var values: [String: Any] = ["message": code == 0 ? "预览已生成" : errorMsg ?? "预览生成失败（\(code)）"]
    if let png = image?.pngData() { values["previewImage"] = FlutterStandardTypedData(bytes: png) }
    if code != 0 { values["installing"] = false }
    update(values)
  }
  func aiStartSendingPreview() { update(["installing": true, "message": "正在发送预览…"]) }
  func aiSentPreview(_ code: Int, errorMsg: String?) {
    update(["installing": false, "message": code == 0 ? "预览已发送，请在手表上确认安装" : errorMsg ?? "预览发送失败（\(code)）"])
  }
  func aiStartSendingWatchface() { update(["installing": true, "progress": 0.0, "message": "正在安装 AI 表盘…"]) }
  func aiSendingWatchfaceProgressUpdated(_ progress: Float) {
    guard progress.isFinite else { return }
    update(["progress": min(1, max(0, Double(progress)))])
  }
  func aiSentWatchface(_ watchface: SlifiCustomWatchface?, code: Int, errorMsg: String?) {
    update(["installing": false, "progress": code == 0 ? 1.0 : 0.0, "message": code == 0 ? "AI 表盘安装成功" : errorMsg ?? "AI 表盘安装失败（\(code)）"])
  }
}
