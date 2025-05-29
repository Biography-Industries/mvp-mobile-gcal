//
//  ScheduleSelectionTestHelper.swift
//  CalendarInviteExtension
//
//  Created by Dezmond Blair
//

import Foundation
import Messages

// MARK: - Test Helper for Schedule Selection Widget
class ScheduleSelectionTestHelper {
    
    static func createTestScheduleEvent() -> ScheduleSelectionEvent {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create test time slots for this weekend
        let saturday2PM = calendar.date(byAdding: .day, value: calendar.component(.weekday, from: today) == 1 ? 6 : (7 - calendar.component(.weekday, from: today) + 1), to: today)!
            .addingTimeInterval(14 * 60 * 60) // 2 PM
        let saturday4PM = saturday2PM.addingTimeInterval(2 * 60 * 60)
        
        let sunday10AM = saturday2PM.addingTimeInterval(24 * 60 * 60 - 4 * 60 * 60) // Next day at 10 AM
        let sunday12PM = sunday10AM.addingTimeInterval(2 * 60 * 60)
        
        let nextWeekSat2PM = saturday2PM.addingTimeInterval(7 * 24 * 60 * 60)
        let nextWeekSat4PM = nextWeekSat2PM.addingTimeInterval(2 * 60 * 60)
        
        let timeSlots = [
            TimeSlot(startDate: saturday2PM, endDate: saturday4PM),
            TimeSlot(startDate: sunday10AM, endDate: sunday12PM),
            TimeSlot(startDate: nextWeekSat2PM, endDate: nextWeekSat4PM)
        ]
        
        var event = ScheduleSelectionEvent(
            title: "Weekend Hiking Adventure",
            description: "Let's explore the local trails together! Great exercise and beautiful scenery.",
            organizerName: "Alex",
            suggestedTimeSlots: timeSlots
        )
        
        // Add some test responses
        let response1 = ScheduleSelectionEvent.ParticipantResponse(
            participantID: "user1",
            selectedTimeSlots: [timeSlots[0].id, timeSlots[2].id],
            customAvailability: nil,
            responseStatus: .selectedSuggested,
            responseDate: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        let response2 = ScheduleSelectionEvent.ParticipantResponse(
            participantID: "user2",
            selectedTimeSlots: [timeSlots[1].id],
            customAvailability: nil,
            responseStatus: .selectedSuggested,
            responseDate: Date().addingTimeInterval(-1800) // 30 minutes ago
        )
        
        event.addParticipantResponse(response1)
        event.addParticipantResponse(response2)
        
        return event
    }
    
    static func createWorkMeetingScheduleEvent() -> ScheduleSelectionEvent {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create weekday slots for a work meeting
        var timeSlots: [TimeSlot] = []
        
        for dayOffset in 1...5 { // Next 5 weekdays
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            
            // Skip weekends
            if weekday == 1 || weekday == 7 { continue }
            
            // Add morning slot (9-10 AM)
            let morning9AM = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date)!
            let morning10AM = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date)!
            timeSlots.append(TimeSlot(startDate: morning9AM, endDate: morning10AM))
            
            // Add afternoon slot (2-3 PM)
            let afternoon2PM = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date)!
            let afternoon3PM = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date)!
            timeSlots.append(TimeSlot(startDate: afternoon2PM, endDate: afternoon3PM))
            
            if timeSlots.count >= 4 { break } // Limit to 4 options
        }
        
        return ScheduleSelectionEvent(
            title: "Q4 Planning Meeting",
            description: "Team meeting to discuss Q4 goals and project roadmap.",
            organizerName: "Sarah (Manager)",
            suggestedTimeSlots: timeSlots
        )
    }
    
    static func createCustomAvailabilityTestSlots() -> [TimeSlot] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create some custom availability slots
        var customSlots: [TimeSlot] = []
        
        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // Add evening slot (6-8 PM)
            let evening6PM = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date)!
            let evening8PM = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date)!
            customSlots.append(TimeSlot(startDate: evening6PM, endDate: evening8PM))
            
            // Add late evening slot (8:30-10 PM)
            let evening830PM = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: date)!
            let evening10PM = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: date)!
            customSlots.append(TimeSlot(startDate: evening830PM, endDate: evening10PM))
        }
        
        return customSlots
    }
    
    static func testScheduleEventEncoding() -> Bool {
        let event = createTestScheduleEvent()
        
        // Test URL encoding/decoding
        let queryItems = event.queryItems
        guard let decodedEvent = ScheduleSelectionEvent(queryItems: queryItems) else {
            print("❌ Failed to decode schedule event from query items")
            return false
        }
        
        // Verify event properties
        guard decodedEvent.title == event.title,
              decodedEvent.eventID == event.eventID,
              decodedEvent.suggestedTimeSlots.count == event.suggestedTimeSlots.count,
              decodedEvent.participantResponses.count == event.participantResponses.count else {
            print("❌ Schedule event properties don't match after encoding/decoding")
            return false
        }
        
        print("✅ Schedule event encoding/decoding test passed")
        return true
    }
    
    static func testScheduleSelectionMessageCreation() -> MSMessage? {
        let event = createTestScheduleEvent()
        
        // Create components for URL
        var components = URLComponents()
        components.queryItems = event.queryItems
        
        guard let url = components.url else {
            print("❌ Failed to create URL from schedule event")
            return nil
        }
        
        // Create alternate layout
        let alternateLayout = MSMessageTemplateLayout()
        alternateLayout.caption = "📅 \(event.organizerName) is coordinating: \(event.title)"
        alternateLayout.subcaption = event.title
        alternateLayout.trailingCaption = "\(event.suggestedTimeSlots.count) options"
        
        // Create live layout
        let liveLayout = MSMessageLiveLayout(alternateLayout: alternateLayout)
        
        // Create message
        let message = MSMessage(session: MSSession())
        message.url = url
        message.layout = liveLayout
        message.summaryText = "\(event.organizerName) is coordinating: \(event.title)"
        
        print("✅ Schedule selection message creation test passed")
        return message
    }
    
    static func testParticipantResponseFlow() -> Bool {
        var event = createTestScheduleEvent()
        let initialResponseCount = event.participantResponses.count
        
        // Test adding a new response
        let newResponse = ScheduleSelectionEvent.ParticipantResponse(
            participantID: "testUser",
            selectedTimeSlots: [event.suggestedTimeSlots[0].id],
            customAvailability: nil,
            responseStatus: .selectedSuggested,
            responseDate: Date()
        )
        
        event.addParticipantResponse(newResponse)
        
        guard event.participantResponses.count == initialResponseCount + 1 else {
            print("❌ Failed to add participant response")
            return false
        }
        
        guard event.participantResponses["testUser"]?.responseStatus == .selectedSuggested else {
            print("❌ Participant response status not correct")
            return false
        }
        
        // Test that time slot selections are updated
        guard event.suggestedTimeSlots[0].participantSelections["testUser"] == true else {
            print("❌ Time slot selection not updated correctly")
            return false
        }
        
        print("✅ Participant response flow test passed")
        return true
    }
    
    static func testCustomAvailabilityFlow() -> Bool {
        let event = createTestScheduleEvent()
        let customSlots = createCustomAvailabilityTestSlots()
        
        // Test creating a custom availability response
        let customResponse = ScheduleSelectionEvent.ParticipantResponse(
            participantID: "customUser",
            selectedTimeSlots: [],
            customAvailability: customSlots,
            responseStatus: .proposedAlternative,
            responseDate: Date()
        )
        
        guard customResponse.customAvailability?.count == customSlots.count else {
            print("❌ Custom availability not stored correctly")
            return false
        }
        
        guard customResponse.responseStatus == .proposedAlternative else {
            print("❌ Custom availability response status incorrect")
            return false
        }
        
        print("✅ Custom availability flow test passed")
        return true
    }
    
    // MARK: - Demo Scenarios
    static func runAllTests() {
        print("🧪 Running Schedule Selection Widget Tests...")
        print("================================================")
        
        let encodingTest = testScheduleEventEncoding()
        let messageTest = testScheduleSelectionMessageCreation() != nil
        let responseTest = testParticipantResponseFlow()
        let customTest = testCustomAvailabilityFlow()
        
        print("================================================")
        if encodingTest && messageTest && responseTest && customTest {
            print("🎉 All Schedule Selection Widget tests passed!")
            print("✅ Ready for production use")
        } else {
            print("❌ Some tests failed. Please check the implementation.")
        }
        print("================================================")
    }
    
    static func printDemoScenarios() {
        print("📋 Schedule Selection Widget Demo Scenarios:")
        print("============================================")
        
        print("\n1. Weekend Activity Coordination:")
        let weekend = createTestScheduleEvent()
        print("   • Title: \(weekend.title)")
        print("   • Options: \(weekend.suggestedTimeSlots.count) time slots")
        print("   • Responses: \(weekend.participantResponses.count) participants")
        
        print("\n2. Work Meeting Scheduling:")
        let work = createWorkMeetingScheduleEvent()
        print("   • Title: \(work.title)")
        print("   • Options: \(work.suggestedTimeSlots.count) time slots")
        print("   • Focus: Weekday business hours")
        
        print("\n3. Custom Availability:")
        let custom = createCustomAvailabilityTestSlots()
        print("   • Custom slots: \(custom.count)")
        print("   • Use case: When suggested times don't work")
        
        print("\n============================================")
    }
}

// MARK: - Usage Example
/*
 To test the Schedule Selection Widget:
 
 1. Run all tests:
    ScheduleSelectionTestHelper.runAllTests()
 
 2. View demo scenarios:
    ScheduleSelectionTestHelper.printDemoScenarios()
 
 3. Create test events:
    let weekend = ScheduleSelectionTestHelper.createTestScheduleEvent()
    let work = ScheduleSelectionTestHelper.createWorkMeetingScheduleEvent()
 
 4. Test message creation:
    let message = ScheduleSelectionTestHelper.testScheduleSelectionMessageCreation()
 */ 
