import AVFoundation
import Photos
import PhotosUI
import SwiftUI
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
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPasteError = false
    @State private var showLibraryList = false
    @StateObject private var libraryStore = LibraryStore()
    @State private var shouldSaveCurrentTextToLibrary = false
    
    @Environment(\.layoutDirection) var layoutDirection
    
    @State private var isSidebarOpen = false
    @State private var dragOffset: CGFloat = 0
    
    @State private var showLabel = false
    
    @AppStorage("foregroundColor") private var storedForeground: CodableColor = .init(.black)
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("storedForegroundDark") private var storedForegroundDark: CodableColor = .init(
        .white)
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("doNotShowClipboardAlert") private var doNotShowClipboardAlert: Bool = false
    @AppStorage("featureDisplayMode") private var featureDisplayMode: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            let sidebarWidth = geometry.size.width
            let (targetX, progress) = sidebarProgress(sidebarWidth: sidebarWidth)
            
            ZStack(alignment: .leading) {
                NavigationStack {
                    ZStack {
                        ReaderView(
                            ocrText: $ocrResultText,
                            showingCameraSheetFromContentView: $showingCameraSheetFromContentView,
                            wasScrolled: $wasScrolled,
                            isSidebarOpen: $isSidebarOpen,
                            shouldSaveCurrentTextToLibrary: $shouldSaveCurrentTextToLibrary,
                            onSaveCurrentTextToLibrary: { text in
                                libraryStore.save(text: text)
                            }
                        )
                        .frame(maxHeight: .infinity)
                        
                        VStack {
                            Spacer()
                            readerToolbar
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 35)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                }
                .accentColor(
                    colorScheme == .dark ? storedForegroundDark.color : storedForeground.color
                )
                .frame(width: sidebarWidth)
                .offset(x: targetX)
                .zIndex(100)
            }
            .simultaneousGesture(sidebarDragGesture(sidebarWidth: sidebarWidth))
        }
        .sheet(
            isPresented: $showSettingsView,
            content: {
                SettingsView(
                    showSettingsView: $showSettingsView,
                )
                .accentColor(Color(.label))
                .presentationDetents(
                    UIDevice.current.userInterfaceIdiom == .phone ? [.medium] : [.large])
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
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedItem,
            matching: .images
        )
        .sheet(
            isPresented: $showLibraryList,
            content: {
                LibraryListView(
                    store: libraryStore,
                    onSelect: { text in
                        setOCRText(text, saveToLibrary: false)
                        showLibraryList = false
                    }
                )
                .accentColor(Color(.label))
                .presentationDetents([.medium, .large])
            }
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
                        argument: NSLocalizedString("image_selected", comment: "")
                    )
                }
                
                performOCR(on: image) { text in
                    Task { @MainActor in
                        self.setOCRText(text)
                        isSidebarOpen = false
                        UIAccessibility.post(
                            notification: .screenChanged,
                            argument: NSLocalizedString(
                                "image_processing_complete", comment: "")
                        )
                    }
                }
            }
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
                        self.setOCRText(recognizedText)
                    }
                }
            }
            isSidebarOpen = false
        }
        .interactiveDismissDisabled(true)
        .alert(
            "clipboard_is_empty", isPresented: $showPasteError,
            actions: {
                Button("close", role: .cancel) {}
                Button("do_not_show_again", role: .destructive) {
                    doNotShowClipboardAlert = true
                }
            }
        )
        .alert(
            "camera_not_allowed", isPresented: $showCameraPermissionAlert,
            actions: {
                Button("open_settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("close", role: .cancel) {}
            },
            message: {
                Text("camera_not_allowed_message")
            }
        )
        .alert(
            "Feature is not available", isPresented: $showCameraSimulatorAlert,
            actions: {
                Button("close", role: .cancel) {}
            },
            message: {
                Text("This feature is not available in the Xcode simulator.")
            })
    }
    
    private var readerToolbar: some View {
        ToolbarView(
            showLabel: ocrResultText == "",
            onSettings: {
                showSettingsView.toggle()
            },
            onCamera: {
                openCamera()
            },
            onLibrary: {
                showLibraryList.toggle()
            },
            onClipboard: {
                pasteFromClipboard()
            },
            onPhotos: {
                showImagePicker = true
            }
        )
    }
    
    private func setOCRText(_ text: String, saveToLibrary: Bool = true) {
        ocrResultText = text
        shouldSaveCurrentTextToLibrary = saveToLibrary
    }
    
    private func sidebarDragGesture(sidebarWidth: CGFloat) -> some Gesture {
        DragGesture(
            minimumDistance: featureDisplayMode == 1 ? 10 : .greatestFiniteMagnitude
        )
        .onChanged { value in
            guard featureDisplayMode == 1 else { return }
            
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
            guard featureDisplayMode == 1 else {
                dragOffset = 0
                return
            }
            
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
                    openCamera()
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
    }
    
    private func sidebarProgress(
        sidebarWidth: CGFloat
    ) -> (targetX: CGFloat, progress: CGFloat) {
        let anchoredX: CGFloat = isSidebarOpen ? 0 : -sidebarWidth
        let combined = anchoredX + dragOffset
        let clampedX = min(combined, 0)
        let halfClamped = clampedX / 2
        let halfAnchored = combined / 2
        let targetX = halfClamped + halfAnchored
        let progress = (targetX + sidebarWidth) / max(sidebarWidth, 1)
        
        return (targetX, progress)
    }
    
    private func openCamera() {
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
    }
    
    private func pasteFromClipboard() {
        if let clipboard = UIPasteboard.general.string {
            setOCRText(clipboard)
            
            UIAccessibility.post(
                notification: .announcement,
                argument: NSLocalizedString("pasted_from_clipboard", comment: "")
            )
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isSidebarOpen = false
            }
        } else {
            if !doNotShowClipboardAlert {
                showPasteError = true
            }
            
            UIAccessibility.post(
                notification: .announcement,
                argument: NSLocalizedString("clipboard_is_empty", comment: "")
            )
            
            if hapticsEnabled {
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.error)
            }
        }
    }
}

#Preview {
    ContentView()
}
