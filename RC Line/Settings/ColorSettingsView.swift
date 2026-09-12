import SwiftUI
import UIKit

struct CodableColor: RawRepresentable, Codable, Equatable {
    var color: Color
    
    init(_ color: Color) { self.color = color }
    
    init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else { return nil }
        do {
            if let uiColor = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: UIColor.self, from: data)
            {
                self.color = Color(uiColor)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: UIColor(color), requiringSecureCoding: false)
            return data.base64EncodedString()
        } catch {
            return ""
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = CodableColor(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid color data")
        }
        self = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct ColorSettingsView: View {
    @AppStorage("foregroundColor") private var storedForeground: CodableColor = .init(.black)
    @AppStorage("backgroundColor") private var storedBackground: CodableColor = .init(.white)
    @AppStorage("highlightColor") private var storedHighlight: CodableColor = .init(.red)
    @AppStorage("storedForegroundDark") private var storedForegroundDark: CodableColor = .init(
        .white)
    @AppStorage("storedBackgroundDark") private var storedBackgroundDark: CodableColor = .init(
        .black)
    @AppStorage("storedHighlightDark") private var storedHighlightDark: CodableColor = .init(.red)
    @AppStorage("theme") private var theme = 0
    
    private var foregroundColorBinding: Binding<Color> {
        Binding(
            get: { storedForeground.color },
            set: { storedForeground = CodableColor($0) }
        )
    }
    
    private var backgroundColorBinding: Binding<Color> {
        Binding(
            get: { storedBackground.color },
            set: { storedBackground = CodableColor($0) }
        )
    }
    
    private var highlightBinding: Binding<Color> {
        Binding(
            get: { storedHighlight.color },
            set: { storedHighlight = CodableColor($0) }
        )
    }
    
    private var foregroundColorBindingDark: Binding<Color> {
        Binding(
            get: { storedForegroundDark.color },
            set: { storedForegroundDark = CodableColor($0) }
        )
    }
    
    private var backgroundColorBindingDark: Binding<Color> {
        Binding(
            get: { storedBackgroundDark.color },
            set: { storedBackgroundDark = CodableColor($0) }
        )
    }
    
    private var highlightBindingDark: Binding<Color> {
        Binding(
            get: { storedHighlightDark.color },
            set: { storedHighlightDark = CodableColor($0) }
        )
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(
                        "theme", selection: $theme,
                        content: {
                            Text("auto").tag(0)
                            Text("theme_light").tag(1)
                            Text("dark").tag(2)
                        })
                } header: {
                    Text("appearance")
                }
                
                if theme != 2 {
                    Section {
                        ColorPicker("background_color", selection: backgroundColorBinding)
                            .accessibilityLabel(Text("background_color"))
                        
                        ColorPicker("text_color", selection: foregroundColorBinding)
                            .accessibilityLabel(Text("text_color"))
                        
                        ColorPicker("highlight_color", selection: highlightBinding)
                            .accessibilityLabel(Text("highlight_color"))
                    } header: {
                        if theme == 0 {
                            Text("light_mode")
                        }
                    }
                }
                
                if theme != 1 {
                    Section {
                        ColorPicker("background_color", selection: backgroundColorBindingDark)
                            .accessibilityLabel(Text("background_color"))
                        
                        ColorPicker("text_color", selection: foregroundColorBindingDark)
                            .accessibilityLabel(Text("text_color"))
                        
                        ColorPicker("highlight_color", selection: highlightBindingDark)
                            .accessibilityLabel(Text("highlight_color"))
                    } header: {
                        if theme == 0 {
                            Text("dark_mode")
                        }
                    }
                }
            }
            .navigationTitle("colors")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
