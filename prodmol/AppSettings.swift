import Foundation
import Observation

@Observable
class AppSettings {
    var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "mollieApiKey") }
    }

    var selectedTerminalId: String? {
        didSet { UserDefaults.standard.set(selectedTerminalId, forKey: "mollieTerminalId") }
    }

    var selectedTerminalDescription: String? {
        didSet { UserDefaults.standard.set(selectedTerminalDescription, forKey: "mollieTerminalDescription") }
    }

    var isConfigured: Bool {
        !apiKey.isEmpty && selectedTerminalId != nil
    }

    init() {
        self.apiKey = UserDefaults.standard.string(forKey: "mollieApiKey") ?? ""
        self.selectedTerminalId = UserDefaults.standard.string(forKey: "mollieTerminalId")
        self.selectedTerminalDescription = UserDefaults.standard.string(forKey: "mollieTerminalDescription")
    }
}
