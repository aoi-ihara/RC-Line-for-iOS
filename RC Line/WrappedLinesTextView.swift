import AVFoundation
import FoundationModels
import NaturalLanguage
import SwiftUI
import ARKit

struct WrappedLinesTextView: View {
    @Binding var speaking: Bool
    @State private var speakingLine = 0

    let text: String
    let font: Font
    let smallFont: Font
    @Binding var focusingLine: Int
    @Binding var wasScrolled: Bool
    let screenWidth: CGFloat
    let fontSize: CGFloat
    @Binding var showExplanation: Bool
    @Binding var explanation: String
    @Binding var eyeTracking: Bool
    @Binding var maxFocusingLine: Int

    let synthesizer = AVSpeechSynthesizer()
    @State private var showSimulatorAlert: Bool = false
    
    private var isARKitSupported: Bool {
        ARFaceTrackingConfiguration.isSupported
    }

    @AppStorage("splitByLineBreak") private var splitByLineBreak: Bool = true
    @AppStorage("splitByPeriod") private var splitByPeriod: Bool = true
    @AppStorage("splitByComma") private var splitByComma: Bool = false
    @AppStorage("splitByExclamationMark") private var splitByExclamationMark: Bool = true
    @AppStorage("splitByQuestionMark") private var splitByQuestionMark: Bool = true
    @AppStorage("splitByBrackets") private var splitByBrackets: Bool = true

    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("autoScrool") var autoScrool: Bool = true
    @AppStorage("lineWidth") var lineWidth: Double = 75
    @AppStorage("scaleEffect") var scaleEffect: Bool = false
    @AppStorage("selectedTextOpacity") var selectedTextOpacity: Double = 0.25
    @AppStorage("borderOpacity") var borderOpacity: Double = 0
    @AppStorage("textOpacity") var textOpacity: Double = 0.15
    @AppStorage("foregroundColor") private var storedForeground: CodableColor = .init(.black)
    @AppStorage("backgroundColor") private var storedBackground: CodableColor = .init(.white)
    @AppStorage("highlightColor") private var storedHighlight: CodableColor = .init(.red)
    @AppStorage("storedForegroundDark") private var storedForegroundDark: CodableColor = .init(.white)
    @AppStorage("storedBackgroundDark") private var storedBackgroundDark: CodableColor = .init(.black)
    @AppStorage("storedHighlightDark") private var storedHighlightDark: CodableColor = .init(.red)
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("theme") private var theme = 0
    @AppStorage("fontFamily") var fontFamily: Int = 0
    @AppStorage("fontWeight") var fontWeight: Int = 4
    @AppStorage("animate") var animate: Bool = true
    @AppStorage("lineHeight") private var lineHeight: Double = 2
    @AppStorage("sectionSpacing") private var sectionSpacing: Double = 8
    @AppStorage("letterSpacing") private var letterSpacing: Double = 1.05
    @AppStorage("summrizeText") private var summrizeText: Bool = false
    @AppStorage("insertSpaceBitweenWords") private var insertSpaceBitweenWords = false
    @AppStorage("spaceInserted") private var spaceInserted = " "
    @AppStorage("separateByWord") private var separateByWord = false
    @AppStorage("summarizeInstructions") private var summarizeInstructions: String = """
        Summarize the following text in 128 characters or less using only simple, easy words. Output only the summary. No extra explanation or comments.
        """
    @AppStorage("explanationInstructions") private var explanationInstructions: String = """
        Please explain this text in a way that even an elementary school kid can understand. Do not use any structure or line breaks.
        """
    @AppStorage("selectedLnaguage") private var selectedLnaguage = "en-US"
    @AppStorage("readSpeed") private var readSpeed: Double = 0.5
    @AppStorage("postUtteranceDelay") private var postUtteranceDelay: Double = 0.9

    @State private var measuredLines: [String] = []
    @State private var measuredLinesRaw: [String] = []
    @State private var summary = ""

    let fontWightList: [Font.Weight] = [
        .thin, .thin, .regular, .regular, .semibold, .semibold, .bold, .bold, .heavy, .heavy,
    ]
    private let model = SystemLanguageModel.default
    
