#!/usr/bin/env swift
// 生成 App 图标：Braun / Sony 工业设计语言的计时器
// 炭黑磨砂底 + 米白表盘 + 细刻度 + 橙色秒针
// 用法：swift Scripts/make-icon.swift

import AppKit

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetURL = projectRoot.appendingPathComponent("Build/AppIcon.iconset")
let icnsURL = projectRoot.appendingPathComponent("Resources/AppIcon.icns")
let previewURL = projectRoot.appendingPathComponent("Resources/AppIcon-1024.png")

try? FileManager.default.removeItem(at: iconsetURL)
try! FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try! FileManager.default.createDirectory(at: projectRoot.appendingPathComponent("Resources"),
                                         withIntermediateDirectories: true)

// MARK: - 配色（克制、哑光）

let charcoal = NSColor(srgbRed: 0.149, green: 0.153, blue: 0.161, alpha: 1)      // 机身
let charcoalDark = NSColor(srgbRed: 0.098, green: 0.102, blue: 0.110, alpha: 1)
let cream = NSColor(srgbRed: 0.949, green: 0.933, blue: 0.894, alpha: 1)         // 表盘
let ink = NSColor(srgbRed: 0.110, green: 0.114, blue: 0.122, alpha: 1)           // 刻度/指针
let braunOrange = NSColor(srgbRed: 1.000, green: 0.396, blue: 0.055, alpha: 1)    // 秒针

/// 在 1024×1024 设计空间里绘制，按目标尺寸缩放
func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high
    ctx.scaleBy(x: size / 1024.0, y: size / 1024.0)

    // MARK: 圆角底（哑光炭黑，几乎无高光，Rams 的克制）
    let inset: CGFloat = 100
    let rect = NSRect(x: inset, y: inset, width: 1024 - inset * 2, height: 1024 - inset * 2)
    let squircle = NSBezierPath(roundedRect: rect, xRadius: 185, yRadius: 185)
    NSGradient(colors: [charcoal, charcoalDark])!.draw(in: squircle, angle: -90)

    // MARK: 几何参数
    let center = NSPoint(x: 512, y: 480)
    let radius: CGFloat = 282

    // 顶部表冠（计时按钮）：先画，表盘盖住下半部分
    let crownRect = NSRect(x: center.x - 46, y: center.y + radius - 26,
                           width: 92, height: 104)
    let crown = NSBezierPath(roundedRect: crownRect, xRadius: 24, yRadius: 24)
    cream.setFill()
    crown.fill()
    ink.setStroke()
    crown.lineWidth = 9
    crown.stroke()

    // MARK: 表盘
    let faceRect = NSRect(x: center.x - radius, y: center.y - radius,
                          width: radius * 2, height: radius * 2)
    let face = NSBezierPath(ovalIn: faceRect)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 40
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    cream.setFill()
    face.fill()
    NSGraphicsContext.restoreGraphicsState()

    ink.setStroke()
    face.lineWidth = 9
    face.stroke()

    // MARK: 刻度（12 格，3/6/9/12 加长）
    for i in 0..<12 {
        let angle = Double(i) * Double.pi / 6 + Double.pi / 2
        let major = i % 3 == 0
        let inner = radius - (major ? 74 : 52)
        let outer = radius - 24

        let tick = NSBezierPath()
        tick.move(to: NSPoint(x: center.x + cos(angle) * inner,
                              y: center.y + sin(angle) * inner))
        tick.line(to: NSPoint(x: center.x + cos(angle) * outer,
                              y: center.y + sin(angle) * outer))
        tick.lineWidth = major ? 13 : 7
        ink.setStroke()
        tick.stroke()
    }

    // MARK: 指针
    func hand(angle: Double, from: CGFloat, to: CGFloat, width: CGFloat, color: NSColor) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: center.x + cos(angle) * from,
                              y: center.y + sin(angle) * from))
        path.line(to: NSPoint(x: center.x + cos(angle) * to,
                              y: center.y + sin(angle) * to))
        path.lineWidth = width
        path.lineCapStyle = .round
        color.setStroke()
        path.stroke()
    }

    // 分针：指向 12 点，粗一点
    hand(angle: Double.pi / 2, from: -radius * 0.12, to: radius * 0.56, width: 17, color: ink)
    // 秒针：指向 1 点半方向，细长，橙色，尾部带配重
    hand(angle: Double.pi / 2 - Double.pi / 5, from: -radius * 0.20, to: radius * 0.72,
         width: 9, color: braunOrange)

    // 中心轴：黑色小圆 + 橙色细环
    let hub = NSBezierPath(ovalIn: NSRect(x: center.x - 20, y: center.y - 20, width: 40, height: 40))
    ink.setFill()
    hub.fill()
    let hubRing = NSBezierPath(ovalIn: NSRect(x: center.x - 27, y: center.y - 27, width: 54, height: 54))
    braunOrange.setStroke()
    hubRing.lineWidth = 7
    hubRing.stroke()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL, pixelSize: Int) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: pixelSize, pixelsHigh: pixelSize,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: url)
}

let entries: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for entry in entries {
    let image = drawIcon(size: CGFloat(entry.pixels))
    writePNG(image, to: iconsetURL.appendingPathComponent("\(entry.name).png"), pixelSize: entry.pixels)
}

writePNG(drawIcon(size: 1024), to: previewURL, pixelSize: 1024)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try! process.run()
process.waitUntilExit()

print("AppIcon.icns 生成完成: \(icnsURL.path)")
print("预览: \(previewURL.path)")
