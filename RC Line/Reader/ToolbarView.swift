//
//  SwiftUIView.swift
//  RC Line
//
//  Created by vgnz93hs on 2026/09/09.
//

import SwiftUI

struct ToolbarView: View {
    @Binding var wasScrolled: Bool
    
    var body: some View {
        VStack {
            Spacer()

            ToolbarButton(title: "Settings", systemImage: "gearshape", action: {}, showLabel: wasScrolled)
            ToolbarButton(title: "From Camera", systemImage: "camera", action: {}, showLabel: wasScrolled)
            ToolbarButton(title: "From Camera", systemImage: "camera", action: {}, showLabel: wasScrolled)
        }
    }
}

struct ToolbarButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    let showLabel: Bool

    var body: some View {
        Button(action: action, label: {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                Text(title)
                    .fontWeight(.semibold)
                    .font(.caption)
            }
            .frame(width: 60, height: 60)
        })
        .buttonStyle(.glass)
        .buttonBorderShape(.roundedRectangle(radius: 10))
    }
}

#Preview {
    ContentView()
}
