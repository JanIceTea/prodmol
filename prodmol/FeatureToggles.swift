import Foundation

enum FeatureToggles {
    /// Allow adding new products from the app
    static var addProducts = true

    /// Allow deleting products
    static var deleteProducts = true

    /// Show the cart and allow purchases
    static var checkout = true

    /// Show the settings screen
    static var settings = true

    /// Show terminal selection in settings
    static var terminalSelection = true

    /// Show Pretix event import feature
    static var pretixEvents = true
}
