import Foundation
import Observation

@Observable
class CartManager {
    var items: [CartItem] = []

    var totalAmount: Decimal {
        items.reduce(Decimal.zero) { $0 + $1.subtotal }
    }

    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: totalAmount as NSDecimalNumber) ?? "€\(totalAmount)"
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    var description: String {
        items.map { "\($0.quantity)x \($0.product.name)" }.joined(separator: ", ")
    }

    func addProduct(_ product: Product) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(product: product))
        }
    }

    func updateQuantity(for item: CartItem, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = quantity
        }
    }

    func removeItem(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
    }

    func clear() {
        items.removeAll()
    }
}
