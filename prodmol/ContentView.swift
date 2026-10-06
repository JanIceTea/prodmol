import SwiftUI

struct ContentView: View {
    @State private var store: any ProductStoring = ProductStore()
    @State private var cart: any CartManaging = CartManager()
    var settings: any SettingsProviding
    var pretixSettings: any PretixSettingsProviding
    var pretixOAuth: any PretixOAuthServicing

    @State private var showingAddProduct = false
    @State private var showingCart = false
    @State private var showingPretixEvents = false

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
                            if FeatureToggles.settings {
                                NavigationLink {
                                    settingsDestination
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                            }
                            if FeatureToggles.pretixEvents {
                                Button {
                                    showingPretixEvents = true
                                } label: {
                                    Image(systemName: "calendar.badge.plus")
                                }
                            }
                            if FeatureToggles.addProducts {
                                Button {
                                    showingAddProduct = true
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingAddProduct) {
                    AddProductView(store: store)
                }
                .sheet(isPresented: $showingPretixEvents) {
                    pretixEventList
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

                    if FeatureToggles.checkout {
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
                if FeatureToggles.settings {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            settingsDestination
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        if FeatureToggles.pretixEvents {
                            Button {
                                showingPretixEvents = true
                            } label: {
                                Image(systemName: "calendar.badge.plus")
                            }
                        }
                        if FeatureToggles.addProducts {
                            Button {
                                showingAddProduct = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
                if FeatureToggles.checkout {
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
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView(store: store)
            }
            .sheet(isPresented: $showingCart) {
                CartView(cart: cart, settings: settings)
            }
            .sheet(isPresented: $showingPretixEvents) {
                pretixEventList
            }
        }
    }

    // MARK: - Shared Destinations

    private var settingsDestination: some View {
        SettingsView(
            settings: settings,
            pretixSettings: pretixSettings,
            pretixOAuth: pretixOAuth
        )
    }

    private var pretixEventList: some View {
        PretixEventListView(
            store: store,
            pretixSettings: pretixSettings,
            apiService: PretixAPIService(oauthService: pretixOAuth)
        )
    }
}

#Preview {
    ContentView(
        settings: AppSettings(),
        pretixSettings: PretixSettings(),
        pretixOAuth: PretixOAuthService()
    )
}
