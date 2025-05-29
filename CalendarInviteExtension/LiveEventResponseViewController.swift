//
//  LiveEventResponseViewController.swift
//  CalendarInviteExtension
//
//  Created by Dezmond Blair
//

import UIKit
import Messages

class LiveEventResponseViewController: UIViewController {
    
    // MARK: - Properties
    private let event: CalendarEvent
    private let participantID: String
    private weak var delegate: LiveEventResponseViewControllerDelegate?
    
    // MARK: - UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let locationLabel = UILabel()
    private let responseStackView = UIStackView()
    private let acceptButton = UIButton(type: .system)
    private let declineButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let responseCountLabel = UILabel()
    
    // MARK: - Initialization
    init(event: CalendarEvent, participantID: String, delegate: LiveEventResponseViewControllerDelegate?) {
        self.event = event
        self.participantID = participantID
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
        view.backgroundColor = .clear
        
        // Configure container view
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Configure labels
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .left
        
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .secondaryLabel
        dateLabel.numberOfLines = 1
        
        locationLabel.font = .systemFont(ofSize: 12)
        locationLabel.textColor = .secondaryLabel
        locationLabel.numberOfLines = 1
        
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        
        responseCountLabel.font = .systemFont(ofSize: 11)
        responseCountLabel.textColor = .tertiaryLabel
        responseCountLabel.textAlignment = .center
        
        // Configure buttons for live layout
        acceptButton.setTitle("✅ Yes", for: .normal)
        acceptButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        acceptButton.backgroundColor = .systemGreen
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.layer.cornerRadius = 6
        acceptButton.addTarget(self, action: #selector(acceptButtonTapped), for: .touchUpInside)
        
        declineButton.setTitle("❌ No", for: .normal)
        declineButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        declineButton.backgroundColor = .systemRed
        declineButton.setTitleColor(.white, for: .normal)
        declineButton.layer.cornerRadius = 6
        declineButton.addTarget(self, action: #selector(declineButtonTapped), for: .touchUpInside)
        
        // Configure response stack view
        responseStackView.axis = .horizontal
        responseStackView.distribution = .fillEqually
        responseStackView.spacing = 8
        responseStackView.addArrangedSubview(acceptButton)
        responseStackView.addArrangedSubview(declineButton)
        
        // Add all elements to container view
        [titleLabel, dateLabel, locationLabel, responseStackView, statusLabel, responseCountLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view constraints
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Date label
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Location label
            locationLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),
            locationLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            locationLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Response stack view
            responseStackView.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 12),
            responseStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            responseStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            responseStackView.heightAnchor.constraint(equalToConstant: 36),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: responseStackView.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Response count label
            responseCountLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 2),
            responseCountLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            responseCountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            responseCountLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    private func configureContent() {
        titleLabel.text = event.title
        
        // Format date for compact display
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        dateLabel.text = "📅 \(formatter.string(from: event.startDate))"
        
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
        
        // Update status label
        if let response = currentResponse {
            statusLabel.text = "Your response: \(response.emoji) \(response.displayText)"
            statusLabel.isHidden = false
        } else {
            statusLabel.text = "Tap to respond"
            statusLabel.isHidden = false
        }
        
        // Update response count
        if totalResponses > 0 {
            responseCountLabel.text = "\(acceptedCount) of \(totalResponses) going"
            responseCountLabel.isHidden = false
        } else {
            responseCountLabel.isHidden = true
        }
        
        // Update button states based on current response
        updateButtonStates(currentResponse: currentResponse)
    }
    
    private func updateButtonStates(currentResponse: CalendarEvent.EventResponse?) {
        if let response = currentResponse {
            // Show selected state
            acceptButton.alpha = response == .accepted ? 1.0 : 0.5
            declineButton.alpha = response == .declined ? 1.0 : 0.5
            
            // Update button styles for selected state
            if response == .accepted {
                acceptButton.backgroundColor = .systemGreen
                acceptButton.setTitle("✅ Going", for: .normal)
            } else {
                acceptButton.backgroundColor = .systemGreen.withAlphaComponent(0.3)
                acceptButton.setTitle("✅ Yes", for: .normal)
            }
            
            if response == .declined {
                declineButton.backgroundColor = .systemRed
                declineButton.setTitle("❌ Can't go", for: .normal)
            } else {
                declineButton.backgroundColor = .systemRed.withAlphaComponent(0.3)
                declineButton.setTitle("❌ No", for: .normal)
            }
        } else {
            // Default state
            acceptButton.alpha = 1.0
            declineButton.alpha = 1.0
            acceptButton.backgroundColor = .systemGreen
            declineButton.backgroundColor = .systemRed
            acceptButton.setTitle("✅ Yes", for: .normal)
            declineButton.setTitle("❌ No", for: .normal)
        }
    }
    
    // MARK: - Actions
    @objc private func acceptButtonTapped() {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Animate button press
        animateButtonPress(acceptButton) {
            self.delegate?.liveEventResponseViewController(self, didRespondToEvent: self.event, with: .accepted)
        }
    }
    
    @objc private func declineButtonTapped() {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Animate button press
        animateButtonPress(declineButton) {
            self.delegate?.liveEventResponseViewController(self, didRespondToEvent: self.event, with: .declined)
        }
    }
    
    private func animateButtonPress(_ button: UIButton, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                button.transform = .identity
            }) { _ in
                completion()
            }
        }
    }
}

// MARK: - Content Size Support
extension LiveEventResponseViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Calculate the preferred content size for the live layout
        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = view.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        preferredContentSize = size
    }
} 
