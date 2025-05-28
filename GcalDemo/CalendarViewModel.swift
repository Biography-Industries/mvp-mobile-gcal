import Foundation
import SwiftUI // For @Published
import GoogleSignIn // For GIDGoogleUser
import GoogleAPIClientForREST_Calendar // For GTLRCalendar_Event

class CalendarViewModel: ObservableObject {
    @Published var events: [GTLRCalendar_Event] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var calendarManager = CalendarManager.shared

    // Called when authentication state changes (e.g., user logs in)
    func fetchEvents(forUser user: GIDGoogleUser?) {
        guard let currentUser = user else {
            // If user is nil (logged out), clear events
            DispatchQueue.main.async {
                self.events = []
                self.errorMessage = nil
                self.isLoading = false
            }
            return
        }

        isLoading = true
        errorMessage = nil

        calendarManager.fetchUpcomingEvents(forUser: currentUser) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let fetchedEvents):
                    self?.events = fetchedEvents
                    print("CalendarViewModel: Fetched \(fetchedEvents.count) events.")
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch events: \(error.localizedDescription)"
                    print("CalendarViewModel: Error fetching events: \(error.localizedDescription)")
                }
            }
        }
    }

    func addEvent(title: String, startTime: Date, endTime: Date, forUser user: GIDGoogleUser?, completion: @escaping (Bool) -> Void) {
        guard let currentUser = user else {
            errorMessage = "User not signed in. Cannot add event."
            isLoading = false
            completion(false)
            return
        }
        
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Event title cannot be empty."
            completion(false)
            return
        }
        
        guard endTime > startTime else {
            errorMessage = "End time must be after start time."
            completion(false)
            return
        }

        isLoading = true
        errorMessage = nil

        calendarManager.addEvent(title: title, startTime: startTime, endTime: endTime, forUser: currentUser) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success( _):
                    print("CalendarViewModel: Successfully added event '\(title)'")
                    // Re-fetch events to update the list
                    self?.fetchEvents(forUser: currentUser)
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = "Failed to add event: \(error.localizedDescription)"
                    print("CalendarViewModel: Error adding event: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    func clearErrorMessage() {
        self.errorMessage = nil
    }

    func updateEvent(originalEventID: String, updatedEventData: GTLRCalendar_Event, forUser user: GIDGoogleUser?, completion: @escaping (Bool) -> Void) {
        guard let currentUser = user else {
            errorMessage = "User not signed in. Cannot update event."
            completion(false)
            return
        }
        
        guard !updatedEventData.summary!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Event title cannot be empty for update."
            completion(false)
            return
        }
        
        // Add other validation as needed (e.g., end time > start time)
        if let start = updatedEventData.start?.dateTime?.date, let end = updatedEventData.end?.dateTime?.date, end <= start {
            errorMessage = "End time must be after start time for update."
            completion(false)
            return
        }

        isLoading = true
        errorMessage = nil

        calendarManager.updateEvent(originalEventID: originalEventID, updatedEvent: updatedEventData, forUser: currentUser) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let event):
                    print("CalendarViewModel: Successfully updated event '\(event.summary ?? "")'")
                    // Option 1: More robust - Re-fetch all events
                    self?.fetchEvents(forUser: currentUser)
                    // Option 2: More performant for UI - Find and update in local list
                    // if let index = self?.events.firstIndex(where: { $0.identifier == originalEventID }) {
                    //     self?.events[index] = event
                    // }
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = "Failed to update event: \(error.localizedDescription)"
                    print("CalendarViewModel: Error updating event: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }

    func deleteEvent(eventId: String, forUser user: GIDGoogleUser?, completion: @escaping (Bool) -> Void) {
        guard let currentUser = user else {
            errorMessage = "User not signed in. Cannot delete event."
            completion(false)
            return
        }

        isLoading = true
        errorMessage = nil

        calendarManager.deleteEvent(eventId: eventId, forUser: currentUser) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    print("CalendarViewModel: Successfully deleted event with ID \(eventId)")
                    self?.events.removeAll { $0.identifier == eventId }
                    completion(true)
                case .failure(let error):
                    self?.errorMessage = "Failed to delete event: \(error.localizedDescription)"
                    print("CalendarViewModel: Error deleting event: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
}

// Helper extension for GTLRDateTime to Date conversion
extension GTLRDateTime {
    var date: Date? {
        let rfc3339DateFormatter = DateFormatter()
        rfc3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = rfc3339DateFormatter.date(from: self.rfc3339String) {
            return date
        }
        
        // Handle all-day events (date only)
        rfc3339DateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = rfc3339DateFormatter.date(from: self.rfc3339String) {
            return date
        }
        return nil
    }
} 
