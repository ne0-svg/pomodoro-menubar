import AppKit
import AVFoundation

/// 交互音效：都是实时合成的短音，不依赖额外素材文件。
/// - `tick()`：钟表开始计时的「啪嗒」声
/// - `tvOff()`：老式电视机关机的下降音
final class SoundFX {

    static let shared = SoundFX()

    private var players: [String: AVAudioPlayer] = [:]
    private var debugLogging = false

    private init() {
        players["tick"] = makePlayer(Self.tickWAV(), volume: 0.55)
        players["tvOff"] = makePlayer(Self.tvOffWAV(), volume: 0.65)
    }

    func setDebugLogging(_ enabled: Bool) {
        debugLogging = enabled
    }

    /// 钟表开始计时：短促的机械「啪嗒」
    func tick() {
        play("tick")
    }

    /// 老式电视机关机：高频衰减 + 低频闷响
    func tvOff() {
        play("tvOff")
    }

    private func play(_ name: String) {
        guard let player = players[name] else { return }
        if debugLogging {
            NSLog("POMODORO_SFX %@", name)
        }
        player.stop()
        player.currentTime = 0
        player.play()
    }

    private func makePlayer(_ data: Data, volume: Float) -> AVAudioPlayer? {
        guard let player = try? AVAudioPlayer(data: data) else { return nil }
        player.volume = volume
        player.prepareToPlay()
        return player
    }

    // MARK: - 合成

    /// 啪嗒：极短噪声爆点 + 165Hz 闷击，共 90ms
    static func tickWAV() -> Data {
        let sampleRate = 44100
        let count = Int(0.09 * Double(sampleRate))
        var pcm = [Int16]()
        pcm.reserveCapacity(count)

        var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
        for i in 0..<count {
            let t = Double(i) / Double(sampleRate)

            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let noise = Double((seed >> 40) % 2001) / 1000.0 - 1.0
            let noiseEnv = exp(-t / 0.006)

            let thump = sin(2 * Double.pi * 165 * t) * exp(-t / 0.018)

            var value = noise * noiseEnv * 0.55 + thump * 0.45
            value *= min(1.0, Double(i) / 22.0)      // 0.5ms 淡入
            value *= min(1.0, Double(count - i) / 44.0)
            value *= 0.9

            pcm.append(Int16(max(-1, min(1, value)) * 32767))
        }
        return wavData(pcm: pcm, sampleRate: sampleRate)
    }

    /// 关机：1600Hz 滑落到 70Hz 的 CRT 高频余音 + 电流噪声 + 结尾闷响，共 750ms
    static func tvOffWAV() -> Data {
        let sampleRate = 44100
        let duration = 0.75
        let count = Int(duration * Double(sampleRate))
        var pcm = [Int16]()
        pcm.reserveCapacity(count)

        var phase = 0.0
        var seed: UInt64 = 0x2545_F491_4F6C_DD1D

        for i in 0..<count {
            let t = Double(i) / Double(sampleRate)
            let progress = t / duration

            // 高频余音：频率三次衰减，音量线性衰减
            let frequency = 70.0 + (1600.0 - 70.0) * pow(1.0 - progress, 3.0)
            phase += 2 * Double.pi * frequency / Double(sampleRate)
            var value = sin(phase) * pow(1.0 - progress, 1.6) * 0.55

            // 开头的电流噪声
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let noise = (Double((seed >> 40) % 2001) / 1000.0 - 1.0)
            value += noise * exp(-t / 0.03) * 0.18

            // 结尾的闷响
            let thumpTime = t - 0.55
            if thumpTime > 0 {
                value += sin(2 * Double.pi * 65 * thumpTime) * exp(-thumpTime / 0.12) * 0.35
            }

            value *= min(1.0, Double(i) / 44.0)
            value *= 0.8

            pcm.append(Int16(max(-1, min(1, value)) * 32767))
        }
        return wavData(pcm: pcm, sampleRate: sampleRate)
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
        appendUInt16(1)
        appendUInt16(1)
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate * bytesPerSample))
        appendUInt16(UInt16(bytesPerSample))
        appendUInt16(16)
        appendASCII("data")
        appendUInt32(UInt32(dataSize))
        for sample in pcm {
            appendUInt16(UInt16(bitPattern: sample))
        }
        return data
    }
}
