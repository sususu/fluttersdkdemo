import Flutter
import UIKit
import AVFoundation
import HwBluetoothSDK
import WatchfaceSDK
import Zip
import PhotosUI
import ImageIO
import eZIPSDK
import CryptoKit

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
  private let agpsEvents = TransferEvents()
  private let watchfaceEvents = TransferEvents()
  private let customEvents = TransferEvents()
  private var customPackaging = false
  private var customFace: SlifiCustomWatchface?
  private var pickingCustomBackground = false
  private var watchfaceTask: URLSessionTask?
  private var watchfaceProgress: NSKeyValueObservation?
  private var watchfaceCatalog: [[String: Any]] = []
  private var catalogDevice = ""
  private var agpsDownload: URLSessionDataTask?
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
  private var jieli = false
  var busy: Bool { session != nil || customPackaging }

  func register(with registrar: FlutterPluginRegistrar) {
    FlutterEventChannel(name: "sdkdemo/hw_ble/agps", binaryMessenger: registrar.messenger())
      .setStreamHandler(agpsEvents)
    FlutterEventChannel(name: "sdkdemo/hw_ble/watchface", binaryMessenger: registrar.messenger())
      .setStreamHandler(watchfaceEvents)
    FlutterEventChannel(name: "sdkdemo/hw_ble/customWatchface", binaryMessenger: registrar.messenger())
      .setStreamHandler(customEvents)
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
    let events = activeKind == "custom" ? customEvents : activeKind == "watchface" ? watchfaceEvents : activeKind == "agps" ? agpsEvents : activeKind == "album" ? albumEvents : musicEvents
    let progress = activeKind == "agps" && phase == "transferring" ? 0.5 + progress * 0.5 : progress
    let mapped = activeKind == "watchface" && phase == "transferring" ? 0.4 + progress * 0.6 : progress
    events.state = ["phase": phase, "progress": mapped]
    events.sink?(events.state)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickCustomWatchfaceBackground":
      if #available(iOS 14, *) { pickAlbum(result, custom: true) }
      else { result(error("UNSUPPORTED", "选择照片需要 iOS 14 或以上")) }
    case "previewCustomWatchface":
      do {
        let args = call.arguments as? [String: Any] ?? [:]
        let png: Data
        if args["jieli"] as? Bool == true {
          guard let data = try JieliWatchface.make(args).preview.pngData() else {
            result(error("CUSTOM_PREVIEW", "无法生成表盘预览")); return
          }
          png = data
        }
        else { (_, png) = try CustomWatchface.make(args) }
        result(FlutterStandardTypedData(bytes: png))
      } catch { result(self.error("CUSTOM_CONFIG", error.localizedDescription)) }
    case "pushCustomWatchface": startCustomWatchface(call.arguments as? [String: Any] ?? [:], result: result)
    case "getOnlineWatchfaces": loadWatchfaceCatalog(result, jieli: (call.arguments as? [String: Any])?["jieli"] as? Bool == true)
    case "installOnlineWatchface": installWatchface(call.arguments as? [String: Any] ?? [:], result: result)
    case "cancelWatchfaceTransfer":
      if ["watchface", "custom"].contains(activeKind) { cancel() }
      result(nil)
    case "getDeviceGpsStatus":
      guard sdk.connected() else { result(error("13", "请先连接手表")); return }
      sdk.getDeviceGpsStatus { status, failure in
        DispatchQueue.main.async {
          if let failure = failure { result(self.error("GPS_STATUS", failure.localizedDescription)); return }
          guard let status = status else { result(self.error("GPS_STATUS", "未返回 GPS 状态")); return }
          func millis(_ value: Int64) -> Int64 { value > 0 && value < 10_000_000_000 ? value * 1000 : value }
          result(["gpsClipType": status.gpsClipType ?? "",
                  "gpsFirmwareVersion": status.gpsFirmwareVersion ?? "",
                  "gpsFirmwareBuild": Int(status.gpsFirmwareBuild),
                  "agpsValidStartTimeMs": millis(Int64(status.agpsValidStartTime)),
                  "agpsValidEndTimeMs": millis(Int64(status.agpsValidEndTime))])
        }
      }
    case "updateAgps":
      guard let (id, uuid) = begin(result, kind: "agps") else { return }
      downloadAgps(id: id, uuid: uuid)
    case "cancelAgpsUpdate":
      if activeKind == "agps" { cancel() }
      result(nil)
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

  private func begin(_ result: @escaping FlutterResult, kind: String, jieli: Bool = false) -> (UUID, String)? {
    guard sdk.connected(), let uuid = sdk.connectedDevice()?.peripheral?.identifier.uuidString else {
      result(error("13", "请先连接手表")); return nil
    }
    guard !busy, pickerResult == nil, albumPickerResult == nil, !SifliWatchfaceSDK.getInstance().isWorking else {
      result(error("BUSY", "已有文件操作进行中")); return nil
    }
    guard sdk.multipleFileTransferService?.isRunning != true else { result(error("BUSY", "杰里文件正在传输")); return nil }
    self.jieli = jieli
    if !jieli && !initialized {
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

  private func sendZip(_ zip: URL, root: URL, id: UUID, uuid: String, type: Int, byteAlign: Bool = true) {
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
      devIdentifier: uuid, filePath: zip, type: type, byteAlign: byteAlign,
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

  private func finish(_ id: UUID, failure: FlutterError?, cancelled: Bool = false, value: Any? = nil) {
    guard session == id else { return }
    session = nil
    watchfaceTask?.cancel()
    watchfaceTask = nil
    watchfaceProgress = nil
    agpsDownload?.cancel()
    agpsDownload = nil
    let result = completion
    completion = nil
    if transmitting {
      if jieli { sdk.multipleFileTransferService?.stop() }
      else { SifliWatchfaceSDK.getInstance().stop() }
    }
    transmitting = false
    if let root = transferRoot { try? FileManager.default.removeItem(at: root) }
    transferRoot = nil
    emit(cancelled ? "cancelled" : failure == nil ? "completed" : "failed", progress: failure == nil ? 1 : 0)
    result?(failure ?? value)
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
  private func pickAlbum(_ result: @escaping FlutterResult, custom: Bool = false) {
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
    config.selectionLimit = custom ? 1 : 10
    pickingCustomBackground = custom
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self
    albumPickerResult = result
    presenter.present(picker, animated: true)
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let result = albumPickerResult else { return }
    guard !results.isEmpty else { albumPickerResult = nil; result(nil); return }
    if pickingCustomBackground {
      results[0].itemProvider.loadFileRepresentation(forTypeIdentifier: "public.image") { url, failure in
        var png: Data?
        if let url = url, let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
             kCGImageSourceCreateThumbnailFromImageAlways: true,
             kCGImageSourceCreateThumbnailWithTransform: true,
             kCGImageSourceThumbnailMaxPixelSize: 2048,
           ] as CFDictionary) { png = UIImage(cgImage: image).pngData() }
        DispatchQueue.main.async {
          self.albumPickerResult = nil
          if let png = png { result(FlutterStandardTypedData(bytes: png)) }
          else { result(self.error("IMAGE_ERROR", failure?.localizedDescription ?? "背景图片无法读取")) }
        }
      }
      return
    }
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


extension SifliTransferBridge {
  private func downloadAgps(id: UUID, uuid: String, entries: [(String, Data)] = [],
                            start: Int64 = 0, end: Int64 = Int64.max, attempt: Int = 0) {
    guard session == id else { return }
    guard entries.count < AgpsPackage.names.count else {
      guard start < end, end > Int64(Date().timeIntervalSince1970) else {
        finish(id, failure: error("AGPS_EXPIRED", "星历已过期或有效期不一致")); return
      }
      let root = FileManager.default.temporaryDirectory.appendingPathComponent("agps-\(id.uuidString)")
      preparationQueue.async {
        do {
          try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
          let zip = root.appendingPathComponent("agps.zip")
          try AgpsPackage.buildStoreZip(entries: entries).write(to: zip)
          DispatchQueue.main.async { self.sendZip(zip, root: root, id: id, uuid: uuid, type: 3) }
        } catch {
          try? FileManager.default.removeItem(at: root)
          DispatchQueue.main.async { self.finish(id, failure: self.error("AGPS_PACKAGE", error.localizedDescription)) }
        }
      }
      return
    }
    emit("preparing", progress: Double(entries.count) / 10)
    let name = AgpsPackage.names[entries.count]
    let url = URL(string: "https://starcourse.rx-networks.cn/IYMx9qGm7H/\(name)?t=\(Int(Date().timeIntervalSince1970 * 1000))")!
    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
    agpsDownload = URLSession.shared.dataTask(with: request) { data, response, failure in
      DispatchQueue.main.async {
        guard self.session == id else { return }
        self.agpsDownload = nil
        do {
          if let failure = failure { throw failure }
          guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), let data = data else {
            throw NSError(domain: "AGPS", code: 3, userInfo: [NSLocalizedDescriptionKey: "星历下载失败：\(name)"])
          }
          let file = try AgpsPackage.process(data)
          self.downloadAgps(id: id, uuid: uuid, entries: entries + [("music/gps/agps/" + name, file.data)],
                            start: max(start, file.start), end: min(end, file.end))
        } catch {
          if attempt < 2 {
            self.downloadAgps(id: id, uuid: uuid, entries: entries, start: start, end: end, attempt: attempt + 1)
          } else { self.finish(id, failure: self.error("AGPS_DOWNLOAD", error.localizedDescription)) }
        }
      }
    }
    agpsDownload?.resume()
  }
}

extension SifliTransferBridge {
  private func loadWatchfaceCatalog(_ result: @escaping FlutterResult, jieli: Bool) {
    guard let (id, uuid) = begin(result, kind: "watchface", jieli: jieli) else { return }
    watchfaceCatalog = []; catalogDevice = ""
    watchfaceQueryTimeout(id)
    sdk.getDeviceInfo { info, failure in
      DispatchQueue.main.async {
        guard self.session == id else { return }
        if let failure = failure { self.finish(id, failure: self.error("DEVICE_INFO", failure.localizedDescription)); return }
        guard let type = info?.type.trimmingCharacters(in: .whitespacesAndNewlines), !type.isEmpty,
              let encoded = type.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
          self.finish(id, failure: self.error("DEVICE_TYPE", "未获取到设备型号")); return
        }
        var components = URLComponents(string: "https://test.huawo-wear.com/api/v1/products/\(encoded)/watchfaces")!
        components.queryItems = [URLQueryItem(name: "customerCode", value: "Huawo"),
          URLQueryItem(name: "locale", value: Locale.preferredLanguages.first?.hasPrefix("zh") == true ? "zh-Hans" : "en")]
        var request = URLRequest(url: components.url!, timeoutInterval: 30)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Bundle.main.bundleIdentifier, forHTTPHeaderField: "appId")
        request.setValue(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", forHTTPHeaderField: "appVersion")
        self.watchfaceTask = URLSession.shared.dataTask(with: request) { data, response, failure in
          DispatchQueue.main.async {
            guard self.session == id else { return }
            do {
              if let failure = failure { throw failure }
              guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), let data = data else {
                throw NSError(domain: "Watchface", code: 1, userInfo: [NSLocalizedDescriptionKey: "表盘列表请求失败"])
              }
              guard self.sdk.connected(), self.sdk.connectedDevice()?.peripheral?.identifier.uuidString == uuid else {
                throw NSError(domain: "Watchface", code: 2, userInfo: [NSLocalizedDescriptionKey: "设备连接已变化，请刷新列表"])
              }
              let rows = try WatchfaceCatalog.parse(data)
              self.watchfaceCatalog = rows
              self.catalogDevice = uuid
              self.finish(id, failure: nil, value: rows)
            } catch { self.finish(id, failure: self.error("WATCHFACE_LIST", error.localizedDescription)) }
          }
        }
        self.watchfaceTask?.resume()
      }
    }
  }

  private func watchfaceQueryTimeout(_ id: UUID) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 35) {
      guard self.session == id, self.watchfaceTask == nil, !self.transmitting, !self.customPackaging else { return }
      self.finish(id, failure: self.error("TIMEOUT", "设备响应超时"))
    }
  }

  private func installWatchface(_ arguments: [String: Any], result: @escaping FlutterResult) {
    guard let itemId = arguments["id"] as? String,
          let item = watchfaceCatalog.first(where: { $0["id"] as? String == itemId }),
          sdk.connectedDevice()?.peripheral?.identifier.uuidString == catalogDevice else {
      result(error("WATCHFACE_ITEM", "请刷新表盘列表后重新选择")); return
    }
    guard let (id, uuid) = begin(result, kind: "watchface", jieli: arguments["jieli"] as? Bool == true) else { return }
    if jieli { downloadWatchface(item, id: id, uuid: uuid); return }
    watchfaceQueryTimeout(id)
    emit("checking")
    sdk.getSifliInstalledWatchfaceNames { list, failure in
      DispatchQueue.main.async {
        guard self.session == id else { return }
        let names = failure == nil ? (list as? [String] ?? []) : []
        let name = item["name"] as? String ?? ""
        if let hit = WatchfaceCatalog.installedMatch(name: name, installed: names) {
          self.emit("switching")
          self.sdk.setSifliDisplayingWatchfaceName(hit) { success, failure in
            DispatchQueue.main.async {
              guard self.session == id else { return }
              if success && failure == nil { self.finish(id, failure: nil) }
              else { self.downloadWatchface(item, id: id, uuid: uuid) }
            }
          }
        } else { self.downloadWatchface(item, id: id, uuid: uuid) }
      }
    }
  }

  private func downloadWatchface(_ item: [String: Any], id: UUID, uuid: String) {
    guard let path = item["bin"] as? String, let url = WatchfaceCatalog.fileURL(path) else {
      finish(id, failure: error("WATCHFACE_FILE", "表盘下载地址无效")); return
    }
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("watchface-\(id.uuidString)")
    do { try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true) }
    catch { finish(id, failure: self.error("FILE_ERROR", error.localizedDescription)); return }
    transferRoot = root
    let zip = root.appendingPathComponent("watchface.zip")
    emit("downloading")
    let isJieli = jieli
    let task = URLSession.shared.downloadTask(with: URLRequest(url: url, timeoutInterval: 120)) { location, response, failure in
      var downloadError = failure
      do {
        if let failure = failure { throw failure }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), let location = location else {
          throw NSError(domain: "Watchface", code: 1, userInfo: [NSLocalizedDescriptionKey: "表盘下载失败"])
        }
        try FileManager.default.moveItem(at: location, to: zip)
        let data = try Data(contentsOf: zip, options: .mappedIfSafe)
        guard !data.isEmpty, isJieli || (data.count >= 4 && data.prefix(4) == Data([0x50, 0x4b, 0x03, 0x04])) else {
          throw NSError(domain: "Watchface", code: 2, userInfo: [NSLocalizedDescriptionKey: "表盘文件不是有效的 ZIP 包"])
        }
        if let expected = item["binMd5"] as? String, !expected.isEmpty {
          let actual = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
          guard expected.caseInsensitiveCompare(actual) == .orderedSame else {
            throw NSError(domain: "Watchface", code: 3, userInfo: [NSLocalizedDescriptionKey: "表盘 MD5 校验失败"])
          }
        }
      } catch { downloadError = error }
      DispatchQueue.main.async {
        guard self.session == id else { try? FileManager.default.removeItem(at: root); return }
        self.watchfaceTask = nil; self.watchfaceProgress = nil
        if let failure = downloadError { self.finish(id, failure: self.error("WATCHFACE_DOWNLOAD", failure.localizedDescription)); return }
        if isJieli {
          do {
            let model = HwMultipleFileTransferModel()
            model.fileName = item["name"] as? String ?? "dial"
            model.fileData = try Data(contentsOf: zip)
            self.sendJieli([model], config: nil, id: id, uuid: uuid)
          } catch { self.finish(id, failure: self.error("WATCHFACE_FILE", error.localizedDescription)) }
          return
        }
        // Online packages require type 5 with no byte alignment, unlike custom dials.
        self.sendZip(zip, root: root, id: id, uuid: uuid, type: 5, byteAlign: false)
      }
    }
    watchfaceTask = task
    watchfaceProgress = task.progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
      let fraction = progress.fractionCompleted
      DispatchQueue.main.async {
        guard self.session == id, !self.transmitting else { return }
        self.emit("downloading", progress: min(1, max(0, fraction)) * 0.4)
      }
    }
    task.resume()
  }
}


