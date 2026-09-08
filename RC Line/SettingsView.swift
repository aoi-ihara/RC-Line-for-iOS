import ARKit
import FoundationModels
import PhotosUI
import SwiftUI
import UIKit

struct DashboardView: View {
    @Binding var isSidebarOpen: Bool
    @Binding var pasteAlert: Bool
    @Binding var ocrText: String
    @Binding var showSettingsView: Bool
    @Binding var wasScrolled: Bool

    let disabled: Bool

    @State private var showPasteError: Bool = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @Namespace private var glassNamespace
    @State private var selectedItem: PhotosPickerItem? = nil

    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("backgroundColor") private var storedBackground: CodableColor = .init(.white)
    @AppStorage("foregroundColor") private var storedForeground: CodableColor = .init(.black)
    @AppStorage("storedForegroundDark") private var storedForegroundDark: CodableColor = .init(
        .white)
    @AppStorage("storedBackgroundDark") private var storedBackgroundDark: CodableColor = .init(
        .black)
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("theme") private var theme = 0
    @AppStorage("doNotShowClipboardAlert") private var doNotShowClipboardAlert: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack(alignment: .leading) {
                    Button(
                        action: {
                            if !disabled {
                                if let clipboard = UIPasteboard.general.string {
                                    ocrText = clipboard

                                    withAnimation(.timingCurve(.easeOut, duration: 0.3)) {
                                        pasteAlert = true
                                    }
                                    UIAccessibility.post(
                                        notification: .announcement,
                                        argument: NSLocalizedString(
                                            "pasted_from_clipboard", comment: ""))

                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isSidebarOpen = false
                                    }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation(.timingCurve(.easeOut, duration: 0.3)) {
                                            pasteAlert = false
                                        }
                                    }
                                } else {
                                    if !doNotShowClipboardAlert {
                                        showPasteError = true
                                    }

                                    UIAccessibility.post(
                                        notification: .announcement,
                                        argument: NSLocalizedString(
                                            "clipboard_is_empty", comment: ""))

                                    if hapticsEnabled {
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.prepare()
                                        generator.notificationOccurred(.error)
                                    }
                                }
                            }
                        },
                        label: {
                            HStack {
                                Image(systemName: "document.on.clipboard.fill")
                                    .font(.system(size: 20))
                                    .fontWeight(.semibold)
                                Text("from_clipboard")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                            }
                            .padding(8)
                            .frame(width: 200, alignment: .leading)
                        }
                    )
                    .buttonStyle(.glassProminent)
                    .alert("clipboard_is_empty", isPresented: $showPasteError) {
                        Button("close", role: .cancel) {}
                        Button("do_not_show_again", role: .destructive) {
                            doNotShowClipboardAlert = true
                        }
                    }
                    .foregroundStyle(
                        colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color
                    )
                    .padding(4)
                    .accessibilityLabel(Text("from_clipboard"))
                    .accessibilityHint(Text("paste_text_from_clipboard"))
                    .accessibilityAddTraits(.isButton)

                    Button(
                        action: {
                            if !disabled {
                                showImagePicker = true
                                UIAccessibility.post(
                                    notification: .screenChanged,
                                    argument: NSLocalizedString("photo_picker_opened", comment: ""))

                                if hapticsEnabled {
                                    let generator = UISelectionFeedbackGenerator()
                                    generator.prepare()
                                    generator.selectionChanged()
                                }
                            }
                        },
                        label: {
                            HStack {
                                Image(systemName: "photo.stack.fill")
                                    .font(.system(size: 20))
                                    .fontWeight(.semibold)
                                Text("from_camera_roll")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                            }
                            .padding(8)
                            .frame(width: 200, alignment: .leading)
                        }
                    )
                    .foregroundStyle(
                        colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color
                    )
                    .buttonStyle(.glassProminent)
                    .padding(4)
                    .accessibilityLabel(Text("from_camera_roll"))
                    .accessibilityHint(Text("select_image_from_library"))
                    .accessibilityAddTraits(.isButton)
                }
                .padding(.vertical, 100)

                Button(
                    action: {
                        if !disabled {
                            showSettingsView.toggle()
                            UIAccessibility.post(
                                notification: .screenChanged,
                                argument: NSLocalizedString("settings_opened", comment: ""))

                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isSidebarOpen = false
                            }
                            withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                                wasScrolled = false
                            }
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                            Text("settings")
                                .font(.system(size: 16))
                                .fontWeight(.semibold)
                        }
                        .padding(8)
                        .frame(width: 200, alignment: .leading)
                    }
                )
                .buttonStyle(.glass)
                .accessibilityLabel(Text("settings"))
                .accessibilityHint(Text("open_settings"))
                .accessibilityAddTraits(.isButton)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color)
            .photosPicker(
                isPresented: $showImagePicker, selection: $selectedItem, matching: .images
            )
            .onChange(of: selectedItem) {
                Task {
                    guard let data = try? await selectedItem?.loadTransferable(type: Data.self),
                        let image = UIImage(data: data)
                    else { return }

                    await MainActor.run {
                        self.selectedImage = image
                        UIAccessibility.post(
                            notification: .announcement,
                            argument: NSLocalizedString("image_selected", comment: ""))
                    }

                    performOCR(on: image) { text in
                        Task { @MainActor in
                            self.ocrText = text

                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isSidebarOpen = false
                            }

                            UIAccessibility.post(
                                notification: .screenChanged,
                                argument: NSLocalizedString(
                                    "image_processing_complete", comment: "")
                            )
                        }
                    }
                }
            }
        }
    }

    var effects: some View {
        NavigationStack {
            List {
            }
            .navigationTitle("highlight")
        }
    }

    var font: some View {
        NavigationStack {
            List {

            }
            .navigationTitle("fonts")
        }
    }
}

