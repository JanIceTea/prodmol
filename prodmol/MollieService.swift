import Foundation

struct MollieTerminal: Identifiable, Codable {
    let id: String
    let description: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, description, status
    }
}

struct MollieTerminalsResponse: Codable {
    let count: Int
    struct Embedded: Codable {
        let terminals: [MollieTerminal]
    }
    let embedded: Embedded

    enum CodingKeys: String, CodingKey {
        case count
        case embedded = "_embedded"
    }
}

struct MolliePaymentResponse: Codable {
    let id: String
    let status: String
    let description: String?
}

struct MollieError: Codable {
    let status: Int
    let title: String
    let detail: String
}

struct MollieErrorResponse: Codable {
    let status: Int
    let title: String
    let detail: String
}

enum MollieServiceError: LocalizedError {
    case notConfigured
    case apiError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Mollie is not configured. Please set your API key and select a terminal in Settings."
        case .apiError(let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

class MollieService {
    private let baseURL = "https://api.mollie.com/v2"

    func listTerminals(apiKey: String) async throws -> [MollieTerminal] {
        let url = URL(string: "\(baseURL)/terminals")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MollieServiceError.apiError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(MollieErrorResponse.self, from: data) {
                throw MollieServiceError.apiError(errorResponse.detail)
            }
            throw MollieServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let decoded = try JSONDecoder().decode(MollieTerminalsResponse.self, from: data)
        return decoded.embedded.terminals
    }

    func createPayment(
        apiKey: String,
        terminalId: String,
        amount: Decimal,
        description: String,
        referenceId: String
    ) async throws -> MolliePaymentResponse {
        let url = URL(string: "\(baseURL)/payments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let amountString = NSDecimalNumber(decimal: amount).stringValue
        // Ensure two decimal places
        let formattedAmount: String
        if amountString.contains(".") {
            let parts = amountString.split(separator: ".")
            let decimals = parts.count > 1 ? String(parts[1]) : ""
            formattedAmount = "\(parts[0]).\(decimals.padding(toLength: 2, withPad: "0", startingAt: 0))"
        } else {
            formattedAmount = "\(amountString).00"
        }

        let body: [String: Any] = [
            "amount": [
                "currency": "EUR",
                "value": formattedAmount
            ],
            "description": description,
            "method": "pointofsale",
            "terminalId": terminalId,
            "metadata": [
                "reference": referenceId
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MollieServiceError.apiError("Invalid response")
        }

        if httpResponse.statusCode != 201 {
            if let errorResponse = try? JSONDecoder().decode(MollieErrorResponse.self, from: data) {
                throw MollieServiceError.apiError(errorResponse.detail)
            }
            throw MollieServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(MolliePaymentResponse.self, from: data)
    }

    /// Generates a PrestaShop-style order reference (9 uppercase alphanumeric characters)
    static func generateReference() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<9).map { _ in chars.randomElement()! })
    }
}
