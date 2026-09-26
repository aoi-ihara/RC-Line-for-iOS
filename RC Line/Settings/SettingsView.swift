import SwiftUI

struct SettingsView: View {
    @Binding var showSettingsView: Bool
    @State private var showInstructionView: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(
                        action: {
                            showInstructionView = true
                        },
                        label: {
                            Label("show_tutorial", systemImage: "lightbulb")
                                .foregroundStyle(Color(.label))
                        }
                    )
                    .accessibilityLabel(Text("show_tutorial"))
                    .accessibilityHint(Text("opens_tutorial"))
                    .accessibilityAddTraits(.isButton)
                    .frame(alignment: .center)
                }
                
                Section {
                    NavigationLink(destination: FontSettingsView()) {
                        Label("fonts", systemImage: "textformat")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("fonts"))
                    .accessibilityAddTraits(.isLink)
                    
                    NavigationLink(destination: HighlightSettingsView()) {
                        Label("highlight", systemImage: "text.line.magnify")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("highlight"))
                    .accessibilityAddTraits(.isLink)
                    
                    NavigationLink(destination: ColorSettingsView()) {
                        Label("colors", systemImage: "camera.filters")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("colors"))
                    .accessibilityAddTraits(.isLink)
                    
                    NavigationLink(destination: FeatureSettingsView()) {
                        Label("features", systemImage: "wrench.and.screwdriver")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("features"))
                    .accessibilityAddTraits(.isLink)
                    
                    NavigationLink(destination: AdvancedFeaturesSettingsView()) {
                        Label("advanced_features", systemImage: "square.badge.plus")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("advanced_features"))
                    .accessibilityAddTraits(.isLink)
                    
                    NavigationLink(destination: InformationView()) {
                        Label("info", systemImage: "info.circle")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("info"))
                    .accessibilityAddTraits(.isLink)
                }
            }
            .sheet(
                isPresented: $showInstructionView,
                content: {
                    InstructionView(showInstructionView: $showInstructionView)
                        .accentColor(Color(.label))
                        .presentationDetents([.large])
                }
            )
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettingsView.toggle()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Text("close"))
                    .accessibilityHint(Text("close_settings"))
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