struct SettingsView: View {
    @Binding var showSettingsView: Bool

    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: FontSettingsView()) {
                    Label("fonts", systemImage: "textformat")
                        .foregroundStyle(Color(.label))
                }
                .accessibilityLabel(Text("fonts"))
                .accessibilityAddTraits(.isLink)

                NavigationLink(destination: HighlightSettingsView()) {
                    Label("highlight", systemImage: "text.line.magnify")
                        .foregroundStyle(Color(.label))
                }
                .accessibilityLabel(Text("highlight"))
                .accessibilityAddTraits(.isLink)

                NavigationLink(destination: ColorSettingsView()) {
                    Label("colors", systemImage: "camera.filters")
                        .foregroundStyle(Color(.label))
                }
                .accessibilityLabel(Text("colors"))
                .accessibilityAddTraits(.isLink)

                NavigationLink(destination: FeatureSettingsView()) {
                    Label("features", systemImage: "wrench.and.screwdriver")
                        .foregroundStyle(Color(.label))
                }
                .accessibilityLabel(Text("features"))
                .accessibilityAddTraits(.isLink)

                NavigationLink(destination: AdvancedFeaturesSettingsView()) {
                    Label("advanced_features", systemImage: "square.badge.plus")
                        .foregroundStyle(Color(.label))
                }
                .accessibilityLabel(Text("advanced_features"))
                .accessibilityAddTraits(.isLink)

                NavigationLink(destination: InformationView()) {
                    Label("info", systemImage: "info.circle")
                        .foregroundStyle(Color(.label))
                }
                .accessibilityLabel(Text("info"))
                .accessibilityAddTraits(.isLink)
            }
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettingsView.toggle()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Text("close"))
                    .accessibilityHint(Text("close_settings"))
                    .accessibilityAddTraits(.isButton)
                }
            }

        }
    }
}

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
}

extension AdvancedFeaturesSettingsView {
    var summarizeInstructionsEditor: some View {
        NavigationStack {
            List {
                TextField("prompt", text: $summarizeInstructions)
            }
            .navigationTitle("prompt")
        }
    }
}

extension AdvancedFeaturesSettingsView {
    var explanationInstructionsEditor: some View {
        NavigationStack {
            List {
                TextField("prompt", text: $explanationInstructions)
            }
            .navigationTitle("prompt")
        }
    }
}

struct FontSettingsView: View {
    @AppStorage("lineWidth") private var lineWidth: Double = 75
    @AppStorage("fontSize") private var fontSize: Double = 13
    @AppStorage("fontFamily") private var fontFamily: Int = 0
    @AppStorage("fontWeight") private var fontWeight: Int = 4
    @AppStorage("lineHeight") private var lineHeight: Double = 2
    @AppStorage("sectionSpacing") private var sectionSpacing: Double = 8
    @AppStorage("letterSpacing") private var letterSpacing: Double = 1.05

    var body: some View {
        NavigationStack {
            List {
                Section(content: {
                    Picker(
                        "font_family_reading", selection: $fontFamily,
                        content: {
                            Text("system_sans").tag(0)
                            Text("system_serif").tag(1)
                            Text("Lexend").tag(3)
                        }
                    )
                    .pickerStyle(.menu)
                    .accessibilityLabel(Text("font_family_reading"))

                    Picker(
                        "weight", selection: $fontWeight,
                        content: {
                            Text("ultra_light").tag(0)
                            Text("thin").tag(1)
                            Text("light").tag(2)
                            Text("regular").tag(3)
                            Text("medium").tag(4)
                            Text("semibold").tag(5)
                            Text("bold").tag(6)
                            Text("heavy").tag(7)
                            Text("black").tag(8)
                        }
                    )
                    .pickerStyle(.menu)
                    .accessibilityLabel(Text("weight"))
                })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "textformat.size.smaller")

                            Slider(value: $fontSize, in: 6...32, step: 1)
                                .accessibilityLabel(Text("font_size"))
                                .accessibilityValue(Text("\(Int(fontSize))px"))
                                .onChange(
                                    of: fontSize,
                                    {
                                        UserDefaults.standard.setValue(fontSize, forKey: "fontSize")
                                    })

                            Image(systemName: "textformat.size.larger")
                        }
                    },
                    header: {
                        Text("font_size")
                    },
                    footer: {
                        Text("\(Int(fontSize))px")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "arrow.right.and.line.vertical.and.arrow.left")

