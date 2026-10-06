import SwiftUI

struct PretixSettingsView: View {
    var settings: any PretixSettingsProviding
    var oauthService: any PretixOAuthServicing

    @State private var callbackInput = ""
    @State private var isExchanging = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        Form {
            Section("Pretix Credentials") {
                TextField("Client ID", text: Binding(
                    get: { settings.clientID },
                    set: { settings.clientID = $0 }
                ))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                SecureField("Client Secret", text: Binding(
                    get: { settings.clientSecret },
                    set: { settings.clientSecret = $0 }
                ))
                .textContentType(.password)

                TextField("Organizer Slug", text: Binding(
                    get: { settings.organizerSlug },
                    set: { settings.organizerSlug = $0 }
                ))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                TextField("Redirect URI", text: Binding(
                    get: { settings.redirectURI },
                    set: { settings.redirectURI = $0 }
                ))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
            }

            Section("Authentication") {
                if oauthService.isAuthenticated {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Connected to Pretix")
                    }

                    Button("Disconnect", role: .destructive) {
                        oauthService.logout()
                        settings.isAuthenticated = false
                        successMessage = nil
                    }
                } else {
                    Button("Open Pretix Authorization") {
                        oauthService.openAuthorizationPage(
                            clientID: settings.clientID,
                            redirectURI: settings.redirectURI
                        )
                    }
                    .disabled(!settings.isConfigured)

                    TextField("Paste callback URL here", text: $callbackInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        exchangeCode()
                    } label: {
                        HStack {
                            Text("Authenticate")
                            Spacer()
                            if isExchanging { ProgressView() }
                        }
                    }
                    .disabled(callbackInput.isEmpty || !settings.isConfigured || isExchanging)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }

            if let successMessage {
                Section {
                    Text(successMessage)
                        .foregroundStyle(.green)
                        .font(.callout)
                }
            }
        }
        .navigationTitle("Pretix")
        .onAppear {
            settings.isAuthenticated = oauthService.isAuthenticated
        }
    }

    private func exchangeCode() {
        isExchanging = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                try await oauthService.exchangeCode(
                    callbackInput,
                    clientID: settings.clientID,
                    clientSecret: settings.clientSecret,
                    redirectURI: settings.redirectURI
                )
                settings.isAuthenticated = true
                successMessage = "Successfully connected to Pretix."
                callbackInput = ""
            } catch {
                errorMessage = error.localizedDescription
            }
            isExchanging = false
        }
    }
}
