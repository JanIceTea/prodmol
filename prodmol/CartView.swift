import SwiftUI

struct CartView: View {
    @Environment(\.dismiss) private var dismiss
    var cart: any CartManaging
    var settings: any SettingsProviding

    var body: some View {
        NavigationStack {
            Group {
                if cart.isEmpty {
                    ContentUnavailableView(
                        "Cart is Empty",
                        systemImage: "cart",
                        description: Text("Tap a product to add it to your cart.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(cart.items) { item in
                                CartItemRow(item: item, cart: cart)
                            }
                        }

                        Section {
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text(cart.formattedTotal)
                                    .font(.headline)
                            }
                        }

                        Section {
                            CheckoutButton(cart: cart, settings: settings)

                            if !settings.isConfigured {
                                Text("Configure your API key and terminal in Settings first.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if !cart.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear", role: .destructive) {
                            cart.clear()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Checkout Button (shared between CartView sheet and sidebar)

struct CheckoutButton: View {
    var cart: any CartManaging
    var settings: any SettingsProviding

    @State private var isProcessing = false
    @State private var paymentResult: PaymentResult?

    private let mollieService: any PaymentServicing = MollieService()

    var body: some View {
        Button(action: checkout) {
            HStack {
                Spacer()
                if isProcessing {
                    ProgressView()
                        .padding(.trailing, 8)
                }
                Label("Pay with Mollie Tap", systemImage: "creditcard")
                    .font(.headline)
                Spacer()
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!settings.isConfigured || isProcessing || cart.isEmpty)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .alert(
            paymentResult?.title ?? "",
            isPresented: Binding(
                get: { paymentResult != nil },
                set: { if !$0 { paymentResult = nil } }
            )
        ) {
            Button("OK") {
                if paymentResult?.isSuccess == true {
                    cart.clear()
                }
                paymentResult = nil
            }
        } message: {
            Text(paymentResult?.message ?? "")
        }
    }

    private func checkout() {
        guard let terminalId = settings.selectedTerminalId,
              !isProcessing else { return }

        isProcessing = true
        let reference = mollieService.generateReference()
        let prefix = "\(reference) — "
        let maxDescriptionLength = 255
        let itemsDescription = String(cart.description.prefix(maxDescriptionLength - prefix.count))
        let description = prefix + itemsDescription
        let amount = cart.totalAmount

        Task {
            do {
                let response = try await mollieService.createPayment(
                    apiKey: settings.apiKey,
                    terminalId: terminalId,
                    amount: amount,
                    description: description,
                    referenceId: reference
                )
                paymentResult = PaymentResult(
                    title: "Payment Created",
                    message: "Reference: \(reference)\nPayment ID: \(response.id)\nStatus: \(response.status)\n\nThe Mollie Tap app will prompt for payment.",
                    isSuccess: true
                )
            } catch {
                paymentResult = PaymentResult(
                    title: "Payment Failed",
                    message: error.localizedDescription,
                    isSuccess: false
                )
            }
            isProcessing = false
        }
    }
}

struct PaymentResult {
    let title: String
    let message: String
    let isSuccess: Bool
}

struct CartItemRow: View {
    let item: CartItem
    var cart: any CartManaging

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.product.name)
                    .font(.body)
                Text(item.product.formattedPrice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    cart.updateQuantity(for: item, quantity: item.quantity - 1)
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)

                Text("\(item.quantity)")
                    .monospacedDigit()
                    .frame(minWidth: 24)

                Button {
                    cart.updateQuantity(for: item, quantity: item.quantity + 1)
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.borderless)
            }

            Text(formattedSubtotal)
                .frame(width: 70, alignment: .trailing)
                .monospacedDigit()
        }
    }

    private var formattedSubtotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: item.subtotal as NSDecimalNumber) ?? "€\(item.subtotal)"
    }
}
