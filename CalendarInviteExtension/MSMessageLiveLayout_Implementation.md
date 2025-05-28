# MSMessageLiveLayout Implementation for Calendar Invites

## Overview

This implementation adds **MSMessageLiveLayout** support to the calendar invite iMessage extension, enabling recipients to respond to event invitations directly from the message bubble without opening the extension.

## Key Features

### ✅ Live Interactive Responses
- Recipients can tap "Yes" or "No" directly in the message bubble
- Responses update immediately without reopening the extension
- Real-time UI updates show current response status

### ✅ Direct Send Integration
- Uses `conversation.send()` for immediate message updates
- Proper spam protection through user-initiated actions
- Maintains message session for proper threading

### ✅ Fallback Support
- Includes `MSMessageTemplateLayout` as alternate layout
- Graceful degradation for devices that don't support live layouts
- Maintains compatibility across iOS versions

## Architecture

### Core Components

1. **MessagesViewController** - Main controller with live layout support
2. **LiveEventResponseViewController** - Compact UI for transcript presentation
3. **EventResponseViewController** - Full UI for expanded presentation
4. **CalendarEvent** - Data model with response tracking

### Presentation Styles

| Style | Controller | Purpose |
|-------|------------|---------|
| `.transcript` | `LiveEventResponseViewController` | Live layout in message bubble |
| `.compact` | `EventResponseViewController` | Quick response interface |
| `.expanded` | `CreateEventViewController` or `EventDetailViewController` | Full event management |

## Implementation Details

### 1. Live Layout Creation

```swift
private func composeMessage(with event: CalendarEvent, caption: String, session: MSSession? = nil) -> MSMessage {
    // Create alternate layout for fallback
    let alternateLayout = MSMessageTemplateLayout()
    alternateLayout.caption = caption
    alternateLayout.subcaption = event.formattedDateRange
    alternateLayout.image = createEventPreviewImage(for: event)
    
    // Create live layout for interactive responses
    let liveLayout = MSMessageLiveLayout(alternateLayout: alternateLayout)
    
    let message = MSMessage(session: session ?? MSSession())
    message.url = components.url!
    message.layout = liveLayout
    message.summaryText = "\(event.organizerName) invited you to \(event.title)"
    
    return message
}
```

### 2. Response Handling

```swift
private func handleEventResponse(event: CalendarEvent, response: CalendarEvent.EventResponse) {
    var updatedEvent = event
    updatedEvent.addResponse(participantID: participantID, response: response)
    
    let message = composeMessage(with: updatedEvent, caption: "📅 \(response.emoji) You \(responseText)")
    
    // Use send() instead of insert() for live layout updates
    conversation.send(message) { error in
        if let error = error {
            print("Error responding to event: \(error)")
        }
    }
    
    // Don't dismiss for live layout - let it update in place
    if presentationStyle != .transcript {
        dismiss()
    }
}
```

### 3. Live Layout UI

The `LiveEventResponseViewController` provides:
- Compact event information display
- Prominent Yes/No response buttons
- Real-time response status updates
- Haptic feedback for interactions
- Smooth button press animations

### 4. Content Sizing

```swift
override func contentSizeThatFits(_ size: CGSize) -> CGSize {
    if presentationStyle == .transcript {
        return CGSize(width: size.width, height: 160) // Compact height for live layout
    }
    return super.contentSizeThatFits(size)
}
```

## User Experience Flow

### For Event Organizers
1. Create event in expanded view
2. Send invitation with live layout
3. See real-time responses as recipients reply
4. View updated response counts in message bubble

### For Event Recipients
1. Receive invitation in message thread
2. See compact event details in message bubble
3. Tap "Yes" or "No" directly in the bubble
4. See immediate confirmation of response
5. View updated response counts from other participants

## Technical Considerations

### Spam Protection
- All response actions are user-initiated (button taps)
- Proper use of `conversation.send()` for updates
- Maintains message session for threading

### Performance
- Lightweight UI for transcript presentation
- Efficient message updates using existing session
- Minimal memory footprint for live layout

### Compatibility
- Fallback to template layout on older devices
- Graceful degradation of features
- Maintains core functionality across iOS versions

## Testing Recommendations

### Simulator Testing
- Test on iOS 16.4+ simulators (iOS 17 simulator has known issues)
- Verify live layout rendering in transcript view
- Test response button interactions

### Device Testing
- Test on physical devices for accurate behavior
- Verify spam protection doesn't block legitimate responses
- Test with multiple participants for response aggregation

### Edge Cases
- Test with long event titles
- Test with missing location information
- Test rapid successive responses
- Test network connectivity issues

## Benefits Over Deferred Sheets

| Aspect | Deferred Sheet | Live Layout |
|--------|----------------|-------------|
| **User Steps** | Tap → Open Extension → Select → Send | Tap Response Button |
| **Context Switching** | Required | None |
| **Response Time** | ~5-10 seconds | ~1 second |
| **Visual Feedback** | Delayed | Immediate |
| **User Experience** | Disruptive | Seamless |

## Future Enhancements

### Potential Improvements
1. **Rich Response Options** - Maybe/Tentative responses
2. **Quick Actions** - Add to calendar, set reminders
3. **Participant Avatars** - Show who's responded
4. **Time Zone Support** - Display in recipient's timezone
5. **Recurring Events** - Handle series responses

### Advanced Features
1. **Live Participant List** - Real-time attendee updates
2. **Location Integration** - Maps integration for venues
3. **Calendar Sync** - Automatic calendar app integration
4. **Notification Preferences** - Customizable response notifications

## Conclusion

The MSMessageLiveLayout implementation significantly improves the user experience for calendar invitations by:
- Reducing friction in the response process
- Providing immediate visual feedback
- Maintaining context within the message thread
- Supporting real-time collaboration features

This approach transforms a multi-step process into a single-tap interaction while maintaining all the functionality of the original implementation. 