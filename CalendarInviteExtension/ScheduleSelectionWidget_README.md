# Schedule Selection Widget for Donna 📅⏰

> **Interactive schedule coordination widget with deferred presentation for optimal user experience** 

The Schedule Selection Widget enables users to coordinate availability when the event time is uncertain. The widget uses **deferred presentation** (tap to expand) to provide a full-featured scheduling interface while avoiding scrolling conflicts with iMessage chat.

## 🎯 Core Features

### ✅ **Deferred Presentation Design**
- **Tap-to-expand summary** in message bubbles
- **No scrolling conflicts** with iMessage chat
- **Full sheet interaction** for complex scheduling tasks
- **Progressive disclosure** from simple summary to full interface

### ✅ **Schedule Selection Interface**
- Display 3–5 suggested time blocks (calendar-integrated)
- Multi-selection support for preferred time blocks
- "None work" option for scheduling conflicts
- Real-time response tracking and visualization

### ✅ **Custom Availability (When2Meet-Style)**
- 7-day view with hourly time slots
- Gesture/swipe-based selection for mobile UX
- Visual feedback with green/gray color coding
- Full-screen interaction without scroll conflicts

### ✅ **"GO AHEAD" Flow**
- Natural language input: *"I want to go on a hike with 5 people this weekend"*
- Calendar analysis for conflict-free time suggestions
- One-tap widget dispatch to invitees as **deferred presentation**
- Automatic response aggregation

### ✅ **Smart Time Suggestion Logic**
- Apple Calendar integration for conflict detection
- Preferred time range configuration
- Weekday/weekend preference selection
- Automatic availability filtering

## 🏗️ Architecture

### Presentation Mode Strategy

```swift
// Scheduling events use deferred presentation (template layout)
private func composeScheduleSelectionMessage(with event: ScheduleSelectionEvent) -> MSMessage {
    let templateLayout = MSMessageTemplateLayout()
    templateLayout.imageTitle = "Tap to coordinate schedule"
    // No live layout - prevents scrolling conflicts
    message.layout = templateLayout
}
```

### Core Components

```swift
// Data Models
ScheduleSelectionEvent     // Main event with multiple time options
TimeSlot                   // Individual time block with participant selections
ParticipantResponse        // User response with selected times or custom availability

// View Controllers
ScheduleSelectionTapToExpandViewController  // Summary view in transcript mode
ScheduleSelectionViewController            // Full interface in expanded mode
CreateScheduleSelectionViewController       // Event creation with smart suggestions
CustomAvailabilityViewController           // When2Meet-style grid selector

// Integration
MessagesViewController                     // Routing between presentation modes
```

### Presentation Flow

```
1. Sender creates scheduling event → Template layout message sent
2. Recipient sees summary in transcript → Clear tap-to-expand indicator
3. Recipient taps message → Full extension opens in expanded mode
4. Full scheduling interface → Multiple selection options available
5. Response handling → Updates message for all participants
```

## 📱 User Experience Flow

### For Event Organizers

1. **Natural Input**: *"I want to organize a team lunch next week"*
2. **Smart Configuration**: 
   - Set preferred time range (12 PM - 2 PM)
   - Select preferred days (weekdays only)
   - Choose event duration (1 hour)
3. **Auto-Generation**: System suggests 4-5 conflict-free options
4. **Send as Deferred Widget**: Message appears as tap-to-expand template
5. **Live Tracking**: See responses update when participants interact

### For Event Recipients

1. **Clear Summary View**: See event title, organizer, and option count in message bubble
2. **No Scroll Conflicts**: Summary view doesn't interfere with chat scrolling
3. **Tap to Expand**: Clear visual indicator to open full interface
4. **Full Interaction**: Complete scheduling interface opens in dedicated space
5. **Multiple Options**:
   - **Quick Selection**: Choose from suggested time slots
   - **None Work**: Indicate all suggestions have conflicts
   - **Custom Availability**: Open When2Meet-style grid for custom proposal

### When2Meet-Style Custom Availability

1. **Full-Screen Interface**: Opens in expanded mode with no scroll conflicts
2. **7-Day Grid**: Hourly time slots across one week
3. **Gesture Selection**: Touch and drag to select available time blocks
4. **Visual Feedback**: Green = available, Gray = unavailable
5. **Batch Operations**: "Clear All" and "Confirm Selection" buttons

## 🎨 UI/UX Design Principles

### Deferred Presentation Benefits
- **No Scroll Conflicts**: Eliminates interference with iMessage chat scrolling
- **Progressive Disclosure**: Simple summary → full interface when needed
- **Better Space Utilization**: Full screen available for complex interactions
- **Context Preservation**: Clear visual connection between summary and full view

### Mobile-First Design
- **Large Touch Targets**: 44pt minimum for all interactive elements
- **Gesture Support**: Pan, tap, and long-press interactions optimized for full screen
- **Haptic Feedback**: Physical confirmation for all selections
- **Animation**: Smooth transitions between summary and full interface

### Visual Hierarchy
- **Summary View**: Clean, scannable information in message bubble
- **Full Interface**: Rich interaction with proper spacing and organization
- **Color Coding**: Blue (organizer), Green (selected), Orange (pending), Red (conflicts)
- **Typography**: Clear font sizing with accessibility support

## 🔧 Technical Implementation

### Message Composition (Deferred Presentation)

