import EventKit
import EventKitUI
import SwiftUI

@MainActor
class EventKitManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published var events: [EKEvent] = []
    @Published var showingEventEditViewController = false
    @Published var selectedEvent: EKEvent?

    func requestAccess() async throws {
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = try await eventStore.requestFullAccessToEvents()
        } else {
            granted = try await eventStore.requestAccess(to: .event)
        }

        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if granted {
            await fetchUpcomingEvents()
        } else {
            // Handle the case where permission was denied or restricted
            if authorizationStatus == .denied {
                throw EventStoreError.denied
            } else if authorizationStatus == .restricted {
                throw EventStoreError.restricted
            }
        }
    }

    func fetchUpcomingEvents() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        let isAuthorizedForFetching: Bool
        if #available(iOS 17.0, *) {
            // On iOS 17+, fullAccess is needed to fetch events. writeOnly is not sufficient.
            isAuthorizedForFetching = (status == .fullAccess)
        } else {
            // On older iOS versions, .authorized was the equivalent of .fullAccess
            isAuthorizedForFetching = (status == .authorized)
        }

        guard isAuthorizedForFetching else {
            print("Access to calendar is not authorized for fetching events.")
            self.events = []
            return
        }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        self.events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    func createNewEvent() {
        let newEvent = EKEvent(eventStore: self.eventStore)
        newEvent.title = "New Event"
        newEvent.startDate = Date()
        newEvent.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        self.selectedEvent = newEvent
        self.showingEventEditViewController = true
    }
    
    func listenForCalendarChanges() async {
        let center = NotificationCenter.default
        let notifications = center.notifications(named: .EKEventStoreChanged).map({ (notification: Notification) in notification.name })
        
        for await _ in notifications {
            if await isFullAccessAuthorized() {
                 await self.fetchUpcomingEvents()
            }
        }
    }

    func removeEvent(event: EKEvent) async throws {
        try eventStore.remove(event, span: .thisEvent, commit: true)
        // Re-fetch to update the UI immediately for single deletions
        await fetchUpcomingEvents()
    }

    func removeEvents(_ eventsToDelete: [EKEvent]) async throws {
        // Batch delete approach - better performance and avoids UI race conditions
        do {
            for event in eventsToDelete {
                try eventStore.remove(event, span: .thisEvent, commit: false)
            }
            try eventStore.commit()
            
            // Only fetch once after all deletions are committed
            await fetchUpcomingEvents()
        } catch {
            // Reset the event store if batch commit fails
            eventStore.reset()
            throw error
        }
    }
    
    func removeEvents(at offsets: IndexSet) async throws {
        let eventsToDelete = offsets.map { events[$0] }
        try await removeEvents(eventsToDelete)
    }

    func isFullAccessAuthorized() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        } else {
            // Fall back on earlier versions.
            return status == .authorized
        }
    }
    
    // MARK: - CRUD Operations for Apple Calendar Events
    
    func addEvent(title: String, startDate: Date, endDate: Date, notes: String) async throws {
        guard await isFullAccessAuthorized() else {
            throw EventStoreError.denied
        }
        
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = title
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        newEvent.notes = notes
        newEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(newEvent, span: .thisEvent, commit: true)
        await fetchUpcomingEvents() // Refresh the events list
    }
    
    func updateEvent(_ event: EKEvent, title: String, startDate: Date, endDate: Date, notes: String) async throws {
        guard await isFullAccessAuthorized() else {
            throw EventStoreError.denied
        }
        
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        
        try eventStore.save(event, span: .thisEvent, commit: true)
        await fetchUpcomingEvents() // Refresh the events list
    }
}

// Define EventStoreError if it's not already globally available
// This is based on the sample code provided
enum EventStoreError: Error, LocalizedError {
    case denied
    case restricted
    case unknown
    case upgrade // Added if you differentiate write-only access, but not used in the manager above for simplicity

    var errorDescription: String? {
        switch self {
        case .denied:
            return NSLocalizedString("The app doesn\'t have permission to Calendar in Settings.", comment: "Access denied")
        case .restricted:
            return NSLocalizedString("This device doesn\'t allow access to Calendar.", comment: "Access restricted")
        case .unknown:
            return NSLocalizedString("An unknown error occurred.", comment: "Unknown error")
        case .upgrade:
            let access = "The app has write-only access to Calendar in Settings."
            let update = "Please grant it full access so the app can fetch and delete your events."
            return NSLocalizedString("\(access) \(update)", comment: "Upgrade to full access")
        }
    }
}

// MARK: - EKEvent Extension for Stable ID
extension EKEvent {
    /// Creates a stable, unique identifier for ForEach operations
    /// Uses the eventIdentifier if available, otherwise falls back to calendarItemIdentifier
    var stableID: String {
        // First try eventIdentifier (most reliable)
        if let eventID = self.eventIdentifier, !eventID.isEmpty {
            return eventID
        }
        
        // Fall back to calendarItemIdentifier
        let calendarItemID = self.calendarItemIdentifier
        if !calendarItemID.isEmpty {
            return calendarItemID
        }
        
        // Last resort: create a unique ID based on memory address
        // This should rarely happen but ensures we always have a unique ID
        return "event-\(String(describing: Unmanaged.passUnretained(self).toOpaque()))"
    }
}

struct EventKitEventEditViewController: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var event: EKEvent?
    let eventStore: EKEventStore

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, EKEventEditViewDelegate {
        var parent: EventKitEventEditViewController

        init(_ parent: EventKitEventEditViewController) {
            self.parent = parent
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            parent.presentationMode.wrappedValue.dismiss()
            // Optionally, refresh events or handle specific actions like .saved, .deleted
            if action == .saved || action == .deleted {
                 Task {
                    await self.parent.eventStore.refreshSourcesIfNecessary()
                    // Consider re-fetching events if needed through a delegate or callback
                 }
            }
        }
    }
} 