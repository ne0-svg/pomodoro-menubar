import AppKit

/// 菜单栏图标：休息态用模板像素图；计时态是黑白模板「爪印」，深浅色下都清晰。
enum StatusIcon {

    /// 休息状态：冒热气的像素咖啡杯
    static let coffee: NSImage = PixelIcon.coffee

    /// 计时状态：两枚爪印（模板图，浅色菜单栏黑、深色菜单栏白）
    static let paw: NSImage = makePaw()

    private static func makePaw() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setFill()
            drawPaw(center: NSPoint(x: 5.6, y: 11.4), scale: 1.0, degrees: -12)
            drawPaw(center: NSPoint(x: 12.2, y: 6.2), scale: 1.0, degrees: 18)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawPaw(center: NSPoint, scale: CGFloat, degrees: CGFloat) {
        let transform = NSAffineTransform()
        transform.translateX(by: center.x, yBy: center.y)
        transform.rotate(byDegrees: degrees)
        transform.scale(by: scale)

        NSGraphicsContext.saveGraphicsState()
        transform.concat()

        // 掌垫
        NSBezierPath(ovalIn: NSRect(x: -1.75, y: -2.7, width: 3.5, height: 3.1)).fill()
        // 四个脚趾
        let toes: [(CGFloat, CGFloat, CGFloat)] = [
            (-1.95, 1.05, 0.62),
            (-0.72, 1.95, 0.66),
            ( 0.72, 1.95, 0.66),
            ( 1.95, 1.05, 0.62),
        ]
        for (x, y, r) in toes {
            NSBezierPath(ovalIn: NSRect(x: x - r, y: y - r, width: r * 2, height: r * 2)).fill()
        }

        NSGraphicsContext.restoreGraphicsState()
    }
}
