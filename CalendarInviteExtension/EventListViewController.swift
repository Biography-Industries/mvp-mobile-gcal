//
//  EventListViewController.swift
//  CalendarInviteExtension
//
//  Created by Dezmond Blair
//

import UIKit
import EventKit

class EventListViewController: UIViewController {
    
    // MARK: - Properties
    private weak var delegate: EventListViewControllerDelegate?
    private var eventStore = EKEventStore()
    private var recentEvents: [EKEvent] = []
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let createEventButton = UIButton(type: .system)
    private let createScheduleSelectionButton = UIButton(type: .system)
    private let emptyStateLabel = UILabel()
    
    // MARK: - Initialization
    init(delegate: EventListViewControllerDelegate?) {
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
        loadRecentEvents()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure create event button
        createEventButton.setTitle("📅 Create New Event", for: .normal)
        createEventButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        createEventButton.backgroundColor = .systemBlue
        createEventButton.setTitleColor(.white, for: .normal)
        createEventButton.layer.cornerRadius = 8
        createEventButton.addTarget(self, action: #selector(createEventButtonTapped), for: .touchUpInside)
        
        // Configure create schedule selection button
        createScheduleSelectionButton.setTitle("⏰ Coordinate Schedule", for: .normal)
        createScheduleSelectionButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        createScheduleSelectionButton.backgroundColor = .systemGreen
        createScheduleSelectionButton.setTitleColor(.white, for: .normal)
        createScheduleSelectionButton.layer.cornerRadius = 8
        createScheduleSelectionButton.addTarget(self, action: #selector(createScheduleSelectionButtonTapped), for: .touchUpInside)
        
        // Configure table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EventTableViewCell.self, forCellReuseIdentifier: "EventCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemBackground
        
        // Configure empty state label
        emptyStateLabel.text = "No recent events\nChoose an option above to get started"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = .systemFont(ofSize: 16)
        emptyStateLabel.isHidden = true
        
        // Add subviews
        [createEventButton, createScheduleSelectionButton, tableView, emptyStateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Create event button
            createEventButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            createEventButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createEventButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createEventButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Create schedule selection button
            createScheduleSelectionButton.topAnchor.constraint(equalTo: createEventButton.bottomAnchor, constant: 12),
            createScheduleSelectionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            createScheduleSelectionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createScheduleSelectionButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: createScheduleSelectionButton.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Empty state label
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func loadRecentEvents() {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            guard granted else { return }
            
            DispatchQueue.main.async {
                self?.fetchRecentEvents()
            }
        }
    }
    
    private func fetchRecentEvents() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        // Filter and sort events
        recentEvents = events
            .filter { !$0.isAllDay && $0.startDate > Date() } // Only future events
            .sorted { $0.startDate < $1.startDate }
            .prefix(10) // Limit to 10 events
            .map { $0 }
        
        tableView.reloadData()
        updateEmptyState()
    }
    
    private func updateEmptyState() {
        emptyStateLabel.isHidden = !recentEvents.isEmpty
        tableView.isHidden = recentEvents.isEmpty
    }
    
    // MARK: - Actions
    @objc private func createEventButtonTapped() {
        delegate?.eventListViewController(self, didSelectCreateEvent: ())
    }
    
    @objc private func createScheduleSelectionButtonTapped() {
        delegate?.eventListViewController(self, didSelectCreateScheduleSelection: ())
    }
}

// MARK: - UITableViewDataSource
extension EventListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventTableViewCell
        let event = recentEvents[indexPath.row]
        cell.configure(with: event)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension EventListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let ekEvent = recentEvents[indexPath.row]
        let calendarEvent = CalendarEvent(
            title: ekEvent.title ?? "Untitled Event",
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            location: ekEvent.location,
            notes: ekEvent.notes,
            organizerName: "You"
        )
        
        delegate?.eventListViewController(self, didSelectEvent: calendarEvent)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - EventTableViewCell
class EventTableViewCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let locationLabel = UILabel()
    private let timeLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure labels
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 1
        
        dateLabel.font = .systemFont(ofSize: 14)
        dateLabel.textColor = .secondaryLabel
        
        locationLabel.font = .systemFont(ofSize: 12)
        locationLabel.textColor = .secondaryLabel
        locationLabel.numberOfLines = 1
        
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .systemBlue
        timeLabel.textAlignment = .right
        
        // Add subviews
        [titleLabel, dateLabel, locationLabel, timeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            locationLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            locationLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.widthAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func configure(with event: EKEvent) {
        titleLabel.text = event.title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateLabel.text = dateFormatter.string(from: event.startDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeLabel.text = timeFormatter.string(from: event.startDate)
        
        if let location = event.location, !location.isEmpty {
            locationLabel.text = "📍 \(location)"
            locationLabel.isHidden = false
        } else {
            locationLabel.isHidden = true
        }
    }
} 
