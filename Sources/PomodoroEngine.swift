import AppKit
import Combine

enum PomodoroPhase: Equatable {
    case idle
    case work
    case rest
}

final class PomodoroEngine: ObservableObject {

    // MARK: - 对外状态

    @Published private(set) var phase: PomodoroPhase = .idle
    @Published private(set) var remaining: TimeInterval = 25 * 60
    @Published private(set) var isRunning = false
    @Published private(set) var completedToday = 0

    @Published var workMinutes: Int = 25 {
        didSet {
            guard !isLoading else { return }
            guard workMinutes != oldValue else { return }
            if phase == .idle { remaining = TimeInterval(workMinutes * 60) }
            persist()
            notifyUpdate()
        }
    }

    @Published var restMinutes: Int = 5 {
        didSet {
            guard !isLoading else { return }
            guard restMinutes != oldValue else { return }
            if phase == .rest && !isRunning { remaining = TimeInterval(restMinutes * 60) }
            persist()
            notifyUpdate()
        }
    }

    /// 自动循环：一轮 = 一次计时 + 一次休息。
    /// 开启时休息结束自动进入下一轮；关闭时休息结束即停止，回到待机。
    @Published var autoLoop: Bool = true {
        didSet {
            guard !isLoading else { return }
            if debugLogging { NSLog("POMODORO_SET autoLoop=%d", autoLoop ? 1 : 0) }
            persist()
            notifyUpdate()
        }
    }

    @Published var notificationsEnabled: Bool = true {
        didSet {
            guard !isLoading else { return }
            persist()
        }
    }

    /// 状态栏标题刷新回调
    var onUpdate: (() -> Void)?

    // MARK: - 内部

    private enum Key {
        static let work = "workMinutes"
        static let rest = "restMinutes"
        static let autoLoop = "autoStartNext"   // 沿用旧键名，保留用户已有设置
        static let notify = "notificationsEnabled"
    }

    private let defaults = UserDefaults.standard
    private var endDate: Date?
    private var ticker: Timer?
    private var midnightTimer: Timer?
    private var todayKey = ""
    private var isLoading = true
    private let debugLogging = ProcessInfo.processInfo.environment["POMODORO_DEBUG"] != nil

    init() {
        WatchBeep.shared.setDebugLogging(ProcessInfo.processInfo.environment["POMODORO_DEBUG"] != nil)
        let d = UserDefaults.standard

        // 先把持久化的值读出来，再一次性赋值，避免初始化过程中触发 didSet 把设置写坏
        let storedWork = d.object(forKey: Key.work) != nil ? max(1, d.integer(forKey: Key.work)) : 25
        let storedRest = d.object(forKey: Key.rest) != nil ? max(1, d.integer(forKey: Key.rest)) : 5
        let storedLoop = d.object(forKey: Key.autoLoop) != nil ? d.bool(forKey: Key.autoLoop) : true
        let storedNotify = d.object(forKey: Key.notify) != nil ? d.bool(forKey: Key.notify) : true
        let storedDayKey = Self.dayKey()
        let storedCount = d.integer(forKey: "count.\(storedDayKey)")

        workMinutes = storedWork
        restMinutes = storedRest
        autoLoop = storedLoop
        notificationsEnabled = storedNotify
        todayKey = storedDayKey
        completedToday = storedCount
        remaining = TimeInterval(storedWork * 60)
        isLoading = false

        if d.object(forKey: Key.work) == nil { persist() }
        scheduleMidnightRollover()
        if debugLogging {
            NSLog("POMODORO_INIT work=%d rest=%d autoLoop=%d notify=%d",
                  workMinutes, restMinutes, autoLoop ? 1 : 0, notificationsEnabled ? 1 : 0)
        }
    }

    // MARK: - 派生显示

    var totalSeconds: TimeInterval {
        switch phase {
        case .idle, .work: return TimeInterval(workMinutes * 60)
        case .rest: return TimeInterval(restMinutes * 60)
        }
    }

