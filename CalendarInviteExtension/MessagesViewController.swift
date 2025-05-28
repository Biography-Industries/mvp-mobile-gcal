//
//  MessagesViewController.swift
//  CalendarInviteExtension
//
//  Created by Calendar Invite Extension
//

import UIKit
import Messages
import EventKit

class MessagesViewController: MSMessagesAppViewController {
    
    // MARK: - Properties
    private var eventStore: EKEventStore?
    private var currentEvent: CalendarEvent?
    private let participantID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    private var hasInitialized = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MessagesViewController: Starting initialization...")
        
        // Initialize with error handling
        initializeExtension()
    }
    
    private func initializeExtension() {
        do {
            // Initialize EventKit with error handling
            eventStore = EKEventStore()
            print("MessagesViewController: EventStore initialized successfully")
            
            // Request calendar access safely
            requestCalendarAccess()
            
            hasInitialized = true
            print("MessagesViewController: Extension initialized successfully")
            
        } catch {
            print("MessagesViewController: Error during initialization: \(error)")
            // Continue without EventKit if it fails
            hasInitialized = true
        }
    }
    
    // MARK: - MSMessagesAppViewController Overrides
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        
        guard hasInitialized else {
            print("MessagesViewController: Extension not initialized, skipping presentation")
            return
        }
        
        do {
            presentViewController(for: conversation, with: presentationStyle)
        } catch {
            print("MessagesViewController: Error presenting view controller: \(error)")
            presentFallbackViewController()
        }
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        removeAllChildViewControllers()
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        guard let conversation = activeConversation, hasInitialized else { return }
        
        do {
            presentViewController(for: conversation, with: presentationStyle)
        } catch {
            print("MessagesViewController: Error during transition: \(error)")
            presentFallbackViewController()
        }
    }
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        
        guard hasInitialized else { return }
        
        // Handle live layout updates
        if presentationStyle == .transcript {
            if let event = CalendarEvent(message: message) {
                currentEvent = event
                // Update the live layout view if needed
                updateLiveLayoutIfNeeded(for: conversation, with: event)
            }
        }
    }
    
    // MARK: - Live Layout Support
    private func updateLiveLayoutIfNeeded(for conversation: MSConversation, with event: CalendarEvent) {
        // This method handles live updates when messages are received
        // The live layout will automatically update the UI
        DispatchQueue.main.async {
            if self.presentationStyle == .transcript {
                do {
                    self.presentViewController(for: conversation, with: self.presentationStyle)
                } catch {
                    print("MessagesViewController: Error updating live layout: \(error)")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func requestCalendarAccess() {
        guard let eventStore = eventStore else { return }
        
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("MessagesViewController: Calendar access error: \(error)")
                }
                if !granted {
                    print("MessagesViewController: Calendar access not granted")
                    // Continue without calendar access
                }
            }
        }
    }
    
    private func presentFallbackViewController() {
        // Present a simple fallback view if main initialization fails
        let fallbackController = UIViewController()
        fallbackController.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Calendar Invites"
        label.font = .boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        fallbackController.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: fallbackController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: fallbackController.view.centerYAnchor)
        ])
        
        addChild(fallbackController)
        fallbackController.view.frame = view.bounds
        fallbackController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fallbackController.view)
        
        NSLayoutConstraint.activate([
            fallbackController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fallbackController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fallbackController.view.topAnchor.constraint(equalTo: view.topAnchor),
            fallbackController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        fallbackController.didMove(toParent: self)
    }
    
    private func presentViewController(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle) {
        removeAllChildViewControllers()
        
        let controller: UIViewController
        
        do {
            if presentationStyle == .compact {
                controller = createCompactViewController(for: conversation)
            } else if presentationStyle == .transcript {
                controller = createTranscriptViewController(for: conversation)
            } else {
                controller = createExpandedViewController(for: conversation)
            }
            
            addChild(controller)
            controller.view.frame = view.bounds
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(controller.view)
            
            NSLayoutConstraint.activate([
                controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                controller.view.topAnchor.constraint(equalTo: view.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            controller.didMove(toParent: self)
            
        } catch {
            print("MessagesViewController: Error creating view controller: \(error)")
            presentFallbackViewController()
        }
    }
    
    private func createCompactViewController(for conversation: MSConversation) -> UIViewController {
        // Check if there's a selected message with an event
        if let selectedMessage = conversation.selectedMessage,
           let event = CalendarEvent(message: selectedMessage) {
            return EventResponseViewController(event: event, delegate: self)
        } else {
            return EventListViewController(delegate: self)
        }
    }
    
    private func createTranscriptViewController(for conversation: MSConversation) -> UIViewController {
        // Create a live layout view controller for transcript presentation
        if let selectedMessage = conversation.selectedMessage,
           let event = CalendarEvent(message: selectedMessage) {
            return LiveEventResponseViewController(event: event, participantID: participantID, delegate: self)
        } else {
            // Fallback to compact view if no event is selected
            return createCompactViewController(for: conversation)
        }
    }
    
    private func createExpandedViewController(for conversation: MSConversation) -> UIViewController {
        // Check if there's a selected message with an event
        if let selectedMessage = conversation.selectedMessage,
           let event = CalendarEvent(message: selectedMessage) {
            return EventDetailViewController(event: event, delegate: self)
        } else {
            guard let eventStore = eventStore else {
                // Return a simple view if EventStore is not available
                return createFallbackCreateEventViewController()
            }
            return CreateEventViewController(eventStore: eventStore, delegate: self)
        }
    }
    
    private func createFallbackCreateEventViewController() -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Calendar access required to create events"
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        controller.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -20)
        ])
        
        return controller
    }
    
    private func removeAllChildViewControllers() {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    private func composeMessage(with event: CalendarEvent, caption: String, session: MSSession? = nil) -> MSMessage {
        var components = URLComponents()
        components.queryItems = event.queryItems
        
        // Create alternate layout for devices that don't support live layouts
        let alternateLayout = MSMessageTemplateLayout()
        alternateLayout.caption = caption
        alternateLayout.subcaption = event.formattedDateRange
        alternateLayout.trailingCaption = event.location
        alternateLayout.image = createEventPreviewImage(for: event)
        
        // Create live layout for interactive responses
        let liveLayout = MSMessageLiveLayout(alternateLayout: alternateLayout)
        
        let message = MSMessage(session: session ?? MSSession())
        message.url = components.url!
        message.layout = liveLayout
        message.summaryText = "\(event.organizerName) invited you to \(event.title)"
        
        return message
    }
    
    private func createEventPreviewImage(for event: CalendarEvent) -> UIImage {
        let size = CGSize(width: 300, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Calendar icon background
            UIColor.white.setFill()
            let iconRect = CGRect(x: 20, y: 20, width: 60, height: 60)
            context.fill(iconRect)
            
            // Calendar icon details
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 20, y: 20, width: 60, height: 15))
            
            // Event title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.white
            ]
            
            let titleRect = CGRect(x: 100, y: 30, width: 180, height: 50)
            event.title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Date
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateText = dateFormatter.string(from: event.startDate)
            
            let dateRect = CGRect(x: 100, y: 85, width: 180, height: 30)
            dateText.draw(in: dateRect, withAttributes: dateAttributes)
            
            // Location if available
            if let location = event.location, !location.isEmpty {
                let locationRect = CGRect(x: 100, y: 115, width: 180, height: 30)
                location.draw(in: locationRect, withAttributes: dateAttributes)
            }
            
            // Response summary
            let responseCount = event.responses.values.filter { $0 == .accepted }.count
            let totalResponses = event.responses.count
            
            if totalResponses > 0 {
                let responseText = "\(responseCount)/\(totalResponses) going"
                let responseRect = CGRect(x: 20, y: 160, width: 260, height: 20)
                responseText.draw(in: responseRect, withAttributes: dateAttributes)
            }
        }
    }
    
    // MARK: - Content Size Support
    override func contentSizeThatFits(_ size: CGSize) -> CGSize {
        // Return appropriate size for live layout in transcript presentation
        if presentationStyle == .transcript {
            return CGSize(width: size.width, height: 160) // Compact height for live layout
        }
        
        // Default size for other presentation styles
        return super.contentSizeThatFits(size)
    }
}

