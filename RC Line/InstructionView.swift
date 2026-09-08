import ARKit
import AVFoundation
import AVKit
import SwiftUI

struct InstructionView: View {
    @Binding var showInstructionView: Bool
    @AccessibilityFocusState private var focusedTitle: Bool
    
    @Environment(\.dismiss) private var dismiss

    @AppStorage("eyeTracking") private var eyeTracking: Bool = false
    @State private var blinkEye: Bool = false


    let player0 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView0", withExtension: "mov")!)
    let player1 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView1", withExtension: "mov")!)
    let player2 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView2", withExtension: "mov")!)
    let player3 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView3", withExtension: "mov")!)
    let player4 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView4", withExtension: "mov")!)
    let player8 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView8", withExtension: "mov")!)
    let player9 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView9", withExtension: "mov")!)

    @State private var status = AVCaptureDevice.authorizationStatus(for: .video)
    
    @State private var playTrigger = 0
    @State private var hasPlayedBlinkVideoOnce = false
    
    let titles = [
        "welcome_view_0_title", "welcome_view_1_title", "welcome_view_2_title",
        "welcome_view_3_title", "welcome_view_3.5_title", "welcome_view_4_title",
        "read_aloud_feature", "welcome_view_5_title", "welcome_view_6_title",
    ]
    
    private var isARKitSupported: Bool {
        ARFaceTrackingConfiguration.isSupported
    }
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    mediaImportView
                } label: {
                    Label(
                        "メディアの読み込み",
                        systemImage: "photo.on.rectangle.angled"
                    )
                }
                
                NavigationLink {
                    gestureView
                } label: {
                    Label(
                        "ジェスチャ操作",
                        systemImage: "hand.tap"
                    )
                }
                
                NavigationLink {
                    advancedFeaturesView
                } label: {
                    Label(
                        "高度な機能",
                        systemImage: "square.badge.plus"
                    )
                }
                
                NavigationLink {
                    customizationView
                } label: {
                    Label(
                        "カスタマイズ",
                        systemImage: "paintbrush"
                    )
                }
            }
            .navigationTitle("インストラクション")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

