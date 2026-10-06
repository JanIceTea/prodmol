import Foundation

// MARK: - ProductStoring

protocol ProductStoring: AnyObject, Observable {
    var products: [Product] { get set }
    func add(_ product: Product)
    func delete(at offsets: IndexSet)
    func delete(_ product: Product)
    func deleteAllEventProducts()
}

// MARK: - CartManaging

protocol CartManaging: AnyObject, Observable {
    var items: [CartItem] { get }
    var totalAmount: Decimal { get }
    var formattedTotal: String { get }
    var isEmpty: Bool { get }
    var description: String { get }
    func addProduct(_ product: Product)
    func updateQuantity(for item: CartItem, quantity: Int)
    func removeItem(_ item: CartItem)
    func clear()
}

// MARK: - PaymentServicing

protocol PaymentServicing {
    func listTerminals(apiKey: String) async throws -> [MollieTerminal]
    func createPayment(
        apiKey: String,
        terminalId: String,
        amount: Decimal,
        description: String,
        referenceId: String
    ) async throws -> MolliePaymentResponse
    func generateReference() -> String
}

// MARK: - PretixOAuthServicing

protocol PretixOAuthServicing: AnyObject {
    var isAuthenticated: Bool { get }
    func openAuthorizationPage(clientID: String, redirectURI: String)
    func exchangeCode(_ callbackInput: String, clientID: String, clientSecret: String, redirectURI: String) async throws
    func getAccessToken() async throws -> String
    func logout()
}

// MARK: - PretixAPIServicing

protocol PretixAPIServicing {
    func fetchEvents(organizer: String) async throws -> [PretixEventResponse]
    func fetchItems(organizer: String, eventSlug: String) async throws -> [PretixItemResponse]
}

// MARK: - PretixSettingsProviding

protocol PretixSettingsProviding: AnyObject, Observable {
    var clientID: String { get set }
    var clientSecret: String { get set }
    var organizerSlug: String { get set }
    var redirectURI: String { get set }
    var isConfigured: Bool { get }
    var isAuthenticated: Bool { get set }
}

// MARK: - SettingsProviding

protocol SettingsProviding: AnyObject, Observable {
    var apiKey: String { get set }
    var selectedTerminalId: String? { get set }
    var selectedTerminalDescription: String? { get set }
    var isConfigured: Bool { get }
}