extension SifliTransferBridge {
  private func startCustomWatchface(_ args: [String: Any], result: @escaping FlutterResult) {
    if args["jieli"] as? Bool == true { startJieliCustom(args, result: result); return }
    let face: SlifiCustomWatchface
    do { (face, _) = try CustomWatchface.make(args) }
    catch { result(self.error("CUSTOM_CONFIG", error.localizedDescription)); return }
    guard let (id, uuid) = begin(result, kind: "custom") else { return }
    customPackaging = true
    customFace = face
    // The SDK uses a shared packaging directory. Keep it locked until its callback,
    // even after cancellation, then copy the ZIP before releasing that directory.
    face.makeZip { url, failure in
      DispatchQueue.main.async {
        self.customPackaging = false
        self.customFace = nil
        guard self.session == id else { return }
        guard failure == nil, let url = url else {
          self.finish(id, failure: self.error("CUSTOM_PACKAGE", "表盘打包失败：\(String(describing: failure))")); return
        }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("custom-watchface-\(id.uuidString)")
        do {
          try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
          let zip = root.appendingPathComponent("custom.zip")
          try FileManager.default.copyItem(at: url, to: zip)
          self.sendZip(zip, root: root, id: id, uuid: uuid, type: 5, byteAlign: true)
        } catch {
          try? FileManager.default.removeItem(at: root)
          self.finish(id, failure: self.error("CUSTOM_PACKAGE", error.localizedDescription))
        }
      }
    }
  }
}

