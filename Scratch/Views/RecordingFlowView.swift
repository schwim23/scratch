import SwiftData
import SwiftUI

/// Full-screen capture flow: recording first, then the review sheet content
/// in the same cover once the take is stopped.
struct RecordingFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [Note]

    @State private var recorder = RecorderEngine()
    @State private var result: RecordingResult?
    var autoStart = true

    var body: some View {
        ZStack {
            Palette.charcoal.ignoresSafeArea()
            if let result {
                ReviewView(
                    result: result,
                    takeNumber: notes.count + 1,
                    onSave: { title, transcript, timings in
                        save(result: result, title: title, transcript: transcript, timings: timings)
                    },
                    onDiscard: {
                        AudioStore.delete(result.audioFileName)
                        dismiss()
                    }
                )
            } else {
                RecordingView(
                    recorder: recorder,
                    onStop: {
                        Task {
                            if let r = await recorder.stop(), r.duration > 0.2 {
                                result = r
                            } else {
                                dismiss()
                            }
                        }
                    },
                    onCancel: {
                        Task {
                            await recorder.abandon()
                            dismiss()
                        }
                    }
                )
                .task {
                    if autoStart { await recorder.start() }
                    #if DEBUG
                    // SCRATCH_AUTOSTOP=<seconds> ends the take automatically
                    // so the flow can be exercised headlessly in CI/simulator.
                    if let seconds = ProcessInfo.processInfo.environment["SCRATCH_AUTOSTOP"].flatMap(Double.init) {
                        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                        if recorder.isActive, let r = await recorder.stop() {
                            result = r
                        }
                    }
                    #endif
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save(result: RecordingResult, title: String, transcript: String, timings: [WordTiming]) {
        let note = Note(
            title: title,
            duration: result.duration,
            transcript: transcript,
            wordTimings: timings,
            audioFileName: result.audioFileName,
            waveform: result.waveform
        )
        modelContext.insert(note)
        dismiss()
    }
}

/// Screen 2: the live take. Elapsed time in big mono, red waveform, and the
/// transcript streaming in as you speak.
struct RecordingView: View {
    let recorder: RecorderEngine
    let onStop: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundStyle(Palette.dimmed)
                Spacer()
                statusBadge
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Text(TimeFormat.clock(recorder.elapsed))
                .font(.mono(56, weight: .light))
                .foregroundStyle(Palette.offWhite)
                .padding(.top, 28)
                .contentTransition(.numericText())

            LiveWaveformView(
                levels: recorder.liveLevels,
                isPaused: recorder.state == .paused
            )
            .frame(height: 88)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            transcriptArea
                .padding(.top, 12)

            controls
                .padding(.bottom, 32)
        }
        .background(Palette.charcoal)
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            switch recorder.state {
            case .recording:
                Circle().fill(Palette.recRed).frame(width: 9, height: 9)
                Text("REC").font(.mono(13, weight: .bold)).foregroundStyle(Palette.recRed)
            case .paused:
                Image(systemName: "pause.fill").font(.system(size: 9)).foregroundStyle(Palette.amber)
                Text("PAUSED").font(.mono(13, weight: .bold)).foregroundStyle(Palette.amber)
            case .requestingPermission, .idle:
                Text("STANDBY").font(.mono(13, weight: .bold)).foregroundStyle(Palette.dimmed)
            case .finishing:
                Text("SAVING").font(.mono(13, weight: .bold)).foregroundStyle(Palette.dimmed)
            case .failed:
                Text("ERROR").font(.mono(13, weight: .bold)).foregroundStyle(Palette.recRed)
            }
        }
    }

    private var transcriptArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if case .failed(let message) = recorder.state {
                        Text(message)
                            .font(.system(size: 17))
                            .foregroundStyle(Palette.recRed)
                    } else if recorder.liveTranscript.isEmpty {
                        Text(recorder.state == .recording ? "Listening…" : " ")
                            .font(.system(size: 22))
                            .foregroundStyle(Palette.dimmed)
                    } else {
                        Text(recorder.liveTranscript)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(Palette.offWhite)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .id("transcript")
            }
            .onChange(of: recorder.liveTranscript) {
                withAnimation { proxy.scrollTo("transcript", anchor: .bottom) }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var controls: some View {
        HStack(spacing: 48) {
            Button {
                if recorder.state == .paused {
                    recorder.resume()
                } else {
                    recorder.pause()
                }
            } label: {
                Image(systemName: recorder.state == .paused ? "record.circle" : "pause.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Palette.amber)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Palette.surface))
            }
            .disabled(!recorder.isActive)
            .accessibilityLabel(recorder.state == .paused ? "Resume" : "Pause")

            Button(action: onStop) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Palette.recRed)
                    .frame(width: 84, height: 84)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Palette.offWhite)
                            .frame(width: 28, height: 28)
                    )
            }
            .disabled(!recorder.isActive)
            .accessibilityLabel("Stop and review")

            // Mirror the pause button's footprint to keep stop centered.
            Color.clear.frame(width: 64, height: 64)
        }
    }
}
