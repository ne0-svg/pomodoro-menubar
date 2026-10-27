import SwiftUI

/// 表盘里的「水银」效果：几团半透明液体在圆盘内缓慢游走，带高光反光。
/// 用 TimelineView 驱动，不依赖 @State（swiftc 直连编译时 SwiftUI 宏不可用）。
struct DialLiquid: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2
                let dark = colorScheme == .dark

                let body = dark ? Color.white : Color(red: 0.36, green: 0.44, blue: 0.58)
                let alpha: Double = dark ? 0.16 : 0.30

                // 液体主体：三团不同速度的慢速漂移
                for i in 0..<3 {
                    let phase = Double(i) * 2.1
                    let speed = 0.42 + Double(i) * 0.13      // 周期约 15s / 11s / 9s
                    let dx = sin(t * speed + phase) * radius * 0.40
                    let dy = cos(t * speed * 0.8 + phase * 1.4) * radius * 0.40
                    let blob = radius * (0.30 + 0.10 * sin(t * 0.6 + phase))
                    let point = CGPoint(x: center.x + dx, y: center.y + dy)

                    // 中间偏透、边缘加深，更像一滴有张力的水银
                    let gradient = Gradient(stops: [
                        .init(color: body.opacity(alpha * 0.35), location: 0.0),
                        .init(color: body.opacity(alpha), location: 0.62),
                        .init(color: body.opacity(alpha * 0.15), location: 0.82),
                        .init(color: body.opacity(0), location: 1.0),
                    ])
                    context.fill(Path(ellipseIn: CGRect(x: point.x - blob,
                                                        y: point.y - blob,
                                                        width: blob * 2,
                                                        height: blob * 2)),
                                 with: .radialGradient(gradient,
                                                       center: point,
                                                       startRadius: 0,
                                                       endRadius: blob))

                    // 高光：偏左上的小亮点，模拟水银反光
                    let highlightBlob = blob * 0.30
                    let highlightPoint = CGPoint(x: point.x - blob * 0.25,
                                                 y: point.y + blob * 0.25)
                    let highlight = Gradient(colors: [
                        Color.white.opacity(dark ? 0.28 : 0.85),
                        Color.white.opacity(0.0),
                    ])
                    context.fill(Path(ellipseIn: CGRect(x: highlightPoint.x - highlightBlob,
                                                        y: highlightPoint.y - highlightBlob,
                                                        width: highlightBlob * 2,
                                                        height: highlightBlob * 2)),
                                 with: .radialGradient(highlight,
                                                       center: highlightPoint,
                                                       startRadius: 0,
                                                       endRadius: highlightBlob))
                }
            }
            .blur(radius: 4.5)
        }
        .clipShape(Circle())
        .allowsHitTesting(false)
    }
}
