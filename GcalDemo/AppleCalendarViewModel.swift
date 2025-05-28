import SwiftUI
import EventKit

struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: LocalizedError
}

@MainActor
class AppleCalendarViewModel: ObservableObject {
    @StateObject private var eventKitManager = EventKitManager()
    @Published var error: IdentifiableError?
    @Published var isInitialized = false

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
        print("AppleCalendarViewModel: Starting initialization...")
        // Delay initialization to avoid blocking the main thread during app startup
        Task {
            await initializeEventKit()
        }
    }
    
    private func initializeEventKit() async {
        do {
            print("AppleCalendarViewModel: Initializing EventKit...")
            
            // Check authorization status first
            let status = eventKitManager.authorizationStatus
            print("AppleCalendarViewModel: Current authorization status: \(status.rawValue)")
            
            if status == .notDetermined {
                print("AppleCalendarViewModel: Authorization not determined, waiting for user action")
                // Don't request access automatically - wait for user to explicitly use calendar features
            } else if await eventKitManager.isFullAccessAuthorized() {
                print("AppleCalendarViewModel: Full access authorized, fetching events...")
                await eventKitManager.fetchUpcomingEvents()
                await eventKitManager.listenForCalendarChanges()
                print("AppleCalendarViewModel: EventKit initialization completed successfully")
            } else {
                print("AppleCalendarViewModel: Limited or no access to calendar")
            }
            
            isInitialized = true
            
        } catch {
            print("AppleCalendarViewModel: Error during initialization: \(error)")
            let genericError = GenericLocalizedError(message: "Failed to initialize calendar: \(error.localizedDescription)")
            self.error = IdentifiableError(error: genericError)
            isInitialized = true // Mark as initialized even with error to prevent hanging
        }
    }

    func requestCalendarAccess() {
        Task {
            do {
                print("AppleCalendarViewModel: Requesting calendar access...")
                try await eventKitManager.requestAccess()
                if await eventKitManager.isFullAccessAuthorized() {
                    await eventKitManager.listenForCalendarChanges()
                    print("AppleCalendarViewModel: Calendar access granted and listening for changes")
                }
            } catch let localizedError as LocalizedError {
                print("AppleCalendarViewModel: Calendar access error: \(localizedError)")
                self.error = IdentifiableError(error: localizedError)
            } catch {
                print("AppleCalendarViewModel: Generic calendar access error: \(error)")
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
        guard isInitialized else {
            print("AppleCalendarViewModel: Cannot create event - not initialized")
            return
        }
        eventKitManager.createNewEvent()
    }
    
    func refreshEvents() {
        guard isInitialized else {
            print("AppleCalendarViewModel: Cannot refresh events - not initialized")
            return
        }
        Task {
            await eventKitManager.fetchUpcomingEvents()
        }
    }

    func deleteAppleEvents(at offsets: IndexSet) {
        guard isInitialized else {
            print("AppleCalendarViewModel: Cannot delete events - not initialized")
            return
        }
        
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
        guard isInitialized else {
            throw GenericLocalizedError(message: "Calendar not initialized")
        }
        
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
        guard isInitialized else {
            throw GenericLocalizedError(message: "Calendar not initialized")
        }
        
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
        guard isInitialized else {
            throw GenericLocalizedError(message: "Calendar not initialized")
        }
        
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