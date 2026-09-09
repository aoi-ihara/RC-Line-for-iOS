//
//  Buttons.swift
//  RC Line
//
//  Created by vgnz93hs on 2026/09/09.
//

import SwiftUI

struct ToolbarButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(Color.black)
            .cornerRadius(5)
        })
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
