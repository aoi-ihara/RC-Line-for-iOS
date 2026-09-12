//
//  LibraryListView.swift
//  RC Line
//
//  Created by vgnz93hs on 2026/09/12.
//

import SwiftUI

struct LibraryListView: View {
    @AppStorage("lineWidth") var lineWidth: Double = 75
    @AppStorage("fontFamily") var fontFamily: Int = 0
    @AppStorage("fontWeight") var fontWeight: Int = 4
    @AppStorage("lineHeight") private var lineHeight: Double = 2
    @AppStorage("letterSpacing") private var letterSpacing: Double = 1.05
    
    private var selectedFontName: String {
        let fontNames = [
            "Jost-Regular", "Lexend-Regular", "Roboto-Regular", "OpenDyslexic-Regular",
            "JetBrainsMono-Regular",
        ]
        
        if fontFamily == 8 {
            return fontWeight >= 6 ? "OpenDyslexic-Bold" : "OpenDyslexic-Regular"
        }
        
        return fontNames[fontFamily - 2]
    }
    
    private var selectedFont: Font {
        if fontFamily < 2 {
            return .system(size: 16, design: fontFamily == 0 ? .default : .serif)
        }
        
        return .custom(selectedFontName, size: 16)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Button {} label: {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Title")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("1d ago")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        Text("This is the explanation.")
                            .font(selectedFont)
                            .lineLimit(3)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
