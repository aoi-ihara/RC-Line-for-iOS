import SwiftUI

struct FontSettingsView: View {
    @AppStorage("lineWidth") private var lineWidth: Double = 75
    @AppStorage("fontSize") private var fontSize: Double = 13
    @AppStorage("fontFamily") private var fontFamily: Int = 0
    @AppStorage("fontWeight") private var fontWeight: Int = 4
    @AppStorage("lineHeight") private var lineHeight: Double = 2
    @AppStorage("sectionSpacing") private var sectionSpacing: Double = 8
    @AppStorage("letterSpacing") private var letterSpacing: Double = 1.05

    var body: some View {
        NavigationStack {
            List {
                Section(content: {
                    Picker(
                        "font_family_reading", selection: $fontFamily,
                        content: {
                            Text("system_sans").tag(0)
                            Text("system_serif").tag(1)
                            Text("Jost").tag(2)
                            Text("Lexend").tag(3)
                            Text("Roboto").tag(4)
                            Text("OpenDyslexic").tag(5)
                            Text("JetBrains Mono").tag(6)
                        }
                    )
                    .pickerStyle(.menu)
                    .accessibilityLabel(Text("font_family_reading"))

                    Picker(
                        "weight", selection: $fontWeight,
                        content: {
                            Text("ultra_light").tag(0)
                            Text("thin").tag(1)
                            Text("light").tag(2)
                            Text("regular").tag(3)
                            Text("medium").tag(4)
                            Text("semibold").tag(5)
                            Text("bold").tag(6)
                            Text("heavy").tag(7)
                            Text("black").tag(8)
                        }
                    )
                    .pickerStyle(.menu)
                    .accessibilityLabel(Text("weight"))
                })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "textformat.size.smaller")

                            Slider(value: $fontSize, in: 6...32, step: 1)
                                .accessibilityLabel(Text("font_size"))
                                .accessibilityValue(Text("\(Int(fontSize))px"))
                                .onChange(
                                    of: fontSize,
                                    {
                                        UserDefaults.standard.setValue(fontSize, forKey: "fontSize")
                                    })

                            Image(systemName: "textformat.size.larger")
                        }
                    },
                    header: {
                        Text("font_size")
                    },
                    footer: {
                        Text("\(Int(fontSize))px")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "arrow.right.and.line.vertical.and.arrow.left")

                            Slider(value: $lineWidth, in: 50...100, step: 1)
                                .accessibilityLabel(Text("line_width"))
                                .accessibilityValue(Text("\(Int(lineWidth))%"))

                            Image(systemName: "arrow.left.and.line.vertical.and.arrow.right")
                        }
                    },
                    header: {
                        Text("line_width")
                    },
                    footer: {
                        Text("\(Int(lineWidth))%")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")

                            Slider(value: $lineHeight, in: 0...4, step: 0.1)
                                .accessibilityLabel(Text("line_spacing"))
                                .accessibilityValue(Text("\(Int(lineHeight*100))%"))

                            Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                        }
                    },
                    header: {
                        Text("line_spacing")
                    },
                    footer: {
                        Text("\(Int(lineHeight*100))%")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")

                            Slider(value: $sectionSpacing, in: 0...20, step: 1)
                                .accessibilityLabel(Text("section_spacing"))
                                .accessibilityValue(Text("\(Int(sectionSpacing))pt"))

                            Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                        }
                    },
                    header: {
                        Text("section_spacing")
                    },
                    footer: {
                        Text("\(Int(sectionSpacing))pt")
                    })

                Section(
                    content: {
                        HStack {
                            Image(systemName: "arrow.right.and.line.vertical.and.arrow.left")

                            Slider(value: $letterSpacing, in: 1...2, step: 0.01)
                                .accessibilityLabel(Text("letter_spacing"))
                                .accessibilityValue(Text("\(Int(letterSpacing * 100))%"))

                            Image(systemName: "arrow.left.and.line.vertical.and.arrow.right")
                        }
                    },
                    header: {
                        Text("letter_spacing")
                    },
                    footer: {
                        Text("\(Int(letterSpacing * 100))%")
                    })
            }
            .navigationTitle("fonts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
