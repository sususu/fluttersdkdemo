import Flutter
import UIKit
import AVFoundation
import HwBluetoothSDK
import WatchfaceSDK
import Zip

final class MusicTransferBridge: NSObject, FlutterStreamHandler, UIDocumentPickerDelegate {
  private let sdk = HwBluetoothSDK.sharedInstance()
  private var pickerResult: FlutterResult?
  private weak var presenter: UIViewController?
  private var selectedRoot: URL?
  private var selectedFiles: [URL] = []
  private var sink: FlutterEventSink?
  private var state: [String: Any] = ["phase": "idle", "progress": 0.0]
  private var session: UUID?
  private var completion: FlutterResult?
  private var transferRoot: URL?
  private var transmitting = false
  private var initialized = false
  var busy: Bool { session != nil }

  func register(with registrar: FlutterPluginRegistrar) {
    presenter = registrar.viewController
    FlutterEventChannel(name: "sdkdemo/hw_ble/music", binaryMessenger: registrar.messenger())
      .setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    events(state)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  private func error(_ code: String, _ message: String) -> FlutterError {
    FlutterError(code: code, message: message, details: nil)
  }

  private func emit(_ phase: String, progress: Double = 0) {
    state = ["phase": phase, "progress": progress]
    sink?(state)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getMusicStorage":
      guard sdk.connected() else { result(error("13", "请先连接手表")); return }
      guard !busy else { result(error("BUSY", "音乐正在传输")); return }
      sdk.getMusicAvailableStorage { available, total, failure in
        DispatchQueue.main.async {
          if let failure = failure {
            result(self.error(String((failure as NSError).code), failure.localizedDescription))
          } else {
            result(["availableKb": available, "totalKb": total])
          }
        }
      }
    case "pickMusicFiles": pick(result)
    case "pushMusicSifli": start(result)
    case "cancelMusicTransfer":
      cancel()
      result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func pick(_ result: @escaping FlutterResult) {
    guard !busy, pickerResult == nil else { result(error("BUSY", "请等待当前操作完成")); return }
    let currentPresenter = presenter ?? UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
      .flatMap { $0.windows }.first(where: { $0.isKeyWindow })?.rootViewController
    guard let presenter = currentPresenter, presenter.presentedViewController == nil else {
      result(error("PICKER_UNAVAILABLE", "无法打开文件选择器")); return
    }
    let picker = UIDocumentPickerViewController(documentTypes: ["public.mp3"], in: .import)
    picker.allowsMultipleSelection = true
    picker.delegate = self
    pickerResult = result
    presenter.present(picker, animated: true)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pickerResult
    pickerResult = nil
    result?(nil)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pickerResult else { return }
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("music-selection-\(UUID().uuidString)")
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        guard !urls.isEmpty else { throw NSError(domain: "Music", code: 1, userInfo: [NSLocalizedDescriptionKey: "未选择 MP3 文件"]) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var files: [URL] = []
        var rows: [[String: Any]] = []
        for (index, url) in urls.enumerated() {
          let access = url.startAccessingSecurityScopedResource()
          defer { if access { url.stopAccessingSecurityScopedResource() } }
          guard url.pathExtension.lowercased() == "mp3" else {
            throw NSError(domain: "Music", code: 2, userInfo: [NSLocalizedDescriptionKey: "请选择 MP3 文件"])
          }
          let folder = root.appendingPathComponent(String(index))
          try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
          let copy = folder.appendingPathComponent(url.lastPathComponent)
          try FileManager.default.copyItem(at: url, to: copy)
          let size = try copy.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
          guard size > 0, !AVURLAsset(url: copy).tracks(withMediaType: .audio).isEmpty else {
            throw NSError(domain: "Music", code: 3, userInfo: [NSLocalizedDescriptionKey: "文件为空或无法读取音频：\(url.lastPathComponent)"])
          }
          files.append(copy)
          rows.append(["name": url.lastPathComponent, "sizeBytes": size])
        }
        DispatchQueue.main.async {
          if let old = self.selectedRoot { try? FileManager.default.removeItem(at: old) }
          self.selectedRoot = root
          self.selectedFiles = files
          self.pickerResult = nil
          result(rows)
        }
      } catch {
        try? FileManager.default.removeItem(at: root)
        DispatchQueue.main.async {
          self.pickerResult = nil
          result(self.error("FILE_ERROR", error.localizedDescription))
        }
      }
    }
  }

  private func start(_ result: @escaping FlutterResult) {
    guard sdk.connected(), let uuid = sdk.connectedDevice()?.peripheral?.identifier.uuidString else {
      result(error("13", "请先连接手表")); return
    }
    guard !busy, pickerResult == nil, !SifliWatchfaceSDK.getInstance().isWorking else {
      result(error("BUSY", "已有文件操作进行中")); return
    }
    guard !selectedFiles.isEmpty else { result(error("NO_FILES", "请先选择 MP3 文件")); return }
    if !initialized {
      SifliWatchfaceSDK.getInstance().initSDK()
      initialized = true
    }
    let id = UUID()
    session = id
    completion = result
    emit("preparing")
    let files = selectedFiles
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("music-transfer-\(id.uuidString)")
    // Keep packaging outside the SDK's shared output path so cancellation cannot start a late transfer.
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let directory = root.appendingPathComponent("music/mp3")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var names = Set<String>()
        for file in files {
          let raw = file.deletingPathExtension().lastPathComponent
          let cleaned = raw.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
          let base = cleaned.isEmpty ? "music" : cleaned
          var name = base + ".mp3"
          var suffix = 2
          while names.contains(name.lowercased()) {
            name = "\(base)\(suffix).mp3"
            suffix += 1
          }
          names.insert(name.lowercased())
          try FileManager.default.copyItem(at: file, to: directory.appendingPathComponent(name))
        }
        let zip = root.appendingPathComponent("music.zip")
        try Zip.zipFiles(paths: [directory.deletingLastPathComponent()], zipFilePath: zip, password: nil, progress: nil)
        DispatchQueue.main.async {
          guard self.session == id else { try? FileManager.default.removeItem(at: root); return }
          guard self.sdk.connected(), self.sdk.connectedDevice()?.peripheral?.identifier.uuidString == uuid else {
            try? FileManager.default.removeItem(at: root)
            self.finish(id, failure: self.error("13", "连接已断开或设备已切换"))
            return
          }
          self.transferRoot = root
          self.transmitting = true
          self.emit("transferring")
          // Same music transfer type and byte alignment used by setMusicFiles.
          SifliWatchfaceSDK.getInstance().syncZipFile(
            devIdentifier: uuid, filePath: zip, type: 4, byteAlign: true,
            progressCallback: { value in
              DispatchQueue.main.async {
                guard self.session == id else { return }
                self.emit("transferring", progress: min(1, max(0, Double(value) / 100)))
              }
            },
            finishCallback: { success, message, code, _ in
              DispatchQueue.main.async {
                self.finish(id, failure: success ? nil : self.error(String(code), message ?? "音乐推送失败"))
              }
            })
        }
      } catch {
        try? FileManager.default.removeItem(at: root)
        DispatchQueue.main.async { self.finish(id, failure: self.error("FILE_ERROR", error.localizedDescription)) }
      }
    }
  }

  private func finish(_ id: UUID, failure: FlutterError?, cancelled: Bool = false) {
    guard session == id else { return }
    session = nil
    let result = completion
    completion = nil
    if transmitting { SifliWatchfaceSDK.getInstance().stop() }
    transmitting = false
    if let root = transferRoot { try? FileManager.default.removeItem(at: root) }
    transferRoot = nil
    emit(cancelled ? "cancelled" : failure == nil ? "completed" : "failed", progress: failure == nil ? 1 : 0)
    result?(failure)
  }

  func cancel() {
    guard let id = session else { return }
    finish(id, failure: error("CANCELLED", "已取消音乐推送"), cancelled: true)
  }

  func disconnected() {
    guard let id = session else { return }
    finish(id, failure: error("13", "连接断开，音乐推送已停止"))
  }
}
