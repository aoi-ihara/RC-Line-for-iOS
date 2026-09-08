import ARKit
import AVFoundation
import FoundationModels
import SwiftUI

struct AdvancedFeaturesSettingsView: View {
    @AppStorage("summrizeText") private var summrizeText = false
    @AppStorage("insertSpaceBitweenWords") private var insertSpaceBitweenWords = false
    @AppStorage("spaceInserted") private var spaceInserted = " "
    @AppStorage("trackGaze") private var trackGaze = false
    @AppStorage("summarizeInstructions") private var summarizeInstructions: String = """
        Summarize the following text in 128 characters or less using only simple, easy words. Output only the summary. No extra explanation or comments.
        """
    @AppStorage("explanationInstructions") private var explanationInstructions: String = """
        Please explain this text in a way that even an elementary school kid can understand. Do not use any structure or line breaks.
        """

    private var isARKitSupported: Bool {
        ARFaceTrackingConfiguration.isSupported
    }

    let status = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        NavigationStack {
            List {
                if #available(iOS 18.1, *) {
                    let available = SystemLanguageModel.default.isAvailable

                    if available {
                        Section {
                            Toggle(
                                isOn: $summrizeText,
                                label: {
                                    Text("summarize")
                                    Text("summarize_explanation")
                                }
                            )
                            .accessibilityLabel(Text("summarize"))
                            .accessibilityHint(Text("summarize_explanation"))
                            .accessibilityAddTraits(.updatesFrequently)
                            .onChange(of: summrizeText) {
                                UIAccessibility.post(
                                    notification: .announcement,
                                    argument: summrizeText
                                        ? NSLocalizedString("summarize_enabled", comment: "")
                                        : NSLocalizedString("summarize_disabled", comment: ""))
                            }

                            if summrizeText {
                                NavigationLink {
                                    summarizeInstructionsEditor
                                } label: {
                                    HStack {
                                        Text("prompt")
                                            .padding(.trailing)
                                        Spacer()
                                        Text(summarizeInstructions)
                                            .lineLimit(1)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } header: {
                            Text("summarize")
                        }
                    }
                }

                Section {
                    Toggle(
                        isOn: $insertSpaceBitweenWords,
                        label: {
                            Text("word_separation")
                            Text("word_separation_explanation")
                        }
                    )
                    .accessibilityLabel(Text("word_separation"))
                    .accessibilityHint(Text("word_separation_explanation"))
                    .onChange(of: insertSpaceBitweenWords) {
                        UIAccessibility.post(
                            notification: .announcement,
                            argument: insertSpaceBitweenWords
                                ? NSLocalizedString("word_separation_enabled", comment: "")
                                : NSLocalizedString("word_separation_disabled", comment: ""))
                    }

                    if insertSpaceBitweenWords {
                        Picker("separator", selection: $spaceInserted) {
                            Text("half_width_space").tag(" ")
                            Text("full_width_space").tag("　")
                            Text("slash").tag("/")
                            Text("hyphen").tag("-")
                            Text("space_slash").tag(" / ")
                            Text("space_hyphen").tag(" - ")
                        }
                    }
                } header: {
                    Text("word_separation")
                }

                if #available(iOS 18.1, *) {
                    let available = SystemLanguageModel.default.isAvailable

                    if available {
                        Section {
                            NavigationLink {
                                explanationInstructionsEditor
                            } label: {
                                HStack {
                                    Text("prompt")
                                        .padding(.trailing)
                                    Spacer()
                                    Text(explanationInstructions)
                                        .lineLimit(1)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } header: {
                            Text("explanation")
                        }
                    }
                }
            }
            .navigationTitle("advanced_features")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var summarizeInstructionsEditor: some View {
        NavigationStack {
            List {
                TextField("prompt", text: $summarizeInstructions)
            }
            .navigationTitle("prompt")
        }
    }

    private var explanationInstructionsEditor: some View {
        NavigationStack {
            List {
                TextField("prompt", text: $explanationInstructions)
            }
            .navigationTitle("prompt")
        }
    }
}