//
//  ScheduleSelectionEvent.swift
//  CalendarInviteExtension
//
//  Created by Dezmond Blair
//

import Foundation
import Messages

struct TimeSlot: Codable, Identifiable, Equatable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    var participantSelections: [String: Bool] = [:] // participantID -> selected
    
    init(startDate: Date, endDate: Date, participantSelections: [String: Bool] = [:]) {
        self.startDate = startDate
        self.endDate = endDate
        self.participantSelections = participantSelections
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            
            return "\(dateFormatter.string(from: startDate)) \(timeFormatter.string(from: startDate))-\(timeFormatter.string(from: endDate))"
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
    
    var selectionCount: Int {
        return participantSelections.values.filter { $0 }.count
    }
    
    static func == (lhs: TimeSlot, rhs: TimeSlot) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ScheduleSelectionEvent: Codable {
    let eventID: String
    let title: String
    let description: String?
    let organizerName: String
    var suggestedTimeSlots: [TimeSlot]
    var participantResponses: [String: ParticipantResponse] = [:]
    let createdDate: Date
    
    struct ParticipantResponse: Codable {
        let participantID: String
        let selectedTimeSlots: [UUID] // IDs of selected time slots
        let customAvailability: [TimeSlot]? // Custom availability if none of the suggested work
        let responseStatus: ResponseStatus
        let responseDate: Date
        
        enum ResponseStatus: String, Codable {
            case pending = "pending"
            case selectedSuggested = "selected_suggested"
            case proposedAlternative = "proposed_alternative"
            case noneWork = "none_work"
        }
    }
    
    init(title: String, description: String? = nil, organizerName: String, suggestedTimeSlots: [TimeSlot]) {
        self.eventID = UUID().uuidString
        self.title = title
        self.description = description
        self.organizerName = organizerName
        self.suggestedTimeSlots = suggestedTimeSlots
        self.createdDate = Date()
    }
    
    mutating func addParticipantResponse(_ response: ParticipantResponse) {
        participantResponses[response.participantID] = response
        
        // Update time slot selections
        for (index, _) in suggestedTimeSlots.enumerated() {
            let isSelected = response.selectedTimeSlots.contains(suggestedTimeSlots[index].id)
            suggestedTimeSlots[index].participantSelections[response.participantID] = isSelected
        }
    }
    
    func getTopTimeSlots(limit: Int = 3) -> [TimeSlot] {
        return suggestedTimeSlots
            .sorted { $0.selectionCount > $1.selectionCount }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - URL Query Items Support
extension ScheduleSelectionEvent {
    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem]()
        
        items.append(URLQueryItem(name: "eventID", value: eventID))
        items.append(URLQueryItem(name: "title", value: title))
        items.append(URLQueryItem(name: "organizerName", value: organizerName))
        items.append(URLQueryItem(name: "createdDate", value: String(createdDate.timeIntervalSince1970)))
        
        if let description = description {
            items.append(URLQueryItem(name: "description", value: description))
        }
        
        // Encode suggested time slots
        for (index, timeSlot) in suggestedTimeSlots.enumerated() {
            let prefix = "slot_\(index)"
            items.append(URLQueryItem(name: "\(prefix)_id", value: timeSlot.id.uuidString))
            items.append(URLQueryItem(name: "\(prefix)_start", value: String(timeSlot.startDate.timeIntervalSince1970)))
            items.append(URLQueryItem(name: "\(prefix)_end", value: String(timeSlot.endDate.timeIntervalSince1970)))
            
            // Encode participant selections for this slot
            for (participantID, selected) in timeSlot.participantSelections {
                items.append(URLQueryItem(name: "\(prefix)_participant_\(participantID)", value: String(selected)))
            }
        }
        
        // Encode participant responses
        for (participantID, response) in participantResponses {
            let prefix = "response_\(participantID)"
            items.append(URLQueryItem(name: "\(prefix)_status", value: response.responseStatus.rawValue))
            items.append(URLQueryItem(name: "\(prefix)_date", value: String(response.responseDate.timeIntervalSince1970)))
            
            // Encode selected time slot IDs
            for (index, slotID) in response.selectedTimeSlots.enumerated() {
                items.append(URLQueryItem(name: "\(prefix)_selected_\(index)", value: slotID.uuidString))
            }
        }
        
        return items
    }
    
    init?(queryItems: [URLQueryItem]) {
        var eventID: String?
        var title: String?
        var description: String?
        var organizerName: String?
        var createdDate: Date?
        var timeSlots: [Int: TimeSlot] = [:]
        var responses: [String: ParticipantResponse] = [:]
        
        for item in queryItems {
            guard let value = item.value else { continue }
            
            switch item.name {
            case "eventID":
                eventID = value
            case "title":
                title = value
            case "description":
                description = value
            case "organizerName":
                organizerName = value
            case "createdDate":
                if let timestamp = Double(value) {
                    createdDate = Date(timeIntervalSince1970: timestamp)
                }
            default:
                if item.name.hasPrefix("slot_") {
                    let components = item.name.components(separatedBy: "_")
                    if components.count >= 3,
                       let slotIndex = Int(components[1]) {
                        
                        switch components[2] {
                        case "id":
                            // Skip ID processing for now, we'll handle it when creating the final TimeSlot
                            break
                        case "start":
                            if let timestamp = Double(value) {
                                let startDate = Date(timeIntervalSince1970: timestamp)
                                if let existingSlot = timeSlots[slotIndex] {
                                    timeSlots[slotIndex] = TimeSlot(
                                        startDate: startDate,
                                        endDate: existingSlot.endDate,
                                        participantSelections: existingSlot.participantSelections
                                    )
                                } else {
                                    timeSlots[slotIndex] = TimeSlot(
                                        startDate: startDate,
                                        endDate: Date(),
                                        participantSelections: [:]
                                    )
                                }
                            }
                        case "end":
                            if let timestamp = Double(value) {
                                let endDate = Date(timeIntervalSince1970: timestamp)
                                if let existingSlot = timeSlots[slotIndex] {
                                    timeSlots[slotIndex] = TimeSlot(
                                        startDate: existingSlot.startDate,
                                        endDate: endDate,
                                        participantSelections: existingSlot.participantSelections
                                    )
                                } else {
                                    timeSlots[slotIndex] = TimeSlot(
                                        startDate: Date(),
                                        endDate: endDate,
                                        participantSelections: [:]
                                    )
                                }
                            }
                        case "participant":
                            if components.count >= 4,
                               let selected = Bool(value) {
                                let participantID = components[3]
                                if let existingSlot = timeSlots[slotIndex] {
                                    var updatedSelections = existingSlot.participantSelections
                                    updatedSelections[participantID] = selected
                                    timeSlots[slotIndex] = TimeSlot(
                                        startDate: existingSlot.startDate,
                                        endDate: existingSlot.endDate,
                                        participantSelections: updatedSelections
                                    )
                                } else {
                                    timeSlots[slotIndex] = TimeSlot(
                                        startDate: Date(),
                                        endDate: Date(),
                                        participantSelections: [participantID: selected]
                                    )
                                }
                            }
                        default:
                            break
                        }
                    }
                }
            }
        }
        
        guard let eventID = eventID,
              let title = title,
              let organizerName = organizerName,
              let createdDate = createdDate else {
            return nil
        }
        
        self.eventID = eventID
        self.title = title
        self.description = description
        self.organizerName = organizerName
        self.suggestedTimeSlots = timeSlots.keys.sorted().compactMap { timeSlots[$0] }
        self.participantResponses = responses
        self.createdDate = createdDate
    }
}

// MARK: - MSMessage Support
extension ScheduleSelectionEvent {
    init?(message: MSMessage?) {
        guard let messageURL = message?.url else { return nil }
        guard let urlComponents = URLComponents(url: messageURL, resolvingAgainstBaseURL: false) else { return nil }
        guard let queryItems = urlComponents.queryItems else { return nil }
        self.init(queryItems: queryItems)
    }
} 