extension SifliTransferBridge {
  private func startJieliCustom(_ args: [String: Any], result: @escaping FlutterResult) {
    let face: JieliWatchface
    do { face = try JieliWatchface.make(args) }
    catch { result(self.error("CUSTOM_CONFIG", error.localizedDescription)); return }
    guard let (id, uuid) = begin(result, kind: "custom", jieli: true) else { return }
    watchfaceQueryTimeout(id)
    sdk.getCoustomInterfaceAvailableStorage { storage, failure in
      DispatchQueue.main.async {
        guard self.session == id else { return }
        if let failure = failure { self.finish(id, failure: self.error("STORAGE", failure.localizedDescription)); return }
        let maximum = min(8, max(1, (storage * 1024 - 100 * 1024 - 70_800) / 220_128))
        guard face.backgrounds.count <= maximum else { self.finish(id, failure: self.error("NO_SPACE", "当前设备最多支持 \(maximum) 张背景")); return }
        self.customPackaging = true
        self.preparationQueue.async {
          let output = Result { try face.files() }
          DispatchQueue.main.async {
            self.customPackaging = false
            guard self.session == id else { return }
            switch output {
            case .success(let files): self.sendJieli(files, config: face.config, id: id, uuid: uuid)
            case .failure(let failure): self.finish(id, failure: self.error("CUSTOM_PACKAGE", failure.localizedDescription))
            }
          }
        }
      }
    }
  }

