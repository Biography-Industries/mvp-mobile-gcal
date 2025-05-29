//
//  ScheduleSelectionTapToExpandViewController.swift
//  CalendarInviteExtension
//
//  Created by Dezmond Blair
//

import UIKit
import Messages

class ScheduleSelectionTapToExpandViewController: UIViewController {
    
    // MARK: - Properties
    private let scheduleEvent: ScheduleSelectionEvent
    
    // MARK: - UI Elements
    private let containerView = UIView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let organizerLabel = UILabel()
    private let summaryLabel = UILabel()
    private let optionsCountLabel = UILabel()
    private let responseCountLabel = UILabel()
    private let tapToExpandLabel = UILabel()
    private let expandIconImageView = UIImageView()
    
    // MARK: - Initialization
    init(scheduleEvent: ScheduleSelectionEvent) {
        self.scheduleEvent = scheduleEvent
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
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Configure header view
        headerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure labels
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .left
        
        organizerLabel.font = .systemFont(ofSize: 12)
        organizerLabel.textColor = .secondaryLabel
        organizerLabel.textAlignment = .left
        
        summaryLabel.font = .systemFont(ofSize: 14)
        summaryLabel.textColor = .label
        summaryLabel.numberOfLines = 2
        summaryLabel.textAlignment = .left
        
        optionsCountLabel.font = .boldSystemFont(ofSize: 14)
        optionsCountLabel.textColor = .systemBlue
        optionsCountLabel.textAlignment = .center
        
        responseCountLabel.font = .systemFont(ofSize: 12)
        responseCountLabel.textColor = .tertiaryLabel
        responseCountLabel.textAlignment = .center
        
        tapToExpandLabel.font = .systemFont(ofSize: 12)
        tapToExpandLabel.textColor = .systemBlue
        tapToExpandLabel.textAlignment = .center
        tapToExpandLabel.text = "Tap to choose your availability"
        
        // Configure expand icon
        expandIconImageView.image = UIImage(systemName: "chevron.up.circle.fill")
        expandIconImageView.tintColor = .systemBlue
        expandIconImageView.contentMode = .scaleAspectFit
        
        // Add subviews
        [headerView, titleLabel, organizerLabel, summaryLabel, optionsCountLabel, 
         responseCountLabel, tapToExpandLabel, expandIconImageView].forEach {
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
            
            // Header view
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 4),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: expandIconImageView.leadingAnchor, constant: -8),
            
            // Organizer label
            organizerLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            organizerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            organizerLabel.trailingAnchor.constraint(equalTo: expandIconImageView.leadingAnchor, constant: -8),
            
            // Summary label (description)
            summaryLabel.topAnchor.constraint(equalTo: organizerLabel.bottomAnchor, constant: 8),
            summaryLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            summaryLabel.trailingAnchor.constraint(equalTo: expandIconImageView.leadingAnchor, constant: -8),
            
            // Options count label
            optionsCountLabel.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 12),
            optionsCountLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            optionsCountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Response count label
            responseCountLabel.topAnchor.constraint(equalTo: optionsCountLabel.bottomAnchor, constant: 4),
            responseCountLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            responseCountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Tap to expand label
            tapToExpandLabel.topAnchor.constraint(equalTo: responseCountLabel.bottomAnchor, constant: 8),
            tapToExpandLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            tapToExpandLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            tapToExpandLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            // Expand icon
            expandIconImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            expandIconImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            expandIconImageView.widthAnchor.constraint(equalToConstant: 24),
            expandIconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func configureContent() {
        titleLabel.text = scheduleEvent.title
        organizerLabel.text = "Organized by \(scheduleEvent.organizerName)"
        
        if let description = scheduleEvent.description, !description.isEmpty {
            summaryLabel.text = description
            summaryLabel.isHidden = false
        } else {
            summaryLabel.text = "Choose from \(scheduleEvent.suggestedTimeSlots.count) time options"
            summaryLabel.isHidden = false
        }
        
        // Format options count
        let optionCount = scheduleEvent.suggestedTimeSlots.count
        optionsCountLabel.text = "\(optionCount) time option\(optionCount == 1 ? "" : "s")"
        
        // Format response count
        let responseCount = scheduleEvent.participantResponses.count
        if responseCount > 0 {
            responseCountLabel.text = "\(responseCount) response\(responseCount == 1 ? "" : "s") so far"
            responseCountLabel.isHidden = false
        } else {
            responseCountLabel.text = "Be the first to respond!"
            responseCountLabel.isHidden = false
        }
    }
    
    // MARK: - Content Size Support
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Calculate preferred content size for transcript presentation
        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = view.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        
        // Ensure reasonable height bounds for transcript mode
        let clampedHeight = min(max(size.height, 120), 180)
        preferredContentSize = CGSize(width: size.width, height: clampedHeight)
    }
} 