                            Slider(value: $lineWidth, in: 50...100, step: 1)
                                .accessibilityLabel(Text("line_width"))
                                .accessibilityValue(Text("\(Int(lineWidth))%"))

                            Image(systemName: "arrow.left.and.line.vertical.and.arrow.right")
                        }
                    },
                    header: {
                        Text("line_width")
                    },
                    footer: {
                        Text("\(Int(lineWidth))%")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")

                            Slider(value: $lineHeight, in: 0...4, step: 0.1)
                                .accessibilityLabel(Text("line_spacing"))
                                .accessibilityValue(Text("\(Int(lineHeight*100))%"))

                            Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                        }
                    },
                    header: {
                        Text("line_spacing")
                    },
                    footer: {
                        Text("\(Int(lineHeight*100))%")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")

                            Slider(value: $sectionSpacing, in: 0...20, step: 1)
                                .accessibilityLabel(Text("section_spacing"))
                                .accessibilityValue(Text("\(Int(sectionSpacing))pt"))

                            Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                        }
                    },
                    header: {
                        Text("section_spacing")
                    },
                    footer: {
                        Text("\(Int(sectionSpacing))pt")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "arrow.right.and.line.vertical.and.arrow.left")

                            Slider(value: $letterSpacing, in: 1...2, step: 0.01)
                                .accessibilityLabel(Text("letter_spacing"))
                                .accessibilityValue(Text("\(Int(letterSpacing * 100))%"))

                            Image(systemName: "arrow.left.and.line.vertical.and.arrow.right")
                        }
                    },
                    header: {
                        Text("letter_spacing")
                    },
                    footer: {
                        Text("\(Int(letterSpacing * 100))%")
                    })
            }
            .navigationTitle("fonts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HighlightSettingsView: View {
    @AppStorage("borderOpacity") var borderOpacity: Double = 0
    @AppStorage("textOpacity") var textOpacity: Double = 0.15
    @AppStorage("scaleEffect") var scaleEffect: Bool = false
    @AppStorage("selectedTextOpacity") var selectedTextOpacity: Double = 0.25
    @AppStorage("animate") private var animate: Bool = true

    var body: some View {
        NavigationStack {
            List {
                Section(
                    content: {
                        HStack {
                            Image(systemName: "character")

                            Slider(value: $selectedTextOpacity, in: 0...1, step: 0.05)
                                .accessibilityLabel(Text("background_opacity"))
                                .accessibilityValue(Text("\(Int(selectedTextOpacity*100))%"))

                            Image(systemName: "a.square.fill")
                        }
                    },
                    header: {
                        Text("background_opacity")
                    },
                    footer: {
                        Text("\(Int(selectedTextOpacity*100))%")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "square.dotted")

                            Slider(value: $borderOpacity, in: 0...1, step: 0.05)
                                .accessibilityLabel(Text("border_opacity"))
                                .accessibilityValue(Text("\(Int(borderOpacity*100))%"))

                            Image(systemName: "square")
                        }
                    },
                    header: {
                        Text("border_opacity")
                    },
                    footer: {
                        Text("\(Int(borderOpacity*100))%")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "square.stack.3d.forward.dottedline")

                            Slider(value: $textOpacity, in: 0...0.5, step: 0.05)
                                .accessibilityLabel(Text("fade_distance"))
                                .accessibilityValue(Text("\(Int(textOpacity*100))%"))

                            Image(systemName: "square.stack.3d.forward.dottedline.fill")
                        }
                    },
                    header: {
                        Text("fade_distance")
                    },
                    footer: {
                        Text("\(Int(textOpacity*100))%")
                    })

                Toggle("animations", isOn: $animate)
                    .accessibilityLabel(Text("animations"))
                Toggle("scale_effect", isOn: $scaleEffect)
                    .accessibilityLabel(Text("scale_effect"))
            }
            .navigationTitle("highlight")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CodableColor: RawRepresentable, Codable, Equatable {
    var color: Color

    init(_ color: Color) { self.color = color }

    init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else { return nil }
        do {
            if let uiColor = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: UIColor.self, from: data)
            {
                self.color = Color(uiColor)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: UIColor(color), requiringSecureCoding: false)
            return data.base64EncodedString()
        } catch {
            return ""
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = CodableColor(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid color data")
        }
        self = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct ColorSettingsView: View {
    @AppStorage("foregroundColor") private var storedForeground: CodableColor = .init(.black)
    @AppStorage("backgroundColor") private var storedBackground: CodableColor = .init(.white)
    @AppStorage("highlightColor") private var storedHighlight: CodableColor = .init(.red)
    @AppStorage("storedForegroundDark") private var storedForegroundDark: CodableColor = .init(
        .white)
    @AppStorage("storedBackgroundDark") private var storedBackgroundDark: CodableColor = .init(
        .black)
    @AppStorage("storedHighlightDark") private var storedHighlightDark: CodableColor = .init(.red)
    @AppStorage("theme") private var theme = 0

    private var foregroundColorBinding: Binding<Color> {
        Binding(
            get: { storedForeground.color },
            set: { storedForeground = CodableColor($0) }
        )
    }

    private var backgroundColorBinding: Binding<Color> {
        Binding(
            get: { storedBackground.color },
            set: { storedBackground = CodableColor($0) }
        )
    }

    private var highlightBinding: Binding<Color> {
        Binding(
            get: { storedHighlight.color },
            set: { storedHighlight = CodableColor($0) }
        )
    }

    private var foregroundColorBindingDark: Binding<Color> {
        Binding(
            get: { storedForegroundDark.color },
            set: { storedForegroundDark = CodableColor($0) }
        )
    }

    private var backgroundColorBindingDark: Binding<Color> {
        Binding(
            get: { storedBackgroundDark.color },
            set: { storedBackgroundDark = CodableColor($0) }
        )
    }

    private var highlightBindingDark: Binding<Color> {
        Binding(
            get: { storedHighlightDark.color },
            set: { storedHighlightDark = CodableColor($0) }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(
                        "theme", selection: $theme,
                        content: {
                            Text("auto").tag(0)
                            Text("theme_light").tag(1)
                            Text("dark").tag(2)
                        })
                } header: {
                    Text("appearance")
                }

                if theme != 2 {
                    Section {
                        ColorPicker("background_color", selection: backgroundColorBinding)
                            .accessibilityLabel(Text("background_color"))

                        ColorPicker("text_color", selection: foregroundColorBinding)
                            .accessibilityLabel(Text("text_color"))

                        ColorPicker("highlight_color", selection: highlightBinding)
                            .accessibilityLabel(Text("highlight_color"))
                    } header: {
                        if theme == 0 {
                            Text("light_mode")
                        }
                    }
                }

                if theme != 1 {
                    Section {
                        ColorPicker("background_color", selection: backgroundColorBindingDark)
                            .accessibilityLabel(Text("background_color"))

                        ColorPicker("text_color", selection: foregroundColorBindingDark)
                            .accessibilityLabel(Text("text_color"))

                        ColorPicker("highlight_color", selection: highlightBindingDark)
                            .accessibilityLabel(Text("highlight_color"))
                    } header: {
                        if theme == 0 {
                            Text("dark_mode")
                        }
                    }
                }
            }
            .navigationTitle("colors")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FeatureSettingsView: View {
    @AppStorage("fullScreenMode") private var fullScreenMode: Bool = true
    @AppStorage("ocrMode") private var ocrMode: Int = 0
    @AppStorage("autoScrool") private var autoScrool: Bool = true
    @AppStorage("saveToLibrary") private var saveToLibrary: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("priorityFrontCamera") private var priorityFrontCamera: Bool = false

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

struct InformationView: View {
    @Environment(\.openURL) var openURL

    @State private var showWelcomeView: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(
                        action: {
                            showWelcomeView = true
                        },
                        label: {
                            Label("show_tutorial", systemImage: "lightbulb")
                                .foregroundStyle(Color(.label))
                        }
                    )
                    .accessibilityLabel(Text("show_tutorial"))
                    .accessibilityHint(Text("opens_tutorial"))
                    .accessibilityAddTraits(.isButton)
                    .frame(alignment: .center)
                }

                Section("version_info") {
                    if let version = Bundle.main.object(
                        forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                    {
                        Text(version)
                    }
                }
            }
            .navigationTitle("info")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: showWelcomeView) {
                UIAccessibility.post(
                    notification: showWelcomeView ? .screenChanged : .announcement,
                    argument: showWelcomeView
                        ? NSLocalizedString("tutorial_opened", comment: "")
                        : NSLocalizedString("tutorial_closed", comment: ""))
            }
            .fullScreenCover(
                isPresented: $showWelcomeView,
                content: {
                    WelcomeView(showWelcomeView: $showWelcomeView)
                        .accentColor(Color(.label))
                        .presentationDetents([.large])
                        .interactiveDismissDisabled(true)
                }
            )
        }
    }
}

#Preview {
    ContentView()
}
