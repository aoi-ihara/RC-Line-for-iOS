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
                    .frame(alignment: .center)
                }
                
                Section {
                    NavigationLink(destination: FontSettingsView()) {
                        Label("fonts", systemImage: "textformat")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("fonts"))
                    
                    NavigationLink(destination: HighlightSettingsView()) {
                        Label("highlight", systemImage: "text.line.magnify")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("highlight"))
                    
                    NavigationLink(destination: ColorSettingsView()) {
                        Label("colors", systemImage: "camera.filters")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("colors"))
                    
                    NavigationLink(destination: FeatureSettingsView()) {
                        Label("features", systemImage: "wrench.and.screwdriver")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("features"))
                    
                    NavigationLink(destination: AdvancedFeaturesSettingsView()) {
                        Label("advanced_features", systemImage: "square.badge.plus")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("advanced_features"))
                    
                    NavigationLink(destination: InformationView()) {
                        Label("info", systemImage: "info.circle")
                            .foregroundStyle(Color(.label))
                    }
                    .accessibilityLabel(Text("info"))
                }
            }
            .sheet(
                isPresented: $showInstructionView,
                content: {
                    InstructionView(showInstructionView: $showInstructionView)
                        .tint(Color(.label))
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            )
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done") {
                        showSettingsView = false
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel(Text("done"))
                    .accessibilityHint(Text("close_settings"))
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
