import SwiftUI

/// 表盘里的一团水银：单个大液滴，缓慢漂移 + 表面轻微起伏，
/// 用金属渐变 + 高光 + 底部反光模拟真实水银质感。
struct DialLiquid: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let dialRadius = min(size.width, size.height) / 2
                let dark = colorScheme == .dark

                // 缓慢漂移：整体偏下半区，避免盖住时间和状态文字
                let driftX = sin(t * 0.23) * dialRadius * 0.16
                let driftY = center.y + dialRadius * 0.66 + cos(t * 0.17) * dialRadius * 0.04
                let blobCenter = CGPoint(x: center.x + driftX, y: driftY)
                let blobRadius = dialRadius * 0.34

                // 有机外形：单一液滴，边缘缓慢起伏
                var path = Path()
                let steps = 140
                for i in 0...steps {
                    let angle = Double(i) / Double(steps) * 2 * Double.pi
                    let wobble = 1.0
                        + 0.050 * sin(3 * angle + t * 0.55)
                        + 0.028 * sin(5 * angle - t * 0.40)
                    let radius = blobRadius * wobble
                    let point = CGPoint(x: blobCenter.x + CGFloat(cos(angle) * radius),
                                        y: blobCenter.y + CGFloat(sin(angle) * radius))
                    if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                path.closeSubpath()

                // 投影
                var shadow = context
                shadow.addFilter(.blur(radius: 12))
                shadow.translateBy(x: 0, y: 7)
                shadow.fill(path, with: .color(.black.opacity(dark ? 0.45 : 0.14)))

                // 水银本体：顶部亮、腰部银、底部再反光
                let body = Gradient(stops: [
                    .init(color: dark ? Color(white: 0.80) : Color(white: 1.00), location: 0.00),
                    .init(color: dark ? Color(white: 0.55) : Color(red: 0.90, green: 0.93, blue: 0.97), location: 0.30),
                    .init(color: dark ? Color(white: 0.20) : Color(red: 0.45, green: 0.51, blue: 0.60), location: 0.68),
                    .init(color: dark ? Color(white: 0.12) : Color(red: 0.36, green: 0.41, blue: 0.50), location: 0.88),
                    .init(color: dark ? Color(white: 0.35) : Color(red: 0.78, green: 0.83, blue: 0.90), location: 1.00),
                ])
                context.fill(path, with: .linearGradient(
                    body,
                    startPoint: CGPoint(x: blobCenter.x, y: blobCenter.y - blobRadius),
                    endPoint: CGPoint(x: blobCenter.x, y: blobCenter.y + blobRadius)))

                // 顶部高光（主反射）
                var highlight = context
                highlight.addFilter(.blur(radius: 3.5))
                let hlRect = CGRect(x: blobCenter.x - blobRadius * 0.52,
                                    y: blobCenter.y - blobRadius * 0.62,
                                    width: blobRadius * 0.58,
                                    height: blobRadius * 0.30)
                highlight.fill(Path(ellipseIn: hlRect), with: .color(.white))

                // 次级小高光，增加湿润感
                var sparkle = context
                sparkle.addFilter(.blur(radius: 1.6))
                let spRect = CGRect(x: blobCenter.x + blobRadius * 0.18,
                                    y: blobCenter.y - blobRadius * 0.30,
                                    width: blobRadius * 0.16,
                                    height: blobRadius * 0.12)
                sparkle.fill(Path(ellipseIn: spRect),
                             with: .color(.white.opacity(dark ? 0.45 : 0.85)))

                // 底部反射光带（桌面/环境倒影）
                var bottomGlow = context
                bottomGlow.addFilter(.blur(radius: 7))
                let glowRect = CGRect(x: blobCenter.x - blobRadius * 0.46,
                                      y: blobCenter.y + blobRadius * 0.52,
                                      width: blobRadius * 0.92,
                                      height: blobRadius * 0.24)
                bottomGlow.fill(Path(ellipseIn: glowRect),
                                with: .color(.white.opacity(dark ? 0.20 : 0.55)))

                // 边缘收一下，避免糊成一坨
                context.stroke(path,
                               with: .color(dark ? .white.opacity(0.18) : .black.opacity(0.16)),
                               lineWidth: 1.2)
            }
        }
        .clipShape(Circle())
        .opacity(0.95)
        .allowsHitTesting(false)
    }
}
