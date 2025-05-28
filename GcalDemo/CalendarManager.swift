import Foundation
import GoogleSignIn
import GoogleAPIClientForREST_Calendar

@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    private let calendarService = GTLRCalendarService()

    private init() {
        // Simple initialization
        print("📅 CalendarManager initialized")
    }

    // MARK: - Simple Fetch Events
    func fetchUpcomingEvents(forUser user: GIDGoogleUser) async throws -> [GTLRCalendar_Event] {
        print("📅 Fetching events for user: \(user.profile?.name ?? "Unknown")")
        
        // Set up the service with the user's authorizer
        calendarService.authorizer = user.fetcherAuthorizer
        
        // Create the query
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.maxResults = 10
        query.timeMin = GTLRDateTime(date: Date())
        query.singleEvents = true
        query.orderBy = kGTLRCalendarOrderByStartTime
        
        // Execute the query
        return try await withCheckedThrowingContinuation { continuation in
            calendarService.executeQuery(query) { (ticket, result, error) in
                if let error = error {
                    print("❌ Error fetching events: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let eventList = result as? GTLRCalendar_Events,
                      let events = eventList.items else {
                    print("✅ No events found")
                    continuation.resume(returning: [])
                    return
                }
                
                print("✅ Successfully fetched \(events.count) events")
                continuation.resume(returning: events)
            }
        }
    }

    // MARK: - Simple Add Event
    func addEvent(title: String, startTime: Date, endTime: Date, forUser user: GIDGoogleUser) async throws -> GTLRCalendar_Event {
        print("📅 Adding event: \(title)")
        
        calendarService.authorizer = user.fetcherAuthorizer

        let newEvent = GTLRCalendar_Event()
        newEvent.summary = title
        
        let startDateTime = GTLRDateTime(date: startTime)
        let endDateTime = GTLRDateTime(date: endTime)
        
        newEvent.start = GTLRCalendar_EventDateTime()
        newEvent.start?.dateTime = startDateTime
        
        newEvent.end = GTLRCalendar_EventDateTime()
        newEvent.end?.dateTime = endDateTime

        let query = GTLRCalendarQuery_EventsInsert.query(withObject: newEvent, calendarId: "primary")

        return try await withCheckedThrowingContinuation { continuation in
            calendarService.executeQuery(query) { (ticket, createdEvent, error) in
                if let error = error {
                    print("❌ Error adding event: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                if let event = createdEvent as? GTLRCalendar_Event {
                    print("✅ Successfully added event: \(event.summary ?? "Untitled Event")")
                    continuation.resume(returning: event)
                } else {
                    continuation.resume(throwing: CalendarError.invalidResponse)
                }
            }
        }
    }

    // MARK: - Simple Update Event
    func updateEvent(originalEventID: String, updatedEvent: GTLRCalendar_Event, forUser user: GIDGoogleUser) async throws -> GTLRCalendar_Event {
        print("📅 Updating event: \(originalEventID)")
        
        calendarService.authorizer = user.fetcherAuthorizer

        let eventToUpdate = updatedEvent.copy() as! GTLRCalendar_Event
        eventToUpdate.identifier = nil

        let query = GTLRCalendarQuery_EventsUpdate.query(withObject: eventToUpdate, calendarId: "primary", eventId: originalEventID)

        return try await withCheckedThrowingContinuation { continuation in
            calendarService.executeQuery(query) { (ticket, event, error) in
                if let error = error {
                    print("❌ Error updating event: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                if let updatedEventResponse = event as? GTLRCalendar_Event {
                    print("✅ Successfully updated event: \(updatedEventResponse.summary ?? "Untitled Event")")
                    continuation.resume(returning: updatedEventResponse)
                } else {
                    continuation.resume(throwing: CalendarError.invalidResponse)
                }
            }
        }
    }

    // MARK: - Simple Delete Event
    func deleteEvent(eventId: String, forUser user: GIDGoogleUser) async throws {
        print("📅 Deleting event: \(eventId)")
        
        calendarService.authorizer = user.fetcherAuthorizer

        let query = GTLRCalendarQuery_EventsDelete.query(withCalendarId: "primary", eventId: eventId)

        return try await withCheckedThrowingContinuation { continuation in
            calendarService.executeQuery(query) { (ticket, nilObject, error) in
                if let error = error {
                    print("❌ Error deleting event: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                print("✅ Successfully deleted event with ID: \(eventId)")
                continuation.resume()
            }
        }
    }
}

// MARK: - Simple Error Handling
enum CalendarError: LocalizedError {
    case invalidResponse
    case authorizationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .authorizationFailed:
            return "Authorization failed"
        }
    }
} 
