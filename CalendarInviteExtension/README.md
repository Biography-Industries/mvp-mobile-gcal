# Calendar Invite iMessage Extension

This iMessage extension allows users to send calendar event invitations directly through Messages and receive responses from friends. The extension supports two types of interactive widgets with different presentation modes optimized for their specific use cases.

## Features

### 📅 RSVP Event Widget (Live Layout)
- Quick "Going" or "Can't go" responses directly in message bubbles
- Real-time response tracking and display
- Automatic calendar integration when accepting invites
- Uses **MSMessageLiveLayout** for immediate interaction without opening the extension

### ⏰ Schedule Coordination Widget (Deferred Presentation)
- Coordinate availability when event time is uncertain
- Multiple time slot selection with conflict detection
- Custom availability proposal (When2Meet-style interface)
- Uses **deferred presentation** (tap to expand) to avoid scrolling conflicts
- Full sheet interaction for better user experience with complex interfaces

### 🔄 Smart Presentation Mode Selection
- **Live Layout**: Used for simple RSVP interactions that work well in message bubbles
- **Deferred Presentation**: Used for complex scheduling interfaces that need full screen interaction
- Automatic conflict resolution between iMessage chat scroll and widget scroll
- Both widgets work independently within the same app target

## Features

### 📅 Event Sharing
- Create new calendar events within the Messages app
- Share existing events from your Apple Calendar
- Rich message bubbles with event details (title, date, time, location)

### 🔄 Interactive Responses
- Recipients can respond with "Going" or "Can't go" directly in Messages
- Real-time response tracking and display
- Automatic calendar integration when accepting invites

### 📱 Dual Interface
- **Compact Mode**: Quick response buttons and event list
- **Expanded Mode**: Full event creation and detailed view

## Setup Instructions

### 1. Add Extension Target to Xcode Project

1. Open your `GcalDemo.xcodeproj` in Xcode
2. Go to **File > New > Target**
3. Choose **iOS > Application Extension > iMessage Extension**
4. Name it `CalendarInviteExtension`
5. Set the bundle identifier to `com.yourcompany.GcalDemo.CalendarInviteExtension`

### 2. Configure Project Settings

1. **Add EventKit Framework**:
   - Select your extension target
   - Go to **Build Phases > Link Binary With Libraries**
   - Add `EventKit.framework` and `Messages.framework`

2. **Update Info.plist**:
   - Ensure calendar usage description is included
   - Verify extension point identifier is correct

3. **Add Calendar Permission**:
   - The extension automatically requests calendar access
   - Users will see a permission dialog on first use

### 3. File Structure

```
CalendarInviteExtension/
├── Info.plist
├── MainInterface.storyboard
├── MessagesViewController.swift
├── CalendarEvent.swift
├── EventResponseViewController.swift
├── EventListViewController.swift
├── CreateEventViewController.swift
├── EventDetailViewController.swift
└── README.md
```

## How It Works

### RSVP Widget Flow (Live Layout)

1. **Sender Creates RSVP Event**:
   - Opens Messages app and selects Calendar Invites extension
   - Creates event with specific time/date
   - Sends invitation as **live interactive message**

2. **Recipient Sees RSVP Widget**:
   - Event details appear directly in message bubble
   - "Going" and "Can't go" buttons are immediately visible
   - Can respond without opening the extension

3. **Response Handling**:
   - Responses update the message for all participants in real-time
   - Uses `MSMessageLiveLayout` for seamless interaction
   - Accepted events can be automatically added to recipient's calendar

### Scheduling Widget Flow (Deferred Presentation)

1. **Sender Creates Scheduling Event**:
   - Opens extension and chooses "Coordinate Schedule"
   - Sets preferences (time range, preferred days, duration)
   - System generates 3-5 conflict-free time suggestions
   - Sends as **template layout message** (not live)

2. **Recipient Sees Scheduling Summary**:
   - Compact view shows event title, organizer, and option count
   - Clear "Tap to choose your availability" instruction
   - **No scrolling conflicts** with iMessage chat

3. **Full Interaction Experience**:
   - Tapping opens full extension in expanded mode
   - Complete scheduling interface with proper scrolling
   - Multiple selection options:
     - Select from suggested time slots
     - Indicate "none of these work"
     - Propose custom availability with When2Meet-style grid

4. **Response Options**:
   - **Quick Selection**: Choose from suggested time slots
   - **None Work**: Indicate scheduling conflicts
   - **Custom Availability**: Open When2Meet-style interface for custom time proposal

## Technical Implementation

### Message Type Detection

