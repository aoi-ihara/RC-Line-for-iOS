import Photos
import SwiftUI
import AVFoundation
import UIKit

struct ContentView: View {
    @State private var showingCameraSheetFromContentView = false
    @State private var capturedImageInContentView: UIImage?
    @State private var ocrResultText: String = ""
    @State private var hideStatusBar: Bool = true
    @State private var pasteAlert: Bool = false
    @State private var capturedImage: UIImage?
    @State private var showSettingsView: Bool = false
    @State private var wasScrolled: Bool = true
    @State private var hasTriggeredHaptic: Bool = false
    @State private var showCameraPermissionAlert: Bool = false
    @State private var showCameraSimulatorAlert: Bool = false
    
    @Environment(\.layoutDirection) var layoutDirection
    
    @State private var isSidebarOpen = false
    @State private var dragOffset: CGFloat = 0
    
    @AppStorage("foregroundColor") private var storedForeground: CodableColor = .init(.black)
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("storedForegroundDark") private var storedForegroundDark: CodableColor = .init(.white)
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            let sidebarWidth = geometry.size.width
            
            let anchoredX: CGFloat = isSidebarOpen ? 0 : -sidebarWidth
            let combined: CGFloat = anchoredX + dragOffset
            let clampedX: CGFloat = min(combined, 0)
            let halfClamped: CGFloat = clampedX / 2.0
            let halfAnchored: CGFloat = combined / 2.0
            let targetX: CGFloat = halfClamped + halfAnchored
            let progress: CGFloat = (targetX + sidebarWidth) / max(sidebarWidth, 1)
            
