import AppKit
import SwiftUI

struct PopoverView: View {

    @ObservedObject var engine: PomodoroEngine
    var onQuit: () -> Void

    private enum Field: Hashable {
        case work
        case rest
    }

    @FocusState private var focusedField: Field?
    /// 表盘 hover 状态（用 ObservableObject 而不是 @State：swiftc 直接编译时 SwiftUI 宏插件不可用）
    private final class HoverState: ObservableObject {
        @Published var isHovering = false
    }

    @ObservedObject private var hover = HoverState()

    private var tint: Color {
        engine.phase == .rest ? .green : .accentColor
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 14)

            ring
                .padding(.top, 10)

            primaryButton
                .padding(.horizontal, 18)
                .padding(.top, 14)

            secondaryButtons
                .padding(.horizontal, 18)
                .padding(.top, 8)

            Divider()
                .padding(.top, 14)
                .padding(.horizontal, 18)

            settings
                .padding(.horizontal, 18)
                .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 18)

            footer
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .frame(width: 300)
        .onAppear { focusedField = nil }
    }

    // MARK: - 头部

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("番茄钟")
                .font(.system(size: 13, weight: .semibold))

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 11, weight: .medium))
                Text("今日 \(engine.completedToday) 个")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - 环形计时（点击表盘 = 开始 / 暂停 / 继续）

    private var ring: some View {
        Button(action: startOrPause) {
            ringBody
        }
        .buttonStyle(RingPressStyle())
        .help("点击表盘：开始 / 暂停 / 继续")
        .onHover { hovering in
            hover.isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private var ringBody: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(hover.isHovering ? 0.12 : 0.08), lineWidth: 10)

            if engine.progress > 0.002 {
                Circle()
                    .trim(from: 0, to: engine.progress)
                    .stroke(tint.gradient,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.25), value: engine.progress)
            }

            VStack(spacing: 2) {
                Text(engine.timeText)
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(hover.isHovering ? engine.ringHint : engine.stateCaption)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 170, height: 170)
        .contentShape(Circle())
        .scaleEffect(hover.isHovering ? 1.012 : 1)
        .animation(.easeOut(duration: 0.15), value: hover.isHovering)
    }

    /// 按下时轻微缩一下，给点击反馈
    private struct RingPressStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .opacity(configuration.isPressed ? 0.92 : 1)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }

    /// 开始 / 暂停 / 继续（每次点击都有单音反馈）
    private func startOrPause() {
        SoundFX.shared.click()
        engine.primaryAction()
    }

    // MARK: - 主操作

    private var primaryButton: some View {
        Button(action: startOrPause) {
            Text(engine.primaryTitle)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(tint)
        .clipShape(Capsule())
    }

    private var secondaryButtons: some View {
        HStack(spacing: 10) {
            Button {
                SoundFX.shared.click()
                engine.reset()
            } label: {
                Label("重置", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .clipShape(Capsule())

            Button {
                SoundFX.shared.click()
                engine.skip()
            } label: {
                Label("跳过", systemImage: "forward.end")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .clipShape(Capsule())
        }
    }

    // MARK: - 设置

    private var settings: some View {
        VStack(spacing: 0) {
            row("计时时长") {
                minutesEditor(workMinutesBinding, field: .work)
            }

            row("休息时长") {
                minutesEditor(restMinutesBinding, field: .rest)
            }

            row("自动循环") {
                Toggle("", isOn: $engine.autoLoop)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }

            row("完成通知") {
                Toggle("", isOn: $engine.notificationsEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }
        }
    }

    private func row<Content: View>(_ title: String,
                                    @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12.5))
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            content()
        }
        .frame(height: 34)
    }

    /// 任意分钟输入：输入框（可直接键入）+ 步进器（±1 分钟），范围 1–180
    private func minutesEditor(_ binding: Binding<Int>, field: Field) -> some View {
        HStack(spacing: 6) {
            TextField("", value: binding, format: .number)
                .focused($focusedField, equals: field)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 50)
                .labelsHidden()

            Text("分钟")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Stepper("", value: binding, in: 1...180)
                .labelsHidden()
                .controlSize(.small)
        }
        .help("1–180 分钟，可直接输入任意数值")
    }

    private var workMinutesBinding: Binding<Int> {
        Binding(
            get: { engine.workMinutes },
            set: { engine.workMinutes = min(180, max(1, $0)) }
        )
    }

    private var restMinutesBinding: Binding<Int> {
        Binding(
            get: { engine.restMinutes },
            set: { engine.restMinutes = min(180, max(1, $0)) }
        )
    }

    // MARK: - 底部

    private var footer: some View {
        HStack {
            Spacer(minLength: 0)
            Button(action: onQuit) {
                Label("退出", systemImage: "power")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .clipShape(Capsule())
        }
    }
}
