import UIKit
import Flutter
import WatchfaceSDK
import ImageIO

// Shared by preview and packaging so thumbnail geometry follows the editor.
enum CustomWatchface {
  static func make(_ args: [String: Any]) throws -> (SlifiCustomWatchface, Data) {
    func invalid(_ message: String) -> NSError {
      NSError(domain: "CustomWatchface", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
    guard let w = args["width"] as? Int, let h = args["height"] as? Int,
          let tw = args["thumbWidth"] as? Int, let th = args["thumbHeight"] as? Int,
          [w, h, tw, th].allSatisfy({ (64...1024).contains($0) }),
          let corner = args["corner"] as? Int, (0...min(w, h) / 2).contains(corner),
          let tc = args["thumbCorner"] as? Int, (0...min(tw, th) / 2).contains(tc) else {
      throw invalid("宽高须为 64–1024 像素，圆角不能超过短边的一半")
    }
    let name = (args["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard name.range(of: "^[A-Za-z][A-Za-z0-9_]{0,31}$", options: .regularExpression) != nil else {
      throw invalid("名称须以英文字母开头，限 32 位字母、数字或下划线")
    }
    let face = SlifiCustomWatchface(width: w, height: h)
    face.name = name
    let size = CGSize(width: w, height: h)
    let format = UIGraphicsImageRendererFormat(); format.scale = 1
    var background: UIImage?
    if let bytes = args["background"] as? FlutterStandardTypedData {
      guard bytes.data.count <= 10_000_000,
            let source = CGImageSourceCreateWithData(bytes.data as CFData, nil),
            let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [
              kCGImageSourceCreateThumbnailFromImageAlways: true,
              kCGImageSourceCreateThumbnailWithTransform: true,
              kCGImageSourceThumbnailMaxPixelSize: 2048,
            ] as CFDictionary) else { throw invalid("背景图片无法读取") }
      background = UIImage(cgImage: cg)
    }
    let bitmap = UIGraphicsImageRenderer(size: size, format: format).image { context in
      UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: CGFloat(corner)).addClip()
      UIColor.darkGray.setFill(); context.fill(CGRect(origin: .zero, size: size))
      if let image = background {
        let scale = max(size.width / image.size.width, size.height / image.size.height)
        let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        image.draw(in: CGRect(x: (size.width - scaled.width) / 2, y: (size.height - scaled.height) / 2, width: scaled.width, height: scaled.height))
      }
    }
    face.backgroundImage = bitmap
    let tint = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    let time = QjsTimeWidget(tintColor: tint)
    time.x = max(0, (w - time.width) / 2)
    time.y = max(0, h / 2 - time.height / 2 - 20)
    face.addWidget(time)
    var labels: [(String, QjsWidget)] = [("10:08", time)]
    func add(_ widget: QjsWidget, _ text: String, x: Int, y: Int) {
      widget.x = max(0, x); widget.y = max(0, y)
      face.addWidget(widget); labels.append((text, widget))
    }
    if args["date"] as? Bool == true {
      let widget = QjsDateWidget(tintColor: tint)
      add(widget, "09/08", x: (w - widget.width) / 2, y: time.y + time.height + 8)
    }
    if args["week"] as? Bool == true {
      let widget = QjsWeekWidget(tintColor: tint)
      add(widget, "TUE", x: (w - widget.width) / 2, y: time.y - widget.height - 8)
    }
    if args["step"] as? Bool == true {
      let widget = QjsStepWidget(tintColor: tint)
      add(widget, "步数 8888", x: (w - widget.width) / 2, y: h - widget.height - 24)
    }
    if args["weather"] as? Bool == true {
      let widget = QjsWeatherTAWidget(tintColor: tint)
      add(widget, "☀ 26°", x: 24, y: 24)
    }
    let pointers = args["pointer"] as? Bool == true
    if pointers {
      var pointerSize = Size.zero; pointerSize.width = w; pointerSize.height = h
      face.addWidget(QjsHourPointerWidget(pointerSize, tintColor: tint))
      face.addWidget(QjsMinutePointerWidget(pointerSize, tintColor: tint))
      face.addWidget(QjsSecondPointerWidget(pointerSize, tintColor: tint))
      face.addWidget(QjsDotWidget(tintColor: tint))
    }
    let preview = UIGraphicsImageRenderer(size: size, format: format).image { context in
      UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: CGFloat(corner)).addClip()
      bitmap.draw(at: .zero)
      // Preview values illustrate layout; the SDK widgets use live watch data.
      for (text, widget) in labels {
        let rect = CGRect(x: widget.x, y: widget.y, width: widget.width, height: widget.height)
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
        var font = UIFont.monospacedDigitSystemFont(ofSize: max(8, CGFloat(widget.height) * 0.8), weight: .medium)
        let measured = (text as NSString).size(withAttributes: [.font: font]).width
        if measured > rect.width { font = font.withSize(font.pointSize * rect.width / measured) }
        (text as NSString).draw(in: rect, withAttributes: [.font: font, .foregroundColor: tint, .paragraphStyle: paragraph])
      }
      if pointers {
        let ctx = context.cgContext
        let center = CGPoint(x: w / 2, y: h / 2)
        let hands: [(CGFloat, CGFloat, CGFloat)] = [(-CGFloat.pi / 3, 0.23, 7), (CGFloat.pi / 3, 0.34, 5), (CGFloat.pi, 0.4, 2)]
        for (angle, length, lineWidth) in hands {
          ctx.setStrokeColor(tint.cgColor); ctx.setLineWidth(lineWidth); ctx.setLineCap(.round)
          ctx.move(to: center)
          let radius = CGFloat(min(w, h)) * length
          let point = CGPoint(x: center.x + sin(angle) * radius, y: center.y - cos(angle) * radius)
          ctx.addLine(to: point)
          ctx.strokePath()
        }
        tint.setFill(); ctx.fillEllipse(in: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10))
      }
    }
    face.thumbnailImage = UIGraphicsImageRenderer(size: CGSize(width: tw, height: th), format: format).image { _ in
      let rect = CGRect(x: 0, y: 0, width: tw, height: th)
      UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(tc)).addClip()
      preview.draw(in: rect)
    }
    guard let png = preview.pngData() else { throw invalid("无法生成表盘预览") }
    return (face, png)
  }
}