    var progress: Double {
        let total = totalSeconds
        guard total > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / total))
    }

    var timeText: String { Self.format(remaining) }

    var stateCaption: String {
        switch phase {
        case .idle: return "准备开始"
        case .work: return isRunning ? "计时中" : "已暂停"
        case .rest: return isRunning ? "休息中" : "已暂停"
        }
    }

    var primaryTitle: String {
        if isRunning { return "暂停" }
        switch phase {
        case .idle: return "开始计时"
        case .work: return "继续计时"
        case .rest: return "继续休息"
        }
    }

    var isPaused: Bool { phase != .idle && !isRunning }

    var phaseName: String {
        switch phase {
        case .idle: return "idle"
        case .work: return "work"
        case .rest: return "rest"
        }
    }

    // MARK: - 操作

    func primaryAction() {
        stopChime()
        if isRunning {
            pause()
        } else if phase == .idle {
            startWork()
        } else {
            begin()
        }
    }

    func startWork() {
        phase = .work
        remaining = TimeInterval(workMinutes * 60)
        begin()
    }

    func pause() {
        guard isRunning else { return }
        if let end = endDate {
            remaining = max(0, end.timeIntervalSinceNow)
        }
        stop()
        notifyUpdate()
    }

    func reset() {
        stopChime()
        stop()
        phase = .idle
        remaining = TimeInterval(workMinutes * 60)
        notifyUpdate()
    }

    func skip() {
        stopChime()
        stop()
        if phase == .work {
            phase = .rest
            remaining = TimeInterval(restMinutes * 60)
        } else {
            phase = .idle
            remaining = TimeInterval(workMinutes * 60)
        }
        notifyUpdate()
    }

    // MARK: - 计时

    /// 调试用：直接进入休息状态，便于截图、检查图标与配色。
    func debugRestState(remaining: TimeInterval = 4 * 60 + 12) {
        stopChime()
        phase = .rest
        self.remaining = remaining
        begin()
    }

    /// 调试用：伪造跨天，验证计数归零。
    func debugSimulateDayRollover() {
        todayKey = "1999-01-01"
        completedToday = 99
        refreshDayIfNeeded()
        NSLog("POMODORO_ROLLOVER todayKey=%@ completed=%d", todayKey, completedToday)
    }

    /// 调试用：立即结束当前阶段，用于验证提示音与阶段切换。
    func debugFinish() {
        finishPhase()
    }

    /// 调试用：以指定「已过时间」直接进入专注状态，便于截图检查运行态。
    func debugBeginWork(elapsed: TimeInterval) {
        phase = .work
        remaining = max(1, TimeInterval(workMinutes * 60) - elapsed)
        begin()
    }

    private func begin() {
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        startTicker()
        notifyUpdate()
    }

    private func stop() {
        isRunning = false
        endDate = nil
        ticker?.invalidate()
        ticker = nil
    }

    private func startTicker() {
        ticker?.invalidate()
        let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func tick() {
        guard isRunning, let end = endDate else { return }
        let left = end.timeIntervalSinceNow
        if left <= 0 {
            remaining = 0
            notifyUpdate()
            finishPhase()
        } else {
            remaining = left
            notifyUpdate()
        }
    }

    private func finishPhase() {
        let finished = phase
        stop()
        remaining = 0
        refreshDayIfNeeded()

        switch finished {
        case .work:
            completedToday += 1
            saveCount()
            chime(pairs: 10)
            postNotification(
                title: "计时完成",
                body: "今日已完成 \(completedToday) 次计时，休息 \(restMinutes) 分钟"
            )
            // 一轮里的休息总是自动开始
            phase = .rest
            remaining = TimeInterval(restMinutes * 60)
            begin()

        case .rest:
            chime(pairs: 10)
            if autoLoop {
                // 自动循环：休息结束直接进入下一轮
                postNotification(title: "休息结束", body: "开始下一轮 \(workMinutes) 分钟计时")
                phase = .work
                remaining = TimeInterval(workMinutes * 60)
                begin()
            } else {
                // 关闭自动循环：一轮结束就停
                postNotification(title: "休息结束", body: "本轮已完成，已自动停止")
                phase = .idle
                remaining = TimeInterval(workMinutes * 60)
                notifyUpdate()
            }

        case .idle:
            notifyUpdate()
        }
    }

    // MARK: - 提示

    /// 「滴滴。。」节奏：每组两声，组间停顿。
    /// 10 组 = 20 声，整段合成后一次性播放，节奏不受主线程调度影响。
    private func chime(pairs: Int) {
        stopChime()
        WatchBeep.shared.play(pairs: pairs)
    }

    func stopChime() {
        WatchBeep.shared.stop()
    }

    private func postNotification(title: String, body: String) {
        guard notificationsEnabled else { return }
        let t = Self.sanitize(title)
        let b = Self.sanitize(body)
        let script = "display notification \"\(b)\" with title \"\(t)\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    private static func sanitize(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "\"", with: "'")
    }

    // MARK: - 持久化

    private func persist() {
        defaults.set(workMinutes, forKey: Key.work)
        defaults.set(restMinutes, forKey: Key.rest)
        defaults.set(autoLoop, forKey: Key.autoLoop)
        defaults.set(notificationsEnabled, forKey: Key.notify)
    }

    private func saveCount() {
        defaults.set(completedToday, forKey: "count.\(todayKey)")
    }

    // MARK: - 每日归零（北京时间 00:00）

    /// 跨天时把计数切换到新的一天（新的一天默认 0）。
    func refreshDayIfNeeded() {
        let key = Self.dayKey()
        guard key != todayKey else { return }
        todayKey = key
        completedToday = defaults.integer(forKey: "count.\(key)")
        notifyUpdate()
    }

    private func scheduleMidnightRollover() {
        midnightTimer?.invalidate()
        let now = Date()
        guard let nextMidnight = Self.beijingCalendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else { return }

        let interval = max(1, nextMidnight.timeIntervalSince(now))
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            self?.refreshDayIfNeeded()
            self?.scheduleMidnightRollover()
        }
        RunLoop.main.add(timer, forMode: .common)
        midnightTimer = timer
    }

    private func notifyUpdate() {
        onUpdate?()
    }

    static func format(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.up)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// 计数器以北京时间 00:00 为一天的分界
    private static let beijingCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return calendar
    }()

    private static func dayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = beijingCalendar
        formatter.timeZone = beijingCalendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