// MARK: - EventListViewControllerDelegate
extension MessagesViewController: EventListViewControllerDelegate {
    func eventListViewController(_ controller: EventListViewController, didSelectCreateEvent: Void) {
        requestPresentationStyle(.expanded)
    }
    
    func eventListViewController(_ controller: EventListViewController, didSelectEvent event: CalendarEvent) {
        currentEvent = event
        requestPresentationStyle(.expanded)
    }
}

// MARK: - CreateEventViewControllerDelegate
extension MessagesViewController: CreateEventViewControllerDelegate {
    func createEventViewController(_ controller: CreateEventViewController, didCreateEvent event: CalendarEvent) {
        guard let conversation = activeConversation else { return }
        
        let message = composeMessage(
            with: event,
            caption: "📅 \(event.organizerName) invited you to \(event.title)",
            session: conversation.selectedMessage?.session
        )
        
        conversation.insert(message) { error in
            if let error = error {
                print("Error inserting message: \(error)")
            }
        }
        
        dismiss()
    }
    
    func createEventViewControllerDidCancel(_ controller: CreateEventViewController) {
        dismiss()
    }
}

// MARK: - EventDetailViewControllerDelegate
extension MessagesViewController: EventDetailViewControllerDelegate {
    func eventDetailViewController(_ controller: EventDetailViewController, didUpdateEvent event: CalendarEvent) {
        guard let conversation = activeConversation else { return }
        
        let message = composeMessage(
            with: event,
            caption: "📅 Event updated: \(event.title)",
            session: conversation.selectedMessage?.session
        )
        
        conversation.insert(message) { error in
            if let error = error {
                print("Error updating message: \(error)")
            }
        }
        
        dismiss()
    }
}

