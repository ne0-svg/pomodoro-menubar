import AppKit

/// 状态栏用的黑白模板图标（按系统图标的比例绘制，16pt 画布、字形约 14pt 高）。
enum StatusGlyph {

    static let mac: NSImage = make { _ in
        NSColor.black.setStroke()
        NSColor.black.setFill()

        // 机身
        let body = NSBezierPath(roundedRect: NSRect(x: 3.9, y: 6.4, width: 8.2, height: 8.2),
                                xRadius: 1.1, yRadius: 1.1)
        body.lineWidth = 1.25
        body.stroke()

        // 屏幕
        let screen = NSBezierPath(roundedRect: NSRect(x: 5.2, y: 8.6, width: 5.6, height: 4.6),
                                  xRadius: 0.5, yRadius: 0.5)
        screen.lineWidth = 1.0
        screen.stroke()

        // 软驱插槽
        let slot = NSBezierPath()
        slot.move(to: NSPoint(x: 7.2, y: 7.4))
        slot.line(to: NSPoint(x: 10.0, y: 7.4))
        slot.lineWidth = 1.15
        slot.lineCapStyle = .round
        slot.stroke()

        // 底座
        let base = NSBezierPath(roundedRect: NSRect(x: 2.8, y: 3.6, width: 10.4, height: 2.5),
                                xRadius: 1.0, yRadius: 1.0)
        base.lineWidth = 1.25
        base.stroke()
    }

    static let person: NSImage = make { _ in
        NSColor.black.setStroke()
        NSColor.black.setFill()

        // 头
        NSBezierPath(ovalIn: NSRect(x: 6.9, y: 11.9, width: 2.4, height: 2.4)).fill()

        // 躯干
        let torso = NSBezierPath()
        torso.move(to: NSPoint(x: 6.5, y: 11.7))
        torso.line(to: NSPoint(x: 9.7, y: 11.7))
        torso.line(to: NSPoint(x: 9.4, y: 7.6))
        torso.line(to: NSPoint(x: 6.8, y: 7.6))
        torso.close()
        torso.fill()

        // 手臂（叉腰）
        for mirror in [false, true] {
            let sign: CGFloat = mirror ? 1 : -1
            let arm = NSBezierPath()
            arm.move(to: NSPoint(x: 8.1 + sign * 1.5, y: 11.4))
            arm.curve(to: NSPoint(x: 8.1 + sign * 2.4, y: 8.0),
                      controlPoint1: NSPoint(x: 8.1 + sign * 3.0, y: 10.6),
                      controlPoint2: NSPoint(x: 8.1 + sign * 3.0, y: 8.6))
            arm.lineWidth = 1.35
            arm.lineCapStyle = .round
            arm.stroke()
        }

        // 腿
        for mirror in [false, true] {
            let sign: CGFloat = mirror ? 1 : -1
            let leg = NSBezierPath()
            leg.move(to: NSPoint(x: 8.1 + sign * 0.8, y: 7.7))
            leg.line(to: NSPoint(x: 8.1 + sign * 1.1, y: 3.4))
            leg.lineWidth = 1.6
            leg.lineCapStyle = .round
            leg.stroke()
        }
    }

    private static func make(_ draw: @escaping (NSRect) -> Void) -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { rect in
            draw(rect)
            return true
        }
        image.isTemplate = true
        return image
    }
}
