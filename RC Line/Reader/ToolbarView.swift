//
//  SwiftUIView.swift
//  RC Line
//
//  Created by vgnz93hs on 2026/09/09.
//

import SwiftUI

struct ToolbarView: View {
    var wasScrolled: Bool
    
    var body: some View {
        HStack {
            ToolbarButton(title: "Settings", systemImage: "gearshape", action: {}, showLabel: wasScrolled)
            
            Spacer()

            ToolbarButton(title: "From Camera", systemImage: "camera", action: {}, showLabel: wasScrolled)
            ToolbarButton(title: "From Library", systemImage: "clipboard", action: {}, showLabel: wasScrolled)
            ToolbarButton(title: "From Clipboard", systemImage: "clipboard", action: {}, showLabel: wasScrolled)
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
            ZStack {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .offset(y: showLabel ? -18 : 0)
                
                Text(title)
                    .offset(y: showLabel ? 18 : 0)
                    .opacity(showLabel ? 1 : 0)
                    .fontWeight(.semibold)
                    .font(.caption2)
                    .frame(width: 60)
            }
            .frame(width: showLabel ? 60 : 50, height: showLabel ? 80 : 50)
        })
        .buttonStyle(.glass)
        .animation(.bouncy(duration: 0.2), value: showLabel)
        .buttonBorderShape(.roundedRectangle(radius: 24))
    }
}

#Preview {
    ContentView()
}
