import Flutter
import UIKit
import AVFoundation
import HwBluetoothSDK
import WatchfaceSDK
import Zip
import PhotosUI
import ImageIO
import eZIPSDK

private final class TransferEvents: NSObject, FlutterStreamHandler {
  var sink: FlutterEventSink?
  var state: [String: Any] = ["phase": "idle", "progress": 0.0]
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    events(state)
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? { sink = nil; return nil }
}

final class SifliTransferBridge: NSObject, UIDocumentPickerDelegate {
  private let sdk = HwBluetoothSDK.sharedInstance()
  private var pickerResult: FlutterResult?
  private weak var presenter: UIViewController?
  private var selectedRoot: URL?
  private var selectedFiles: [URL] = []
  private let musicEvents = TransferEvents()
  private let albumEvents = TransferEvents()
  private var activeKind = "music"
  private let preparationQueue = DispatchQueue(label: "sdkdemo.filePreparation", qos: .userInitiated)
  private var albumPickerResult: FlutterResult?
  private var albumRoot: URL?
  private var albumFiles: [URL] = []
  private var session: UUID?
  private var completion: FlutterResult?
  private var transferRoot: URL?
  private var transmitting = false
  private var initialized = false
  var busy: Bool { session != nil }

  func register(with registrar: FlutterPluginRegistrar) {
    presenter = registrar.viewController
    FlutterEventChannel(name: "sdkdemo/hw_ble/music", binaryMessenger: registrar.messenger())
      .setStreamHandler(musicEvents)
    FlutterEventChannel(name: "sdkdemo/hw_ble/album", binaryMessenger: registrar.messenger())
      .setStreamHandler(albumEvents)
  }

  private func error(_ code: String, _ message: String) -> FlutterError {
    FlutterError(code: code, message: message, details: nil)
  }

