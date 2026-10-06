import SwiftUI

struct SettingsView: View {
    var settings: any SettingsProviding
    var pretixSettings: (any PretixSettingsProviding)?
    var pretixOAuth: (any PretixOAuthServicing)?
    private let mollieService: any PaymentServicing = MollieService()

    @State private var terminals: [MollieTerminal] = []
    @State private var isLoadingTerminals = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Mollie API") {
                SecureField("API Key", text: Binding(
                    get: { settings.apiKey },
                    set: { settings.apiKey = $0 }
                ))
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            if FeatureToggles.terminalSelection { Section("Terminal") {
                if let terminal = settings.selectedTerminalId,
                   let description = settings.selectedTerminalDescription {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(description)
                                .font(.body)
                            Text(terminal)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Text("No terminal selected")
                        .foregroundStyle(.secondary)
                }

                Button {
                    loadTerminals()
                } label: {
                    HStack {
                        Text("Load Terminals")
                        Spacer()
                        if isLoadingTerminals {
                            ProgressView()
                        }
                    }
                }
                .disabled(settings.apiKey.isEmpty || isLoadingTerminals)

                ForEach(terminals) { terminal in
                    let isActive = terminal.status == "active"
                    Button {
                        settings.selectedTerminalId = terminal.id
                        settings.selectedTerminalDescription = terminal.description
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(terminal.description)
                                    .font(.body)
                                    .foregroundStyle(isActive ? .primary : .secondary)
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(isActive ? .green : .red)
                                        .frame(width: 8, height: 8)
                                    Text("\(terminal.id) · \(terminal.status)")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if settings.selectedTerminalId == terminal.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .disabled(!isActive)
                }
            } }

            if FeatureToggles.pretixEvents,
               let pretixSettings,
               let pretixOAuth {
                Section("Pretix Events") {
                    NavigationLink {
                        PretixSettingsView(
                            settings: pretixSettings,
                            oauthService: pretixOAuth
                        )
                    } label: {
                        HStack {
                            Text("Pretix Configuration")
                            Spacer()
                            if pretixSettings.isAuthenticated {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Text("Not connected")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
        }
        .navigationTitle("Settings")
    }

    private func loadTerminals() {
        guard !settings.apiKey.isEmpty else { return }
        isLoadingTerminals = true
        errorMessage = nil

        Task {
            do {
                terminals = try await mollieService.listTerminals(apiKey: settings.apiKey)
                if terminals.isEmpty {
                    errorMessage = "No terminals found. Make sure the Mollie Tap app is set up and paired."
                } else if !terminals.contains(where: { $0.status == "active" }) {
                    errorMessage = "No active terminals found. Open the Mollie Tap app and complete the setup to activate a terminal."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoadingTerminals = false
        }
    }
}