```swift
// RSVP events use live layout
private func composeMessage(with event: CalendarEvent, caption: String, session: MSSession? = nil) -> MSMessage {
    let liveLayout = MSMessageLiveLayout(alternateLayout: alternateLayout)
    // ... configure live interactive message
}

// Scheduling events use deferred presentation
private func composeScheduleSelectionMessage(with event: ScheduleSelectionEvent, caption: String, session: MSSession? = nil) -> MSMessage {
    let templateLayout = MSMessageTemplateLayout()
    templateLayout.imageTitle = "Tap to coordinate schedule"
    // ... configure tap-to-expand message
}
```

### Presentation Mode Routing

```swift
private func createTranscriptViewController(for conversation: MSConversation) -> UIViewController {
    if let event = CalendarEvent(message: selectedMessage) {
        // RSVP: Show live interactive view
        return LiveEventResponseViewController(event: event, participantID: participantID, delegate: self)
    } else if let scheduleEvent = ScheduleSelectionEvent(message: selectedMessage) {
        // Scheduling: Show tap-to-expand summary
        return ScheduleSelectionTapToExpandViewController(scheduleEvent: scheduleEvent)
    }
}

private func createExpandedViewController(for conversation: MSConversation) -> UIViewController {
    if let scheduleEvent = ScheduleSelectionEvent(message: selectedMessage) {
        // Scheduling: Show full interactive interface
        return ScheduleSelectionViewController(scheduleEvent: scheduleEvent, delegate: self)
    }
    // ... other cases
}
```

## Widget Presentation Modes

| Widget Type | Transcript Mode | Compact Mode | Expanded Mode |
|-------------|----------------|--------------|---------------|
| **RSVP** | Live interactive buttons | Quick response interface | Full event details |
| **Scheduling** | Tap-to-expand summary | Event list | Full scheduling interface |

## User Experience Benefits

### RSVP Widget Advantages
- **Zero friction**: Respond without leaving Messages
- **Immediate feedback**: See response reflected instantly
- **Context preservation**: No app switching required
- **Real-time updates**: See others' responses as they come in

### Scheduling Widget Advantages
- **No scroll conflicts**: Eliminates iMessage chat scroll interference
- **Better interaction**: Full screen space for complex time selection
- **Visual clarity**: Proper layout for When2Meet-style grid
- **Progressive disclosure**: Simple summary → full interface when needed

## Setup Instructions

The extension supports both widget types automatically. No additional configuration is needed beyond the standard iMessage extension setup.

### Required Permissions
- **Calendar Access**: For conflict detection and event creation
- **Messages Framework**: For iMessage extension functionality

## File Structure

```
CalendarInviteExtension/
├── MessagesViewController.swift              # Main controller with widget routing
├── CalendarEvent.swift                       # RSVP event data model
├── ScheduleSelectionEvent.swift             # Scheduling event data model
├── LiveEventResponseViewController.swift     # RSVP live layout view
├── ScheduleSelectionTapToExpandViewController.swift  # Scheduling summary view
├── ScheduleSelectionViewController.swift     # Full scheduling interface
├── CustomAvailabilityViewController.swift   # When2Meet-style grid
└── README.md
```

## Troubleshooting

### Common Issues

1. **Scheduling Widget Not Expanding**:
   - Ensure the message uses `MSMessageTemplateLayout` (not live layout)
   - Check that tapping triggers expanded presentation mode

2. **RSVP Buttons Not Responding**:
   - Verify `MSMessageLiveLayout` is properly configured
   - Check live layout delegate methods are implemented

3. **Scroll Conflicts** (Legacy Issue - Now Resolved):
   - Old issue where scheduling widget used live layout
   - Resolved by moving scheduling to deferred presentation

## Best Practices

### When to Use Live Layout
- Simple, single-action responses (Yes/No, Accept/Decline)
- Interactions that benefit from immediate visibility
- Actions that don't require complex input

### When to Use Deferred Presentation
- Complex interfaces with multiple selection options
- Views that require significant scrolling
- Multi-step workflows or detailed input forms

## Future Enhancements

- [ ] Rich scheduling preferences (timezone support, recurring events)
- [ ] Advanced conflict detection with multiple calendar sources
- [ ] Integration with Google Calendar and other services
- [ ] Participant avatars and response visualization
- [ ] Smart time suggestion based on historical preferences

This dual-widget approach provides the best of both worlds: immediate interaction for simple responses and full-featured interfaces for complex coordination, all while avoiding UI conflicts and maintaining excellent user experience.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Apple's Messages Framework documentation
3. Test on physical devices for accurate behavior
4. Ensure all permissions are properly configured 