  private func emit(_ phase: String, progress: Double = 0) {
    let events = activeKind == "album" ? albumEvents : musicEvents
    events.state = ["phase": phase, "progress": progress]
    events.sink?(events.state)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAlbumFileIds":
      guard !busy else { result(error("BUSY", "文件正在传输")); return }
      readAlbumIds { value in
        switch value {
        case .success(let ids): result(ids)
        case .failure(let failure): result(self.error("ALBUM_IDS_ERROR", failure.localizedDescription))
        }
      }
    case "pickAlbumImages":
      if #available(iOS 14, *) { pickAlbum(result) }
      else { result(error("UNSUPPORTED", "选择照片需要 iOS 14 或以上")) }
    case "pushAlbumSifli": startAlbum(call.arguments as? [String: Any] ?? [:], result: result)
    case "cancelAlbumTransfer":
      if activeKind == "album" { cancel() }
      result(nil)
    case "getMusicStorage":
      guard sdk.connected() else { result(error("13", "请先连接手表")); return }
      guard !busy else { result(error("BUSY", "文件正在传输")); return }
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
      if activeKind == "music" { cancel() }
      result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func pick(_ result: @escaping FlutterResult) {
    guard !busy, pickerResult == nil, albumPickerResult == nil else { result(error("BUSY", "请等待当前操作完成")); return }
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
    preparationQueue.async {
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
    guard !selectedFiles.isEmpty else { result(error("NO_FILES", "请先选择 MP3 文件")); return }
    guard let (id, uuid) = begin(result, kind: "music") else { return }
    let files = selectedFiles
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("music-transfer-\(id.uuidString)")
    // Keep packaging outside the SDK's shared output path so cancellation cannot start a late transfer.
    preparationQueue.async {
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
        DispatchQueue.main.async { self.sendZip(zip, root: root, id: id, uuid: uuid, type: 4) }
      } catch {
        try? FileManager.default.removeItem(at: root)
        DispatchQueue.main.async { self.finish(id, failure: self.error("FILE_ERROR", error.localizedDescription)) }
      }
    }
  }

  private func begin(_ result: @escaping FlutterResult, kind: String) -> (UUID, String)? {
    guard sdk.connected(), let uuid = sdk.connectedDevice()?.peripheral?.identifier.uuidString else {
      result(error("13", "请先连接手表")); return nil
    }
    guard !busy, pickerResult == nil, albumPickerResult == nil, !SifliWatchfaceSDK.getInstance().isWorking else {
      result(error("BUSY", "已有文件操作进行中")); return nil
    }
    if !initialized {
      SifliWatchfaceSDK.getInstance().initSDK()
      initialized = true
    }
    let id = UUID()
    session = id
    completion = result
    activeKind = kind
    emit("preparing")
    return (id, uuid)
  }

  private func sendZip(_ zip: URL, root: URL, id: UUID, uuid: String, type: Int) {
    guard session == id else { try? FileManager.default.removeItem(at: root); return }
    guard sdk.connected(), sdk.connectedDevice()?.peripheral?.identifier.uuidString == uuid else {
      try? FileManager.default.removeItem(at: root)
      finish(id, failure: error("13", "连接已断开或设备已切换"))
      return
    }
    transferRoot = root
    transmitting = true
    emit("transferring")
    SifliWatchfaceSDK.getInstance().syncZipFile(
      devIdentifier: uuid, filePath: zip, type: type, byteAlign: true,
      progressCallback: { value in
        DispatchQueue.main.async {
          guard self.session == id else { return }
          self.emit("transferring", progress: min(1, max(0, Double(value) / 100)))
        }
      },
      finishCallback: { success, message, code, _ in
        DispatchQueue.main.async {
          self.finish(id, failure: success ? nil : self.error(String(code), message ?? "文件推送失败"))
        }
      })
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
    finish(id, failure: error("CANCELLED", "已取消推送"), cancelled: true)
  }

  func disconnected() {
    guard let id = session else { return }
    finish(id, failure: error("13", "连接断开，推送已停止"))
  }
}

extension SifliTransferBridge {
  private func readAlbumIds(_ callback: @escaping (Result<[Int], Error>) -> Void) {
    guard sdk.connected() else {
      callback(.failure(NSError(domain: "Album", code: 13, userInfo: [NSLocalizedDescriptionKey: "请先连接手表"])))
      return
    }
    sdk.getAlbumFilesIdList { raw, failure in
      DispatchQueue.main.async {
        if let failure = failure { callback(.failure(failure)); return }
        guard let raw = raw else {
          callback(.failure(NSError(domain: "Album", code: 1, userInfo: [NSLocalizedDescriptionKey: "未返回相册位置列表"])))
          return
        }
        var ids: [Int] = []
        for value in raw {
          guard let id = Int("\(value)") else {
            callback(.failure(NSError(domain: "Album", code: 2, userInfo: [NSLocalizedDescriptionKey: "相册位置数据无效"])))
            return
          }
          ids.append(id)
        }
        callback(.success(ids))
      }
    }
  }

  private func startAlbum(_ args: [String: Any], result: @escaping FlutterResult) {
    guard let width = args["width"] as? Int, let height = args["height"] as? Int,
          (1...4096).contains(width), (1...4096).contains(height) else {
      result(error("INVALID_SIZE", "宽高须为 1–4096 像素")); return
    }
    guard !albumFiles.isEmpty else { result(error("NO_IMAGES", "请先选择照片")); return }
    guard let (id, uuid) = begin(result, kind: "album") else { return }
    let files = albumFiles
    readAlbumIds { value in
      guard self.session == id else { return }
      switch value {
      case .failure(let failure): self.finish(id, failure: self.error("ALBUM_IDS_ERROR", failure.localizedDescription))
      case .success(let occupied):
        let used = Set(occupied)
        let indices = Array((1...50).filter { !used.contains($0) }.prefix(files.count))
        guard indices.count == files.count else {
          self.finish(id, failure: self.error("NO_SPACE", "相册剩余位置不足，需要 \(files.count) 个"))
          return
        }
        self.prepareAlbum(files, indices: indices, size: CGSize(width: width, height: height), id: id, uuid: uuid)
      }
    }
  }

