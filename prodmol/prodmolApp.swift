import SwiftUI

@main
struct prodmolApp: App {
    @State private var settings = AppSettings()
    @State private var pretixSettings = PretixSettings()
    @State private var pretixOAuth = PretixOAuthService()

    var body: some Scene {
        WindowGroup {
            ContentView(
                settings: settings,
                pretixSettings: pretixSettings,
                pretixOAuth: pretixOAuth
            )
        }
    }
}
