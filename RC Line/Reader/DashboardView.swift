import SwiftUI

struct DashboardView: View {
    let disabled: Bool
    let onClipboard: () -> Void
    let onCamera: () -> Void
    let onCameraRoll: () -> Void
    let onLibrary: () -> Void
    let onSettings: () -> Void

    @AppStorage("backgroundColor") private var storedBackground: CodableColor = .init(.white)
    @AppStorage("storedBackgroundDark") private var storedBackgroundDark: CodableColor = .init(
        .black)
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                dashboardButton(
                    title: "from_clipboard",
                    systemImage: "clipboard",
                    prominent: true,
                    action: onClipboard,
                    hint: "paste_text_from_clipboard"
                )
                dashboardButton(
                    title: "from_camera",
                    systemImage: "camera",
                    prominent: true,
                    action: onCamera,
                    hint: "open_camera"
                )
                dashboardButton(
                    title: "from_camera_roll",
                    systemImage: "photo.on.rectangle.angled",
                    prominent: true,
                    action: onCameraRoll,
                    hint: "select_image_from_library"
                )
                dashboardButton(
                    title: "from_library",
                    systemImage: "books.vertical",
                    prominent: true,
                    action: onLibrary,
                    hint: "from_library"
                )
            }
            .padding(.vertical, 48)

            dashboardButton(
                title: "settings",
                systemImage: "gearshape",
                prominent: false,
                action: onSettings,
                hint: "open_settings"
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            colorScheme == .dark ? storedBackgroundDark.color : storedBackground.color
        )
    }

    @ViewBuilder
    private func dashboardButton(
        title: LocalizedStringKey,
        systemImage: String,
        prominent: Bool,
        action: @escaping () -> Void,
        hint: LocalizedStringKey
    ) -> some View {
        let label = HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 28, height: 28)
            Text(title)
                .font(.body.weight(.semibold))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(minWidth: 220, maxWidth: 280, minHeight: 44, alignment: .leading)

        if prominent {
            Button(action: action, label: { label })
                .buttonStyle(.glassProminent)
                .disabled(disabled)
                .accessibilityLabel(Text(title))
                .accessibilityHint(Text(hint))
        } else {
            Button(action: action, label: { label })
                .buttonStyle(.glass)
                .disabled(disabled)
                .accessibilityLabel(Text(title))
                .accessibilityHint(Text(hint))
        }
    }
}