    @State var explanationSession = LanguageModelSession()
    @State var summarizeSession = LanguageModelSession()
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundCalculationView
            mainContentView
        }
    }
}

extension WrappedLinesTextView {
    fileprivate var backgroundCalculationView: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    updateMeasuredLines()
                    
                    maxFocusingLine = measuredLines.count
                }
                .onChange(of: proxy.size.width) { _, _ in
                    updateMeasuredLines()
                    
                    maxFocusingLine = measuredLines.count
                }
                .onChange(of: currentSplitSettings) {
                    updateMeasuredLines()
                    
                    maxFocusingLine = measuredLines.count
                }
                .onChange(of: text) {
                    updateMeasuredLines()
                    generateSummary()
                    
                    maxFocusingLine = measuredLines.count
                }
                .onChange(of: insertSpaceBitweenWords) {
                    updateMeasuredLines()
                    
                    maxFocusingLine = measuredLines.count
                }
                .onChange(of: spaceInserted) {
                    updateMeasuredLines()
                    
                    maxFocusingLine = measuredLines.count
                }
                .onChange(of: separateByWord) {
                    updateMeasuredLines()
                    
                    maxFocusingLine = measuredLines.count
                }
        }
    }

    fileprivate var mainContentView: some View {
        ScrollViewReader { scrollProxy in
            LazyVStack(spacing: 0) {
                if text.isEmpty {
                    emptyStateView
                } else {
                    if !summary.isEmpty && summrizeText {
                        summaryView
                    }
                }

                linesListView(scrollProxy: scrollProxy)
            }
            .padding(.bottom, 100)
            .onChange(of: focusingLine, {
                focusLineForAccessibility(focusingLine)
            })
        }
    }

    fileprivate var emptyStateView: some View {
        VStack {
            VStack {
                Image(systemName: "camera.fill")
                    .imageScale(.large)
                    .foregroundStyle(colorScheme == .dark ? storedForegroundDark.color : storedForeground.color)
                    .padding()
                Text("swipe_left_to_camera")
                    .fontWeight(.semibold)
                    .foregroundStyle(colorScheme == .dark ? storedForegroundDark.color : storedForeground.color)
            }
            .padding(.top, 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    fileprivate var summaryView: some View {
        Text(summary == "generating_summary" ? "Generating Summary" : summary)
            .foregroundStyle(colorScheme == .dark ? storedForegroundDark.color : storedForeground.color)
            .frame(width: screenWidth * CGFloat(lineWidth) / 100, alignment: .leading)
            .opacity(wasScrolled ? 0.5 : 0)
            .lineSpacing(fontSize * (lineHeight - 1))
            .padding(10)
            .font(smallFont)
            .fontWeight(fontWightList[fontWeight])
            .blur(radius: wasScrolled ? 0 : (abs(Double(0 - focusingLine) - 0.25) - 0.25) * 1)
    }

    fileprivate func linesListView(scrollProxy: ScrollViewProxy) -> some View {
        ForEach(Array(measuredLines.enumerated()), id: \.offset) { index, line in
            lineRow(index: index, line: line, rawText: text, scrollProxy: scrollProxy)
        }
    }
    
    func focusLineForAccessibility(_ index: Int) {
        guard index < measuredLines.count else { return }
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
        UIAccessibility.post(notification: .announcement, argument: measuredLines[index])
    }

    func lineRow(
        index: Int, line: String, rawText: String, scrollProxy: ScrollViewProxy
    ) -> some View {
        VStack(alignment: .leading) {
            let lineTextOpacity =
            (focusingLine == index || wasScrolled)
            ? 1 : (0.5 - Double(abs(index - focusingLine)) * textOpacity)
            
            VStack {
                Text(line)
                    .foregroundStyle(colorScheme == .dark ? storedForegroundDark.color : storedForeground.color)
                    .frame(width: screenWidth * CGFloat(lineWidth) / 100, alignment: .leading)
                    .font(font)
                    .fontWeight(fontWightList[fontWeight])
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(lineTextOpacity)
                    .id(index)
                    .tracking(fontSize * (letterSpacing - 1))
                    .lineSpacing(fontSize * (lineHeight - 1))
                    .padding(CGFloat(sectionSpacing))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                colorScheme == .dark ? storedHighlightDark.color : storedHighlight.color
                            ).opacity((index == focusingLine && !wasScrolled) ? selectedTextOpacity : 0)
                    )
                    .accessibilityLabel(line)
                    .overlay {
                        if index == focusingLine && !wasScrolled {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .dark ? storedHighlightDark.color.opacity(borderOpacity) : storedHighlight.color.opacity(borderOpacity), lineWidth: 2)
                        }
                    }
                    .blur(
                        radius: wasScrolled
                        ? 0.0 : (abs(Double(index - focusingLine) - 0.25) - 0.25) * 1
                    )
                    .padding(CGFloat(sectionSpacing))
            }
            .scaleEffect(scaleEffect && (index == focusingLine && !wasScrolled) ? 1.05 : 1.0)
            .background(colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color)
            .contextMenu {
                if !eyeTracking {
                    if speaking {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                stopSpeaking()
                            }
                        } label: {
                            Label("stop_speaking", systemImage: "speaker.slash")
                        }
                        .accessibilityLabel("stop_speaking")
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                speakingLine = index
                                focusingLine = index
                                startSpeaking(text: measuredLinesRaw, index: index, scrollProxy: scrollProxy)
                            }
                        } label: {
                            Label("start_speaking", systemImage: "speaker.wave.2")
                        }
                        .accessibilityLabel("start_speaking")
                    }
                }
                
