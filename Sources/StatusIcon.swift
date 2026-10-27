import AppKit

/// 菜单栏图标：黑白模板图，浅色菜单栏黑、深色菜单栏白，点击高亮自动反相。
enum StatusIcon {

    /// 计时状态：秒表
    static let timer: NSImage = makeTimer()

    /// 休息状态：冒热气的像素咖啡杯
    static let coffee: NSImage = PixelIcon.coffee

    // MARK: - 秒表

    private static func makeTimer() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            let center = NSPoint(x: 9.0, y: 7.9)

            // 表壳
            let casePath = NSBezierPath(ovalIn: NSRect(x: center.x - 5.9, y: center.y - 5.9,
                                                       width: 11.8, height: 11.8))
            casePath.lineWidth = 1.5
            casePath.stroke()

            // 顶部表冠
            let crown = NSBezierPath(roundedRect: NSRect(x: 7.3, y: 14.2, width: 3.4, height: 1.9),
                                     xRadius: 0.65, yRadius: 0.65)
            crown.fill()
            let neck = NSBezierPath(rect: NSRect(x: 8.3, y: 13.3, width: 1.4, height: 1.1))
            neck.fill()

            // 指针
            let hand = NSBezierPath()
            hand.move(to: NSPoint(x: center.x, y: center.y))
            hand.line(to: NSPoint(x: center.x, y: center.y + 3.9))
            hand.lineWidth = 1.5
            hand.lineCapStyle = .round
            hand.stroke()

            // 中心轴
            NSBezierPath(ovalIn: NSRect(x: center.x - 0.95, y: center.y - 0.95,
                                        width: 1.9, height: 1.9)).fill()

            return true
        }
        image.isTemplate = true
        return image
    }
}
