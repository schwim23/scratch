import SwiftData
import SwiftUI

/// Screen 4: a saved note — synced playback, edit, re-share, delete.
struct NoteDetailView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingTranscript = false
    @State private var shareItems: [Any]?
    @State private var confirmDelete = false
    @FocusState private var transcriptFocused: Bool

    var body: some View {
        VStack(spacing: 14) {
            TextField("Title", text: $note.title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Palette.offWhite)
                .padding(.horizontal, 20)

            HStack(spacing: 6) {
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                Text("·")
                Text(TimeFormat.clock(note.duration))
                Spacer()
                Button(isEditingTranscript ? "Done" : "Edit text") {
                    if isEditingTranscript { transcriptFocused = false }
                    isEditingTranscript.toggle()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.amber)
            }
            .font(.mono(12))
            .foregroundStyle(Palette.dimmed)
            .padding(.horizontal, 20)

            Group {
                if isEditingTranscript {
                    TextEditor(
                        text: Binding(
                            get: { note.transcript },
                            set: { newValue in
                                if newValue != note.transcript {
                                    note.transcript = newValue
                                    // Edited text no longer lines up with the
                                    // recognizer's word timings.
                                    note.wordTimings = []
                                }
                            }
                        )
                    )
                    .font(.system(size: 19))
                    .foregroundStyle(Palette.offWhite)
                    .scrollContentBackground(.hidden)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12))
                    .focused($transcriptFocused)
                    .onAppear { transcriptFocused = true }
                } else {
                    PlaybackTranscriptSection(
                        audioURL: note.audioURL,
                        transcript: note.transcript,
                        wordTimings: note.wordTimings,
                        duration: note.duration
                    )
                    .id(note.transcript)
                }
            }
            .padding(.horizontal, 20)
            .frame(maxHeight: .infinity)
        }
        .padding(.top, 12)
        .background(Palette.charcoal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareMenu { kind in
                    shareItems = kind.items(
                        transcript: note.transcript,
                        audioFileName: note.audioFileName,
                        title: note.title
                    )
                }
                .tint(Palette.amber)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .tint(Palette.dimmed)
            }
        }
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
        .confirmationDialog("Delete this note?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Note", role: .destructive) {
                AudioStore.delete(note.audioFileName)
                modelContext.delete(note)
                dismiss()
            }
        }
    }
}
