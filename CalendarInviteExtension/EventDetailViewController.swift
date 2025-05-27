//
//  EventDetailViewController.swift
//  CalendarInviteExtension
//
//  Created by Calendar Invite Extension
//

import UIKit
import Messages

class EventDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let event: CalendarEvent
    private weak var delegate: EventDetailViewControllerDelegate?
    private let participantID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let organizerLabel = UILabel()
    private let dateLabel = UILabel()
    private let locationLabel = UILabel()
    private let notesLabel = UILabel()
    private let notesTextView = UITextView()
    private let responseHeaderLabel = UILabel()
    private let responseStackView = UIStackView()
    private let acceptButton = UIButton(type: .system)
    private let declineButton = UIButton(type: .system)
    private let responseListStackView = UIStackView()
    
    // MARK: - Initialization
    init(event: CalendarEvent, delegate: EventDetailViewControllerDelegate?) {
        self.event = event
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContent()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure labels
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        organizerLabel.font = .systemFont(ofSize: 16)
        organizerLabel.textColor = .secondaryLabel
        organizerLabel.textAlignment = .center
        
        dateLabel.font = .systemFont(ofSize: 18)
        dateLabel.numberOfLines = 0
        dateLabel.textAlignment = .center
        dateLabel.textColor = .systemBlue
        
        locationLabel.font = .systemFont(ofSize: 16)
        locationLabel.textColor = .secondaryLabel
        locationLabel.numberOfLines = 0
        locationLabel.textAlignment = .center
        
        notesLabel.font = .boldSystemFont(ofSize: 18)
        notesLabel.text = "Notes"
        
        notesTextView.font = .systemFont(ofSize: 16)
        notesTextView.isEditable = false
        notesTextView.isScrollEnabled = false
        notesTextView.backgroundColor = .systemGray6
        notesTextView.layer.cornerRadius = 8
        notesTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        responseHeaderLabel.font = .boldSystemFont(ofSize: 18)
        responseHeaderLabel.text = "Your Response"
        
        // Configure buttons
        acceptButton.setTitle("✅ Going", for: .normal)
        acceptButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        acceptButton.backgroundColor = .systemGreen
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.layer.cornerRadius = 8
        acceptButton.addTarget(self, action: #selector(acceptButtonTapped), for: .touchUpInside)
        
        declineButton.setTitle("❌ Can't go", for: .normal)
        declineButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        declineButton.backgroundColor = .systemRed
        declineButton.setTitleColor(.white, for: .normal)
        declineButton.layer.cornerRadius = 8
        declineButton.addTarget(self, action: #selector(declineButtonTapped), for: .touchUpInside)
        
        // Configure response stack view
        responseStackView.axis = .horizontal
        responseStackView.distribution = .fillEqually
        responseStackView.spacing = 12
        responseStackView.addArrangedSubview(acceptButton)
        responseStackView.addArrangedSubview(declineButton)
        
        // Configure response list stack view
        responseListStackView.axis = .vertical
        responseListStackView.spacing = 8
        
        // Add all elements to content view
        let allElements = [
            titleLabel, organizerLabel, dateLabel, locationLabel,
            notesLabel, notesTextView,
            responseHeaderLabel, responseStackView, responseListStackView
        ]
        
        allElements.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Organizer label
            organizerLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            organizerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            organizerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Date label
            dateLabel.topAnchor.constraint(equalTo: organizerLabel.bottomAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Location label
            locationLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Notes section
            notesLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 24),
            notesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            notesTextView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 8),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Response section
            responseHeaderLabel.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: 24),
            responseHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            responseHeaderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            responseStackView.topAnchor.constraint(equalTo: responseHeaderLabel.bottomAnchor, constant: 12),
            responseStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            responseStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Response list
            responseListStackView.topAnchor.constraint(equalTo: responseStackView.bottomAnchor, constant: 24),
            responseListStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            responseListStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            responseListStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Button heights
            acceptButton.heightAnchor.constraint(equalToConstant: 44),
            declineButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func configureContent() {
        titleLabel.text = event.title
        organizerLabel.text = "Organized by \(event.organizerName)"
        dateLabel.text = event.formattedDateRange
        
        if let location = event.location, !location.isEmpty {
            locationLabel.text = "📍 \(location)"
            locationLabel.isHidden = false
        } else {
            locationLabel.isHidden = true
        }
        
        if let notes = event.notes, !notes.isEmpty {
            notesTextView.text = notes
            notesLabel.isHidden = false
            notesTextView.isHidden = false
        } else {
            notesLabel.isHidden = true
            notesTextView.isHidden = true
        }
        
        updateResponseButtons()
        updateResponseList()
    }
    
    private func updateResponseButtons() {
        let currentResponse = event.responses[participantID]
        
        if let response = currentResponse {
            acceptButton.alpha = response == .accepted ? 1.0 : 0.6
            declineButton.alpha = response == .declined ? 1.0 : 0.6
            
            // Update button titles to show current status
            if response == .accepted {
                acceptButton.setTitle("✅ You're going!", for: .normal)
            } else {
                acceptButton.setTitle("✅ Going", for: .normal)
            }
            
            if response == .declined {
                declineButton.setTitle("❌ You declined", for: .normal)
            } else {
                declineButton.setTitle("❌ Can't go", for: .normal)
            }
        } else {
            acceptButton.alpha = 1.0
            declineButton.alpha = 1.0
            acceptButton.setTitle("✅ Going", for: .normal)
            declineButton.setTitle("❌ Can't go", for: .normal)
        }
    }
    
    private func updateResponseList() {
        // Clear existing response views
        responseListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if !event.responses.isEmpty {
            let headerLabel = UILabel()
            headerLabel.text = "Responses"
            headerLabel.font = .boldSystemFont(ofSize: 18)
            responseListStackView.addArrangedSubview(headerLabel)
            
            let acceptedResponses = event.responses.filter { $0.value == .accepted }
            let declinedResponses = event.responses.filter { $0.value == .declined }
            let pendingResponses = event.responses.filter { $0.value == .pending }
            
            // Show accepted responses
            if !acceptedResponses.isEmpty {
                let acceptedLabel = UILabel()
                acceptedLabel.text = "✅ Going (\(acceptedResponses.count))"
                acceptedLabel.font = .boldSystemFont(ofSize: 16)
                acceptedLabel.textColor = .systemGreen
                responseListStackView.addArrangedSubview(acceptedLabel)
                
                for (participantID, _) in acceptedResponses {
                    let responseLabel = UILabel()
                    responseLabel.text = "  • \(participantID == self.participantID ? "You" : "Participant \(participantID.prefix(8))")"
                    responseLabel.font = .systemFont(ofSize: 14)
                    responseLabel.textColor = .secondaryLabel
                    responseListStackView.addArrangedSubview(responseLabel)
                }
            }
            
            // Show declined responses
            if !declinedResponses.isEmpty {
                let declinedLabel = UILabel()
                declinedLabel.text = "❌ Can't go (\(declinedResponses.count))"
                declinedLabel.font = .boldSystemFont(ofSize: 16)
                declinedLabel.textColor = .systemRed
                responseListStackView.addArrangedSubview(declinedLabel)
                
                for (participantID, _) in declinedResponses {
                    let responseLabel = UILabel()
                    responseLabel.text = "  • \(participantID == self.participantID ? "You" : "Participant \(participantID.prefix(8))")"
                    responseLabel.font = .systemFont(ofSize: 14)
                    responseLabel.textColor = .secondaryLabel
                    responseListStackView.addArrangedSubview(responseLabel)
                }
            }
            
            // Show pending responses
            if !pendingResponses.isEmpty {
                let pendingLabel = UILabel()
                pendingLabel.text = "⏳ Pending (\(pendingResponses.count))"
                pendingLabel.font = .boldSystemFont(ofSize: 16)
                pendingLabel.textColor = .systemOrange
                responseListStackView.addArrangedSubview(pendingLabel)
                
                for (participantID, _) in pendingResponses {
                    let responseLabel = UILabel()
                    responseLabel.text = "  • \(participantID == self.participantID ? "You" : "Participant \(participantID.prefix(8))")"
                    responseLabel.font = .systemFont(ofSize: 14)
                    responseLabel.textColor = .secondaryLabel
                    responseListStackView.addArrangedSubview(responseLabel)
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func acceptButtonTapped() {
        var updatedEvent = event
        updatedEvent.addResponse(participantID: participantID, response: .accepted)
        delegate?.eventDetailViewController(self, didUpdateEvent: updatedEvent)
    }
    
    @objc private func declineButtonTapped() {
        var updatedEvent = event
        updatedEvent.addResponse(participantID: participantID, response: .declined)
        delegate?.eventDetailViewController(self, didUpdateEvent: updatedEvent)
    }
} 