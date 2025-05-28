import SwiftUI
import EventKit

struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: LocalizedError
}

@MainActor
class AppleCalendarViewModel: ObservableObject {
    @ObservedObject var eventKitManager = EventKitManager()
    @Published var error: IdentifiableError? // Changed to IdentifiableError?

    var events: [EKEvent] {
        eventKitManager.events
    }

    var authorizationStatus: EKAuthorizationStatus {
        eventKitManager.authorizationStatus
    }

    var showingEventEditViewController: Binding<Bool> {
        $eventKitManager.showingEventEditViewController
    }

    var selectedEvent: Binding<EKEvent?> {
        $eventKitManager.selectedEvent
    }

    var eventStore: EKEventStore {
        eventKitManager.eventStore
    }

    init() {
        // Initial check for authorization status
        Task {
            if eventKitManager.authorizationStatus == .notDetermined {
                // You might want to delay requesting access until the user explicitly tries to use Apple Calendar features
            } else if await eventKitManager.isFullAccessAuthorized() {
                await eventKitManager.fetchUpcomingEvents()
                await eventKitManager.listenForCalendarChanges() 
            }
        }
    }

    func requestCalendarAccess() {
        Task {
            do {
                try await eventKitManager.requestAccess()
                if await eventKitManager.isFullAccessAuthorized() {
                    await eventKitManager.listenForCalendarChanges()
                }
            } catch let localizedError as LocalizedError {
                self.error = IdentifiableError(error: localizedError)
            } catch {
                struct GenericLocalizedError: LocalizedError {
                    var errorDescription: String?
                    init(message: String) {
                        self.errorDescription = message
                    }
                }
                self.error = IdentifiableError(error: GenericLocalizedError(message: error.localizedDescription))
            }
        }
    }

    func createNewEvent() {
        eventKitManager.createNewEvent()
    }
    
    func refreshEvents() {
        Task {
            await eventKitManager.fetchUpcomingEvents()
        }
    }

    func deleteAppleEvents(at offsets: IndexSet) {
        Task {
            do {
                // Get the events to delete BEFORE any UI changes
                let eventsToDelete = offsets.map { eventKitManager.events[$0] }
                
                // Use the batch deletion method to avoid multiple UI updates
                try await eventKitManager.removeEvents(eventsToDelete)
                
                // The EventKitManager already re-fetches events once after batch deletion
            } catch let localizedError as LocalizedError {
                self.error = IdentifiableError(error: localizedError)
            } catch {
                struct GenericLocalizedError: LocalizedError {
                    var errorDescription: String?
                    init(message: String) { self.errorDescription = message }
                }
                self.error = IdentifiableError(error: GenericLocalizedError(message: error.localizedDescription))
            }
        }
    }
    
    // MARK: - CRUD Operations for Apple Calendar Events
    
    func addAppleEvent(title: String, startDate: Date, endDate: Date, notes: String) async throws {
        do {
            try await eventKitManager.addEvent(title: title, startDate: startDate, endDate: endDate, notes: notes)
        } catch let localizedError as LocalizedError {
            self.error = IdentifiableError(error: localizedError)
            throw localizedError
        } catch {
            let genericError = GenericLocalizedError(message: error.localizedDescription)
            self.error = IdentifiableError(error: genericError)
            throw genericError
        }
    }
    
    func updateAppleEvent(_ event: EKEvent, title: String, startDate: Date, endDate: Date, notes: String) async throws {
        do {
            try await eventKitManager.updateEvent(event, title: title, startDate: startDate, endDate: endDate, notes: notes)
        } catch let localizedError as LocalizedError {
            self.error = IdentifiableError(error: localizedError)
            throw localizedError
        } catch {
            let genericError = GenericLocalizedError(message: error.localizedDescription)
            self.error = IdentifiableError(error: genericError)
            throw genericError
        }
    }
    
    func deleteAppleEvent(_ event: EKEvent) async throws {
        do {
            try await eventKitManager.removeEvent(event: event)
        } catch let localizedError as LocalizedError {
            self.error = IdentifiableError(error: localizedError)
            throw localizedError
        } catch {
            let genericError = GenericLocalizedError(message: error.localizedDescription)
            self.error = IdentifiableError(error: genericError)
            throw genericError
        }
    }
}

// Helper struct for generic errors
private struct GenericLocalizedError: LocalizedError {
    var errorDescription: String?
    init(message: String) { self.errorDescription = message }
} 