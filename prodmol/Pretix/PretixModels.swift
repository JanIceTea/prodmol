import Foundation

// MARK: - OAuth Models

struct PretixOAuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let scope: String

    var isExpired: Bool { Date() >= expiresAt }
}

struct PretixOAuthTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String
    let scope: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
        case refreshToken = "refresh_token"
    }

    func toToken() -> PretixOAuthToken {
        PretixOAuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn)),
            scope: scope
        )
    }
}

// MARK: - Event Models

struct PretixEventResponse: Codable, Identifiable {
    let slug: String
    let name: [String: String]
    let dateFrom: String
    let dateTo: String?
    let live: Bool
    let currency: String

    var id: String { slug }

    var displayName: String {
        name["en"] ?? name["nl"] ?? name.values.first ?? slug
    }

    var parsedDateFrom: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateFrom) ?? ISO8601DateFormatter().date(from: dateFrom)
    }

    var formattedDate: String {
        guard let date = parsedDateFrom else { return dateFrom }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    enum CodingKeys: String, CodingKey {
        case slug, name, live, currency
        case dateFrom = "date_from"
        case dateTo = "date_to"
    }
}

// MARK: - Item Models

struct PretixItemResponse: Codable, Identifiable {
    let id: Int
    let name: [String: String]
    let defaultPrice: String
    let active: Bool
    let hasVariations: Bool
    let variations: [PretixItemVariationResponse]

    var displayName: String {
        name["en"] ?? name["nl"] ?? name.values.first ?? "Item \(id)"
    }

    var price: Decimal {
        Decimal(string: defaultPrice) ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id, name, active, variations
        case defaultPrice = "default_price"
        case hasVariations = "has_variations"
    }
}

struct PretixItemVariationResponse: Codable, Identifiable {
    let id: Int
    let value: [String: String]
    let defaultPrice: String?
    let price: String
    let active: Bool
    let position: Int

    var displayName: String {
        value["en"] ?? value["nl"] ?? value.values.first ?? "Variation \(id)"
    }

    var effectivePrice: Decimal {
        Decimal(string: price) ?? Decimal(string: defaultPrice ?? "") ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id, value, price, active, position
        case defaultPrice = "default_price"
    }
}

// MARK: - Pagination

struct PretixPaginatedResponse<T: Codable>: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [T]
}

// MARK: - Errors

enum PretixOAuthError: LocalizedError {
    case notConfigured
    case authenticationFailed
    case tokenExchangeFailed(String)
    case tokenRefreshFailed
    case noToken
    case noCodeInURL

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Pretix is not configured."
        case .authenticationFailed: return "Authentication failed."
        case .tokenExchangeFailed(let detail): return "Token exchange failed: \(detail)"
        case .tokenRefreshFailed: return "Token refresh failed. Please reconnect."
        case .noToken: return "Not authenticated. Please connect in Settings."
        case .noCodeInURL: return "No authorization code found in the callback URL."
        }
    }
}

enum PretixAPIError: LocalizedError {
    case invalidURL
    case requestFailed(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .requestFailed(let code): return "API request failed (\(code))."
        case .decodingFailed: return "Failed to decode API response."
        }
    }
}