#if targetEnvironment(simulator)
                Button {
                    showSimulatorAlert.toggle()
                } label: {
                    Label("explanation", systemImage: "text.append")
                }
                .accessibilityLabel("explanation")
                
                Button {
                    showSimulatorAlert.toggle()
                } label: {
                    Label("start_eye_tracking", systemImage: "eye")
                }
                .accessibilityLabel("start_eye_tracking")
#else
                if isARKitSupported {
                    if !speaking {
                        if eyeTracking {
                            Button(role: .destructive) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    eyeTracking = false
                                    wasScrolled = true
                                }
                            } label: {
                                Label("stop_eye_tracking", systemImage: "eye.slash")
                            }
                            .accessibilityLabel("stop_eye_tracking")
                        } else {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    eyeTracking = true
                                    wasScrolled = false
                                    focusingLine = index
                                }
                            } label: {
                                Label("start_eye_tracking", systemImage: "eye")
                            }
                            .accessibilityLabel("start_eye_tracking")
                        }
                    }
                }

                if #available(iOS 18.1, *) {
                    let available = SystemLanguageModel.default.isAvailable

                    if available {
                        Button {
                            showExplanation.toggle()

                            explanation = line

                            focusingLine = index

                            if autoScrool {
                                if animate {
                                    DispatchQueue.main.async {
                                        withAnimation {
                                            scrollProxy.scrollTo(
                                                focusingLine, anchor: UnitPoint(x: 0.5, y: 0.25))
                                        }
                                    }
                                } else {
                                    scrollProxy.scrollTo(
                                        focusingLine, anchor: UnitPoint(x: 0.5, y: 0.25))
                                }
                            }

                            generateExplanation(rawText: measuredLinesRaw[index])
                        } label: {
                            Label("explanation", systemImage: "text.append")
                        }
                        .accessibilityLabel("explanation")
                    }
                }
