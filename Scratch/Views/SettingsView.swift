import SwiftUI

enum SettingsKeys {
    static let autoStopEnabled = "autoStopEnabled"
    static let autoStopSeconds = "autoStopSeconds"
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.autoStopEnabled) private var autoStopEnabled = true
    @AppStorage(SettingsKeys.autoStopSeconds) private var autoStopSeconds = 4.0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Auto-stop on silence", isOn: $autoStopEnabled)
                        .tint(Palette.amber)
                    if autoStopEnabled {
                        Stepper(value: $autoStopSeconds, in: 2...10, step: 1) {
                            HStack {
                                Text("After")
                                Text("\(Int(autoStopSeconds))s")
                                    .font(.mono(15))
                                    .foregroundStyle(Palette.amber)
                                Text("of silence")
                            }
                        }
                    }
                } header: {
                    Text("Recording")
                } footer: {
                    Text("When you stop talking, the take wraps itself up and goes straight to review. Hands stay free.")
                }
                .listRowBackground(Palette.surface)

                Section {
                    LabeledContent("Quick capture") {
                        Text("Settings → Action Button → Shortcut → New Take")
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.system(size: 14))
                } footer: {
                    Text("You can also say \"New Take in Scratch\" to Siri, or add the Scratch widget to your Lock Screen or Control Center.")
                }
                .listRowBackground(Palette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.charcoal)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
