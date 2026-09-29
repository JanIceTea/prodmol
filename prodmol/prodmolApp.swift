import SwiftUI

@main
struct prodmolApp: App {
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings)
        }
    }
}
