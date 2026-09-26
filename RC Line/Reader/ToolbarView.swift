//
//  SwiftUIView.swift
//  RC Line
//
//  Created by vgnz93hs on 2026/09/09.
//

import SwiftUI

struct ToolbarView: View {
    var showLabel: Bool
    let onSettings: () -> Void
    let onCamera: () -> Void
    let onLibrary: () -> Void
    let onClipboard: () -> Void
    let onPhotos: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ToolbarButton(
                title: "settings", systemImage: "gearshape", action: onSettings,
                showLabel: showLabel, index: 0)
            ToolbarButton(
                title: "from_library", systemImage: "books.vertical", action: onLibrary,
                showLabel: showLabel, index: 1)
            ToolbarButton(
                title: "from_camera", systemImage: "camera", action: onCamera,
                showLabel: showLabel, index: 2)
            ToolbarButton(
                title: "from_camera_roll", systemImage: "photo.on.rectangle.angled", action: onPhotos,
                showLabel: showLabel, index: 3)
            ToolbarButton(
                title: "from_clipboard", systemImage: "clipboard", action: onClipboard,
                showLabel: showLabel, index: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ToolbarButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void
    let showLabel: Bool
    let index: CGFloat

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .offset(x: showLabel ? -70 : 0)
                Text(title)
                    .offset(x: showLabel ? 20 : 0)
                    .opacity(showLabel ? 1 : 0)
                    .fontWeight(.semibold)
                    .font(showLabel ? .body : .caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 140)
            }
            .frame(
                minWidth: showLabel ? 180 : 44,
                minHeight: 44
            )
            .frame(
                width: showLabel ? 200 : 44,
                height: showLabel ? 50 : 44
            )
        }
        .offset(
            x: showLabel ? 0 : (index - 2) * 72,
            y: showLabel ? index * -64 : 0
        )
        .buttonStyle(.glass)
        .animation(.bouncy(duration: 0.4), value: showLabel)
        .buttonBorderShape(.roundedRectangle(radius: 22))
        .accessibilityLabel(Text(title))
    }
}

#Preview {
    ContentView()
}
