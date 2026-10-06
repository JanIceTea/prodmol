import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class PretixOAuthService: PretixOAuthServicing {
    private let baseURL = "https://pretix.eu"
    private let tokenKeychainKey = "pretix_oauth_token"
    private let session: URLSession

    private var token: PretixOAuthToken?
    private var clientID: String?
    private var clientSecret: String?

    var isAuthenticated: Bool { token != nil }

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        self.session = URLSession(configuration: config)
        loadStoredToken()
    }

    func openAuthorizationPage(clientID: String, redirectURI: String) {
        self.clientID = clientID

        var components = URLComponents(string: "\(baseURL)/api/v1/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "read"),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]

        guard let url = components.url else { return }

        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }

    func exchangeCode(
        _ callbackInput: String,
        clientID: String,
        clientSecret: String,
        redirectURI: String
    ) async throws {
        self.clientID = clientID
        self.clientSecret = clientSecret

        let code = extractCode(from: callbackInput)
        guard let code, !code.isEmpty else {
            throw PretixOAuthError.noCodeInURL
        }

        let tokenResponse = try await requestToken(
            grantType: "authorization_code",
            parameters: "code=\(code)&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI)",
            clientID: clientID,
            clientSecret: clientSecret
        )

        self.token = tokenResponse.toToken()
        saveToken()
    }

    func getAccessToken() async throws -> String {
        guard var token else { throw PretixOAuthError.noToken }

        if token.isExpired {
            guard let clientID, let clientSecret else {
                throw PretixOAuthError.notConfigured
            }
            token = try await refreshToken(token, clientID: clientID, clientSecret: clientSecret)
            self.token = token
            saveToken()
        }

        return token.accessToken
    }

    func logout() {
        token = nil
        KeychainHelper.delete(forKey: tokenKeychainKey)
    }

    // MARK: - Private

    private func refreshToken(
        _ token: PretixOAuthToken,
        clientID: String,
        clientSecret: String
    ) async throws -> PretixOAuthToken {
        let tokenResponse = try await requestToken(
            grantType: "refresh_token",
            parameters: "refresh_token=\(token.refreshToken)",
            clientID: clientID,
            clientSecret: clientSecret
        )
        return tokenResponse.toToken()
    }

    private func requestToken(
        grantType: String,
        parameters: String,
        clientID: String,
        clientSecret: String
    ) async throws -> PretixOAuthTokenResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/oauth/token") else {
            throw PretixOAuthError.authenticationFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let credentials = "\(clientID):\(clientSecret)"
        let encoded = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")

        request.httpBody = "grant_type=\(grantType)&\(parameters)".data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PretixOAuthError.tokenExchangeFailed(detail)
        }

        return try JSONDecoder().decode(PretixOAuthTokenResponse.self, from: data)
    }

    private func extractCode(from input: String) -> String? {
        if let components = URLComponents(string: input),
           let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
            return code
        }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func saveToken() {
        guard let token, let data = try? JSONEncoder().encode(token) else { return }
        KeychainHelper.saveData(data, forKey: tokenKeychainKey)
    }

    private func loadStoredToken() {
        guard let data = KeychainHelper.loadData(forKey: tokenKeychainKey),
              let decoded = try? JSONDecoder().decode(PretixOAuthToken.self, from: data) else {
            return
        }
        token = decoded
    }
}
