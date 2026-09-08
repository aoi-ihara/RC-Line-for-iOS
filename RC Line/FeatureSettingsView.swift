import Photos
import SwiftUI

struct FeatureSettingsView: View {
    @AppStorage("fullScreenMode") private var fullScreenMode: Bool = true
    @AppStorage("ocrMode") private var ocrMode: Int = 0
    @AppStorage("autoScrool") private var autoScrool: Bool = true
    @AppStorage("saveToLibrary") private var saveToLibrary: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("priorityFrontCamera") private var priorityFrontCamera: Bool = false
    @AppStorage("textCase") private var textCase: Int = 0
    @AppStorage("featureDisplayMode") private var featureDisplayMode: Int = 0

    @AppStorage("splitByLineBreak") private var splitByLineBreak: Bool = true  // ↩
    @AppStorage("splitByPeriod") private var splitByPeriod: Bool = true  // 。 / .
    @AppStorage("splitByComma") private var splitByComma: Bool = false  // 、 / ,
    @AppStorage("splitByExclamationMark") private var splitByExclamationMark: Bool = true  // !
    @AppStorage("splitByQuestionMark") private var splitByQuestionMark: Bool = true  // ?
    @AppStorage("splitByBrackets") private var splitByBrackets: Bool = true  // 「」 / " / ' / []

    @AppStorage("selectedLnaguage") private var selectedLnaguage = "en-US"
    @AppStorage("readSpeed") private var readSpeed: Double = 0.5
    @AppStorage("postUtteranceDelay") private var postUtteranceDelay: Double = 0.9

    var body: some View {
        NavigationStack {
            List {
                Section("haptics") {
                    Toggle("haptic_feedback", isOn: $hapticsEnabled)
                        .accessibilityLabel(Text("haptic_feedback"))
                }

                Section(
                    content: {
                        Picker(
                            "preferred_camera", selection: $priorityFrontCamera,
                            content: {
                                Text("rear").tag(false)
                                Text("front").tag(true)
                            }
                        )
                        .accessibilityLabel(Text("preferred_camera"))

                        Picker(
                            selection: $ocrMode,
                            content: {
                                Text("high_precision").tag(0)
                                Text("high_speed").tag(1)
                            },
                            label: {
                                Text("ocr_accuracy")
                                Text("speed_mode_not_japanese")
                            }
                        )
                        .accessibilityLabel(Text("ocr_accuracy"))

                        if PHPhotoLibrary.authorizationStatus(for: .addOnly) != .denied {
                            Toggle(
                                isOn: $saveToLibrary,
                                label: {
                                    Text("save_to_photos")
                                    Text("add_captured_image")
                                }
                            )
                            .accessibilityLabel(Text("save_to_photos"))
                            .onChange(of: saveToLibrary) {
                                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in }
                            }
                        }
                    },
                    header: {
                        Text("load_image")
                    })

                Section("reader") {
                    Toggle(
                        isOn: $autoScrool,
                        label: {
                            Text("auto_scroll")
                            Text("scroll_to_highlight")
                        }
                    )
                    .accessibilityLabel(Text("auto_scroll"))

                    Picker("text_case", selection: $textCase) {
                        Text("text_case_original").tag(0)
                        Text("text_case_lowercase").tag(1)
                        Text("text_case_uppercase").tag(2)
                    }
                    .accessibilityLabel(Text("text_case"))

                    Picker("feature_display_mode", selection: $featureDisplayMode) {
                        Text("feature_display_mode_buttons").tag(0)
                        Text("feature_display_mode_gestures").tag(1)
                    }
                    .accessibilityLabel(Text("feature_display_mode"))
                }

                Section(
                    content: {
                        Toggle("line_break", isOn: $splitByLineBreak)
                            .accessibilityLabel(Text("line_break"))
                        Toggle("。 / .", isOn: $splitByPeriod)
                            .accessibilityLabel(Text("。 / ."))
                        Toggle("、 / ,", isOn: $splitByComma)
                            .accessibilityLabel(Text("、 / ,"))
                        Toggle("!", isOn: $splitByExclamationMark)
                            .accessibilityLabel(Text("!"))
                        Toggle("?", isOn: $splitByQuestionMark)
                            .accessibilityLabel(Text("?"))
                        Toggle("「」 / \" / ' / []", isOn: $splitByBrackets)
                            .accessibilityLabel(Text("「」 / \" / ' / []"))
                    },
                    header: {
                        Text("section")
                    },
                    footer: {
                        Text("split_by_symbol")
                    })

                Section(
                    content: {
                        Picker(
                            "language", selection: $selectedLnaguage,
                            content: {
                                Text("English").tag("en-US")
                                Text("English (United Kingdom)").tag("en-GB")
                                Text("English (Australia)").tag("en-AU")
                                Text("日本語").tag("ja-JP")
                                Text("한국어").tag("ko-KR")
                                Text("简体中文").tag("zh-CN")
                                Text("繁體中文 (香港)").tag("zh-HK")
                                Text("Français").tag("fr-FR")
                                Text("Deutsch").tag("de-DE")
                                Text("Español").tag("es-ES")
                                Text("Italiano").tag("it-IT")
                                Text("Português").tag("pt-PT")
                                Text("Русский").tag("ru-RU")
                            }
                        )
                        .accessibilityLabel(Text("language"))

                        HStack {
                            Image(systemName: "tortoise.fill")
                            Slider(value: $readSpeed, in: 0...1, step: 0.02)
                                .accessibilityLabel(Text("read_aloud_feature"))
                                .accessibilityValue(Text("\(Int(readSpeed * 100))%"))
                            Image(systemName: "hare.fill")
                        }
                    },
                    header: {
                        Text("read_aloud_feature")
                    },
                    footer: {
                        Text("\(Int(readSpeed*100))%")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "tortoise.fill")
                            Slider(value: $postUtteranceDelay, in: 0...1, step: 0.02)
                                .accessibilityLabel(Text("pause_duration"))
                                .accessibilityValue(Text("\(Int(postUtteranceDelay * 100))%"))
                            Image(systemName: "hare.fill")
                        }
                    },
                    header: {
                        Text("pause_duration")
                    },
                    footer: {
                        Text("\(Int(postUtteranceDelay*100))%")
                    })
            }
            .navigationTitle("features")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
