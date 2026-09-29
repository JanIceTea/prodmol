import Foundation
import Observation
import Security

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

// MARK: - Keychain Helper

private enum KeychainHelper {
    private static let service = "com.prodmol.settings"

    static func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Only store non-empty values
        guard !value.isEmpty else { return }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}
