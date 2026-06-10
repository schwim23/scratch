import AVFoundation
import Foundation
import Observation
import Speech

struct RecordingResult {
    let audioFileName: String
    let duration: TimeInterval
    let transcript: String
    let wordTimings: [WordTiming]
    let waveform: [Float]
}

/// Records the mic to an .m4a file while streaming the same buffers into
/// on-device speech recognition for a live transcript.
///
/// Threading: the tap closure runs on the audio render thread and writes the
/// file / feeds the recognizer there; published UI state (elapsed, levels,
/// transcript) is hopped to the main queue.
@Observable
final class RecorderEngine {
    enum State: Equatable {
        case idle
        case requestingPermission
        case recording
        case paused
        case finishing
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var elapsed: TimeInterval = 0
    private(set) var liveTranscript: String = ""
    /// Rolling buffer of recent input levels (0...1) for the live waveform.
    private(set) var liveLevels: [Float] = []

    static let liveLevelCount = 72

    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var fileName = ""
    private var sampleRate: Double = 48_000
    private var writtenFrames: AVAudioFramePosition = 0
    private var allLevels: [Float] = []
    /// The recognizer finalizes an utterance at each silence boundary and
    /// starts over, so finished utterances are accumulated here and only the
    /// in-flight partial gets replaced.
    private var finalizedTranscript = ""
    private var finalizedTimings: [WordTiming] = []
    private var partialTranscript = ""
    private var partialTimings: [WordTiming] = []
    private var sawFinalResult = false
    /// Read on the audio thread, written on main; worst case a buffer or two
    /// lands on the wrong side of a pause toggle.
    private var isWriting = false

    var isActive: Bool { state == .recording || state == .paused }

    @MainActor
    func start() async {
        guard state == .idle else { return }
        state = .requestingPermission

        let micGranted = await AVAudioApplication.requestRecordPermission()
        guard micGranted else {
            state = .failed("Microphone access denied. Enable it in Settings → Privacy → Microphone.")
            return
        }
        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            state = .failed("Speech recognition denied. Enable it in Settings → Privacy → Speech Recognition.")
            return
        }

        do {
            try begin()
            state = .recording
        } catch {
            state = .failed("Couldn't start recording: \(error.localizedDescription)")
        }
    }

    private func begin() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        guard let recognizer = SFSpeechRecognizer() ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.isAvailable
        else {
            throw NSError(
                domain: "Scratch", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognition isn't available on this device."]
            )
        }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.addsPunctuation = true
        // Private + offline whenever the device has the model; the simulator
        // often doesn't, so fall back rather than fail there.
        if recognizer.supportsOnDeviceRecognition {
            req.requiresOnDeviceRecognition = true
        }
        request = req

        fileName = UUID().uuidString + ".m4a"
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        sampleRate = format.sampleRate
        audioFile = try AVAudioFile(
            forWriting: AudioStore.url(for: fileName),
            settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: Int(format.channelCount),
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ],
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )

        writtenFrames = 0
        allLevels = []
        finalizedTranscript = ""
        finalizedTimings = []
        partialTranscript = ""
        partialTimings = []
        sawFinalResult = false
        isWriting = true

        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.consume(buffer)
        }
        engine.prepare()
        try engine.start()

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.handle(result: result, error: error)
            }
        }
    }

    private func consume(_ buffer: AVAudioPCMBuffer) {
        guard isWriting, let file = audioFile else { return }
        do {
            try file.write(from: buffer)
        } catch {
            return
        }
        writtenFrames += AVAudioFramePosition(buffer.frameLength)
        request?.append(buffer)

        let level = Self.rmsLevel(of: buffer)
        let seconds = Double(writtenFrames) / sampleRate
        DispatchQueue.main.async { [weak self] in
            guard let self, self.state == .recording else { return }
            self.allLevels.append(level)
            self.liveLevels.append(level)
            if self.liveLevels.count > Self.liveLevelCount {
                self.liveLevels.removeFirst(self.liveLevels.count - Self.liveLevelCount)
            }
            self.elapsed = seconds
        }
    }

    private static func rmsLevel(of buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData, buffer.frameLength > 0 else { return 0 }
        let n = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<n {
            let s = data[0][i]
            sum += s * s
        }
        let rms = sqrt(sum / Float(n))
        // Map typical speech RMS into a 0...1 display range.
        return min(1, rms * 8)
    }

    private func handle(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            let text = result.bestTranscription.formattedString
            let timings = result.bestTranscription.segments.map {
                WordTiming(word: $0.substring, start: $0.timestamp, duration: $0.duration)
            }
            #if DEBUG
            print("SCRATCH-SPEECH final=\(result.isFinal) len=\(text.count) text='\(text.prefix(60))'")
            #endif
            if result.isFinal {
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // The recognizer can finalize trailing silence as an empty
                    // utterance; keep the last partial instead of losing it.
                    appendFinalized(text: partialTranscript, timings: partialTimings)
                } else {
                    appendFinalized(text: text, timings: timings)
                }
                partialTranscript = ""
                partialTimings = []
                sawFinalResult = true
            } else {
                partialTranscript = text
                partialTimings = timings
            }
            liveTranscript = combinedTranscript
        }
        if let error {
            #if DEBUG
            print("SCRATCH-SPEECH error: \(error.localizedDescription)")
            #endif
            sawFinalResult = true
        }
    }

    private func appendFinalized(text: String, timings: [WordTiming]) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        finalizedTranscript = finalizedTranscript.isEmpty
            ? trimmed
            : finalizedTranscript + " " + trimmed
        finalizedTimings.append(contentsOf: timings)
    }

    private var combinedTranscript: String {
        let partial = partialTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalizedTranscript.isEmpty { return partial }
        return partial.isEmpty ? finalizedTranscript : finalizedTranscript + " " + partial
    }

    private var combinedTimings: [WordTiming] {
        finalizedTimings + partialTimings
    }

    @MainActor
    func pause() {
        guard state == .recording else { return }
        isWriting = false
        state = .paused
    }

    @MainActor
    func resume() {
        guard state == .paused else { return }
        isWriting = true
        state = .recording
    }

    @MainActor
    func stop() async -> RecordingResult? {
        guard isActive else { return nil }
        state = .finishing
        isWriting = false

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        // Only wait on the recognizer if an utterance is still in flight;
        // anything before the last silence boundary is already finalized.
        if !partialTranscript.isEmpty { sawFinalResult = false }
        request?.endAudio()
        for _ in 0..<30 where !sawFinalResult {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        task?.cancel()
        task = nil
        request = nil
        audioFile = nil // closes the file

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        let result = RecordingResult(
            audioFileName: fileName,
            duration: Double(writtenFrames) / sampleRate,
            transcript: combinedTranscript,
            wordTimings: combinedTimings,
            waveform: Waveform.downsample(allLevels, to: 60)
        )
        state = .idle
        return result
    }

    /// Tear down without keeping anything (recording screen dismissed early).
    @MainActor
    func abandon() async {
        guard isActive || state == .finishing else { return }
        _ = await stop()
        AudioStore.delete(fileName)
    }

    #if DEBUG
    /// Seed visible state for screenshot/UI verification without touching
    /// the mic or permissions.
    @MainActor
    func seedForPreview(transcript: String, elapsed: TimeInterval, levels: [Float]) {
        state = .recording
        liveTranscript = transcript
        self.elapsed = elapsed
        liveLevels = levels
    }
    #endif
}