```swift
private func composeScheduleSelectionMessage(with event: ScheduleSelectionEvent, caption: String, session: MSSession? = nil) -> MSMessage {
    // Use template layout for deferred presentation (NOT live layout)
    let templateLayout = MSMessageTemplateLayout()
    templateLayout.caption = caption
    templateLayout.subcaption = event.title
    templateLayout.trailingCaption = "\(event.suggestedTimeSlots.count) options"
    templateLayout.imageTitle = "Tap to coordinate schedule"
    templateLayout.imageSubtitle = "Choose your preferred times"
    
    let message = MSMessage(session: session ?? MSSession())
    message.layout = templateLayout // Template layout enables tap-to-expand
    message.summaryText = "\(event.organizerName) is coordinating: \(event.title)"
    
    return message
}
```

### Presentation Mode Routing

```swift
private func createTranscriptViewController(for conversation: MSConversation) -> UIViewController {
    if let scheduleEvent = ScheduleSelectionEvent(message: selectedMessage) {
        // Show tap-to-expand summary (NOT full interface)
        return ScheduleSelectionTapToExpandViewController(scheduleEvent: scheduleEvent)
    }
}

private func createExpandedViewController(for conversation: MSConversation) -> UIViewController {
    if let scheduleEvent = ScheduleSelectionEvent(message: selectedMessage) {
        // Show full interactive interface
        return ScheduleSelectionViewController(scheduleEvent: scheduleEvent, delegate: self)
    }
}
```

### Calendar Integration

```swift
// Smart time suggestion with conflict detection
func generateSuggestedTimeSlots() {
    let candidateSlots = generateCandidateSlots(preferences)
    filterOutConflictingTimes(&candidateSlots)
    return candidateSlots.sorted(by: preferenceScore)
}
```

## 🧪 Testing & Validation

### Presentation Mode Testing

```swift
// Test deferred presentation flow
ScheduleSelectionTestHelper.testDeferredPresentationFlow()

// Verify no scroll conflicts
ScheduleSelectionTestHelper.testScrollConflictResolution()

// Test tap-to-expand behavior
ScheduleSelectionTestHelper.testTapToExpandInteraction()
```

### Test Coverage

- ✅ **Deferred Presentation**: Template layout message creation
- ✅ **Tap-to-Expand**: Summary view to full interface transition
- ✅ **Scroll Conflict Resolution**: No interference with chat scrolling
- ✅ **Full Interface**: Complete scheduling functionality in expanded mode
- ✅ **Response Aggregation**: Multi-participant coordination
- ✅ **Custom Availability**: When2Meet-style grid interaction

## 📊 Presentation Mode Comparison

| Aspect | Live Layout (Old) | Deferred Presentation (New) |
|--------|-------------------|----------------------------|
| **Scroll Conflicts** | ❌ Interfered with chat | ✅ No conflicts |
| **User Steps** | Scroll in bubble → Select | Tap → Full interface → Select |
| **Screen Space** | Limited bubble area | Full screen available |
| **Complex Interactions** | Problematic | Optimal |
| **Visual Feedback** | Constrained | Rich and clear |
| **User Experience** | Frustrating scroll conflicts | Smooth and intuitive |

## 🚀 Deployment Benefits

### Problem Resolution
- ✅ **Eliminated scroll conflicts** between widget and iMessage chat
- ✅ **Improved usability** for complex scheduling interfaces  
- ✅ **Better space utilization** with full-screen interaction
- ✅ **Maintained simplicity** with clear tap-to-expand pattern

### User Experience Improvements
- **Reduced Friction**: Clear interaction model without confusion
- **Better Visibility**: Full interface space for time selection
- **Intuitive Flow**: Natural progression from summary to detail
- **Conflict-Free**: No more fighting with chat scroll

## 🔄 Integration with RSVP Widget

### Coexistence Strategy
- **RSVP Widget**: Continues to use live layout (optimal for simple Yes/No responses)
- **Scheduling Widget**: Uses deferred presentation (optimal for complex interactions)
- **Shared Infrastructure**: Both use same MessagesViewController base
- **Independent Operation**: Each widget type optimized for its specific use case

### Message Type Detection
```swift
// Automatic routing based on message content
if let rsvpEvent = CalendarEvent(message: message) {
    // Use live layout for RSVP
    return LiveEventResponseViewController(event: rsvpEvent)
} else if let scheduleEvent = ScheduleSelectionEvent(message: message) {
    // Use deferred presentation for scheduling
    return ScheduleSelectionTapToExpandViewController(scheduleEvent: scheduleEvent)
}
```

## 🎉 Ready for Production

The Schedule Selection Widget with **deferred presentation** is **fully implemented** and **thoroughly tested**. It provides:

- ✅ **Scroll Conflict Resolution**: No more interference with iMessage chat
- ✅ **Optimal User Experience**: Progressive disclosure from summary to full interface
- ✅ **Complete Feature Set**: All scheduling functionality in proper full-screen context
- ✅ **Mobile-Optimized UX**: Gesture-based, intuitive interface without constraints
- ✅ **Calendar Integration**: Smart suggestions with conflict detection
- ✅ **Independent Operation**: Works seamlessly alongside RSVP widget

**Key Achievement**: Transformed a problematic scrollable interface into an elegant tap-to-expand experience that users will love! 🚀 