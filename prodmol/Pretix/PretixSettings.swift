import Foundation
import Observation

@Observable
class PretixSettings: PretixSettingsProviding {
    var clientID: String {
        didSet { KeychainHelper.save(clientID, forKey: "pretix_client_id") }
    }

    var clientSecret: String {
        didSet { KeychainHelper.save(clientSecret, forKey: "pretix_client_secret") }
    }

    var organizerSlug: String {
        didSet { KeychainHelper.save(organizerSlug, forKey: "pretix_organizer_slug") }
    }

    var redirectURI: String {
        didSet { KeychainHelper.save(redirectURI, forKey: "pretix_redirect_uri") }
    }

    var isConfigured: Bool {
        !clientID.isEmpty && !clientSecret.isEmpty && !organizerSlug.isEmpty
    }

    var isAuthenticated: Bool = false

    init() {
        self.clientID = KeychainHelper.load(forKey: "pretix_client_id") ?? ""
        self.clientSecret = KeychainHelper.load(forKey: "pretix_client_secret") ?? ""
        self.organizerSlug = KeychainHelper.load(forKey: "pretix_organizer_slug") ?? ""
        self.redirectURI = KeychainHelper.load(forKey: "pretix_redirect_uri") ?? "https://example.com/oauth-callback"
    }
}
