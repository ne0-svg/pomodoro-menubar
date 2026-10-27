import SwiftUI

/// 表盘里的「水银」效果：几团半透明液体在圆盘内缓慢游走，若隐若现。
/// 用 TimelineView 驱动，不依赖 @State（swiftc 直连编译时 SwiftUI 宏不可用）。
struct DialLiquid: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2
                let base = colorScheme == .dark
                    ? Color(white: 0.95)
                    : Color(red: 0.42, green: 0.47, blue: 0.55)   // 冷灰蓝，像水银

                for i in 0..<3 {
                    let phase = Double(i) * 2.4
                    let speed = 0.13 + Double(i) * 0.05

                    let dx = sin(t * speed + phase) * radius * 0.42
                    let dy = cos(t * speed * 0.75 + phase * 1.6) * radius * 0.42
                    let blob = radius * (0.26 + 0.08 * sin(t * 0.21 + phase))
                    let alpha = 0.050 + 0.030 * sin(t * 0.17 + phase * 1.3)

                    let gradient = Gradient(colors: [
                        base.opacity(alpha * 2.0),
                        base.opacity(alpha * 0.6),
                        base.opacity(0.0),
                    ])

                    let blobCenter = CGPoint(x: center.x + dx, y: center.y + dy)
                    let rect = CGRect(x: blobCenter.x - blob,
                                      y: blobCenter.y - blob,
                                      width: blob * 2, height: blob * 2)
                    context.fill(Path(ellipseIn: rect),
                                 with: .radialGradient(gradient,
                                                       center: blobCenter,
                                                       startRadius: 0,
                                                       endRadius: blob))
                }
            }
            .blur(radius: 10)
        }
        .clipShape(Circle())
        .allowsHitTesting(false)
    }
}
