import SwiftUI

struct ContentView: View {
    @State private var store = ProductStore()
    @State private var cart = CartManager()
    var settings: AppSettings

    @State private var showingAddProduct = false
    @State private var showingCart = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            wideLayout
        } else {
            compactLayout
        }
    }

    // MARK: - iPad / Mac: side-by-side layout

    private var wideLayout: some View {
        NavigationSplitView {
            cartSidebar
                .navigationTitle("Cart")
        } detail: {
            NavigationStack {
                ProductGridView(products: store.products) { product in
                    cart.addProduct(product)
                }
                .navigationTitle("Products")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack {
                            NavigationLink {
                                SettingsView(settings: settings)
                            } label: {
                                Image(systemName: "gearshape")
                            }
                            Button {
                                showingAddProduct = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingAddProduct) {
                    AddProductView(store: store)
                }
            }
        }
    }

    private var cartSidebar: some View {
        Group {
            if cart.isEmpty {
                ContentUnavailableView(
                    "Cart is Empty",
                    systemImage: "cart",
                    description: Text("Tap a product to add it.")
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
                        CheckoutButton(
                            cart: cart,
                            settings: settings
                        )

                        if !settings.isConfigured {
                            Text("Configure your API key and terminal in Settings first.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear", role: .destructive) {
                            cart.clear()
                        }
                    }
                }
            }
        }
    }

    // MARK: - iPhone: compact layout with sheets

    private var compactLayout: some View {
        NavigationStack {
            ProductGridView(products: store.products) { product in
                cart.addProduct(product)
                showingCart = true
            }
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView(settings: settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddProduct = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if !cart.isEmpty {
                        Button {
                            showingCart = true
                        } label: {
                            HStack {
                                Image(systemName: "cart")
                                Text("\(cart.items.count) items — \(cart.formattedTotal)")
                            }
                            .font(.headline)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView(store: store)
            }
            .sheet(isPresented: $showingCart) {
                CartView(cart: cart, settings: settings)
            }
        }
    }
}

#Preview {
    ContentView(settings: AppSettings())
}
