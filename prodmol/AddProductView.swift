import SwiftUI

struct AddProductView: View {
    @Environment(\.dismiss) private var dismiss
    var store: ProductStore

    @State private var name = ""
    @State private var priceText = ""

    private var price: Decimal? {
        Decimal(string: priceText.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && price != nil
            && (price ?? 0) > 0
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
                            store.add(Product(name: name.trimmingCharacters(in: .whitespaces), price: price))
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
