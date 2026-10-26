#!/usr/bin/env swift
// 生成 App 图标（沙漏）：暖色圆角底 + 白色沙漏 + 奶油色沙粒
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

/// 在 1024×1024 设计空间里绘制，按目标尺寸缩放
func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high
    ctx.scaleBy(x: size / 1024.0, y: size / 1024.0)

    // MARK: 圆角底
    let inset: CGFloat = 100
    let rect = NSRect(x: inset, y: inset, width: 1024 - inset * 2, height: 1024 - inset * 2)
    let radius: CGFloat = 185
    let background = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 1.00, green: 0.76, blue: 0.36, alpha: 1),   // 顶部暖黄
        NSColor(srgbRed: 0.94, green: 0.42, blue: 0.24, alpha: 1),   // 底部橘红
    ])!
    gradient.draw(in: background, angle: -90)

    // 顶部柔光
    NSGraphicsContext.saveGraphicsState()
    background.addClip()
    let highlight = NSGradient(colors: [
        NSColor(white: 1, alpha: 0.20),
        NSColor(white: 1, alpha: 0.0),
    ])!
    highlight.draw(in: NSRect(x: inset, y: 512, width: 1024 - inset * 2, height: 1024 - inset * 2 - 412),
                   angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    // MARK: 沙漏
    let cx: CGFloat = 512
    let topCapY: CGFloat = 742
    let bottomCapY: CGFloat = 282
    let capHeight: CGFloat = 42
    let capWidth: CGFloat = 316
    let glassTop: CGFloat = topCapY
    let glassBottom: CGFloat = bottomCapY + capHeight
    let glassHalf: CGFloat = 150
    let neckY: CGFloat = 512

    // 投影
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(srgbRed: 0.55, green: 0.18, blue: 0.05, alpha: 0.35)
    shadow.shadowBlurRadius = 36
    shadow.shadowOffset = NSSize(width: 0, height: -14)
    shadow.set()

    let glass = NSBezierPath()
    glass.move(to: NSPoint(x: cx - glassHalf, y: glassTop))
    glass.line(to: NSPoint(x: cx + glassHalf, y: glassTop))
    glass.line(to: NSPoint(x: cx, y: neckY))
    glass.close()
    glass.move(to: NSPoint(x: cx - glassHalf, y: glassBottom))
    glass.line(to: NSPoint(x: cx + glassHalf, y: glassBottom))
    glass.line(to: NSPoint(x: cx, y: neckY))
    glass.close()
    NSColor.white.setFill()
    glass.fill()

    let caps = NSBezierPath()
    caps.appendRoundedRect(NSRect(x: cx - capWidth / 2, y: topCapY, width: capWidth, height: capHeight),
                           xRadius: 14, yRadius: 14)
    caps.appendRoundedRect(NSRect(x: cx - capWidth / 2, y: bottomCapY, width: capWidth, height: capHeight),
                           xRadius: 14, yRadius: 14)
    caps.fill()
    NSGraphicsContext.restoreGraphicsState()

    // MARK: 沙粒（奶油色）
    NSColor(srgbRed: 0.99, green: 0.72, blue: 0.34, alpha: 1).setFill()

    // 沙粒与玻璃之间留出白边，读感才是「玻璃里的沙」
    let margin: CGFloat = 26
    func halfLower(_ y: CGFloat) -> CGFloat { glassHalf * (neckY - y) / (neckY - glassBottom) }
    func halfUpper(_ y: CGFloat) -> CGFloat { glassHalf * (y - neckY) / (glassTop - neckY) }

    let lowerBottomY = glassBottom + 12
    let lowerTopY = glassBottom + 104
    let lowerSand = NSBezierPath()
    lowerSand.move(to: NSPoint(x: cx - (glassHalf - margin), y: lowerBottomY))
    lowerSand.line(to: NSPoint(x: cx + (glassHalf - margin), y: lowerBottomY))
    lowerSand.line(to: NSPoint(x: cx + max(12, halfLower(lowerTopY) - margin), y: lowerTopY))
    lowerSand.line(to: NSPoint(x: cx - max(12, halfLower(lowerTopY) - margin), y: lowerTopY))
    lowerSand.close()
    lowerSand.fill()

    let upperTopY = glassTop - 12
    let upperBottomY = glassTop - 96
    let upperSand = NSBezierPath()
    upperSand.move(to: NSPoint(x: cx - (glassHalf - margin), y: upperTopY))
    upperSand.line(to: NSPoint(x: cx + (glassHalf - margin), y: upperTopY))
    upperSand.line(to: NSPoint(x: cx + max(12, halfUpper(upperBottomY) - margin), y: upperBottomY))
    upperSand.line(to: NSPoint(x: cx - max(12, halfUpper(upperBottomY) - margin), y: upperBottomY))
    upperSand.close()
    upperSand.fill()

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

// 预览图
writePNG(drawIcon(size: 1024), to: previewURL, pixelSize: 1024)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try! process.run()
process.waitUntilExit()

print("AppIcon.icns 生成完成: \(icnsURL.path)")
print("预览: \(previewURL.path)")
