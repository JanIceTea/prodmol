import SwiftUI

struct ProductGridView: View {
    var products: [Product]
    var onProductTapped: (Product) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 12)
    ]

    var body: some View {
        if products.isEmpty {
            ContentUnavailableView(
                "No Products",
                systemImage: "bag",
                description: Text("Tap + to add your first product.")
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(products) { product in
                        ProductTile(product: product) {
                            onProductTapped(product)
                        }
                    }
                }
                .padding()
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
