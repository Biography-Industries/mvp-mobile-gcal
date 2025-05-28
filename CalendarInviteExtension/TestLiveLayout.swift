//
//  TestLiveLayout.swift
//  CalendarInviteExtension
//
//  Created by Calendar Invite Extension
//

import Foundation
import Messages

// MARK: - Test Helper for Live Layout Implementation
class LiveLayoutTestHelper {
    
    static func createTestEvent() -> CalendarEvent {
        let startDate = Date().addingTimeInterval(3600) // 1 hour from now
        let endDate = startDate.addingTimeInterval(3600) // 2 hours from now
        
        var event = CalendarEvent(
            title: "Team Meeting",
            startDate: startDate,
            endDate: endDate,
            location: "Conference Room A",
            notes: "Quarterly planning discussion",
            organizerName: "John Doe"
        )
        
        // Add some test responses
        event.addResponse(participantID: "user1", response: .accepted)
        event.addResponse(participantID: "user2", response: .declined)
        event.addResponse(participantID: "user3", response: .pending)
        
        return event
    }
    
    static func testLiveLayoutCreation() -> Bool {
        let event = createTestEvent()
        
        // Test URL encoding/decoding
        let queryItems = event.queryItems
        guard let decodedEvent = CalendarEvent(queryItems: queryItems) else {
            print("❌ Failed to decode event from query items")
            return false
        }
        
        // Verify event properties
        guard decodedEvent.title == event.title,
              decodedEvent.eventID == event.eventID,
              decodedEvent.responses.count == event.responses.count else {
            print("❌ Event properties don't match after encoding/decoding")
            return false
        }
        
        print("✅ Live layout test passed - Event encoding/decoding works correctly")
        return true
    }
    
    static func testMessageCreation() -> MSMessage? {
        let event = createTestEvent()
        
        // Create components for URL
        var components = URLComponents()
        components.queryItems = event.queryItems
        
        guard let url = components.url else {
            print("❌ Failed to create URL from event")
            return nil
        }
        
        // Create alternate layout
        let alternateLayout = MSMessageTemplateLayout()
        alternateLayout.caption = "📅 \(event.organizerName) invited you to \(event.title)"
        alternateLayout.subcaption = event.formattedDateRange
        alternateLayout.trailingCaption = event.location
        
        // Create live layout
        let liveLayout = MSMessageLiveLayout(alternateLayout: alternateLayout)
        
        // Create message
        let message = MSMessage(session: MSSession())
        message.url = url
        message.layout = liveLayout
        message.summaryText = "\(event.organizerName) invited you to \(event.title)"
        
        print("✅ Message creation test passed - MSMessageLiveLayout created successfully")
        return message
    }
    
    static func runAllTests() {
        print("🧪 Running Live Layout Tests...")
        
        let eventTest = testLiveLayoutCreation()
        let messageTest = testMessageCreation() != nil
        
        if eventTest && messageTest {
            print("🎉 All tests passed! Live layout implementation is ready.")
        } else {
            print("❌ Some tests failed. Please check the implementation.")
        }
    }
}

// MARK: - Usage Example
/*
 To test the live layout implementation:
 
 1. In your MessagesViewController or any test context, call:
    LiveLayoutTestHelper.runAllTests()
 
 2. To create a test event for UI testing:
    let testEvent = LiveLayoutTestHelper.createTestEvent()
 
 3. To test message creation:
    let testMessage = LiveLayoutTestHelper.testMessageCreation()
 */ 