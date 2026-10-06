import SwiftUI

struct AddProductView: View {
    @Environment(\.dismiss) private var dismiss
    var store: any ProductStoring

    @State private var name = ""
    @State private var priceText = ""

    private var price: Decimal? {
        Decimal(string: priceText.replacingOccurrences(of: ",", with: "."))
    }

    private static let maxNameLength = 100
    private static let maxPrice: Decimal = 99999.99

    private var sanitizedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove control characters
        let filtered = trimmed.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
        let clean = String(String.UnicodeScalarView(filtered))
        return String(clean.prefix(Self.maxNameLength))
    }

    private var isValid: Bool {
        !sanitizedName.isEmpty
            && price != nil
            && (price ?? 0) > 0
            && (price ?? 0) <= Self.maxPrice
    }

    private var regularProducts: [Product] {
        store.products.filter { $0.eventName == nil }
    }

    private var eventProducts: [Product] {
        store.products.filter { $0.eventName != nil }
    }

    var body: some View {
        NavigationStack {
            Form {
                if FeatureToggles.addProducts {
                    Section("New Product") {
                        TextField("Name", text: $name)
                        TextField("Price", text: $priceText)
                            .keyboardType(.decimalPad)

                        Button("Add") {
                            if let price {
                                store.add(Product(name: sanitizedName, price: price))
                                name = ""
                                priceText = ""
                            }
                        }
                        .disabled(!isValid)
                    }
                }

                if !regularProducts.isEmpty {
                    Section("Products") {
                        ForEach(regularProducts) { product in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.name)
                                    Text(product.formattedPrice)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if FeatureToggles.deleteProducts {
                                    Button(role: .destructive) {
                                        store.delete(product)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                if !eventProducts.isEmpty {
                    Section {
                        ForEach(eventProducts) { product in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.name)
                                    Text("\(product.eventName ?? "") · \(product.formattedPrice)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if FeatureToggles.deleteProducts {
                                    Button(role: .destructive) {
                                        store.delete(product)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Event Tickets")
                    } footer: {
                        if FeatureToggles.deleteProducts {
                            Button("Remove All Event Tickets", role: .destructive) {
                                store.deleteAllEventProducts()
                            }
                            .font(.callout)
                        }
                    }
                }
            }
            .navigationTitle("Manage Products")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
