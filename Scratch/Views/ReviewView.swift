import SwiftUI

/// Screen 3: review the take — fix the title or transcript, play it back
/// with word sync, then Save, Share, or Discard.
struct ReviewView: View {
    let result: RecordingResult
    let takeNumber: Int
    let onSave: (_ title: String, _ transcript: String, _ timings: [WordTiming]) -> Void
    let onDiscard: () -> Void

    @State private var title = ""
    @State private var transcript = ""
    @State private var isEditingTranscript = false
    @State private var transcriptWasEdited = false
    @State private var shareItems: [Any]?
    @State private var confirmDiscard = false
    @FocusState private var transcriptFocused: Bool

    /// Recognizer timings only stay valid while the text is untouched.
    private var currentTimings: [WordTiming] {
        transcriptWasEdited ? [] : result.wordTimings
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            TextField("Title", text: $title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Palette.offWhite)
                .padding(.horizontal, 20)

            HStack {
                Text(TimeFormat.clock(result.duration))
                    .font(.mono(13))
                    .foregroundStyle(Palette.dimmed)
                Spacer()
                Button(isEditingTranscript ? "Done" : "Edit text") {
                    if isEditingTranscript {
                        transcriptFocused = false
                    }
                    isEditingTranscript.toggle()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.amber)
            }
            .padding(.horizontal, 20)

            Group {
                if isEditingTranscript {
                    TextEditor(text: $transcript)
                        .font(.system(size: 19))
                        .foregroundStyle(Palette.offWhite)
                        .scrollContentBackground(.hidden)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12))
                        .focused($transcriptFocused)
                        .onAppear { transcriptFocused = true }
                        .onChange(of: transcript) { transcriptWasEdited = true }
                } else {
                    PlaybackTranscriptSection(
                        audioURL: AudioStore.url(for: result.audioFileName),
                        transcript: transcript,
                        wordTimings: currentTimings,
                        duration: result.duration
                    )
                }
            }
            .padding(.horizontal, 20)
            .frame(maxHeight: .infinity)

            actionBar
        }
        .padding(.top, 12)
        .background(Palette.charcoal)
        .onAppear {
            transcript = result.transcript
            title = TitleGenerator.title(from: result.transcript, takeNumber: takeNumber)
        }
        #if DEBUG
        .task {
            guard ProcessInfo.processInfo.environment["SCRATCH_AUTOSAVE"] == "1" else { return }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            onSave(
                title.isEmpty ? "Take \(takeNumber)" : title,
                transcript,
                currentTimings
            )
        }
        #endif
        .sheet(
            isPresented: Binding(
                get: { shareItems != nil },
                set: { if !$0 { shareItems = nil } }
            )
        ) {
            if let shareItems {
                ActivityView(items: shareItems)
                    .presentationDetents([.medium, .large])
            }
        }
        .confirmationDialog("Discard this take?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard Take", role: .destructive, action: onDiscard)
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("TAKE \(String(format: "%02d", takeNumber))")
                .font(.mono(13, weight: .bold))
                .foregroundStyle(Palette.amber)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button(role: .destructive) {
                confirmDiscard = true
            } label: {
                Text("Discard")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .foregroundStyle(Palette.dimmed)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))

            ShareMenu { kind in
                shareItems = kind.items(
                    transcript: transcript,
                    audioFileName: result.audioFileName,
                    title: title
                )
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Palette.offWhite)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))

            Button {
                onSave(
                    title.isEmpty ? "Take \(takeNumber)" : title,
                    transcript,
                    currentTimings
                )
            } label: {
                Text("Save")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .foregroundStyle(Palette.charcoal)
            .background(Palette.amber, in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
