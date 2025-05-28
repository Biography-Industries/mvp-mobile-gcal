# Calendar Invite iMessage Extension

This iMessage extension allows users to send calendar event invitations directly through Messages and receive responses from friends.

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

### Message Flow

1. **Sender Creates Event**:
   - Opens Messages app
   - Taps the app drawer and selects Calendar Invites
   - Creates new event or selects existing one
   - Sends invitation as interactive message

2. **Recipient Receives Invitation**:
   - Sees rich message bubble with event details
   - Can tap to expand and see full details
   - Responds with "Going" or "Can't go"

3. **Response Handling**:
   - Response updates the message for all participants
   - Sender sees updated response count
   - Accepted events can be automatically added to recipient's calendar

### Data Sharing

Events are shared securely using `MSMessage` URL components:
- Event data is encoded in URL query parameters
- No external servers required
- Responses are tracked per participant using device identifiers

## User Interface

### Compact Mode (Default)
- **Event List**: Shows recent calendar events with "Create New Event" button
- **Response View**: Quick accept/decline buttons with event summary

### Expanded Mode (Tap to expand)
- **Create Event**: Full form with title, dates, location, and notes
- **Event Detail**: Complete event information with response tracking

## Technical Implementation

### Key Components

1. **CalendarEvent Model**:
   - Represents event data with responses
   - Handles URL encoding/decoding for message sharing
   - Supports EventKit integration

2. **MessagesViewController**:
   - Main controller managing presentation styles
   - Handles message composition and response processing
   - Integrates with EventKit for calendar access

3. **Response System**:
   - Tracks responses per participant using device identifiers
   - Updates message content with response status
   - Provides real-time feedback to all participants

### EventKit Integration

- Reads existing calendar events for sharing
- Adds accepted events to user's calendar
- Respects user's calendar permissions and preferences

## Best Practices

### Security
- No personal data is stored externally
- Device identifiers are used for response tracking
- Calendar access requires explicit user permission

### User Experience
- Clean, intuitive interface following iOS design guidelines
- Responsive design for different screen sizes
- Clear visual feedback for all interactions

### Performance
- Efficient message encoding/decoding
- Minimal memory footprint
- Fast response to user interactions

## Customization Options

### Styling
- Modify colors and fonts in view controllers
- Customize message bubble appearance
- Add custom icons or branding

### Features
- Add recurring event support
- Implement reminder notifications
- Add Google Calendar integration
- Support for multiple calendar accounts

## Troubleshooting

### Common Issues

1. **Calendar Permission Denied**:
   - Guide users to Settings > Privacy & Security > Calendars
   - Enable access for your app

2. **Extension Not Appearing**:
   - Ensure extension target is properly configured
   - Check bundle identifier matches main app
   - Verify Info.plist settings

3. **Messages Not Sending**:
   - Check network connectivity
   - Verify message composition logic
   - Test with different conversation types

### Debug Tips

- Use Xcode debugger with extension target
- Check console logs for error messages
- Test on physical device (extensions may not work properly in simulator)

## Future Enhancements

- [ ] Google Calendar integration
- [ ] Recurring event support
- [ ] Custom reminder settings
- [ ] Event modification capabilities
- [ ] Group event management
- [ ] Calendar sync across devices

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Apple's Messages Framework documentation
3. Test on physical devices for accurate behavior
4. Ensure all permissions are properly configured 