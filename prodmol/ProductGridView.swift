import SwiftUI

struct ProductGridView: View {
    var products: [Product]
    var onProductTapped: (Product) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 12)
    ]

    private var regularProducts: [Product] {
        products.filter { $0.eventName == nil }
    }

    private var eventGroups: [(name: String, products: [Product])] {
        let eventProducts = products.filter { $0.eventName != nil }
        let grouped = Dictionary(grouping: eventProducts) { $0.eventName! }
        return grouped.sorted { $0.key < $1.key }.map { (name: $0.key, products: $0.value) }
    }

    var body: some View {
        if products.isEmpty {
            ContentUnavailableView(
                "No Products",
                systemImage: "bag",
                description: Text("Tap + to add your first product.")
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !regularProducts.isEmpty {
                        productSection(title: "Products", items: regularProducts)
                    }

                    ForEach(eventGroups, id: \.name) { group in
                        productSection(title: group.name, items: group.products)
                    }
                }
                .padding()
            }
        }
    }

    private func productSection(title: String, items: [Product]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { product in
                    ProductTile(product: product) {
                        onProductTapped(product)
                    }
                }
            }
        }
    }
}

struct ProductTile: View {
    let product: Product
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(product.formattedPrice)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding()
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
