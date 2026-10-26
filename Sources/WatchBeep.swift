import AppKit
import AVFoundation

/// 老式电子手表蜂鸣：把「滴滴。。」整段节奏合成成一个音频一次播放，
/// 避免主线程调度抖动导致节奏不齐。
final class WatchBeep {

    static let shared = WatchBeep()

    /// 每组两声之间的间隔（像呼吸的换气，不催）
    static let intraPairGap: TimeInterval = 0.28
    /// 组与组之间的停顿
    static let interPairGap: TimeInterval = 0.65
    /// 单声时长
    static let toneDuration: TimeInterval = 0.055

    /// 整段提示音总时长（用于「提示音结束后再开始下一阶段」）
    static func duration(pairs: Int) -> TimeInterval {
        Double(max(1, pairs)) * (toneDuration * 2 + intraPairGap + interPairGap)
    }

    private var player: AVAudioPlayer?
    private var loadedPairs = 0
    private var debugLogging = false

    private init() {}

    func setDebugLogging(_ enabled: Bool) {
        debugLogging = enabled
    }

    func play(pairs: Int) {
        ensurePlayer(pairs: pairs)
        guard let player = player else {
            NSSound.beep()
            return
        }
        if debugLogging {
            NSLog("POMODORO_CHIME pattern pairs=%d", pairs)
        }
        player.stop()
        player.currentTime = 0
        player.play()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
    }

    private func ensurePlayer(pairs: Int) {
        guard player == nil || loadedPairs != pairs else { return }
        do {
            let generated = try AVAudioPlayer(data: Self.wav(pairs: pairs))
            generated.volume = 1.0
            generated.prepareToPlay()
            player = generated
            loadedPairs = pairs
        } catch {
            NSLog("POMODORO_WATCHBEEP init failed: %@", error.localizedDescription)
            player = nil
        }
    }

    // MARK: - 合成

    static func wav(pairs: Int) -> Data {
        let sampleRate = 44100
        let tone = toneSamples(sampleRate: sampleRate)
        let intra = silenceSamples(seconds: intraPairGap, sampleRate: sampleRate)
        let inter = silenceSamples(seconds: interPairGap, sampleRate: sampleRate)

        var pcm: [Int16] = []
        pcm.reserveCapacity(max(1, pairs) * (tone.count * 2 + intra.count + inter.count))

        for _ in 0..<max(1, pairs) {
            pcm.append(contentsOf: tone)
            pcm.append(contentsOf: intra)
            pcm.append(contentsOf: tone)
            pcm.append(contentsOf: inter)
        }

        return wavData(pcm: pcm, sampleRate: sampleRate)
    }

    /// 方波 4000Hz，接近满刻度振幅：响度与系统提示音一致（跟随系统输出音量），
    /// 55ms，起音极快，靠高频而非加音染提升穿透力
    private static func toneSamples(sampleRate: Int) -> [Int16] {
        let frequency = 4000.0
        let sampleCount = Int(Double(sampleRate) * toneDuration)
        let fadeIn = 22.0      // 0.5ms，起音更锐
        let fadeOut = 350.0    // 8ms

        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)

        for i in 0..<sampleCount {
            let t = Double(i) / Double(sampleRate)
            let phase = (t * frequency).truncatingRemainder(dividingBy: 1.0)
            var value: Double = phase < 0.5 ? 1.0 : -1.0
            value *= min(1.0, Double(i) / fadeIn)
            value *= min(1.0, Double(sampleCount - i) / fadeOut)
            value *= 0.80
            samples.append(Int16(max(-1, min(1, value)) * 32767))
        }
        return samples
    }

    private static func silenceSamples(seconds: TimeInterval, sampleRate: Int) -> [Int16] {
        Array(repeating: 0, count: Int(Double(sampleRate) * seconds))
    }

    private static func wavData(pcm: [Int16], sampleRate: Int) -> Data {
        let bytesPerSample = 2
        let dataSize = pcm.count * bytesPerSample
        var data = Data()

        func appendASCII(_ text: String) {
            data.append(contentsOf: Array(text.utf8))
        }
        func appendUInt32(_ value: UInt32) {
            var v = value.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }
        func appendUInt16(_ value: UInt16) {
            var v = value.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }

        appendASCII("RIFF")
        appendUInt32(UInt32(36 + dataSize))
        appendASCII("WAVE")
        appendASCII("fmt ")
        appendUInt32(16)
        appendUInt16(1)                                    // PCM
        appendUInt16(1)                                    // 单声道
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate * bytesPerSample))  // byte rate
        appendUInt16(UInt16(bytesPerSample))               // block align
        appendUInt16(16)                                   // 位深
        appendASCII("data")
        appendUInt32(UInt32(dataSize))
        for sample in pcm {
            appendUInt16(UInt16(bitPattern: sample))
        }
        return data
    }
}
