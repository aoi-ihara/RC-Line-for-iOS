import SwiftUI

struct SettingsView: View {
    @Binding var showSettingsView: Bool

    var body: some View {
        NavigationStack {
            List {
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