import FoundationModels
import NaturalLanguage
import SwiftUI

struct ReaderView: View {
    @State private var speaking = false
    @State private var isAnimating = true
    @State private var scrollPosition: Int? = nil
    @State private var focusingLine: Int = 0

    @Binding var ocrText: String
    @Binding var showingCameraSheetFromContentView: Bool
    @Binding var wasScrolled: Bool
    @Binding var isSidebarOpen: Bool
    
    @State private var showWelcomeView = !UserDefaults.standard.bool(forKey: "wasRuned")

    @AppStorage("fullScreenMode") var fullScreenMode: Bool = true
    @AppStorage("ocrMode") var ocrMode: Int = 0
    @AppStorage("saveToLibrary") var saveToLibrary: Bool = false
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("fontSize") var fontSize: Double = 13
    @AppStorage("backgroundColor") private var storedBackground: CodableColor = .init(.white)
    @AppStorage("storedBackgroundDark") private var storedBackgroundDark: CodableColor = .init(.black)
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("theme") private var theme = 0
    @AppStorage("animate") var animate: Bool = true
    
    @State private var eyeTracking: Bool = false
    @State private var maxFocusingLine: Int = 0
    
    var body: some View {
        ZStack {
            if eyeTracking && !showWelcomeView {
                EyeTrackingView(onBlink: {
                    if animate {
                        withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                            if focusingLine > maxFocusingLine-2 {
                                wasScrolled = true
                                eyeTracking = false
                            } else {
                                focusingLine += 1
                            }
                        }
                    } else {
                        focusingLine += 1
                    }
                }, onLeftWink: {
                    if animate {
                        withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                            focusingLine -= 1
                        }
                    } else {
                        focusingLine -= 1
                    }
                }, onRightWink: {
                    if animate {
                        withAnimation(.timingCurve(.easeInOut, duration: 0.3)) {
                            focusingLine -= 1
                        }
                    } else {
                        focusingLine -= 1
                    }
                }, isActive: eyeTracking)
                .ignoresSafeArea()
                .opacity(0)
            }
            
            AnyView(
                GeometryReader { geometry in
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                VStack {

                                    let screenHeight = geometry.size.height
                                    let screenWidth = geometry.size.width

                                    TextView(
                                        text: ocrText,
                                        fontSize: fontSize,
                                        screenHeight: screenHeight,
                                        screenWidth: screenWidth,
                                        speaking: $speaking,
                                        wasScrolled: $wasScrolled,
                                        focusingLine: $focusingLine,
                                        eyeTracking: $eyeTracking,
                                        maxFocusingLine: $maxFocusingLine
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .coordinateSpace(name: "scroll")
                        .scrollIndicators(
                            (wasScrolled && fullScreenMode == false) ? .automatic : .hidden
                        )
                        .onChange(of: ocrText) {
                            if !showWelcomeView {
                                focusingLine = 0
                                withAnimation(.timingCurve(.linear, duration: 0.2)) {
                                    wasScrolled = true
                                }
                            }
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    if abs(value.translation.height) > abs(value.translation.width)
                                    {
                                        withAnimation(.timingCurve(.linear, duration: 0.2)) {
                                            wasScrolled = true
                                        }
                                    }
                                }
                        )
                        .onChange(of: wasScrolled) {
                            if wasScrolled {
                                if hapticsEnabled {
                                    playSelectionHaptics()
                                }
                            }
                        }
                        .padding(.vertical, fullScreenMode ? 0 : 1)
                    }
                }
                    .background(colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color)
            )
        }
        .onChange(of: ocrText) {
            if hapticsEnabled {
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
            }
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
        
        VStack(alignment: .center) {
            Spacer()
            Button {
                if speaking {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        speaking = false
                    }
                }
                
                if eyeTracking {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        eyeTracking = false
                        wasScrolled = true
                    }
                }
            } label: {
                Image(systemName: "stop.fill")
                    .imageScale(.large)
                    .frame(width: 40, height: 40)
            }
            .padding()
            .buttonStyle(.glass)
            .opacity(speaking || eyeTracking ? 1 : 0)
            .scaleEffect(speaking || eyeTracking ? 1 : 0)
            .accessibilityLabel(speaking ? "stop_speaking" : "stop_eye_tracking")
        }
        .frame(maxWidth: .infinity)
    }
    
    func playSelectionHaptics() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

struct TextView: View {
    let text: String
    let fontSize: CGFloat
    let screenHeight: CGFloat
    let screenWidth: CGFloat

    @AppStorage("lineWidth") var lineWidth: Double = 75
    @AppStorage("fontFamily") var fontFamily: Int = 0
    @AppStorage("fontWeight") var fontWeight: Int = 4
    @AppStorage("lineHeight") private var lineHeight: Double = 2
    @AppStorage("letterSpacing") private var letterSpacing: Double = 1.05

    let fontWightList: [Font.Weight] = [
        .thin, .thin, .regular, .regular, .semibold, .semibold, .bold, .bold, .heavy, .heavy,
    ]

    let fontNames = [
        "Jost-Regular", "Lexend-Regular", "LINESeedJPApp_OTF-Regular", "NotoSansJP-Thin_Regular",
        "NotoSerifJP-Regular", "Roboto-Regular",
    ]

    @Binding var speaking: Bool
    @Binding var wasScrolled: Bool
    @Binding var focusingLine: Int
    @Binding var eyeTracking: Bool
    @Binding var maxFocusingLine: Int

    @State private var showExplanation = false
    @State private var explanation = ""

    var body: some View {
        VStack(alignment: .center) {
            WrappedLinesTextView(
                speaking: $speaking,
                text: text,
                font: fontFamily < 2
                    ? .system(size: fontSize, design: fontFamily == 0 ? .default : .serif)
                    : .custom(fontNames[fontFamily - 2], size: fontSize),
                smallFont: fontFamily < 2
                    ? .system(size: fontSize * 0.75, design: fontFamily == 0 ? .default : .serif)
                    : .custom(fontNames[fontFamily - 2], size: fontSize * 0.75),
                focusingLine: $focusingLine,
                wasScrolled: $wasScrolled,
                screenWidth: screenWidth,
                fontSize: fontSize,
                showExplanation: $showExplanation,
                explanation: $explanation,
                eyeTracking: $eyeTracking,
                maxFocusingLine: $maxFocusingLine
            )
        }
        .frame(maxWidth: .infinity)
        .sheet(
            isPresented: $showExplanation,
            content: {
                NavigationStack {
                    ScrollView {
                        Text(explanation == "generating_explanation" ? "Generating Explanation" : explanation)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                            .font(
                                fontFamily < 2
                                    ? .system(
                                        size: fontSize * 1.2,
                                        design: fontFamily == 0 ? .default : .serif)
                                    : .custom(fontNames[fontFamily - 2], size: fontSize * 1.2)
                            )
                            .fontWeight(fontWightList[fontWeight])
                            .tracking(fontSize * (letterSpacing - 1))
                            .lineSpacing(fontSize * (lineHeight - 1))
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        showExplanation.toggle()
                                    } label: {
                                        Image(systemName: "xmark")
                                    }
                                }
                            }
                        
                            .presentationDetents(UIDevice.current.userInterfaceIdiom == .phone ? [.medium, .large] : [.large])
                    }
                }
            })
    }
}

#Preview {
    ContentView()
}
