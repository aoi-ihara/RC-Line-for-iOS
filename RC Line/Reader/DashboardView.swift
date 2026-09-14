import SwiftUI

struct DashboardView: View {
    @Binding var isSidebarOpen: Bool

    let disabled: Bool
    let onClipboard: () -> Void
    let onCameraRoll: () -> Void
    let onLibrary: () -> Void
    let onSettings: () -> Void

    @AppStorage("backgroundColor") private var storedBackground: CodableColor = .init(.white)
    @AppStorage("storedBackgroundDark") private var storedBackgroundDark: CodableColor = .init(
        .black)
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                VStack(alignment: .leading) {
                    Button(action: onClipboard) {
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
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(
                        colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color
                    )
                    .padding(4)
                    .disabled(disabled)
                    .accessibilityLabel(Text("from_clipboard"))
                    .accessibilityHint(Text("paste_text_from_clipboard"))
                    .accessibilityAddTraits(.isButton)

                    Button(action: onCameraRoll) {
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
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(
                        colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color
                    )
                    .padding(4)
                    .disabled(disabled)
                    .accessibilityLabel(Text("from_camera_roll"))
                    .accessibilityHint(Text("select_image_from_library"))
                    .accessibilityAddTraits(.isButton)

                    Button(action: onLibrary) {
                        HStack {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                            Text("from_library")
                                .font(.system(size: 16))
                                .fontWeight(.semibold)
                        }
                        .padding(8)
                        .frame(width: 200, alignment: .leading)
                    }
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(
                        colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color
                    )
                    .padding(4)
                    .disabled(disabled)
                    .accessibilityLabel(Text("from_library"))
                    .accessibilityHint(Text("select_text_from_library"))
                    .accessibilityAddTraits(.isButton)
                }
                .padding(.vertical, 100)

                Button(action: onSettings) {
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
                .buttonStyle(.glass)
                .disabled(disabled)
                .accessibilityLabel(Text("settings"))
                .accessibilityHint(Text("open_settings"))
                .accessibilityAddTraits(.isButton)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color
            )
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