extension InstructionView {
    var mediaImportView: some View {
        VStack {
            Text("welcome_view_1_title")
                .font(.title)
                .fontWeight(.semibold)

            Text("welcome_view_1_explanation")
        }
        .navigationTitle("メディアの読み込み")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

extension InstructionView {
    var gestureView: some View {
        NavigationStack {
            VStack {
                Text("welcome_view_1_title")
                    .accessibilityLabel(Text("welcome_view_1_title"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)
                Text("welcome_view_1_explanation")
                    .accessibilityLabel(Text("welcome_view_1_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)
            }
            .navigationTitle("メディアの読み込み")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

extension InstructionView {
    var advancedFeaturesView: some View {
        NavigationStack {
            VStack {
                Text("welcome_view_1_title")
                    .accessibilityLabel(Text("welcome_view_1_title"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)
                Text("welcome_view_1_explanation")
                    .accessibilityLabel(Text("welcome_view_1_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showInstructionView = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .navigationTitle("メディアの読み込み")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

extension InstructionView {
    var customizationView: some View {
        NavigationStack {
            VStack {
                Text("welcome_view_1_title")
                    .accessibilityLabel(Text("welcome_view_1_title"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)
                Text("welcome_view_1_explanation")
                    .accessibilityLabel(Text("welcome_view_1_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showInstructionView = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .navigationTitle("メディアの読み込み")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct WelcomeView: View {
    @State private var slide = 0
    @State private var blinkEye: Bool = false

    @Binding var showWelcomeView: Bool
    @AccessibilityFocusState private var focusedTitle: Bool

    @AppStorage("eyeTracking") private var eyeTracking: Bool = false

    let player0 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView0", withExtension: "mov")!)
    let player1 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView1", withExtension: "mov")!)
    let player2 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView2", withExtension: "mov")!)
    let player3 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView3", withExtension: "mov")!)
    let player4 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView4", withExtension: "mov")!)
    let player8 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView8", withExtension: "mov")!)
    let player9 = AVPlayer(url: Bundle.main.url(forResource: "WelcomeView9", withExtension: "mov")!)

    @State private var status = AVCaptureDevice.authorizationStatus(for: .video)

    @State private var playTrigger = 0
    @State private var hasPlayedBlinkVideoOnce = false

    let titles = [
        "welcome_view_0_title", "welcome_view_1_title", "welcome_view_2_title",
        "welcome_view_3_title", "welcome_view_3.5_title", "welcome_view_4_title",
        "read_aloud_feature", "welcome_view_5_title", "welcome_view_6_title",
    ]

    private var isARKitSupported: Bool {
        ARFaceTrackingConfiguration.isSupported
    }

    var body: some View {
        NavigationStack {
            if slide == 0 {
                Text("welcome_view_0_title")
                    .accessibilityFocused($focusedTitle)
                    .accessibilityLabel(Text("welcome_view_0_title"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)
                Text("welcome_view_0_explanation")
                    .accessibilityLabel(Text("welcome_view_0_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)

                Image("WelcomeView0")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: .infinity)
                    .accessibilityLabel(Text("welcome_view_0_media_explanation"))
            } else if slide == 1 {
                Text("welcome_view_1_title")
                    .accessibilityFocused($focusedTitle)
                    .accessibilityLabel(Text("welcome_view_1_title"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)
                Text("welcome_view_1_explanation")
                    .accessibilityLabel(Text("welcome_view_1_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)

                TransparentPlayerView(player: player0)
                    .background(Color.clear)
                    .onAppear {
                        player0.seek(to: .zero)
                        player0.play()
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player0.currentItem,
                            queue: .main
                        ) { _ in
                            player0.seek(to: .zero)
                            player0.play()
                        }
                    }
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel(Text("welcome_view_1_media_explanation"))
            } else if slide == 2 {
                Text("welcome_view_2_title")
                    .accessibilityFocused($focusedTitle)
                    .accessibilityLabel(Text("welcome_view_2_title"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)

                Text("welcome_view_2_explanation")
                    .accessibilityLabel(Text("welcome_view_2_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)

                TransparentPlayerView(player: player1)
                    .background(Color.clear)
                    .onAppear {
                        player1.seek(to: .zero)
                        player1.play()
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player1.currentItem,
                            queue: .main
                        ) { _ in
                            player1.seek(to: .zero)
                            player1.play()
                        }
                    }
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel(Text("welcome_view_2_media_explanation"))
            } else if slide == 3 {
                Text("welcome_view_3_title")
                    .accessibilityFocused($focusedTitle)
                    .accessibilityLabel(Text("welcome_view_3_title"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)

                Text("welcome_view_3_explanation")
                    .accessibilityLabel(Text("welcome_view_3_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)

                TransparentPlayerView(player: player2)
                    .background(Color.clear)
                    .onAppear {
                        player2.seek(to: .zero)
                        player2.play()
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player2.currentItem,
                            queue: .main
                        ) { _ in
                            player2.seek(to: .zero)
                            player2.play()
                        }
                    }
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel(Text("welcome_view_3_media_explanation"))
            } else if slide == 4 {
                Text("welcome_view_3.5_title")
                    .accessibilityFocused($focusedTitle)
                    .accessibilityLabel(Text("welcome_view_3.5_title"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)

                Text("welcome_view_3.5_explanation")
                    .accessibilityLabel(Text("welcome_view_3.5_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)

                TransparentPlayerView(player: player8)
                    .background(Color.clear)
                    .onAppear {
                        player8.seek(to: .zero)
                        player8.play()
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player8.currentItem,
                            queue: .main
                        ) { _ in
                            player8.seek(to: .zero)
                            player8.play()
                        }
                    }
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel(Text("welcome_view_3.5_media_explanation"))
            } else if slide == 5 {
                ZStack {
                    if eyeTracking {
                        EyeTrackingView(
                            onBlink: {
                                if eyeTracking && !hasPlayedBlinkVideoOnce {
                                    player3.seek(
                                        to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                                    player3.play()
                                }
                            },
                            onLeftWink: {
                                if eyeTracking && !hasPlayedBlinkVideoOnce {
                                    player3.seek(
                                        to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                                    player3.play()
                                }
                            },
                            onRightWink: {
                                if eyeTracking && !hasPlayedBlinkVideoOnce {
                                    player3.seek(
                                        to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                                    player3.play()
                                }
                            }, isActive: true
                        )
                        .ignoresSafeArea()
                        .opacity(0)
                    }

                    VStack {
                        Text("welcome_view_4_title")
                            .accessibilityFocused($focusedTitle)
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(.top, 64)
                            .accessibilityLabel(Text("welcome_view_4_title"))
                            .padding(.horizontal)
                            .accessibilityAddTraits(.isHeader)

                        Text("welcome_view_4_explanation")
                            .fontWeight(.semibold)
                            .padding(.top, 2)
                            .accessibilityLabel(Text("welcome_view_4_explanation"))
                            .padding(.horizontal)

                        ZStack {
                            TransparentPlayerView(player: player3)
                                .background(Color.clear)
                                .opacity(eyeTracking ? 1 : 0)
                                .onAppear {
                                    player3.pause()
                                    player3.seek(
                                        to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                                }
                                .onDisappear {
                                    player3.pause()
                                    player3.seek(
                                        to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                                }

                            VStack {
                                Spacer()

                                Image(systemName: blinkEye ? "eye.half.closed.fill" : "eye.fill")
                                    .font(.system(size: 64))
                                    .opacity(eyeTracking ? 0 : 1)

                                Spacer()
                            }
                        }
                        .onChange(of: eyeTracking) {
                            if !eyeTracking {
                                hasPlayedBlinkVideoOnce = false
                                player3.pause()
                                player3.seek(
                                    to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                            }
                        }

                        if isARKitSupported && !UIAccessibility.isVoiceOverRunning {
                            VStack {
                                Toggle(
                                    isOn: $eyeTracking,
                                    label: {
                                        Text("blink_to_move_row")
                                    }
                                )
                                .accessibilityLabel(Text("blink_to_move_row"))
                                .onChange(of: eyeTracking) {
                                    UIAccessibility.post(
                                        notification: .announcement,
                                        argument: eyeTracking
                                            ? NSLocalizedString(
                                                "blink_to_move_row_enabled", comment: "")
                                            : NSLocalizedString(
                                                "blink_to_move_row_disabled", comment: "")
                                    )
                                }
                                .fontWeight(.semibold)
                                .padding()

                            }
                            .background(
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(.quinary)
                            )
                            .padding(.horizontal, 32)
                        } else {
                            VStack {
                                Toggle(
                                    isOn: $eyeTracking,
                                    label: {
                                        Text("not_supported")
                                    }
                                )
                                .accessibilityLabel(Text("blink_to_move_row"))
                                .fontWeight(.semibold)
                                .padding()
                                .disabled(true)

                            }
                            .background(
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(.quinary)
                            )
                            .padding(.horizontal, 32)
                        }
                    }
                }
            } else if slide == 6 {
                Text("read_aloud_feature")
                    .accessibilityFocused($focusedTitle)
                    .accessibilityLabel(Text("read_aloud_feature"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)

                Text("welcome_view_4.5_explanation")
                    .accessibilityLabel(Text("welcome_view_4.5_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)

                TransparentPlayerView(player: player9)
                    .background(Color.clear)
                    .onAppear {
                        player9.seek(to: .zero)
                        player9.play()
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player9.currentItem,
                            queue: .main
                        ) { _ in
                            player9.seek(to: .zero)
                            player9.play()
                        }
                    }
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel(Text("welcome_view_4.5_media_explanation"))
            } else if slide == 7 {
                Text("welcome_view_5_title")
                    .accessibilityFocused($focusedTitle)
                    .accessibilityLabel(Text("welcome_view_5_title"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isHeader)

                Text("welcome_view_5_explanation")
                    .accessibilityLabel(Text("welcome_view_5_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)

                TransparentPlayerView(player: player4)
                    .background(Color.clear)
                    .onAppear {
                        player4.seek(to: .zero)
                        player4.play()
                        NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: player4.currentItem,
                            queue: .main
                        ) { _ in
                            player4.seek(to: .zero)
                            player4.play()
                        }
                    }
            } else {
                Text("welcome_view_6_title")
                    .accessibilityFocused($focusedTitle)
                    .accessibilityLabel(Text("welcome_view_6_title"))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 64)
                    .padding(.horizontal)

                Text("welcome_view_6_explanation")
                    .accessibilityLabel(Text("welcome_view_6_explanation"))
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                    .padding(.horizontal)

                Image("WelcomeView6")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: .infinity)
                    .accessibilityLabel(Text("welcome_view_6_media_explanation"))
            }

            Spacer()

            Button {
                if slide == 8 {
                    UserDefaults.standard.set(true, forKey: "wasRuned")
                    showWelcomeView.toggle()
                } else {
                    withAnimation {
                        if slide == 4 {
                            status = AVCaptureDevice.authorizationStatus(for: .video)
                        }

                        if slide == 4
                            && (status != .authorized || UIAccessibility.isVoiceOverRunning)
                        {
                            slide += 2
                        } else {
                            slide += 1
                        }
                    }
                }
            } label: {
                if slide == 8 {
                    Text("done")
                        .padding(.vertical, 10)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(Text("done"))
                        .accessibilityAddTraits(.isButton)
                } else {
                    Text("continue")
                        .padding(.vertical, 10)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(Text("continue"))
                        .accessibilityAddTraits(.isButton)
                }
            }
            .foregroundStyle(Color(.systemBackground))
            .padding(.horizontal, 32)
            .buttonStyle(.glassProminent)

            Button {
                withAnimation {
                    if slide == 6 {
                        status = AVCaptureDevice.authorizationStatus(for: .video)
                    }

                    if slide == 6 && (status != .authorized || UIAccessibility.isVoiceOverRunning) {
                        slide -= 2
                    } else {
                        slide -= 1
                    }
                }
            } label: {
                Text("back")
                    .padding(.vertical, 10)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(Text("back"))
            }
            .padding(.horizontal, 32)
            .buttonStyle(.glass)
            .disabled(slide == 0)
            .onChange(of: slide) {
                focusedTitle = true
                UIAccessibility.post(
                    notification: .layoutChanged,
                    argument: NSLocalizedString(titles[slide], comment: "")
                )

                if slide == 2 {
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        DispatchQueue.main.async {
                            if granted {
                                print("Camera access granted")
                            } else {
                                print("Camera access denied")
                            }
                        }
                    }
                }

                if slide == 5 {
                    hasPlayedBlinkVideoOnce = false
                    player3.pause()
                    player3.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                }
            }
        }
        .onAppear {
            func scheduleBlink() {
                let interval = Double.random(in: 1.0...3.0)

                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    blinkEye = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        blinkEye = false
                        scheduleBlink()
                    }
                }
            }

            scheduleBlink()
        }
    }
}

struct TransparentPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .clear
        view.playerLayer.player = player
        view.playerLayer.isOpaque = false
        view.playerLayer.backgroundColor = UIColor.clear.cgColor
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }

    final class PlayerContainerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

#Preview {
    ContentView()
}