#endif
            }
        }
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color)
        .onTapGesture { location in
            handleTap(index: index, tapX: location.x, scrollProxy: scrollProxy)
        }
        .alert("Feature is not available", isPresented: $showSimulatorAlert, actions: {
            Button("close", role: .cancel) {}
        }, message: {
            Text("This feature is not available in the Xcode simulator.")
        })
        .onChange(of: focusingLine, {
            if autoScrool {
                if animate {
                    DispatchQueue.main.async {
                        withAnimation {
                            scrollProxy.scrollTo(
                                focusingLine, anchor: UnitPoint(x: 0.5, y: 0.4))
                        }
                    }
                } else {
                    scrollProxy.scrollTo(
                        focusingLine, anchor: UnitPoint(x: 0.5, y: 0.4))
                }
            }
        })
        .onChange(of: wasScrolled, {
            if autoScrool {
                if animate {
                    DispatchQueue.main.async {
                        withAnimation {
                            scrollProxy.scrollTo(
                                focusingLine, anchor: UnitPoint(x: 0.5, y: 0.4))
                        }
                    }
                } else {
                    scrollProxy.scrollTo(
                        focusingLine, anchor: UnitPoint(x: 0.5, y: 0.4))
                }
            }
        })
    }

    private func startSpeaking(text: [String], index: Int, scrollProxy: ScrollViewProxy) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            speaking = true
        }

        if animate {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                focusingLine = index
                wasScrolled = false
            }
        } else {
            wasScrolled = false
        }

        Task {
            var i = focusingLine
            while focusingLine < text.count && speaking {
                i = focusingLine
                
                let sentence = text[i].trimmingCharacters(in: .whitespacesAndNewlines)

                if sentence.isEmpty {
                    i += 1
                    continue
                }
                
                if animate {
                    withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                        wasScrolled = false
                    }
                } else {
                    wasScrolled = false
                }
                
                if autoScrool {
                    if animate {
                        withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                            scrollProxy.scrollTo(i, anchor: .init(x: 0.5, y: 0.4))
                        }
                    } else {
                        scrollProxy.scrollTo(i, anchor: .init(x: 0.5, y: 0.4))
                    }
                }
                
                let utterance = AVSpeechUtterance(string: sentence)
                utterance.voice = AVSpeechSynthesisVoice(language: selectedLnaguage)
                utterance.rate = Float(readSpeed)
                utterance.postUtteranceDelay = 1 - postUtteranceDelay

                synthesizer.speak(utterance)

                try? await Task.sleep(for: .milliseconds(50))
                
                while (synthesizer.isSpeaking || synthesizer.isPaused) && speaking {
                    try? await Task.sleep(for: .milliseconds(100))
                }
                
                if speaking {
                    if animate {
                        withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                            if i == focusingLine {
                                focusingLine += 1
                            }
                        }
                    } else {
                        if i == focusingLine {
                            focusingLine += 1
                        }
                    }
                }
            }

            if animate {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    wasScrolled = true
                }
            } else {
                wasScrolled = true
            }
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                speaking = false
            }
        }
    }

    private func stopSpeaking() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            speaking = false
        }
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension WrappedLinesTextView {
    fileprivate func handleTap(index: Int, tapX: CGFloat, scrollProxy: ScrollViewProxy) {
        if index == focusingLine {
            if hapticsEnabled && wasScrolled {
                let generator = UISelectionFeedbackGenerator()
                generator.prepare()
                generator.selectionChanged()
            }
            
            if animate {
                withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                    wasScrolled.toggle()
                }
            } else {
                wasScrolled.toggle()
            }
        } else {
            if tapX <= screenWidth / 2 {
                if hapticsEnabled {
                    let generator = UIImpactFeedbackGenerator(style: .rigid)
                    generator.prepare()
                    generator.impactOccurred()
                }
                
                if animate && !wasScrolled {
                    withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                        focusingLine = index
                    }
                } else {
                    focusingLine = index
                }
                
                if animate {
                    withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                        wasScrolled = false
                    }
                } else {
                    wasScrolled = false
                }
            } else {
                if index < focusingLine {
                    if animate {
                        withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                            focusingLine = max(0, focusingLine - 1)
                        }
                    } else {
                        focusingLine = max(0, focusingLine - 1)
                    }
                    
                    if hapticsEnabled {
                        let generator = UIImpactFeedbackGenerator(style: .soft)
                        generator.prepare()
                        generator.impactOccurred()
                    }
                } else {
                    if animate {
                        withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                            focusingLine += 1
                        }
                    } else {
                        focusingLine += 1
                    }
                    
                    if hapticsEnabled {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                    }
                }
                
                if animate {
                    withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                        wasScrolled = false
                    }
                } else {
                    wasScrolled = false
                }
            }
        }
    }
    
    func generateExplanation(rawText: String) {
        Task {
            do {
                switch model.availability {
                case .available:
                    withAnimation {
                        explanation = "generating_explanation"
                    }
                case .unavailable(.appleIntelligenceNotEnabled):
                    explanation = "enable_apple_intelligence"
                    return
                case .unavailable(.deviceNotEligible):
                    explanation = "device_not_supported"
                    return
                case .unavailable(.modelNotReady):
                    explanation = "model_initializing"
                    return
                case .unavailable(let other):
                    explanation = "model_unavailable\(String(describing: other))"
                    return
                @unknown default:
                    explanation = "unknown_error"
                    return
                }
                
                let prompt = explanationInstructions + ": " + rawText
                guard !prompt.isEmpty else {
                    explanation = ""
                    return
                }
                
                let response = try await explanationSession.respond(to: prompt)
                
                withAnimation {
                    explanation = response.content
                }
            } catch {
                explanation = "Error: \(error)"
            }
        }
    }
    
    func generateSummary() {
#if targetEnvironment(simulator)
        summary = "This feature is not available in the Xcode simulator."
#else
        guard summrizeText else { return }
        Task {
            do {
                switch model.availability {
                case .available:
                    withAnimation {
                        summary = "generating_summary"
                    }
                case .unavailable(.appleIntelligenceNotEnabled):
                    summary = "enable_apple_intelligence"
                    return
                case .unavailable(.deviceNotEligible):
                    summary = "device_not_supported"
                    return
                case .unavailable(.modelNotReady):
                    summary = "model_initializing"
                    return
                case .unavailable(let other):
                    summary = "model_unavailable\(String(describing: other))"
                    return
                @unknown default:
                    summary = "unknown_error"
                    return
                }
                
                let prompt = summarizeInstructions + ": " + text
                guard !prompt.isEmpty else {
                    summary = ""
                    return
                }
                
                let response = try await summarizeSession.respond(to: prompt)
                
                withAnimation {
                    summary = response.content
                }
            } catch {
                summary = "Error: \(error)"
            }
        }
#endif
    }
    
    fileprivate func updateMeasuredLines() {
        var lines = splitTextBySentenceEnd(text)
        measuredLinesRaw = lines
        
        if insertSpaceBitweenWords {
            for i in 0..<lines.count {
                lines[i] = wakachigaki(text: lines[i])
            }
        }

        measuredLines = lines
    }

    fileprivate func splitTextUsingNLTokenizer(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty { sentences.append(sentence) }
            return true
        }
        return sentences
    }
    
    fileprivate func wakachigaki(text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = text
        
        var words: [String] = []
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex, unit: .word, scheme: .tokenType
        ) { tag, range in
            let word = String(text[range])
            if !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                words.append(word)
            }
            return true
        }
        return words.joined(separator: spaceInserted)
    }
    
    fileprivate func splitTextBySentenceEnd(_ text: String) -> [String] {
        var pattern: String {
            var separators = ""
            if splitByLineBreak { separators += "\\r\\n" }
            if splitByPeriod { separators += "。\\." }
            if splitByComma { separators += "、," }
            if splitByExclamationMark { separators += "！!" }
            if splitByQuestionMark { separators += "？?" }

            var bracketPatterns: [String] = []
            var stopChars = separators

            if splitByBrackets {
                bracketPatterns.append("「[^」]*」")
                bracketPatterns.append("『[^』]*』")
                bracketPatterns.append("【[^】]*】")
                bracketPatterns.append("\"[^\"]*\"")
                bracketPatterns.append("'[^']*'")
                bracketPatterns.append("\\[[^\\]]*\\]")

                stopChars += "「『\\["
            }

            let normalPattern = "[^\(stopChars)]+[\(separators)]?"

            let allPatterns = bracketPatterns + [normalPattern]
            return allPatterns.joined(separator: "|")
        }

        if pattern.isEmpty { return [text] }

        let regex = try! NSRegularExpression(pattern: pattern)
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        return matches.map {
            nsText.substring(with: $0.range).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter { !$0.isEmpty }
    }

    fileprivate var currentSplitSettings: [Bool] {
        [
            splitByLineBreak,
            splitByPeriod,
            splitByComma,
            splitByExclamationMark,
            splitByQuestionMark,
            splitByBrackets,
        ]
    }
}

#Preview {
    Text("test")
}