  private func prepareAlbum(_ files: [URL], indices: [Int], size: CGSize, id: UUID, uuid: String) {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("album-transfer-\(id.uuidString)")
    preparationQueue.async {
      do {
        let directory = root.appendingPathComponent("music/photo")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (index, url) in files.enumerated() {
          try autoreleasepool {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 4096,
                  ] as CFDictionary) else {
              throw NSError(domain: "Album", code: 3, userInfo: [NSLocalizedDescriptionKey: "照片读取失败"])
            }
            let image = UIImage(cgImage: cgImage)
            let scale = max(size.width / image.size.width, size.height / image.size.height)
            let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let cropped = UIGraphicsImageRenderer(size: size, format: format).image { _ in
              image.draw(in: CGRect(x: (size.width - scaled.width) / 2, y: (size.height - scaled.height) / 2,
                                    width: scaled.width, height: scaled.height))
            }
            let thumbnailSize = CGSize(width: max(1, size.width / 3), height: max(1, size.height / 3))
            let preview = UIGraphicsImageRenderer(size: thumbnailSize, format: format).image { _ in
              cropped.draw(in: CGRect(origin: .zero, size: thumbnailSize))
            }
            for (prefix, bitmap) in [("PNG", cropped), ("PRE", preview)] {
              guard let png = bitmap.pngData(),
                    let data = ImageConvertor.eBin(fromPNGData: png, eColor: "rgb565", eType: 0, binType: 1, boardType: SFBoardType.type56X),
                    !data.isEmpty else {
                throw NSError(domain: "Album", code: 4, userInfo: [NSLocalizedDescriptionKey: "照片转换失败"])
              }
              try data.write(to: directory.appendingPathComponent("\(prefix)_\(indices[index]).bin"))
            }
          }
        }
        let zip = root.appendingPathComponent("photo.zip")
        try Zip.zipFiles(paths: [directory.deletingLastPathComponent()], zipFilePath: zip, password: nil, progress: nil)
        DispatchQueue.main.async { self.sendZip(zip, root: root, id: id, uuid: uuid, type: 3) }
      } catch {
        try? FileManager.default.removeItem(at: root)
        DispatchQueue.main.async { self.finish(id, failure: self.error("ALBUM_PREPARE_ERROR", error.localizedDescription)) }
      }
    }
  }
}

@available(iOS 14, *)
extension SifliTransferBridge: PHPickerViewControllerDelegate {
  private func pickAlbum(_ result: @escaping FlutterResult) {
    guard !busy, pickerResult == nil, albumPickerResult == nil else {
      result(error("BUSY", "请等待当前操作完成")); return
    }
    let currentPresenter = presenter ?? UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }.filter { $0.activationState == .foregroundActive }
      .flatMap { $0.windows }.first(where: { $0.isKeyWindow })?.rootViewController
    guard let presenter = currentPresenter, presenter.presentedViewController == nil else {
      result(error("PICKER_UNAVAILABLE", "无法打开照片选择器")); return
    }
    var config = PHPickerConfiguration()
    config.filter = .images
    config.selectionLimit = 10
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self
    albumPickerResult = result
    presenter.present(picker, animated: true)
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let result = albumPickerResult else { return }
    guard !results.isEmpty else { albumPickerResult = nil; result(nil); return }
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("album-selection-\(UUID().uuidString)")
    do { try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true) }
    catch { albumPickerResult = nil; result(self.error("FILE_ERROR", error.localizedDescription)); return }
    let group = DispatchGroup()
    let lock = NSLock()
    var files = Array<URL?>(repeating: nil, count: results.count)
    for (index, item) in results.enumerated() {
      group.enter()
      item.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.image") { url, _ in
        defer { group.leave() }
        guard let url = url else { return }
        let copy = root.appendingPathComponent("\(index).image")
        do {
          try FileManager.default.copyItem(at: url, to: copy)
          guard let source = CGImageSourceCreateWithURL(copy as CFURL, nil), CGImageSourceGetCount(source) > 0 else { return }
          lock.lock()
          files[index] = copy
          lock.unlock()
        } catch { return }
      }
    }
    group.notify(queue: .main) {
      self.albumPickerResult = nil
      guard files.allSatisfy({ $0 != nil }) else {
        try? FileManager.default.removeItem(at: root)
        result(self.error("IMAGE_ERROR", "部分照片无法读取，请重新选择；原选择已保留"))
        return
      }
      if let old = self.albumRoot { try? FileManager.default.removeItem(at: old) }
      self.albumRoot = root
      self.albumFiles = files.compactMap { $0 }
      result(self.albumFiles.count)
    }
  }
}
