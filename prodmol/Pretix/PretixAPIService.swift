import Foundation

class PretixAPIService: PretixAPIServicing {
    private let baseURL = "https://pretix.eu/api/v1"
    private let oauthService: any PretixOAuthServicing
    private let session: URLSession

    init(oauthService: any PretixOAuthServicing) {
        self.oauthService = oauthService
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        self.session = URLSession(configuration: config)
    }

    func fetchEvents(organizer: String) async throws -> [PretixEventResponse] {
        var allEvents: [PretixEventResponse] = []
        var nextURL: String? = "\(baseURL)/organizers/\(organizer)/events/?is_future=true&ordering=date_from"

        while let urlString = nextURL {
            guard let url = URL(string: urlString) else { throw PretixAPIError.invalidURL }
            let request = try await authenticatedRequest(url: url)
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw PretixAPIError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            let decoded = try JSONDecoder().decode(PretixPaginatedResponse<PretixEventResponse>.self, from: data)
            allEvents.append(contentsOf: decoded.results)
            nextURL = decoded.next
        }

        return allEvents
    }

    func fetchItems(organizer: String, eventSlug: String) async throws -> [PretixItemResponse] {
        var allItems: [PretixItemResponse] = []
        var nextURL: String? = "\(baseURL)/organizers/\(organizer)/events/\(eventSlug)/items/"

        while let urlString = nextURL {
            guard let url = URL(string: urlString) else { throw PretixAPIError.invalidURL }
            let request = try await authenticatedRequest(url: url)
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw PretixAPIError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            let decoded = try JSONDecoder().decode(PretixPaginatedResponse<PretixItemResponse>.self, from: data)
            allItems.append(contentsOf: decoded.results)
            nextURL = decoded.next
        }

        return allItems
    }

    private func authenticatedRequest(url: URL) async throws -> URLRequest {
        let accessToken = try await oauthService.getAccessToken()
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
