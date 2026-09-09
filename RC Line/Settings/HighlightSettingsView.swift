import SwiftUI

struct HighlightSettingsView: View {
    @AppStorage("borderOpacity") var borderOpacity: Double = 0
    @AppStorage("textOpacity") var textOpacity: Double = 0.15
    @AppStorage("scaleEffect") var scaleEffect: Bool = false
    @AppStorage("selectedTextOpacity") var selectedTextOpacity: Double = 0.25
    @AppStorage("animate") private var animate: Bool = true

    var body: some View {
        NavigationStack {
            List {
                Section(
                    content: {
                        HStack {
                            Image(systemName: "character")

                            Slider(value: $selectedTextOpacity, in: 0...1, step: 0.05)
                                .accessibilityLabel(Text("background_opacity"))
                                .accessibilityValue(Text("\(Int(selectedTextOpacity*100))%"))

                            Image(systemName: "a.square.fill")
                        }
                    },
                    header: {
                        Text("background_opacity")
                    },
                    footer: {
                        Text("\(Int(selectedTextOpacity*100))%")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "square.dotted")

                            Slider(value: $borderOpacity, in: 0...1, step: 0.05)
                                .accessibilityLabel(Text("border_opacity"))
                                .accessibilityValue(Text("\(Int(borderOpacity*100))%"))

                            Image(systemName: "square")
                        }
                    },
                    header: {
                        Text("border_opacity")
                    },
                    footer: {
                        Text("\(Int(borderOpacity*100))%")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "square.stack.3d.forward.dottedline")

                            Slider(value: $textOpacity, in: 0...0.5, step: 0.05)
                                .accessibilityLabel(Text("fade_distance"))
                                .accessibilityValue(Text("\(Int(textOpacity*100))%"))

                            Image(systemName: "square.stack.3d.forward.dottedline.fill")
                        }
                    },
                    header: {
                        Text("fade_distance")
                    },
                    footer: {
                        Text("\(Int(textOpacity*100))%")
                    })

                Toggle("animations", isOn: $animate)
                    .accessibilityLabel(Text("animations"))
                Toggle("scale_effect", isOn: $scaleEffect)
                    .accessibilityLabel(Text("scale_effect"))
            }
            .navigationTitle("highlight")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
