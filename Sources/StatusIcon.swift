import AppKit

/// 菜单栏用的计时器图标：与 App logo 同源（表盘 + 表冠 + 指针），
/// 以模板图渲染，自动跟随菜单栏深浅色与高亮反色。
enum StatusIcon {

    static let timer: NSImage = {
        let size = NSSize(width: 17, height: 17)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            // 表盘
            let dial = NSBezierPath(ovalIn: NSRect(x: 2.7, y: 1.7, width: 11.6, height: 11.6))
            dial.lineWidth = 1.5
            dial.stroke()

            // 顶部表冠
            let crown = NSBezierPath(roundedRect: NSRect(x: 6.9, y: 13.3, width: 3.2, height: 2.3),
                                     xRadius: 0.8, yRadius: 0.8)
            crown.fill()

            // 指针（指向 12 点）
            let hand = NSBezierPath()
            hand.move(to: NSPoint(x: 8.5, y: 7.5))
            hand.line(to: NSPoint(x: 8.5, y: 11.2))
            hand.lineWidth = 1.5
            hand.lineCapStyle = .round
            hand.stroke()

            // 中心轴
            NSBezierPath(ovalIn: NSRect(x: 7.75, y: 6.75, width: 1.5, height: 1.5)).fill()

            return true
        }
        image.isTemplate = true
        return image
    }()
}
