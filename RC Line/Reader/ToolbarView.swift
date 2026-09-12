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
    
    @State private var showActions = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ToolbarButton(
                title: "Settings", systemImage: "gearshape", action: onSettings,
                showLabel: showLabel, index: 0)
            ToolbarButton(
                title: "From Library", systemImage: "books.vertical", action: onLibrary,
                showLabel: showLabel, index: 1)
            ToolbarButton(
                title: "From Camera", systemImage: "camera", action: onCamera,
                showLabel: showLabel, index: 2)
            ToolbarButton(
                title: "From Photos", systemImage: "photo.on.rectangle.angled", action: onPhotos,
                showLabel: showLabel, index: 3)
            ToolbarButton(
                title: "From Clipboard", systemImage: "clipboard", action: onClipboard,
                showLabel: showLabel, index: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ToolbarButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    let showLabel: Bool
    let index: CGFloat
    
    var body: some View {
        Button(
            action: action,
            label: {
                ZStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 24))
                        .offset(x: showLabel ? -70 : 0)
                    Text(title)
                        .offset(x: showLabel ? 25 : 0)
                        .opacity(showLabel ? 1 : 0)
                        .fontWeight(.semibold)
                        .font(showLabel ? .body : .caption2)
                        .frame(width: 120)
                }
                .frame(width: showLabel ? 200 : 35, height: showLabel ? 60 : 40)
            }
        )
        .offset(
            x: showLabel ? 0 : (index - 2) * 66,
            y: showLabel ? index * -90 : 0
        )
        .buttonStyle(.glass)
        .animation(.bouncy(duration: 0.4), value: showLabel)
        .buttonBorderShape(.roundedRectangle(radius: 24))
    }
}

#Preview {
    ContentView()
}
