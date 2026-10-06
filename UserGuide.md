# prodmol — User Guide

A simple point-of-sale app that pairs with the Mollie Tap app to accept card payments. Optionally import event tickets from Pretix.

---

## 1. First-Time Setup

### Mollie

1. Sign up at [mollie.com](https://www.mollie.com) and create an API key (Test or Live) from the Dashboard under **Developers → API keys**.
2. Install the **Mollie Tap** app on a second device (iPhone) and pair it with your Mollie account. Complete the onboarding until the terminal shows as **active**.
3. In prodmol, tap the **gear icon** to open Settings.
4. Paste your API key into the **API Key** field.

### Pretix (optional)

1. In your Pretix organizer account, go to **Settings → OAuth applications** and create a new application.
   - Set the **Redirect URI** to `https://example.com/oauth-callback` (or any URL you control).
   - Note the **Client ID** and **Client Secret**.
2. In prodmol Settings, tap **Pretix Configuration**.
3. Enter your **Client ID**, **Client Secret**, and **Organizer Slug** (the short name of your organizer, visible in your Pretix URL).
4. Tap **Open Pretix Authorization** — a browser will open asking you to grant access.
5. After authorizing, copy the full callback URL from your browser's address bar.
6. Paste it into the **callback URL** field in prodmol and tap **Authenticate**.
7. The status should change to **Connected**.

---

## 2. Selecting a Mollie Tap Terminal

1. Open **Settings** via the gear icon.
2. Make sure your API key is entered.
3. Tap **Load Terminals** — the app fetches all terminals linked to your account.
4. Active terminals show a **green dot**; inactive ones show a **red dot** and cannot be selected.
5. Tap an active terminal to select it. A **checkmark** confirms your selection.
6. The terminal is remembered for future payments.

> **Tip:** If your terminal shows as "cancelled", open the Mollie Tap app and complete the setup process to activate it.

---

## 3. Adding Products

1. Tap the **+** button in the top-right corner.
2. Enter a **name** and **price** for the product, then tap **Add**.
3. The product appears in the grid and in the product list below the form.
4. To remove a product, tap the **trash icon** next to it.
5. Tap **Done** when finished.

Products are stored locally on the device and persist across app restarts.

---

## 4. Importing an Event from Pretix

1. Make sure Pretix is connected (see Setup above).
2. Tap the **calendar icon** in the top-right corner.
3. The app shows all upcoming events for your organizer.
   - A **green dot** indicates a live (published) event.
4. Tap an event to import its items and variations as products.
5. The imported products appear in a separate section on the product grid, labeled with the event name.

> **Note:** Only one event can be active at a time. Importing a new event replaces the previous one. To remove all event tickets, go to the **+** screen and tap **Remove All Event Tickets** at the bottom.

---

## 5. Taking a Payment

This workflow assumes prodmol runs on an iPhone and the Mollie Tap app runs on an Android/iPhone placed next to it.

1. **Build the order** — Tap products in the grid to add them to the cart. Each tap increases the quantity by one.
2. **Review the cart** — The cart is visible in the sidebar (iPad) or via the bottom bar (iPhone). Adjust quantities with the **+** and **−** buttons.
3. **Start payment** — Tap **Pay with Mollie Tap**. The app creates a payment with a unique reference and sends it to your selected terminal.
4. **Customer pays** — The Mollie Tap app on the Android/iPhone will prompt the customer to tap or insert their card.
5. **Confirmation** — prodmol shows the payment reference and status. Once the payment succeeds on the Mollie Tap device, the order is complete.
6. **Next customer** — The cart clears automatically after a successful payment. You're ready for the next order.

### Payment Reference

Each payment gets a unique 9-character reference (e.g. `ABCDEFGHI`). This reference appears in:
- The payment description in your Mollie Dashboard
- The confirmation dialog in the app

Use it to match payments to orders.

---

## Quick Reference

| Action | How |
|---|---|
| Open settings | Gear icon (top-left) |
| Add products | **+** button (top-right) |
| Import event | Calendar icon (top-right) |
| View cart | Sidebar (iPad) or bottom bar (iPhone) |
| Clear cart | **Clear** button in cart |
| Pay | **Pay with Mollie Tap** button |
