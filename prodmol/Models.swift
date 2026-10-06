import Foundation

struct Product: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var price: Decimal
    var eventName: String?

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: price as NSDecimalNumber) ?? "€\(price)"
    }

    init(id: UUID = UUID(), name: String, price: Decimal, eventName: String? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.eventName = eventName
    }
}

struct CartItem: Identifiable {
    let id: UUID
    let product: Product
    var quantity: Int

    var subtotal: Decimal {
        product.price * Decimal(quantity)
    }

    init(id: UUID = UUID(), product: Product, quantity: Int = 1) {
        self.id = id
        self.product = product
        self.quantity = quantity
    }
}
