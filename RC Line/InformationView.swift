import SwiftUI

struct InformationView: View {
    @Environment(\.openURL) var openURL

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

                Section("version_info") {
                    if let version = Bundle.main.object(
                        forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                    {
                        Text(version)
                    }
                }
            }
            .navigationTitle("info")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(
                isPresented: $showInstructionView,
                content: {
                    InstructionView(showInstructionView: $showInstructionView)
                        .accentColor(Color(.label))
                        .presentationDetents([.large])
                        .interactiveDismissDisabled(true)
                }
            )
        }
    }
}