import Foundation
import Observation

@Observable
class AppSettings: SettingsProviding {
    var apiKey: String {
        didSet { KeychainHelper.save(apiKey, forKey: "mollieApiKey") }
    }

    var selectedTerminalId: String? {
        didSet { KeychainHelper.save(selectedTerminalId ?? "", forKey: "mollieTerminalId") }
    }

    var selectedTerminalDescription: String? {
        didSet { KeychainHelper.save(selectedTerminalDescription ?? "", forKey: "mollieTerminalDescription") }
    }

    var isConfigured: Bool {
        !apiKey.isEmpty && selectedTerminalId != nil
    }

    init() {
        self.apiKey = KeychainHelper.load(forKey: "mollieApiKey") ?? ""
        self.selectedTerminalId = KeychainHelper.load(forKey: "mollieTerminalId")
        self.selectedTerminalDescription = KeychainHelper.load(forKey: "mollieTerminalDescription")
    }
}
