import Foundation

// MARK: - ProductStoring

protocol ProductStoring: AnyObject, Observable {
    var products: [Product] { get set }
    func add(_ product: Product)
    func delete(at offsets: IndexSet)
    func delete(_ product: Product)
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

// MARK: - SettingsProviding

protocol SettingsProviding: AnyObject, Observable {
    var apiKey: String { get set }
    var selectedTerminalId: String? { get set }
    var selectedTerminalDescription: String? { get set }
    var isConfigured: Bool { get }
}
