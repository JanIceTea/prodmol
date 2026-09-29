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

    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Name", text: $name)
                    TextField("Price", text: $priceText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let price {
                            store.add(Product(name: sanitizedName, price: price))
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
