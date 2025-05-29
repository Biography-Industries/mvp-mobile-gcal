//
//  CreateScheduleSelectionViewController.swift
//  CalendarInviteExtension
//
//  Created by Dezmond Blair
//

import UIKit
import EventKit

class CreateScheduleSelectionViewController: UIViewController {
    
    // MARK: - Properties
    private let eventStore: EKEventStore
    private weak var delegate: CreateScheduleSelectionViewControllerDelegate?
    private var suggestedTimeSlots: [TimeSlot] = []
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerLabel = UILabel()
    private let titleTextField = UITextField()
    private let descriptionTextView = UITextView()
    private let durationControl = UISegmentedControl()
    private let preferredTimeStackView = UIStackView()
    private let timePreferenceLabel = UILabel()
    private let startTimeButton = UIButton(type: .system)
    private let endTimeButton = UIButton(type: .system)
    private let daySelectionStackView = UIStackView()
    private let daySelectionLabel = UILabel()
    private let dayButtons: [UIButton] = (0..<7).map { _ in UIButton(type: .system) }
    private let suggestedTimesLabel = UILabel()
    private let suggestedTimesStackView = UIStackView()
    private let refreshSuggestionsButton = UIButton(type: .system)
    private let sendInviteButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - Configuration
    private var eventDuration: TimeInterval = 60 * 60 // 1 hour default
    private var preferredStartTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 14 // 2 PM
        return calendar.date(from: components) ?? Date()
    }()
    private var preferredEndTime: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18 // 6 PM
        return calendar.date(from: components) ?? Date()
    }()
    private var selectedDays: Set<Int> = [0, 6] // Saturday and Sunday
    
    // MARK: - Initialization
    init(eventStore: EKEventStore, delegate: CreateScheduleSelectionViewControllerDelegate?) {
        self.eventStore = eventStore
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
        generateInitialSuggestions()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupHeaderSection()
        setupEventDetailsSection()
        setupTimePreferencesSection()
        setupDaySelectionSection()
        setupSuggestedTimesSection()
        setupActionButtons()
        
        // Add all sections to content view
        [headerLabel, titleTextField, descriptionTextView, timePreferenceLabel, preferredTimeStackView,
         daySelectionLabel, daySelectionStackView, suggestedTimesLabel, suggestedTimesStackView,
         refreshSuggestionsButton, sendInviteButton, cancelButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func setupHeaderSection() {
        headerLabel.text = "Create Schedule Selection"
        headerLabel.font = .boldSystemFont(ofSize: 24)
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
    }
    
    private func setupEventDetailsSection() {
        titleTextField.placeholder = "Event title (e.g., 'Weekend Hike')"
        titleTextField.borderStyle = .roundedRect
        titleTextField.font = .systemFont(ofSize: 16)
        titleTextField.returnKeyType = .next
        titleTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        descriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.cornerRadius = 8
        descriptionTextView.font = .systemFont(ofSize: 16)
        descriptionTextView.text = "Add event description..."
        descriptionTextView.textColor = .placeholderText
        descriptionTextView.delegate = self
    }
    
    private func setupTimePreferencesSection() {
        timePreferenceLabel.text = "Preferred Time Range"
        timePreferenceLabel.font = .boldSystemFont(ofSize: 18)
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        startTimeButton.setTitle("Start: \(timeFormatter.string(from: preferredStartTime))", for: .normal)
        startTimeButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        startTimeButton.layer.cornerRadius = 8
        startTimeButton.addTarget(self, action: #selector(selectStartTime), for: .touchUpInside)
        
        endTimeButton.setTitle("End: \(timeFormatter.string(from: preferredEndTime))", for: .normal)
        endTimeButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        endTimeButton.layer.cornerRadius = 8
        endTimeButton.addTarget(self, action: #selector(selectEndTime), for: .touchUpInside)
        
        preferredTimeStackView.axis = .horizontal
        preferredTimeStackView.spacing = 12
        preferredTimeStackView.distribution = .fillEqually
        [startTimeButton, endTimeButton].forEach {
            preferredTimeStackView.addArrangedSubview($0)
        }
    }
    
    private func setupDaySelectionSection() {
        daySelectionLabel.text = "Preferred Days"
        daySelectionLabel.font = .boldSystemFont(ofSize: 18)
        
        daySelectionStackView.axis = .horizontal
        daySelectionStackView.spacing = 8
        daySelectionStackView.distribution = .fillEqually
        
        let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
        let fullDayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        
        for (index, button) in dayButtons.enumerated() {
            button.setTitle(dayNames[index], for: .normal)
            button.layer.cornerRadius = 20
            button.tag = index
            button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
            button.accessibilityLabel = fullDayNames[index]
            updateDayButtonAppearance(button, isSelected: selectedDays.contains(index))
            daySelectionStackView.addArrangedSubview(button)
        }
    }
    
    private func setupSuggestedTimesSection() {
        suggestedTimesLabel.text = "Suggested Time Options"
        suggestedTimesLabel.font = .boldSystemFont(ofSize: 18)
        
        suggestedTimesStackView.axis = .vertical
        suggestedTimesStackView.spacing = 12
        
        refreshSuggestionsButton.setTitle("🔄 Refresh Suggestions", for: .normal)
        refreshSuggestionsButton.backgroundColor = .systemOrange
        refreshSuggestionsButton.setTitleColor(.white, for: .normal)
        refreshSuggestionsButton.layer.cornerRadius = 8
        refreshSuggestionsButton.addTarget(self, action: #selector(refreshSuggestionsTapped), for: .touchUpInside)
    }
    
    private func setupActionButtons() {
        sendInviteButton.setTitle("GO AHEAD - Send Invite", for: .normal)
        sendInviteButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        sendInviteButton.backgroundColor = .systemGreen
        sendInviteButton.setTitleColor(.white, for: .normal)
        sendInviteButton.layer.cornerRadius = 8
        sendInviteButton.addTarget(self, action: #selector(sendInviteTapped), for: .touchUpInside)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        updateSendButtonState()
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
            
            // Header
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Title field
            titleTextField.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 24),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Description
            descriptionTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 80),
            
            // Time preferences
            timePreferenceLabel.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 24),
            timePreferenceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timePreferenceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            preferredTimeStackView.topAnchor.constraint(equalTo: timePreferenceLabel.bottomAnchor, constant: 12),
            preferredTimeStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            preferredTimeStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            preferredTimeStackView.heightAnchor.constraint(equalToConstant: 44),
            
            // Day selection
            daySelectionLabel.topAnchor.constraint(equalTo: preferredTimeStackView.bottomAnchor, constant: 24),
            daySelectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            daySelectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            daySelectionStackView.topAnchor.constraint(equalTo: daySelectionLabel.bottomAnchor, constant: 12),
            daySelectionStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            daySelectionStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            daySelectionStackView.heightAnchor.constraint(equalToConstant: 40),
            
            // Suggested times
            suggestedTimesLabel.topAnchor.constraint(equalTo: daySelectionStackView.bottomAnchor, constant: 24),
            suggestedTimesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            suggestedTimesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            suggestedTimesStackView.topAnchor.constraint(equalTo: suggestedTimesLabel.bottomAnchor, constant: 12),
            suggestedTimesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            suggestedTimesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            refreshSuggestionsButton.topAnchor.constraint(equalTo: suggestedTimesStackView.bottomAnchor, constant: 16),
            refreshSuggestionsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            refreshSuggestionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            refreshSuggestionsButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Action buttons
            sendInviteButton.topAnchor.constraint(equalTo: refreshSuggestionsButton.bottomAnchor, constant: 32),
            sendInviteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sendInviteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sendInviteButton.heightAnchor.constraint(equalToConstant: 56),
            
            cancelButton.topAnchor.constraint(equalTo: sendInviteButton.bottomAnchor, constant: 16),
            cancelButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    // MARK: - Time Slot Generation
    private func generateInitialSuggestions() {
        generateSuggestedTimeSlots()
    }
    
    private func generateSuggestedTimeSlots() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var suggestions: [TimeSlot] = []
        
        // Look ahead for the next 2 weeks
        for dayOffset in 0..<14 {
            guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: checkDate) - 1 // 0 = Sunday
            
            // Only consider selected days
            if selectedDays.contains(weekday) {
                // Generate time slots for this day
                let timeSlots = generateTimeSlotsForDay(checkDate)
                suggestions.append(contentsOf: timeSlots)
            }
        }
        
        // Filter out conflicting times with existing calendar events
        filterOutConflictingTimes(&suggestions)
        
        // Sort by date and take top 5
        suggestedTimeSlots = suggestions
            .sorted { $0.startDate < $1.startDate }
            .prefix(5)
            .map { $0 }
        
        updateSuggestedTimesUI()
    }
    
    private func generateTimeSlotsForDay(_ date: Date) -> [TimeSlot] {
        let calendar = Calendar.current
        var timeSlots: [TimeSlot] = []
        
        // Get preferred time range for this day
        let startComponents = calendar.dateComponents([.hour, .minute], from: preferredStartTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: preferredEndTime)
        
        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute else { return [] }
        
        // Create start and end times for this specific date
        var dayStartComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dayStartComponents.hour = startHour
        dayStartComponents.minute = startMinute
        
        var dayEndComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dayEndComponents.hour = endHour
        dayEndComponents.minute = endMinute
        
        guard let dayStart = calendar.date(from: dayStartComponents),
              let dayEnd = calendar.date(from: dayEndComponents) else { return [] }
        
        // Generate slots every hour within the preferred time range
        var currentTime = dayStart
        while currentTime < dayEnd {
            let slotEnd = currentTime.addingTimeInterval(eventDuration)
            if slotEnd <= dayEnd {
                let timeSlot = TimeSlot(startDate: currentTime, endDate: slotEnd)
                timeSlots.append(timeSlot)
            }
            currentTime = currentTime.addingTimeInterval(60 * 60) // 1 hour intervals
        }
        
        return timeSlots
    }
    
    private func filterOutConflictingTimes(_ timeSlots: inout [TimeSlot]) {
        // Get calendar events for the time range
        let calendar = Calendar.current
        let startDate = timeSlots.first?.startDate ?? Date()
        let endDate = timeSlots.last?.endDate ?? Date()
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let existingEvents = eventStore.events(matching: predicate)
        
        // Filter out slots that conflict with existing events
        timeSlots = timeSlots.filter { timeSlot in
            return !existingEvents.contains { event in
                return timeSlot.startDate < event.endDate && timeSlot.endDate > event.startDate
            }
        }
    }
    
    private func updateSuggestedTimesUI() {
        // Clear existing suggestions
        suggestedTimesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if suggestedTimeSlots.isEmpty {
            let noSuggestionsLabel = UILabel()
            noSuggestionsLabel.text = "No available times found. Try adjusting your preferences."
            noSuggestionsLabel.font = .systemFont(ofSize: 16)
            noSuggestionsLabel.textColor = .secondaryLabel
            noSuggestionsLabel.textAlignment = .center
            noSuggestionsLabel.numberOfLines = 0
            suggestedTimesStackView.addArrangedSubview(noSuggestionsLabel)
        } else {
            for timeSlot in suggestedTimeSlots {
                let suggestionView = createSuggestionView(for: timeSlot)
                suggestedTimesStackView.addArrangedSubview(suggestionView)
            }
        }
        
        updateSendButtonState()
    }
    
    private func createSuggestionView(for timeSlot: TimeSlot) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8
        
        let timeLabel = UILabel()
        timeLabel.text = timeSlot.formattedTimeRange
        timeLabel.font = .systemFont(ofSize: 16)
        
        let iconImageView = UIImageView(image: UIImage(systemName: "calendar"))
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        
        [timeLabel, iconImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 50),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            timeLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            timeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        return containerView
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange() {
        updateSendButtonState()
    }
    
    @objc private func selectStartTime() {
        presentTimePicker(for: preferredStartTime, title: "Select Start Time") { [weak self] selectedTime in
            self?.preferredStartTime = selectedTime
            self?.updateTimeButtons()
            self?.generateSuggestedTimeSlots()
        }
    }
    
    @objc private func selectEndTime() {
        presentTimePicker(for: preferredEndTime, title: "Select End Time") { [weak self] selectedTime in
            self?.preferredEndTime = selectedTime
            self?.updateTimeButtons()
            self?.generateSuggestedTimeSlots()
        }
    }
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        let day = sender.tag
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
        
        updateDayButtonAppearance(sender, isSelected: selectedDays.contains(day))
        generateSuggestedTimeSlots()
    }
    
    @objc private func refreshSuggestionsTapped() {
        generateSuggestedTimeSlots()
    }
    
    @objc private func sendInviteTapped() {
        guard let title = titleTextField.text, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Missing Title", message: "Please enter a title for the event.")
            return
        }
        
        guard !suggestedTimeSlots.isEmpty else {
            showAlert(title: "No Time Suggestions", message: "Please adjust your preferences to generate time suggestions.")
            return
        }
        
        let description = (descriptionTextView.textColor == .placeholderText) ? nil : descriptionTextView.text
        
        let scheduleEvent = ScheduleSelectionEvent(
            title: title,
            description: description,
            organizerName: "You",
            suggestedTimeSlots: suggestedTimeSlots
        )
        
        delegate?.createScheduleSelectionViewController(self, didCreateScheduleEvent: scheduleEvent)
    }
    
    @objc private func cancelTapped() {
        delegate?.createScheduleSelectionViewControllerDidCancel(self)
    }
    
    // MARK: - Helper Methods
    private func updateTimeButtons() {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        startTimeButton.setTitle("Start: \(timeFormatter.string(from: preferredStartTime))", for: .normal)
        endTimeButton.setTitle("End: \(timeFormatter.string(from: preferredEndTime))", for: .normal)
    }
    
    private func updateDayButtonAppearance(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = .systemGray5
            button.setTitleColor(.label, for: .normal)
        }
    }
    
    private func updateSendButtonState() {
        let hasTitle = !(titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasSuggestions = !suggestedTimeSlots.isEmpty
        
        sendInviteButton.isEnabled = hasTitle && hasSuggestions
        sendInviteButton.alpha = sendInviteButton.isEnabled ? 1.0 : 0.6
    }
    
    private func presentTimePicker(for initialTime: Date, title: String, completion: @escaping (Date) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.date = initialTime
        
        alert.setValue(datePicker, forKey: "contentViewController")
        
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            completion(datePicker.date)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension CreateScheduleSelectionViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add event description..."
            textView.textColor = .placeholderText
        }
    }
}

// MARK: - Delegate Protocol
protocol CreateScheduleSelectionViewControllerDelegate: AnyObject {
    func createScheduleSelectionViewController(_ controller: CreateScheduleSelectionViewController, didCreateScheduleEvent event: ScheduleSelectionEvent)
    func createScheduleSelectionViewControllerDidCancel(_ controller: CreateScheduleSelectionViewController)
} 
