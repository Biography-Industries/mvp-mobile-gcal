//
//  CalendarEvent.swift
//  CalendarInviteExtension
//
//  Created by Dezmond Blair
//

import Foundation
import Messages

struct CalendarEvent {
    // MARK: Properties
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var notes: String?
    var eventID: String
    var organizerName: String
    var responses: [String: EventResponse] = [:]
    
    enum EventResponse: String, CaseIterable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
        
        var displayText: String {
            switch self {
            case .pending: return "Pending"
            case .accepted: return "Going"
            case .declined: return "Can't go"
            }
        }
        
        var emoji: String {
            switch self {
            case .pending: return "⏳"
            case .accepted: return "✅"
            case .declined: return "❌"
            }
        }
    }
    
    // MARK: Initialization
    init(title: String, startDate: Date, endDate: Date, location: String? = nil, notes: String? = nil, organizerName: String) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.eventID = UUID().uuidString
        self.organizerName = organizerName
    }
}

// MARK: - URL Query Items Support
extension CalendarEvent {
    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem]()
        
        items.append(URLQueryItem(name: "title", value: title))
        items.append(URLQueryItem(name: "startDate", value: String(startDate.timeIntervalSince1970)))
        items.append(URLQueryItem(name: "endDate", value: String(endDate.timeIntervalSince1970)))
        items.append(URLQueryItem(name: "eventID", value: eventID))
        items.append(URLQueryItem(name: "organizerName", value: organizerName))
        
        if let location = location {
            items.append(URLQueryItem(name: "location", value: location))
        }
        
        if let notes = notes {
            items.append(URLQueryItem(name: "notes", value: notes))
        }
        
        // Encode responses
        for (participantID, response) in responses {
            items.append(URLQueryItem(name: "response_\(participantID)", value: response.rawValue))
        }
        
        return items
    }
    
    init?(queryItems: [URLQueryItem]) {
        var title: String?
        var startDate: Date?
        var endDate: Date?
        var location: String?
        var notes: String?
        var eventID: String?
        var organizerName: String?
        var responses: [String: EventResponse] = [:]
        
        for item in queryItems {
            guard let value = item.value else { continue }
            
            switch item.name {
            case "title":
                title = value
            case "startDate":
                if let timestamp = Double(value) {
                    startDate = Date(timeIntervalSince1970: timestamp)
                }
            case "endDate":
                if let timestamp = Double(value) {
                    endDate = Date(timeIntervalSince1970: timestamp)
                }
            case "location":
                location = value
            case "notes":
                notes = value
            case "eventID":
                eventID = value
            case "organizerName":
                organizerName = value
            default:
                if item.name.hasPrefix("response_") {
                    let participantID = String(item.name.dropFirst(9)) // Remove "response_"
                    if let response = EventResponse(rawValue: value) {
                        responses[participantID] = response
                    }
                }
            }
        }
        
        guard let title = title,
              let startDate = startDate,
              let endDate = endDate,
              let eventID = eventID,
              let organizerName = organizerName else {
            return nil
        }
        
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.eventID = eventID
        self.organizerName = organizerName
        self.responses = responses
    }
}

// MARK: - MSMessage Support
extension CalendarEvent {
    init?(message: MSMessage?) {
        guard let messageURL = message?.url else { return nil }
        guard let urlComponents = URLComponents(url: messageURL, resolvingAgainstBaseURL: false) else { return nil }
        guard let queryItems = urlComponents.queryItems else { return nil }
        self.init(queryItems: queryItems)
    }
    
    mutating func addResponse(participantID: String, response: EventResponse) {
        responses[participantID] = response
    }
}

// MARK: - Equatable
extension CalendarEvent: Equatable {
    static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
        return lhs.eventID == rhs.eventID
    }
}

// MARK: - Formatting Helpers
extension CalendarEvent {
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            
            return "\(dateFormatter.string(from: startDate)) from \(timeFormatter.string(from: startDate)) to \(timeFormatter.string(from: endDate))"
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
    
    var shortDescription: String {
        var description = title
        if let location = location, !location.isEmpty {
            description += " at \(location)"
        }
        return description
    }
} 
