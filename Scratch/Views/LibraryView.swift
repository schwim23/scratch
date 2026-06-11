import SwiftData
import SwiftUI

/// Screen 1: the library. Search across transcripts, rows with waveform
/// thumbnails, and the one oversized record button.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @State private var searchText = ""
    #if DEBUG
    @State private var isRecording =
        ProcessInfo.processInfo.environment["SCRATCH_AUTORECORD"] == "1"
    #else
    @State private var isRecording = false
    #endif
    @State private var showSettings = false
    @State private var router = CaptureRouter.shared

    private var filtered: [Note] {
        notes.filter { $0.matches(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.charcoal.ignoresSafeArea()
                if notes.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("scratch")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.offWhite)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Palette.dimmed)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .searchable(text: $searchText, prompt: "Search notes")
            .safeAreaInset(edge: .bottom) {
                recordButton
            }
            .toolbarBackground(Palette.charcoal, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $isRecording) {
            RecordingFlowView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onOpenURL { url in
            if url.scheme == "scratch", url.host() == "record" {
                isRecording = true
            }
        }
        .onChange(of: router.pendingCapture) { _, pending in
            if pending {
                router.pendingCapture = false
                isRecording = true
            }
        }
        .onAppear {
            if router.pendingCapture {
                router.pendingCapture = false
                isRecording = true
            }
        }
    }

    private var list: some View {
        List {
            ForEach(filtered) { note in
                NavigationLink(value: note) {
                    NoteRow(note: note)
                }
                .listRowBackground(Palette.charcoal)
                .listRowSeparatorTint(Palette.groove)
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: Note.self) { note in
            NoteDetailView(note: note)
        }
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 44))
                .foregroundStyle(Palette.groove)
            Text("No takes yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.offWhite)
            Text("Get it down rough.")
                .font(.system(size: 15))
                .foregroundStyle(Palette.dimmed)
        }
        .offset(y: -40)
    }

    private var recordButton: some View {
        Button {
            isRecording = true
        } label: {
            ZStack {
                Circle()
                    .fill(Palette.amber)
                    .frame(width: 76, height: 76)
                    .shadow(color: Palette.amber.opacity(0.35), radius: 18, y: 4)
                Image(systemName: "mic.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Palette.charcoal)
            }
        }
        .accessibilityLabel("Record a new note")
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Palette.charcoal.opacity(0), Palette.charcoal],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let note = filtered[index]
            AudioStore.delete(note.audioFileName)
            modelContext.delete(note)
        }
    }
}

struct NoteRow: View {
    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(note.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.offWhite)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    Text("·")
                    Text(TimeFormat.clock(note.duration))
                }
                .font(.mono(12))
                .foregroundStyle(Palette.dimmed)
            }
            Spacer(minLength: 8)
            WaveformThumbnailView(samples: note.waveform)
                .frame(width: 64, height: 22)
                .opacity(0.7)
        }
        .padding(.vertical, 6)
    }
}
