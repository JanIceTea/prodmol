import SwiftUI

struct PretixEventListView: View {
    @Environment(\.dismiss) private var dismiss
    var store: any ProductStoring
    var pretixSettings: any PretixSettingsProviding
    var apiService: any PretixAPIServicing

    @State private var events: [PretixEventResponse] = []
    @State private var isLoading = false
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var importedEventSlug: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading events...")
                } else if events.isEmpty {
                    ContentUnavailableView(
                        "No Upcoming Events",
                        systemImage: "calendar",
                        description: Text(errorMessage ?? "No future events found for this organizer.")
                    )
                } else {
                    List(events) { event in
                        Button {
                            importEvent(event)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.displayName)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                    Text(event.formattedDate)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if isImporting && importedEventSlug == event.slug {
                                    ProgressView()
                                } else if event.live {
                                    Image(systemName: "circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption2)
                                }
                            }
                        }
                        .disabled(isImporting)
                    }
                }
            }
            .navigationTitle("Pretix Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await loadEvents()
            }
        }
    }

    private func loadEvents() async {
        isLoading = true
        errorMessage = nil

        do {
            events = try await apiService.fetchEvents(organizer: pretixSettings.organizerSlug)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func importEvent(_ event: PretixEventResponse) {
        isImporting = true
        importedEventSlug = event.slug

        let eventName = shortenedName(event.displayName)

        Task {
            do {
                let items = try await apiService.fetchItems(
                    organizer: pretixSettings.organizerSlug,
                    eventSlug: event.slug
                )

                // Remove all existing event products (only one event at a time)
                store.deleteAllEventProducts()

                // Add items (and their variations) as products
                for item in items where item.active {
                    if item.hasVariations && !item.variations.isEmpty {
                        for variation in item.variations where variation.active {
                            let name = "\(item.displayName) — \(variation.displayName)"
                            store.add(Product(
                                name: name,
                                price: variation.effectivePrice,
                                eventName: eventName
                            ))
                        }
                    } else {
                        store.add(Product(
                            name: item.displayName,
                            price: item.price,
                            eventName: eventName
                        ))
                    }
                }

                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isImporting = false
            importedEventSlug = nil
        }
    }

    /// Shortens long event names to a reasonable length
    private func shortenedName(_ name: String, maxLength: Int = 40) -> String {
        guard name.count > maxLength else { return name }
        return String(name.prefix(maxLength - 1)) + "…"
    }
}