  private func sendJieli(_ files: [HwMultipleFileTransferModel], config: HwJLWatchFaceConfigModel?, id: UUID, uuid: String) {
    guard session == id else { return }
    guard sdk.connected(), sdk.connectedDevice()?.peripheral?.identifier.uuidString == uuid,
          let service = sdk.multipleFileTransferService, !service.isRunning else {
      finish(id, failure: error("TRANSFER_UNAVAILABLE", "连接已变化或传输通道忙碌")); return
    }
    transmitting = true
    emit("transferring")
    service.start(withFileModels: files, transferType: config == nil ? .onlineDial : .customDialImage,
      readyCallback: { ok, failure in
        DispatchQueue.main.async {
          guard self.session == id else { return }
          if failure != nil || !ok { self.finish(id, failure: self.error("TRANSFER_READY", failure?.localizedDescription ?? "设备未就绪")) }
        }
      }, progressCallback: { value, failure in
        DispatchQueue.main.async {
          guard self.session == id else { return }
          if let failure = failure { self.finish(id, failure: self.error("TRANSFER", failure.localizedDescription)); return }
          guard value.isFinite else { return }
          self.emit("transferring", progress: min(1, max(0, Double(value))))
        }
      }, finishCallback: { ok, failure in
        DispatchQueue.main.async {
          guard self.session == id else { return }
          guard ok, failure == nil else { self.finish(id, failure: self.error("TRANSFER", failure?.localizedDescription ?? "表盘传输失败")); return }
          guard let config = config else { self.finish(id, failure: nil); return }
          guard let center = HwBluetoothCenter.sharedInstance() else { self.finish(id, failure: self.error("CONFIG", "蓝牙服务不可用")); return }
          self.emit("configuring", progress: 1)
          DispatchQueue.main.asyncAfter(deadline: .now()+30) {
            self.finish(id, failure: self.error("TIMEOUT", "表盘配置响应超时"))
          }
          center.updateJLCustomWatceFace(config) { success, error in
            DispatchQueue.main.async {
              self.finish(id, failure: success && error == nil ? nil : self.error("CONFIG", error?.localizedDescription ?? "表盘配置失败"))
            }
          }
        }
      })
  }
}
