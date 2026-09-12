import SwiftUI

struct InformationView: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationStack {
            List {
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
        }
    }
}
