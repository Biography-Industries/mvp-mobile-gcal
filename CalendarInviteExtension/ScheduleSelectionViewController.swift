//
//  ScheduleSelectionViewController.swift
//  CalendarInviteExtension
//
//  Created by Dezmond Blair
//

import UIKit
import Messages

class ScheduleSelectionViewController: UIViewController {
    
    // MARK: - Properties
    private var scheduleEvent: ScheduleSelectionEvent
    private weak var delegate: ScheduleSelectionViewControllerDelegate?
    private let participantID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    private var selectedTimeSlots: Set<UUID> = []
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let organizerLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let instructionLabel = UILabel()
    private let timeSlotsStackView = UIStackView()
    private let actionButtonsStackView = UIStackView()
    private let confirmButton = UIButton(type: .system)
    private let noneWorkButton = UIButton(type: .system)
    private let suggestTimeButton = UIButton(type: .system)
    private let responseCountLabel = UILabel()
    
    // MARK: - Initialization
    init(scheduleEvent: ScheduleSelectionEvent, delegate: ScheduleSelectionViewControllerDelegate?) {
        self.scheduleEvent = scheduleEvent
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
        updateSelectionState()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure header
        headerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        headerView.layer.cornerRadius = 12
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure labels
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        organizerLabel.font = .systemFont(ofSize: 14)
        organizerLabel.textColor = .secondaryLabel
        organizerLabel.textAlignment = .center
        
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = .label
        
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.text = "Select your preferred time(s) for this event:"
        
        responseCountLabel.font = .systemFont(ofSize: 12)
        responseCountLabel.textColor = .tertiaryLabel
        responseCountLabel.textAlignment = .center
        
        // Configure time slots stack view
        timeSlotsStackView.axis = .vertical
        timeSlotsStackView.spacing = 12
        timeSlotsStackView.distribution = .fill
        
        // Configure action buttons
        configureActionButtons()
        
        // Add header elements
        [titleLabel, organizerLabel, descriptionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }
        
        // Add all elements to content view
        [headerView, instructionLabel, timeSlotsStackView, responseCountLabel, actionButtonsStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func configureActionButtons() {
        // Confirm selection button
        confirmButton.setTitle("Confirm Selection", for: .normal)
        confirmButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 8
        confirmButton.addTarget(self, action: #selector(confirmSelectionTapped), for: .touchUpInside)
        
        // None work button
        noneWorkButton.setTitle("None of these work", for: .normal)
        noneWorkButton.titleLabel?.font = .systemFont(ofSize: 16)
        noneWorkButton.backgroundColor = .systemOrange
        noneWorkButton.setTitleColor(.white, for: .normal)
        noneWorkButton.layer.cornerRadius = 8
        noneWorkButton.addTarget(self, action: #selector(noneWorkTapped), for: .touchUpInside)
        
        // Suggest alternative time button
        suggestTimeButton.setTitle("Suggest Different Times", for: .normal)
        suggestTimeButton.titleLabel?.font = .systemFont(ofSize: 16)
        suggestTimeButton.backgroundColor = .systemGreen
        suggestTimeButton.setTitleColor(.white, for: .normal)
        suggestTimeButton.layer.cornerRadius = 8
        suggestTimeButton.addTarget(self, action: #selector(suggestTimeTapped), for: .touchUpInside)
        
        // Configure action buttons stack view
        actionButtonsStackView.axis = .vertical
        actionButtonsStackView.spacing = 12
        actionButtonsStackView.distribution = .fillEqually
        
        [confirmButton, noneWorkButton, suggestTimeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            actionButtonsStackView.addArrangedSubview($0)
        }
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
            
            // Header view constraints
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Header elements
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            organizerLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            organizerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            organizerLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: organizerLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            // Instruction label
            instructionLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            instructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Time slots stack view
            timeSlotsStackView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            timeSlotsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeSlotsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Response count label
            responseCountLabel.topAnchor.constraint(equalTo: timeSlotsStackView.bottomAnchor, constant: 16),
            responseCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            responseCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Action buttons stack view
            actionButtonsStackView.topAnchor.constraint(equalTo: responseCountLabel.bottomAnchor, constant: 24),
            actionButtonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            actionButtonsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionButtonsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Button heights
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            noneWorkButton.heightAnchor.constraint(equalToConstant: 44),
            suggestTimeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func configureContent() {
        titleLabel.text = scheduleEvent.title
        organizerLabel.text = "Organized by \(scheduleEvent.organizerName)"
        
        if let description = scheduleEvent.description, !description.isEmpty {
            descriptionLabel.text = description
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }
        
        createTimeSlotViews()
        updateResponseCount()
    }
    
    private func createTimeSlotViews() {
        // Clear existing views
        timeSlotsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for timeSlot in scheduleEvent.suggestedTimeSlots {
            let timeSlotView = createTimeSlotView(for: timeSlot)
            timeSlotsStackView.addArrangedSubview(timeSlotView)
        }
    }
    
    private func createTimeSlotView(for timeSlot: TimeSlot) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        
        let timeLabel = UILabel()
        timeLabel.text = timeSlot.formattedTimeRange
        timeLabel.font = .boldSystemFont(ofSize: 16)
        timeLabel.textAlignment = .left
        
        let selectionCountLabel = UILabel()
        let count = timeSlot.selectionCount
        selectionCountLabel.text = count == 0 ? "No responses yet" : "\(count) selected"
        selectionCountLabel.font = .systemFont(ofSize: 14)
        selectionCountLabel.textColor = .secondaryLabel
        selectionCountLabel.textAlignment = .right
        
        let checkmarkImageView = UIImageView()
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.tintColor = .systemBlue
        
        [timeLabel, selectionCountLabel, checkmarkImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 60),
            
            timeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            selectionCountLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            selectionCountLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            checkmarkImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkmarkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Update selection state
        updateTimeSlotView(containerView, timeSlot: timeSlot, checkmarkImageView: checkmarkImageView)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(timeSlotTapped(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.tag = scheduleEvent.suggestedTimeSlots.firstIndex(of: timeSlot) ?? 0
        
        return containerView
    }
    
    private func updateTimeSlotView(_ containerView: UIView, timeSlot: TimeSlot, checkmarkImageView: UIImageView) {
        let isSelected = selectedTimeSlots.contains(timeSlot.id)
        
        if isSelected {
            containerView.layer.borderColor = UIColor.systemBlue.cgColor
            containerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
            containerView.backgroundColor = .systemBackground
            checkmarkImageView.image = UIImage(systemName: "circle")
        }
        
        // Add selection animation
        UIView.animate(withDuration: 0.2) {
            containerView.transform = isSelected ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
        }
    }
    
    private func updateSelectionState() {
        confirmButton.isEnabled = !selectedTimeSlots.isEmpty
        confirmButton.alpha = selectedTimeSlots.isEmpty ? 0.6 : 1.0
        
        let selectionText = selectedTimeSlots.isEmpty ? "Select at least one time" : "\(selectedTimeSlots.count) time(s) selected"
        confirmButton.setTitle(selectionText.isEmpty ? "Confirm Selection" : selectionText, for: .normal)
    }
    
    private func updateResponseCount() {
        let totalResponses = scheduleEvent.participantResponses.count
        if totalResponses > 0 {
            responseCountLabel.text = "\(totalResponses) people have responded"
            responseCountLabel.isHidden = false
        } else {
            responseCountLabel.text = "Be the first to respond!"
            responseCountLabel.isHidden = false
        }
    }
    
    // MARK: - Actions
    @objc private func timeSlotTapped(_ gesture: UITapGestureRecognizer) {
        guard let containerView = gesture.view,
              let timeSlot = scheduleEvent.suggestedTimeSlots[safe: containerView.tag] else { return }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Toggle selection
        if selectedTimeSlots.contains(timeSlot.id) {
            selectedTimeSlots.remove(timeSlot.id)
        } else {
            selectedTimeSlots.insert(timeSlot.id)
        }
        
        // Update UI
        if let checkmarkImageView = containerView.subviews.compactMap({ $0 as? UIImageView }).first {
            updateTimeSlotView(containerView, timeSlot: timeSlot, checkmarkImageView: checkmarkImageView)
        }
        
        updateSelectionState()
    }
    
    @objc private func confirmSelectionTapped() {
        guard !selectedTimeSlots.isEmpty else { return }
        
        let response = ScheduleSelectionEvent.ParticipantResponse(
            participantID: participantID,
            selectedTimeSlots: Array(selectedTimeSlots),
            customAvailability: nil,
            responseStatus: .selectedSuggested,
            responseDate: Date()
        )
        
        delegate?.scheduleSelectionViewController(self, didSelectTimeSlots: response)
    }
    
    @objc private func noneWorkTapped() {
        let response = ScheduleSelectionEvent.ParticipantResponse(
            participantID: participantID,
            selectedTimeSlots: [],
            customAvailability: nil,
            responseStatus: .noneWork,
            responseDate: Date()
        )
        
        delegate?.scheduleSelectionViewController(self, didSelectNoneWork: response)
    }
    
    @objc private func suggestTimeTapped() {
        delegate?.scheduleSelectionViewController(self, didRequestCustomAvailability: scheduleEvent)
    }
}

// MARK: - Array Safe Subscript
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Delegate Protocol
protocol ScheduleSelectionViewControllerDelegate: AnyObject {
    func scheduleSelectionViewController(_ controller: ScheduleSelectionViewController, didSelectTimeSlots response: ScheduleSelectionEvent.ParticipantResponse)
    func scheduleSelectionViewController(_ controller: ScheduleSelectionViewController, didSelectNoneWork response: ScheduleSelectionEvent.ParticipantResponse)
    func scheduleSelectionViewController(_ controller: ScheduleSelectionViewController, didRequestCustomAvailability event: ScheduleSelectionEvent)
} 
