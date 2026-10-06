import SwiftUI
import Observation

@Observable
class ProductStore: ProductStoring {
    var products: [Product] = []

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("products.json")
    }

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

    func deleteAllEventProducts() {
        products.removeAll { $0.eventName != nil }
        save()
    }

    private func save() {
        do {
            let dir = Self.fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(products)
            try data.write(to: Self.fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            // Silently fail — product data is non-critical
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let decoded = try? JSONDecoder().decode([Product].self, from: data) else {
            return
        }
        products = decoded
    }
}
