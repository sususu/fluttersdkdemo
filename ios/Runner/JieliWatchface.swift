import UIKit
import Flutter
import ImageIO
import HwBluetoothSDK
import JLBmpConvertKit

struct JieliWatchface {
  let backgrounds: [UIImage]
  let preview: UIImage
  let thumbnail: UIImage
  let config: HwJLWatchFaceConfigModel

  static func make(_ args: [String: Any]) throws -> JieliWatchface {
    func invalid(_ text: String) -> NSError { NSError(domain: "JieliWatchface", code: 1, userInfo: [NSLocalizedDescriptionKey: text]) }
    guard let w = args["width"] as? Int, let h = args["height"] as? Int,
          let tw = args["thumbWidth"] as? Int, let th = args["thumbHeight"] as? Int,
          [w,h,tw,th].allSatisfy({ (64...1024).contains($0) }),
          let r = args["corner"] as? Int, (0...min(w,h)/2).contains(r),
          let tr = args["thumbCorner"] as? Int, (0...min(tw,th)/2).contains(tr),
          let mode = args["displayMode"] as? Int, (0...2).contains(mode),
          let pointer = args["pointerStyle"] as? Int, (0...3).contains(pointer),
          let slots = args["components"] as? [Int], slots.count == 4, slots.allSatisfy({ (0...8).contains($0) }),
          let hex = args["color"] as? String, hex.range(of: "^[0-9A-Fa-f]{6}$", options: .regularExpression) != nil,
          let rgb = UInt32(hex, radix: 16) else { throw invalid("表盘尺寸或布局配置无效") }
    let bytes = args["backgrounds"] as? [FlutterStandardTypedData] ?? []
    guard bytes.count <= 8, bytes.allSatisfy({ $0.data.count <= 10_000_000 }) else { throw invalid("最多选择 8 张背景，每张不超过 10 MB") }
    let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
    func render(_ image: UIImage?, size: CGSize, corner: CGFloat) -> UIImage {
      UIGraphicsImageRenderer(size: size, format: format).image { ctx in
        UIColor.black.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: corner).addClip()
        if let image = image {
          let scale = max(size.width/image.size.width, size.height/image.size.height)
          let width = image.size.width*scale, height = image.size.height*scale
          image.draw(in: CGRect(x: (size.width-width)/2, y: (size.height-height)/2, width: width, height: height))
        }
      }
    }
    let size = CGSize(width: w, height: h)
    var backgrounds = try bytes.map { bytes -> UIImage in
      guard let source = CGImageSourceCreateWithData(bytes.data as CFData, nil),
            let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [
              kCGImageSourceCreateThumbnailFromImageAlways: true,
              kCGImageSourceCreateThumbnailWithTransform: true,
              kCGImageSourceThumbnailMaxPixelSize: 2048,
            ] as CFDictionary) else { throw invalid("背景图片无法读取") }
      let image = UIImage(cgImage: cg)
      return render(image, size: size, corner: CGFloat(r))
    }
    if backgrounds.isEmpty { backgrounds = [render(nil, size: size, corner: CGFloat(r))] }
    guard let cover = args["cover"] as? Int, backgrounds.indices.contains(cover) else { throw invalid("封面序号无效") }
    let config = HwJLWatchFaceConfigModel()
    switch mode {
    case 1: config.displayModeType = .displayModeType_QueueShow
    case 2: config.displayModeType = .displayModeType_RandomShow
    default: config.displayModeType = .displayModeType_SingleImage
    }
    config.imageCount = backgrounds.count; config.coverImageIndex = Int32(cover)
    config.pointerStyle = Int32(pointer); config.rgbColorStr = hex
    var y: CGFloat = 52
    let x: CGFloat = w == h && r*2 >= min(w,h) ? 121 : 100
    let labels = ["", "10:08", "心率 72", "步数 8888", "热量 300", "电量 80%", "晴 26°", "距离 5.0", "09/11"]
    var placements: [(Int, CGRect)] = []
    config.compentArr = slots.filter { $0 != 0 }.map { type in
      let c = HwJLWatchFaceConfigCompentModel()
      switch type {
      case 1: c.compentType = .componentType_Time
      case 2: c.compentType = .componentType_HeartRate
      case 3: c.compentType = .componentType_Steps
      case 4: c.compentType = .componentType_Calories
      case 5: c.compentType = .componentType_Battery
      case 6: c.compentType = .componentType_Weather
      case 7: c.compentType = .componentType_Distance
      default: c.compentType = .componentType_Date
      }
      c.position = CGPoint(x: x, y: y)
      let height: CGFloat = type == 1 ? 109 : 28
      placements.append((type, CGRect(x: x, y: y, width: 212, height: height)))
      y += height + 14
      return c
    }
    let tint = UIColor(red: CGFloat((rgb >> 16)&255)/255, green: CGFloat((rgb >> 8)&255)/255, blue: CGFloat(rgb&255)/255, alpha: 1)
    let preview = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
      backgrounds[cover].draw(at: .zero)
      UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: CGFloat(r)).addClip()
      for (type, rect) in placements {
        (labels[type] as NSString).draw(in: rect, withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: type == 1 ? 64 : 24, weight: .medium), .foregroundColor: tint])
      }
      if pointer != 0 {
        let c = ctx.cgContext; c.setStrokeColor(tint.cgColor); c.setLineWidth(CGFloat(pointer+2)); c.setLineCap(.round)
        c.move(to: CGPoint(x: w/2-45, y: h/2-55)); c.addLine(to: CGPoint(x: w/2,y: h/2)); c.addLine(to: CGPoint(x: w/2+65,y: h/2-70)); c.strokePath()
      }
    }
    return JieliWatchface(backgrounds: backgrounds, preview: preview,
      thumbnail: render(preview, size: CGSize(width: tw,height: th), corner: CGFloat(tr)), config: config)
  }

  func files() throws -> [HwMultipleFileTransferModel] {
    try (backgrounds.enumerated().map { ("bg\($0.offset+1)", $0.element) } + [("pw", thumbnail)]).map { name, image in
      let option = JLBmpConvertOption(); option.convertType = .type707N_ARGB; option.pixelformat = ._Auto
      guard let jpeg = image.jpegData(compressionQuality: 1),
            let data = JLBmpConvert.convert(option, imageData: jpeg).outFileData, !data.isEmpty else {
        throw NSError(domain: "JieliWatchface", code: 2, userInfo: [NSLocalizedDescriptionKey: "杰里图片转换失败"])
      }
      let model = HwMultipleFileTransferModel(); model.fileName = name; model.fileData = data
      return model
    }
  }
}
