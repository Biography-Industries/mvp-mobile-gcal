//
//  CreateEventViewController.swift
//  CalendarInviteExtension
//
//  Created by Calendar Invite Extension
//

import UIKit
import EventKit

class CreateEventViewController: UIViewController {
    
    // MARK: - Properties
    private let eventStore: EKEventStore
    private weak var delegate: CreateEventViewControllerDelegate?
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleTextField = UITextField()
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let locationTextField = UITextField()
    private let notesTextView = UITextView()
    private let createButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - Initialization
    init(eventStore: EKEventStore, delegate: CreateEventViewControllerDelegate?) {
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
        setupDefaultValues()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure title text field
        titleTextField.placeholder = "Event Title"
        titleTextField.borderStyle = .roundedRect
        titleTextField.font = .systemFont(ofSize: 16)
        titleTextField.delegate = self
        
        // Configure date pickers
        startDatePicker.datePickerMode = .dateAndTime
        startDatePicker.preferredDatePickerStyle = .compact
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        
        endDatePicker.datePickerMode = .dateAndTime
        endDatePicker.preferredDatePickerStyle = .compact
        endDatePicker.addTarget(self, action: #selector(endDateChanged), for: .valueChanged)
        
        // Configure location text field
        locationTextField.placeholder = "Location (optional)"
        locationTextField.borderStyle = .roundedRect
        locationTextField.font = .systemFont(ofSize: 16)
        locationTextField.delegate = self
        
        // Configure notes text view
        notesTextView.layer.borderColor = UIColor.systemGray4.cgColor
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.cornerRadius = 8
        notesTextView.font = .systemFont(ofSize: 16)
        notesTextView.delegate = self
        
        // Configure buttons
        createButton.setTitle("Send Invitation", for: .normal)
        createButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        createButton.backgroundColor = .systemBlue
        createButton.setTitleColor(.white, for: .normal)
        createButton.layer.cornerRadius = 8
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        // Create labels
        let titleLabel = createLabel(text: "Event Title")
        let startDateLabel = createLabel(text: "Start Date & Time")
        let endDateLabel = createLabel(text: "End Date & Time")
        let locationLabel = createLabel(text: "Location")
        let notesLabel = createLabel(text: "Notes")
        
        // Add placeholder text to notes
        let placeholderLabel = UILabel()
        placeholderLabel.text = "Add notes about the event..."
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        notesTextView.addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: notesTextView.topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: notesTextView.leadingAnchor, constant: 5)
        ])
        
        // Store placeholder for later use
        notesTextView.accessibilityLabel = "placeholder"
        
        // Add all elements to content view
        let allElements = [
            titleLabel, titleTextField,
            startDateLabel, startDatePicker,
            endDateLabel, endDatePicker,
            locationLabel, locationTextField,
            notesLabel, notesTextView,
            createButton, cancelButton
        ]
        
        allElements.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        setupConstraints(titleLabel: titleLabel, startDateLabel: startDateLabel, endDateLabel: endDateLabel, locationLabel: locationLabel, notesLabel: notesLabel)
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        return label
    }
    
    private func setupConstraints(titleLabel: UILabel, startDateLabel: UILabel, endDateLabel: UILabel, locationLabel: UILabel, notesLabel: UILabel) {
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
            
            // Title section
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            titleTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Start date section
            startDateLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 24),
            startDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            startDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            startDatePicker.topAnchor.constraint(equalTo: startDateLabel.bottomAnchor, constant: 8),
            startDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            startDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // End date section
            endDateLabel.topAnchor.constraint(equalTo: startDatePicker.bottomAnchor, constant: 24),
            endDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            endDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            endDatePicker.topAnchor.constraint(equalTo: endDateLabel.bottomAnchor, constant: 8),
            endDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            endDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Location section
            locationLabel.topAnchor.constraint(equalTo: endDatePicker.bottomAnchor, constant: 24),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            locationTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            locationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            locationTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Notes section
            notesLabel.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: 24),
            notesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            notesTextView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 8),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            notesTextView.heightAnchor.constraint(equalToConstant: 100),
            
            // Buttons
            createButton.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: 32),
            createButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 16),
            cancelButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupDefaultValues() {
        let now = Date()
        let calendar = Calendar.current
        
        // Set start date to next hour
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        let startDate = calendar.date(bySetting: .minute, value: 0, of: nextHour) ?? nextHour
        startDatePicker.date = startDate
        
        // Set end date to 1 hour after start
        let endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        endDatePicker.date = endDate
        
        updateCreateButtonState()
    }
    
    private func updateCreateButtonState() {
        let hasTitle = !(titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        createButton.isEnabled = hasTitle
        createButton.alpha = hasTitle ? 1.0 : 0.6
    }
    
    // MARK: - Actions
    @objc private func startDateChanged() {
        // Ensure end date is after start date
        if endDatePicker.date <= startDatePicker.date {
            endDatePicker.date = Calendar.current.date(byAdding: .hour, value: 1, to: startDatePicker.date) ?? startDatePicker.date
        }
    }
    
    @objc private func endDateChanged() {
        // Ensure end date is after start date
        if endDatePicker.date <= startDatePicker.date {
            startDatePicker.date = Calendar.current.date(byAdding: .hour, value: -1, to: endDatePicker.date) ?? endDatePicker.date
        }
    }
    
    @objc private func createButtonTapped() {
        guard let title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            showAlert(title: "Missing Title", message: "Please enter a title for the event.")
            return
        }
        
        let event = CalendarEvent(
            title: title,
            startDate: startDatePicker.date,
            endDate: endDatePicker.date,
            location: locationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notesTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            organizerName: "You"
        )
        
        delegate?.createEventViewController(self, didCreateEvent: event)
    }
    
    @objc private func cancelButtonTapped() {
        delegate?.createEventViewControllerDidCancel(self)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension CreateEventViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Update create button state after text changes
        DispatchQueue.main.async {
            self.updateCreateButtonState()
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleTextField {
            locationTextField.becomeFirstResponder()
        } else if textField == locationTextField {
            notesTextView.becomeFirstResponder()
        }
        return true
    }
}

// MARK: - UITextViewDelegate
extension CreateEventViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // Hide/show placeholder
        if let placeholderLabel = textView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
    }
    
    func textViewShouldReturn(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
} 