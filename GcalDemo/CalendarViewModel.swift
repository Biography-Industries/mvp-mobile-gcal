import Foundation
import UIKit
import SwiftUI // For @Published
import GoogleSignIn // For GIDGoogleUser
import GoogleAPIClientForREST_Calendar // For GTLRCalendar_Event

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [GTLRCalendar_Event] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var calendarManager = CalendarManager.shared
    private var fetchTask: Task<Void, Never>?

    // MARK: - Modern Async Fetch Events
    func fetchEvents(forUser user: GIDGoogleUser?) {
        guard let currentUser = user else {
            // If user is nil (logged out), clear events
            events = []
            errorMessage = nil
            isLoading = false
            return
        }

        // Cancel any existing fetch task
        fetchTask?.cancel()
        
        isLoading = true
        errorMessage = nil
        
        fetchTask = Task {
            do {
                let fetchedEvents = try await calendarManager.fetchUpcomingEvents(forUser: currentUser)
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                // Update UI on main actor
                self.events = fetchedEvents
                self.errorMessage = nil
                self.isLoading = false
                print("CalendarViewModel: Fetched \(fetchedEvents.count) events.")
                
            } catch {
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                // Handle errors on main actor with device-specific messaging
                self.isLoading = false
                
                // Provide more helpful error messages for iPhone 16 Pro users
                Task { @MainActor in
                    let deviceName = UIDevice.current.name
                    if deviceName.lowercased().contains("iphone 16") && error.localizedDescription.contains("abort") {
                        self.errorMessage = "iPhone 16 Pro authorization issue detected. Please try signing out and signing back in."
                    } else {
                        self.errorMessage = "Failed to fetch events: \(error.localizedDescription)"
                    }
                    
                    print("CalendarViewModel: Error fetching events: \(error.localizedDescription)")
                    print("CalendarViewModel: Device: \(deviceName)")
                }
                
                self.events = []
            }
        }
    }

    // MARK: - Modern Async Add Event
    func addEvent(title: String, startTime: Date, endTime: Date, forUser user: GIDGoogleUser?) async -> Bool {
        guard let currentUser = user else {
            errorMessage = "User not signed in. Cannot add event."
            return false
        }
        
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Event title cannot be empty."
            return false
        }
        
        guard endTime > startTime else {
            errorMessage = "End time must be after start time."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let _ = try await calendarManager.addEvent(title: title, startTime: startTime, endTime: endTime, forUser: currentUser)
            print("CalendarViewModel: Successfully added event '\(title)'")
            
            // Re-fetch events to update the list
            fetchEvents(forUser: currentUser)
            return true
            
        } catch {
            isLoading = false
            errorMessage = "Failed to add event: \(error.localizedDescription)"
            print("CalendarViewModel: Error adding event: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Backward Compatibility for Add Event
    func addEvent(title: String, startTime: Date, endTime: Date, forUser user: GIDGoogleUser?, completion: @escaping (Bool) -> Void) {
        Task {
            let success = await addEvent(title: title, startTime: startTime, endTime: endTime, forUser: user)
            completion(success)
        }
    }
    
    func clearErrorMessage() {
        self.errorMessage = nil
    }

    // MARK: - Modern Async Update Event
    func updateEvent(originalEventID: String, updatedEventData: GTLRCalendar_Event, forUser user: GIDGoogleUser?) async -> Bool {
        guard let currentUser = user else {
            errorMessage = "User not signed in. Cannot update event."
            return false
        }
        
        guard let summary = updatedEventData.summary,
              !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Event title cannot be empty for update."
            return false
        }
        
        // Add other validation as needed (e.g., end time > start time)
        if let start = safeGetEventDate(from: updatedEventData.start), 
           let end = safeGetEventDate(from: updatedEventData.end), 
           end <= start {
            errorMessage = "End time must be after start time for update."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let _ = try await calendarManager.updateEvent(originalEventID: originalEventID, updatedEvent: updatedEventData, forUser: currentUser)
            print("CalendarViewModel: Successfully updated event '\(summary)'")
            
            // Re-fetch all events to ensure consistency
            fetchEvents(forUser: currentUser)
            return true
            
        } catch {
            isLoading = false
            errorMessage = "Failed to update event: \(error.localizedDescription)"
            print("CalendarViewModel: Error updating event: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Backward Compatibility for Update Event
    func updateEvent(originalEventID: String, updatedEventData: GTLRCalendar_Event, forUser user: GIDGoogleUser?, completion: @escaping (Bool) -> Void) {
        Task {
            let success = await updateEvent(originalEventID: originalEventID, updatedEventData: updatedEventData, forUser: user)
            completion(success)
        }
    }

    // MARK: - Safe Date Extraction Helper
    private func safeGetEventDate(from eventDateTime: GTLRCalendar_EventDateTime?) -> Date? {
        guard let eventDateTime = eventDateTime else { return nil }
        
        // Try dateTime first (for timed events)
        if let dateTime = eventDateTime.dateTime {
            return dateTime.date
        }
        
        // Fall back to date (for all-day events)
        if let date = eventDateTime.date {
            return date.date
        }
        
        return nil
    }

    // MARK: - Modern Async Delete Event
    func deleteEvent(eventId: String, forUser user: GIDGoogleUser?) async -> Bool {
        guard let currentUser = user else {
            errorMessage = "User not signed in. Cannot delete event."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            try await calendarManager.deleteEvent(eventId: eventId, forUser: currentUser)
            print("CalendarViewModel: Successfully deleted event with ID \(eventId)")
            
            // Remove from local array immediately for better UX
            events.removeAll { $0.identifier == eventId }
            isLoading = false
            return true
            
        } catch {
            isLoading = false
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
            print("CalendarViewModel: Error deleting event: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Backward Compatibility for Delete Event
    func deleteEvent(eventId: String, forUser user: GIDGoogleUser?, completion: @escaping (Bool) -> Void) {
        Task {
            let success = await deleteEvent(eventId: eventId, forUser: user)
            completion(success)
        }
    }
    
    // MARK: - Cleanup
    deinit {
        fetchTask?.cancel()
    }
} 
