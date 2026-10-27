import AppKit

/// 状态栏用的矢量模板图标（16pt 画布，字形约 14pt）。
enum StatusGlyph {

    /// 计时：带箭头的圆环 + 指针
    static let timer: NSImage = make { _ in
        NSColor.black.setStroke()
        NSColor.black.setFill()

        let center = NSPoint(x: 8.0, y: 8.0)
        let radius: CGFloat = 5.4

        // 圆环：从 -21° 逆时针画 301°，在右下留出缺口放箭头
        let arc = NSBezierPath()
        arc.appendArc(withCenter: center, radius: radius,
                      startAngle: -21, endAngle: -80, clockwise: false)
        arc.lineWidth = 1.55
        arc.lineCapStyle = .round
        arc.stroke()

        // 箭头：在 -21° 处，沿逆时针切线方向
        let angle = -21.0 * Double.pi / 180.0
        let tip = NSPoint(x: center.x + CGFloat(cos(angle)) * radius,
                          y: center.y + CGFloat(sin(angle)) * radius)
        let tangent = CGPoint(x: -sin(angle), y: cos(angle))
        let normal = CGPoint(x: cos(angle), y: sin(angle))
        let arrow = NSBezierPath()
        arrow.move(to: NSPoint(x: tip.x + tangent.x * 2.0, y: tip.y + tangent.y * 2.0))
        arrow.line(to: NSPoint(x: tip.x + normal.x * 1.5, y: tip.y + normal.y * 1.5))
        arrow.line(to: NSPoint(x: tip.x - normal.x * 1.5, y: tip.y - normal.y * 1.5))
        arrow.close()
        arrow.fill()

        // 指针
        let longHand = NSBezierPath()
        longHand.move(to: center)
        longHand.line(to: NSPoint(x: center.x, y: center.y + 3.9))
        longHand.lineWidth = 1.45
        longHand.lineCapStyle = .round
        longHand.stroke()

        let shortHand = NSBezierPath()
        shortHand.move(to: center)
        shortHand.line(to: NSPoint(x: center.x + 2.7, y: center.y - 2.1))
        shortHand.lineWidth = 1.45
        shortHand.lineCapStyle = .round
        shortHand.stroke()
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
