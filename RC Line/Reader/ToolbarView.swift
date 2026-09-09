//
//  SwiftUIView.swift
//  RC Line
//
//  Created by vgnz93hs on 2026/09/09.
//

import SwiftUI

struct ToolbarView: View {
    var body: some View {
        VStack {
            Spacer()
            
            ToolbarButton(title: "Settings", systemImage: "gearshape", action: {})
        }
    }
}

#Preview {
    ContentView()
}