            ZStack(alignment: .leading) {
                NavigationStack {
                    ZStack {
                        ReaderView(
                            ocrText: $ocrResultText,
                            showingCameraSheetFromContentView: $showingCameraSheetFromContentView,
                            wasScrolled: $wasScrolled,
                            isSidebarOpen: $isSidebarOpen
                        )
                        .frame(maxHeight: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                    .toolbar(content: {
                        if UIAccessibility.isVoiceOverRunning {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        isSidebarOpen.toggle()
                                    }
                                } label: {
                                    Image(systemName: "sidebar.left")
                                }
                                .accessibilityLabel("open_sidebar")
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showingCameraSheetFromContentView.toggle()
                                } label: {
                                    Image(systemName: "camera")
                                }
                                .accessibilityLabel("open_camera")
                            }
                        }
                    })
                }
                .frame(maxHeight: .infinity)
                .disabled(progress > 0.1)
                .offset(x: (targetX + sidebarWidth) * 0.5)
                .overlay {
                    if progress > 0 {
                        Color.black.opacity(progress * 0.25)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isSidebarOpen = false
                                }
                            }
                    }
                }
                
                NavigationStack {
                    VStack {
                        DashboardView(
                            isSidebarOpen: $isSidebarOpen,
                            pasteAlert: $pasteAlert,
                            ocrText: $ocrResultText,
                            showSettingsView: $showSettingsView,
                            wasScrolled: $wasScrolled,
                            disabled: progress < 0.9
                        )
                    }
                    .toolbar(content: {
                        if UIAccessibility.isVoiceOverRunning {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                if true {
                                    Button {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            isSidebarOpen.toggle()
                                        }
                                    } label: {
                                        Image(systemName: "sidebar.right")
                                    }
                                    .accessibilityLabel("close_sidebar")
                                }
                            }
                        }
                    })
                }
                .accentColor(colorScheme == .dark ? storedForegroundDark.color : storedForeground.color)
                .frame(width: sidebarWidth)
                .offset(x: targetX)
                .zIndex(100)
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        let dx: Double
                        
                        if layoutDirection == .rightToLeft {
                            dx = -value.translation.width
                        } else {
                            dx = value.translation.width
                        }
                        
                        let dy = value.translation.height
                        
                        if abs(dy) > abs(dx) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                self.dragOffset = 0
                            }
                            return
                        }
                        
                        if isSidebarOpen && dx > 0 {
                            self.dragOffset = dx / 3
                        } else if !isSidebarOpen && dx < 0 {
                            self.dragOffset = dx / 3
                        } else {
                            self.dragOffset = dx
                        }
                        
                        if hapticsEnabled && !isSidebarOpen {
                            if dx < -125 {
                                if !hasTriggeredHaptic {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    hasTriggeredHaptic = true
                                }
                            } else {
                                hasTriggeredHaptic = false
                            }
                        }
                    }
                    .onEnded { value in
                        hasTriggeredHaptic = false
                        
                        let horizontal: Double
                        
                        if layoutDirection == .rightToLeft {
                            horizontal = -value.translation.width
                        } else {
                            horizontal = value.translation.width
                        }
                        
                        let vertical = abs(value.translation.height)
                        
                        guard abs(horizontal) > vertical * 1.5 else {
                            withAnimation {
                                dragOffset = 0
                            }
                            return
                        }
                        
                        if !isSidebarOpen {
                            let cameraMinDistance: CGFloat = 125
                            let cameraMinVelocity: CGFloat = -1000
                            
                            let isStrongLeftSwipe =
                            horizontal < -cameraMinDistance || horizontal < cameraMinVelocity
                            
                            if isStrongLeftSwipe {
                                let status = AVCaptureDevice.authorizationStatus(for: .video)
                                
                                if status == .denied || status == .restricted {
                                    DispatchQueue.main.async {
                                        showCameraPermissionAlert = true
                                    }
                                } else {
#if targetEnvironment(simulator)
                                    showCameraSimulatorAlert = true
#else
                                    showingCameraSheetFromContentView = true
#endif
                                }
                                
                                withAnimation {
                                    dragOffset = 0
                                }
                            }
                        }
                        
                        let sidebarMinDistance: CGFloat = sidebarWidth * 0.1
                        let sidebarMinVelocity: CGFloat = 900
                        
                        let shouldOpen: Bool
                        if isSidebarOpen {
                            shouldOpen =
                            !(horizontal < -sidebarMinDistance
                              || horizontal < -sidebarMinVelocity)
                        } else {
                            shouldOpen =
                            horizontal > sidebarMinDistance || horizontal > sidebarMinVelocity
                        }
                        
                        withAnimation(.interpolatingSpring(stiffness: 350, damping: 45)) {
                            isSidebarOpen = shouldOpen
                            dragOffset = 0
                        }
                    }
                
            )
        }
        .sheet(
            isPresented: $showSettingsView,
            content: {
                SettingsView(
                    showSettingsView: $showSettingsView,
                )
                .accentColor(Color(.label))
                .presentationDetents(UIDevice.current.userInterfaceIdiom == .phone ? [.medium] : [.large])
            }
        )
        .fullScreenCover(isPresented: $showingCameraSheetFromContentView) {
            VStack {
                CameraPicker(image: $capturedImage, allowsEditing: false)
                    .padding(0)
            }
            .padding(0)
            .background(Color.black)
        }
        .onChange(of: capturedImage) {
            self.capturedImageInContentView = capturedImage
            if let capturedImage = capturedImage {
                let saveToLibrary = UserDefaults.standard.bool(forKey: "saveToLibrary")
                
                if saveToLibrary {
                    UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
                }
                
                performOCR(on: capturedImage) { recognizedText in
                    Task { @MainActor in
                        self.ocrResultText = recognizedText
                    }
                }
            }
            isSidebarOpen = false
        }
        .interactiveDismissDisabled(true)
        .alert("camera_not_allowed", isPresented: $showCameraPermissionAlert, actions: {
            Button("open_settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("close", role: .cancel) {}
        }, message: {
            Text("camera_not_allowed_message")
        })
        .alert("Feature is not available", isPresented: $showCameraSimulatorAlert, actions: {
            Button("close", role: .cancel) {}
        }, message: {
            Text("This feature is not available in the Xcode simulator.")
        })
    }
}

#Preview {
    ContentView()
}
