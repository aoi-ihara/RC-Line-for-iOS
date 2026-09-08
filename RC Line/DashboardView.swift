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
    @AppStorage("storedForegroundDark") private var storedForegroundDark: CodableColor = .init(.white)
    @AppStorage("storedBackgroundDark") private var storedBackgroundDark: CodableColor = .init(.black)
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