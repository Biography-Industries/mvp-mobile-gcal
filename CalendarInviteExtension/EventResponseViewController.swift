//
//  EventResponseViewController.swift
//  CalendarInviteExtension
//
//  Created by Dezmond Blair
//

import UIKit
import Messages

class EventResponseViewController: UIViewController {
    
    // MARK: - Properties
    private let event: CalendarEvent
    private weak var delegate: EventResponseViewControllerDelegate?
    private let participantID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let organizerLabel = UILabel()
    private let dateLabel = UILabel()
    private let locationLabel = UILabel()
    private let responseStackView = UIStackView()
    private let acceptButton = UIButton(type: .system)
    private let declineButton = UIButton(type: .system)
    private let responseStatusLabel = UILabel()
    
    // MARK: - Initialization
    init(event: CalendarEvent, delegate: EventResponseViewControllerDelegate?) {
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
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        organizerLabel.font = .systemFont(ofSize: 14)
        organizerLabel.textColor = .secondaryLabel
        organizerLabel.textAlignment = .center
        
        dateLabel.font = .systemFont(ofSize: 16)
        dateLabel.numberOfLines = 0
        dateLabel.textAlignment = .center
        
        locationLabel.font = .systemFont(ofSize: 14)
        locationLabel.textColor = .secondaryLabel
        locationLabel.numberOfLines = 0
        locationLabel.textAlignment = .center
        
        responseStatusLabel.font = .systemFont(ofSize: 14)
        responseStatusLabel.textColor = .secondaryLabel
        responseStatusLabel.textAlignment = .center
        responseStatusLabel.numberOfLines = 0
        
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
        
        // Add all elements to content view
        [titleLabel, organizerLabel, dateLabel, locationLabel, responseStatusLabel, responseStackView].forEach {
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
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Organizer label
            organizerLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            organizerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            organizerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Date label
            dateLabel.topAnchor.constraint(equalTo: organizerLabel.bottomAnchor, constant: 16),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Location label
            locationLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Response status label
            responseStatusLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 16),
            responseStatusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            responseStatusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Response stack view
            responseStackView.topAnchor.constraint(equalTo: responseStatusLabel.bottomAnchor, constant: 20),
            responseStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            responseStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            responseStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Button heights
            acceptButton.heightAnchor.constraint(equalToConstant: 44),
            declineButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func configureContent() {
        titleLabel.text = event.title
        organizerLabel.text = "Invited by \(event.organizerName)"
        dateLabel.text = event.formattedDateRange
        
        if let location = event.location, !location.isEmpty {
            locationLabel.text = "📍 \(location)"
            locationLabel.isHidden = false
        } else {
            locationLabel.isHidden = true
        }
        
        updateResponseStatus()
    }
    
    private func updateResponseStatus() {
        let currentResponse = event.responses[participantID]
        let acceptedCount = event.responses.values.filter { $0 == .accepted }.count
        let totalResponses = event.responses.count
        
        var statusText = ""
        
        if let response = currentResponse {
            statusText = "Your response: \(response.emoji) \(response.displayText)\n"
        }
        
        if totalResponses > 0 {
            statusText += "\(acceptedCount) of \(totalResponses) people are going"
        }
        
        responseStatusLabel.text = statusText
        responseStatusLabel.isHidden = statusText.isEmpty
        
        // Update button states
        if let response = currentResponse {
            acceptButton.alpha = response == .accepted ? 1.0 : 0.6
            declineButton.alpha = response == .declined ? 1.0 : 0.6
        } else {
            acceptButton.alpha = 1.0
            declineButton.alpha = 1.0
        }
    }
    
    // MARK: - Actions
    @objc private func acceptButtonTapped() {
        delegate?.eventResponseViewController(self, didRespondToEvent: event, with: .accepted)
    }
    
    @objc private func declineButtonTapped() {
        delegate?.eventResponseViewController(self, didRespondToEvent: event, with: .declined)
    }
} 