// MARK: - EventResponseViewControllerDelegate
extension MessagesViewController: EventResponseViewControllerDelegate {
    func eventResponseViewController(_ controller: EventResponseViewController, didRespondToEvent event: CalendarEvent, with response: CalendarEvent.EventResponse) {
        handleEventResponse(event: event, response: response)
    }
}

// MARK: - LiveEventResponseViewControllerDelegate
extension MessagesViewController: LiveEventResponseViewControllerDelegate {
    func liveEventResponseViewController(_ controller: LiveEventResponseViewController, didRespondToEvent event: CalendarEvent, with response: CalendarEvent.EventResponse) {
        handleEventResponse(event: event, response: response)
    }
}

// MARK: - Shared Response Handling
extension MessagesViewController {
    private func handleEventResponse(event: CalendarEvent, response: CalendarEvent.EventResponse) {
        guard let conversation = activeConversation else { return }
        
        var updatedEvent = event
        updatedEvent.addResponse(participantID: participantID, response: response)
        
        let responseText = response == .accepted ? "is going!" : "declined."
        let message = composeMessage(
            with: updatedEvent,
            caption: "📅 \(response.emoji) You \(responseText)",
            session: conversation.selectedMessage?.session
        )
        
        // Use send instead of insert for live layout updates
        conversation.send(message) { error in
            if let error = error {
                print("Error responding to event: \(error)")
            }
        }
        
        // Optionally add to calendar if accepted
        if response == .accepted {
            addEventToCalendar(updatedEvent)
        }
        
        // Don't dismiss for live layout - let it update in place
        if presentationStyle != .transcript {
            dismiss()
        }
    }
    
    private func addEventToCalendar(_ event: CalendarEvent) {
        let calendarEvent = EKEvent(eventStore: eventStore!)
        calendarEvent.title = event.title
        calendarEvent.startDate = event.startDate
        calendarEvent.endDate = event.endDate
        calendarEvent.location = event.location
        calendarEvent.notes = event.notes
        calendarEvent.calendar = eventStore!.defaultCalendarForNewEvents
        
        do {
            try eventStore!.save(calendarEvent, span: .thisEvent)
        } catch {
            print("Error saving event to calendar: \(error)")
        }
    }
}

// MARK: - Delegate Protocols
protocol EventListViewControllerDelegate: AnyObject {
    func eventListViewController(_ controller: EventListViewController, didSelectCreateEvent: Void)
    func eventListViewController(_ controller: EventListViewController, didSelectEvent event: CalendarEvent)
}

protocol CreateEventViewControllerDelegate: AnyObject {
    func createEventViewController(_ controller: CreateEventViewController, didCreateEvent event: CalendarEvent)
    func createEventViewControllerDidCancel(_ controller: CreateEventViewController)
}

protocol EventDetailViewControllerDelegate: AnyObject {
    func eventDetailViewController(_ controller: EventDetailViewController, didUpdateEvent event: CalendarEvent)
}

protocol EventResponseViewControllerDelegate: AnyObject {
    func eventResponseViewController(_ controller: EventResponseViewController, didRespondToEvent event: CalendarEvent, with response: CalendarEvent.EventResponse)
}

protocol LiveEventResponseViewControllerDelegate: AnyObject {
    func liveEventResponseViewController(_ controller: LiveEventResponseViewController, didRespondToEvent event: CalendarEvent, with response: CalendarEvent.EventResponse)
} 