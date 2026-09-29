import Foundation
import Security
import CommonCrypto

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

/*
echo | openssl s_client -connect api.mollie.com:443 -servername api.mollie.com 2>/dev/null  | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
*/

class MollieService: PaymentServicing {
    private let baseURL = "https://api.mollie.com/v2"
    private let session: URLSession

    init() {
        let pinningDelegate = CertificatePinningDelegate()
        session = URLSession(configuration: .default, delegate: pinningDelegate, delegateQueue: nil)
    }

    func listTerminals(apiKey: String) async throws -> [MollieTerminal] {
        guard let url = URL(string: "\(baseURL)/terminals") else {
            throw MollieServiceError.apiError("Invalid URL configuration")
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MollieServiceError.apiError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            throw MollieServiceError.apiError(sanitizedError(from: data, statusCode: httpResponse.statusCode))
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
        guard let url = URL(string: "\(baseURL)/payments") else {
            throw MollieServiceError.apiError("Invalid URL configuration")
        }
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

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MollieServiceError.apiError("Invalid response")
        }

        if httpResponse.statusCode != 201 {
            throw MollieServiceError.apiError(sanitizedError(from: data, statusCode: httpResponse.statusCode))
        }

        return try JSONDecoder().decode(MolliePaymentResponse.self, from: data)
    }

    /// Returns a user-safe error message, stripping internal API details
    private func sanitizedError(from data: Data, statusCode: Int) -> String {
        if let errorResponse = try? JSONDecoder().decode(MollieErrorResponse.self, from: data) {
            // Map known error titles to user-friendly messages
            switch errorResponse.title {
            case "Unauthorized":
                return "Invalid API key. Check your credentials in Settings."
            case "Unprocessable Entity":
                return "The payment could not be processed. Please check the amount and try again."
            case "Not Found":
                return "Terminal not found. Please re-select your terminal in Settings."
            default:
                return "Payment service error (\(statusCode)). Please try again."
            }
        }
        return "Request failed (\(statusCode)). Please try again."
    }

    /// Generates a PrestaShop-style order reference (9 uppercase alphanumeric characters)
    func generateReference() -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var bytes = [UInt8](repeating: 0, count: 9)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return String(bytes.map { chars[Int($0) % chars.count] })
    }
}
// MARK: - Certificate Pinning

private class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    // SHA-256 hashes of pinned public keys (base64-encoded)
    // Leaf certificate for api.mollie.com
    // Intermediate CA as backup (survives leaf rotation)
    private let pinnedKeyHashes: Set<String> = [
        "Yqts8V/ZiwfReBSVHqGoLllps+7v8U/5PW/oUjU/GWw=",
        "OdSlmQD9NWJh4EbcOHBxkhygPwNSwA9Q91eounfbcoE="
    ]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              challenge.protectionSpace.host == "api.mollie.com",
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Evaluate the trust chain first
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Check each certificate in the chain against our pinned hashes
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        for index in 0..<certificateCount {
            guard let certificate = SecTrustCopyCertificateChain(serverTrust)
                .map({ $0 as! [SecCertificate] })?[safe: index] else {
                continue
            }

            if let publicKey = SecCertificateCopyKey(certificate),
               let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as? Data {
                let hash = sha256(data: publicKeyData)
                let hashBase64 = hash.base64EncodedString()

                if pinnedKeyHashes.contains(hashBase64) {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    return
                }
            }
        }

        // No matching pin found — reject the connection
        completionHandler(.cancelAuthenticationChallenge, nil)
    }

    private func sha256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

