import SwiftUI

/// 表盘背景里的「水银」——克制的液体感：
/// 参照 iOS 26/27 Liquid Glass 的做法：材质本身是低对比、强扩散的透镜层，
/// 高光含蓄、边缘完全化开，只靠缓慢的形变和位移让人感觉到「在流动」。
struct DialLiquid: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let dialRadius = min(size.width, size.height) / 2
                let dark = colorScheme == .dark

                // 缓慢漂移（周期约 40 秒，几乎察觉不到但一直在动）
                let driftX = sin(t * 0.155) * dialRadius * 0.22
                let driftY = center.y + dialRadius * 0.30 + cos(t * 0.115) * dialRadius * 0.10
                let blobCenter = CGPoint(x: center.x + driftX, y: driftY)
                let blobRadius = dialRadius * 0.52

                // 有机外形：边缘缓慢起伏，但整体仍是一团
                var path = Path()
                let steps = 160
                for i in 0...steps {
                    let angle = Double(i) / Double(steps) * 2 * Double.pi
                    let wobble = 1.0
                        + 0.045 * sin(2 * angle + t * 0.18)
                        + 0.030 * sin(3 * angle - t * 0.13)
                    let radius = blobRadius * wobble
                    let point = CGPoint(x: blobCenter.x + CGFloat(cos(angle) * radius),
                                        y: blobCenter.y + CGFloat(sin(angle) * radius))
                    if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                path.closeSubpath()

                // 本体：低对比的银灰，径向在边缘之前就淡出（不出现硬边）
                let core = dark ? Color(white: 0.92) : Color(red: 0.52, green: 0.58, blue: 0.68)
                let body = Gradient(stops: [
                    .init(color: core.opacity(dark ? 0.30 : 0.42), location: 0.00),
                    .init(color: core.opacity(dark ? 0.24 : 0.34), location: 0.55),
                    .init(color: core.opacity(0.0), location: 0.92),
                ])
                context.fill(path, with: .radialGradient(body,
                                                         center: blobCenter,
                                                         startRadius: 0,
                                                         endRadius: blobRadius * 1.02))

                // 含蓄的高光：一块柔和的偏移亮部，随液体缓慢移动
                var highlight = context
                highlight.addFilter(.blur(radius: 9))
                let hlRadius = blobRadius * 0.34
                let hlCenter = CGPoint(x: blobCenter.x - blobRadius * 0.26,
                                       y: blobCenter.y - blobRadius * 0.24)
                let hlGradient = Gradient(colors: [
                    Color.white.opacity(dark ? 0.26 : 0.62),
                    Color.white.opacity(0.0),
                ])
                highlight.fill(Path(ellipseIn: CGRect(x: hlCenter.x - hlRadius,
                                                      y: hlCenter.y - hlRadius,
                                                      width: hlRadius * 2,
                                                      height: hlRadius * 2)),
                               with: .radialGradient(hlGradient,
                                                     center: hlCenter,
                                                     startRadius: 0,
                                                     endRadius: hlRadius))
            }
            // 整体再糊一层：边缘彻底化进背景，只在明暗上留下流动的痕迹
            .blur(radius: 7)
        }
        .clipShape(Circle())
        .allowsHitTesting(false)
        .opacity(0.95)
    }
}
