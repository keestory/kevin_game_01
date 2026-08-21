import AVFAudio
import UIKit

@MainActor
final class HapticService {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let success = UINotificationFeedbackGenerator()
    private let warning = UINotificationFeedbackGenerator()
    private var lastImpact = Date.distantPast

    func prepare() {
        light.prepare()
        success.prepare()
    }

    func perfect(enabled: Bool) {
        guard enabled, Date.now.timeIntervalSince(lastImpact) > 0.06 else { return }
        lastImpact = .now
        light.impactOccurred(intensity: 0.72)
        light.prepare()
    }

    func match(enabled: Bool) {
        guard enabled else { return }
        success.notificationOccurred(.success)
        success.prepare()
    }

    func overflow(enabled: Bool) {
        guard enabled else { return }
        warning.notificationOccurred(.warning)
    }

    func brake(enabled: Bool) {
        guard enabled, Date.now.timeIntervalSince(lastImpact) > 0.06 else { return }
        lastImpact = .now
        let medium = UIImpactFeedbackGenerator(style: .medium)
        medium.impactOccurred(intensity: 0.82)
        medium.prepare()
    }
}

enum GameAudioCue {
    case departure
    case brake
    case doors
    case perfect
    case missed
}

@MainActor
final class GameAudioService {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var configured = false

    init() {
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play(_ cue: GameAudioCue, enabled: Bool) {
        guard enabled else { return }
        configureIfNeeded()

        let specification: (frequencies: [Double], duration: Double, volume: Float)
        switch cue {
        case .departure:
            specification = ([196, 247], 0.16, 0.12)
        case .brake:
            specification = ([330, 246], 0.20, 0.16)
        case .doors:
            specification = ([523, 659], 0.22, 0.14)
        case .perfect:
            specification = ([523, 659, 784], 0.34, 0.18)
        case .missed:
            specification = ([196, 164], 0.28, 0.16)
        }

        guard let buffer = makeBuffer(
            frequencies: specification.frequencies,
            duration: specification.duration,
            volume: specification.volume
        ) else { return }

        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    func stop() {
        player.stop()
        engine.pause()
    }

    private func configureIfNeeded() {
        guard !configured else {
            if !engine.isRunning { try? engine.start() }
            return
        }
        configured = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        engine.prepare()
        try? engine.start()
    }

    private func makeBuffer(
        frequencies: [Double],
        duration: Double,
        volume: Float
    ) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let progress = Double(frame) / Double(max(1, Int(frameCount) - 1))
            let attack = min(1, progress / 0.08)
            let release = min(1, (1 - progress) / 0.22)
            let envelope = Float(max(0, min(attack, release)))
            let sample = frequencies.enumerated().reduce(0.0) { value, item in
                let sweep = 1 - Double(item.offset) * 0.018 * progress
                return value + sin(2 * .pi * item.element * sweep * time)
            } / Double(max(1, frequencies.count))
            channel[frame] = Float(sample) * volume * envelope
        }
        return buffer
    }
}
