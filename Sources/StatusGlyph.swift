import AppKit

/// 状态栏用的矢量模板图标（16pt 画布）。
enum StatusGlyph {

    /// 计时：不规则的黑白「溅墨/液滴」形，参考图简化版
    static let timer: NSImage = make { _ in
        NSColor.black.setFill()

        let center = NSPoint(x: 8, y: 8)
        let maxRadius: CGFloat = 7.0

        let spikes = 10.0
        let seed = 1.2
        let sharpness = 2.6
        let base = 0.62
        let amplitude = 0.38

        var points: [NSPoint] = []
        let steps = 720
        for i in 0...steps {
            let theta = Double(i) / Double(steps) * 2 * Double.pi
            let peak = pow(0.5 + 0.5 * cos(spikes * theta + seed), sharpness)
            let variation = 1 + 0.22 * sin(2 * theta + 0.9) + 0.12 * sin(5 * theta + 2.1)
            let r = (base + amplitude * peak) * variation
            points.append(NSPoint(x: CGFloat(cos(theta) * r), y: CGFloat(sin(theta) * r)))
        }

        // 归一化到画布内
        let largest = points.map { hypot($0.x, $0.y) }.max() ?? 1
        let scale = maxRadius / largest

        let path = NSBezierPath()
        for (index, point) in points.enumerated() {
            let p = NSPoint(x: center.x + point.x * scale, y: center.y + point.y * scale)
            if index == 0 { path.move(to: p) } else { path.line(to: p) }
        }
        path.close()
        path.fill()
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
