import Foundation
import GoogleSignIn
import GoogleAPIClientForREST_Calendar // Or GTLRCalendar

class CalendarManager {
    static let shared = CalendarManager()
    private let calendarService = GTLRCalendarService()

    private init() {
        // Optional: Configure service parameters if needed, e.g., for API key (not for OAuth2 user data)
        // calendarService.apiKey = "YOUR_API_KEY_IF_NEEDED_FOR_PUBLIC_CALENDARS"
    }

    // MARK: - Fetch Events
    func fetchUpcomingEvents(forUser user: GIDGoogleUser, completion: @escaping (Result<[GTLRCalendar_Event], Error>) -> Void) {
        GoogleSignInManager.shared.getAuthorizer(forUser: user) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let authorizer):
                self.calendarService.authorizer = authorizer
                
                let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
                query.maxResults = 10
                query.timeMin = GTLRDateTime(date: Date())
                query.orderBy = kGTLRCalendarOrderByStartTime
                query.singleEvents = true // Expand recurring events into single instances

                self.calendarService.executeQuery(query) { (ticket, response, error) in
                    // **DEBUGGING: Print the raw response or its JSON representation**
                    if let responseObject = response as? GTLRObject {
                        print("DEBUG: Raw GTLRObject JSON: \(responseObject.json ?? [:])")
                    } else if let response = response {
                        print("DEBUG: Raw response (not GTLRObject): \(response)")
                    }
                    if let error = error {
                        print("DEBUG: Error before processing: \(error.localizedDescription)")
                    }
                    // **END DEBUGGING**

                    if let error = error {
                        print("Error fetching events: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }

                    if let eventsList = response as? GTLRCalendar_Events,
                       let events = eventsList.items {
                        print("Successfully fetched \(events.count) events.")
                        completion(.success(events))
                    } else {
                        print("No events found or response format incorrect.")
                        completion(.success([])) // Or an error indicating no data
                    }
                }
                
            case .failure(let error):
                print("Failed to get authorizer: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Add Event
    func addEvent(title: String, startTime: Date, endTime: Date, forUser user: GIDGoogleUser, completion: @escaping (Result<GTLRCalendar_Event, Error>) -> Void) {
        GoogleSignInManager.shared.getAuthorizer(forUser: user) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let authorizer):
                self.calendarService.authorizer = authorizer

                let newEvent = GTLRCalendar_Event()
                newEvent.summary = title
                
                let startDateTime = GTLRDateTime(date: startTime)
                let endDateTime = GTLRDateTime(date: endTime)
                
                newEvent.start = GTLRCalendar_EventDateTime()
                newEvent.start?.dateTime = startDateTime
                // newEvent.start?.timeZone = TimeZone.current.identifier // Optional: specify timezone
                
                newEvent.end = GTLRCalendar_EventDateTime()
                newEvent.end?.dateTime = endDateTime
                // newEvent.end?.timeZone = TimeZone.current.identifier // Optional: specify timezone

                let query = GTLRCalendarQuery_EventsInsert.query(withObject: newEvent, calendarId: "primary")

                self.calendarService.executeQuery(query) { (ticket, createdEvent, error) in
                    if let error = error {
                        print("Error adding event: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }

                    if let event = createdEvent as? GTLRCalendar_Event {
                        print("Successfully added event: \(event.summary ?? "Untitled Event")")
                        completion(.success(event))
                    } else {
                        completion(.failure(NSError(domain: "CalendarManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create event or response was not an event."])))
                    }
                }
            case .failure(let error):
                print("Failed to get authorizer for adding event: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Update Event
    func updateEvent(originalEventID: String, updatedEvent: GTLRCalendar_Event, forUser user: GIDGoogleUser, completion: @escaping (Result<GTLRCalendar_Event, Error>) -> Void) {
        GoogleSignInManager.shared.getAuthorizer(forUser: user) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let authorizer):
                self.calendarService.authorizer = authorizer

                // Ensure the updatedEvent object does not have an ID set, as the query takes the ID.
                // The Google API uses the ID in the query parameters for identifying the event to update.
                // Sending an ID in the body can sometimes cause issues or is ignored.
                let eventToUpdate = updatedEvent.copy() as! GTLRCalendar_Event
                eventToUpdate.identifier = nil // Clear identifier from the body if present

                let query = GTLRCalendarQuery_EventsUpdate.query(withObject: eventToUpdate, calendarId: "primary", eventId: originalEventID)

                self.calendarService.executeQuery(query) { (ticket, event, error) in
                    if let error = error {
                        print("Error updating event: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    if let updatedEventResponse = event as? GTLRCalendar_Event {
                        print("Successfully updated event: \(updatedEventResponse.summary ?? "Untitled Event")")
                        completion(.success(updatedEventResponse))
                    } else {
                        completion(.failure(NSError(domain: "CalendarManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to update event or response was not an event."])))
                    }
                }
            case .failure(let error):
                print("Failed to get authorizer for updating event: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Delete Event
    func deleteEvent(eventId: String, forUser user: GIDGoogleUser, completion: @escaping (Result<Void, Error>) -> Void) {
        GoogleSignInManager.shared.getAuthorizer(forUser: user) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let authorizer):
                self.calendarService.authorizer = authorizer

                let query = GTLRCalendarQuery_EventsDelete.query(withCalendarId: "primary", eventId: eventId)

                self.calendarService.executeQuery(query) { (ticket, nilObject, error) in // response object is usually nil for delete
                    if let error = error {
                        print("Error deleting event: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    // Successful deletion typically returns a 204 No Content, so nilObject is expected.
                    print("Successfully deleted event with ID: \(eventId)")
                    completion(.success(()))
                }
            case .failure(let error):
                print("Failed to get authorizer for deleting event: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
} 
