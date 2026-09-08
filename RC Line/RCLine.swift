import SwiftUI

@main
struct RCLineApp: App {
    @AppStorage("theme") private var theme = 0
    @Environment(\.colorScheme) var colorScheme

    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(Color(.label))
                .task {
                    registerCustomFont(fontName: "Lexend-Regular", fileName: "Lexend", extension: "ttf")
                }
                .preferredColorScheme(theme == 0 ? nil : (theme == 1 ? .light : .dark))
        }
    }
}
