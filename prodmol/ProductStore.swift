import SwiftUI
import Observation

@Observable
class ProductStore {
    var products: [Product] = []

    private let storageKey = "savedProducts"

    init() {
        load()
    }

    func add(_ product: Product) {
        products.append(product)
        save()
    }

    func delete(at offsets: IndexSet) {
        products.remove(atOffsets: offsets)
        save()
    }

    func delete(_ product: Product) {
        products.removeAll { $0.id == product.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(products) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Product].self, from: data) else {
            return
        }
        products = decoded
    }
}
