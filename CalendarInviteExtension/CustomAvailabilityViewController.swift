//
//  CustomAvailabilityViewController.swift
//  CalendarInviteExtension
//
//  Created by Dezmond Blair
//

import UIKit

struct AvailabilityBlock: Equatable {
    let timeSlot: TimeSlot
    let gridPosition: GridPosition
    var isSelected: Bool = false
    
    struct GridPosition: Equatable, Hashable {
        let day: Int // 0-6 for days of week
        let timeIndex: Int // Index within the day's time slots
    }
    
    static func == (lhs: AvailabilityBlock, rhs: AvailabilityBlock) -> Bool {
        return lhs.gridPosition == rhs.gridPosition
    }
}

class CustomAvailabilityViewController: UIViewController {
    
    // MARK: - Properties
    private let scheduleEvent: ScheduleSelectionEvent
    private weak var delegate: CustomAvailabilityViewControllerDelegate?
    private var availabilityBlocks: [Int: [AvailabilityBlock]] = [:] // day -> blocks
    private var selectedBlocks: Set<AvailabilityBlock.GridPosition> = []
    private var currentDayIndex = 0
    
    // MARK: - Configuration
    private let numberOfDays = 7 // One week
    private let timeSlotDuration: TimeInterval = 60 * 60 // 1 hour intervals for compact view
    private let startHour = 9 // 9 AM
    private let endHour = 21 // 9 PM (12 hours total)
    private var timeSlotsPerDay: Int {
        return endHour - startHour
    }
    
    // MARK: - UI Elements
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let instructionLabel = UILabel()
    private let dayNavigationView = UIView()
    private let previousDayButton = UIButton(type: .system)
    private let nextDayButton = UIButton(type: .system)
    private let currentDayLabel = UILabel()
    private let dayScrollView = UIScrollView()
    private let dayPageControl = UIPageControl()
    private let timeGridContainer = UIView()
    private let timeLabelsStackView = UIStackView()
    private let actionButtonsStackView = UIStackView()
    private let confirmButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let clearAllButton = UIButton(type: .system)
    
    // MARK: - Gesture Properties
    private var isDragging = false
    private var dragStartSelection: Bool = false
    
    // MARK: - Initialization
    init(scheduleEvent: ScheduleSelectionEvent, delegate: CustomAvailabilityViewControllerDelegate?) {
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
        generateAvailabilityGrid()
        setupGestures()
        showDay(currentDayIndex)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure header
        headerView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        headerView.layer.cornerRadius = 12
        
        titleLabel.text = "Select Your Availability"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = scheduleEvent.title
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        
        instructionLabel.text = "Swipe between days. Tap times when you're available."
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = .secondaryLabel
        
        // Configure day navigation
        setupDayNavigation()
        
        // Configure day scroll view for horizontal scrolling
        dayScrollView.isPagingEnabled = true
        dayScrollView.showsHorizontalScrollIndicator = false
        dayScrollView.showsVerticalScrollIndicator = false
        dayScrollView.delegate = self
        
        // Configure page control
        dayPageControl.numberOfPages = numberOfDays
        dayPageControl.currentPage = currentDayIndex
        dayPageControl.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
        
        // Configure action buttons
        setupActionButtons()
        
        // Add header elements
        [titleLabel, subtitleLabel, instructionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }
        
        // Add all elements to view
        [headerView, dayNavigationView, dayScrollView, dayPageControl, actionButtonsStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func setupDayNavigation() {
        previousDayButton.setTitle("◀", for: .normal)
        previousDayButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        previousDayButton.addTarget(self, action: #selector(previousDayTapped), for: .touchUpInside)
        
        nextDayButton.setTitle("▶", for: .normal)
        nextDayButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        nextDayButton.addTarget(self, action: #selector(nextDayTapped), for: .touchUpInside)
        
        currentDayLabel.font = .boldSystemFont(ofSize: 18)
        currentDayLabel.textAlignment = .center
        
        [previousDayButton, currentDayLabel, nextDayButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            dayNavigationView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            previousDayButton.leadingAnchor.constraint(equalTo: dayNavigationView.leadingAnchor, constant: 16),
            previousDayButton.centerYAnchor.constraint(equalTo: dayNavigationView.centerYAnchor),
            previousDayButton.widthAnchor.constraint(equalToConstant: 44),
            previousDayButton.heightAnchor.constraint(equalToConstant: 44),
            
            currentDayLabel.centerXAnchor.constraint(equalTo: dayNavigationView.centerXAnchor),
            currentDayLabel.centerYAnchor.constraint(equalTo: dayNavigationView.centerYAnchor),
            currentDayLabel.leadingAnchor.constraint(greaterThanOrEqualTo: previousDayButton.trailingAnchor, constant: 8),
            
            nextDayButton.trailingAnchor.constraint(equalTo: dayNavigationView.trailingAnchor, constant: -16),
            nextDayButton.centerYAnchor.constraint(equalTo: dayNavigationView.centerYAnchor),
            nextDayButton.leadingAnchor.constraint(greaterThanOrEqualTo: currentDayLabel.trailingAnchor, constant: 8),
            nextDayButton.widthAnchor.constraint(equalToConstant: 44),
            nextDayButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActionButtons() {
        confirmButton.setTitle("Confirm Availability", for: .normal)
        confirmButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        confirmButton.backgroundColor = .systemGreen
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 8
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.backgroundColor = .systemGray
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        clearAllButton.setTitle("Clear All", for: .normal)
        clearAllButton.titleLabel?.font = .systemFont(ofSize: 16)
        clearAllButton.backgroundColor = .systemRed
        clearAllButton.setTitleColor(.white, for: .normal)
        clearAllButton.layer.cornerRadius = 8
        clearAllButton.addTarget(self, action: #selector(clearAllTapped), for: .touchUpInside)
        
        actionButtonsStackView.axis = .horizontal
        actionButtonsStackView.spacing = 12
        actionButtonsStackView.distribution = .fillEqually
        
        [confirmButton, clearAllButton, cancelButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            actionButtonsStackView.addArrangedSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header view
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Header elements
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            instructionLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
            instructionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            instructionLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            // Day navigation
            dayNavigationView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            dayNavigationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayNavigationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayNavigationView.heightAnchor.constraint(equalToConstant: 50),
            
            // Day scroll view
            dayScrollView.topAnchor.constraint(equalTo: dayNavigationView.bottomAnchor, constant: 8),
            dayScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayScrollView.bottomAnchor.constraint(equalTo: dayPageControl.topAnchor, constant: -8),
            
            // Page control
            dayPageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dayPageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dayPageControl.bottomAnchor.constraint(equalTo: actionButtonsStackView.topAnchor, constant: -16),
            dayPageControl.heightAnchor.constraint(equalToConstant: 30),
            
            // Action buttons
            actionButtonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionButtonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionButtonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            actionButtonsStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func generateAvailabilityGrid() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Generate availability blocks for each day
        for dayOffset in 0..<numberOfDays {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            var dayBlocks: [AvailabilityBlock] = []
            
            for timeIndex in 0..<timeSlotsPerDay {
                let hour = startHour + timeIndex
                let startDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: dayDate)!
                let endDate = calendar.date(byAdding: .hour, value: 1, to: startDate)!
                
                let timeSlot = TimeSlot(startDate: startDate, endDate: endDate)
                let gridPosition = AvailabilityBlock.GridPosition(day: dayOffset, timeIndex: timeIndex)
                let block = AvailabilityBlock(timeSlot: timeSlot, gridPosition: gridPosition)
                
                dayBlocks.append(block)
            }
            
            availabilityBlocks[dayOffset] = dayBlocks
        }
        
        // Setup horizontal scroll view with day pages
        setupDayPages()
    }
    
    private func setupDayPages() {
        // Remove existing subviews
        dayScrollView.subviews.forEach { $0.removeFromSuperview() }
        
        let scrollContentView = UIView()
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        dayScrollView.addSubview(scrollContentView)
        
        NSLayoutConstraint.activate([
            scrollContentView.topAnchor.constraint(equalTo: dayScrollView.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: dayScrollView.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: dayScrollView.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: dayScrollView.bottomAnchor),
            scrollContentView.heightAnchor.constraint(equalTo: dayScrollView.heightAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: dayScrollView.widthAnchor, multiplier: CGFloat(numberOfDays))
        ])
        
        // Create a page for each day
        for dayIndex in 0..<numberOfDays {
            let dayView = createDayView(for: dayIndex)
            dayView.translatesAutoresizingMaskIntoConstraints = false
            scrollContentView.addSubview(dayView)
            
            NSLayoutConstraint.activate([
                dayView.topAnchor.constraint(equalTo: scrollContentView.topAnchor),
                dayView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor),
                dayView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: CGFloat(dayIndex) * view.bounds.width),
                dayView.widthAnchor.constraint(equalToConstant: view.bounds.width)
            ])
        }
    }
    
    private func createDayView(for dayIndex: Int) -> UIView {
        let dayView = UIView()
        
        // Create time labels column
        let timeLabelsStack = UIStackView()
        timeLabelsStack.axis = .vertical
        timeLabelsStack.distribution = .fillEqually
        timeLabelsStack.spacing = 2
        timeLabelsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Create time slots grid
        let timeSlotsStack = UIStackView()
        timeSlotsStack.axis = .vertical
        timeSlotsStack.distribution = .fillEqually
        timeSlotsStack.spacing = 2
        timeSlotsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Create time labels and time slot buttons
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h a"
        
        guard let dayBlocks = availabilityBlocks[dayIndex] else { return dayView }
        
        for (timeIndex, block) in dayBlocks.enumerated() {
            // Time label
            let timeLabel = UILabel()
            timeLabel.text = timeFormatter.string(from: block.timeSlot.startDate)
            timeLabel.font = .systemFont(ofSize: 12)
            timeLabel.textAlignment = .center
            timeLabel.textColor = .secondaryLabel
            timeLabelsStack.addArrangedSubview(timeLabel)
            
            // Time slot button
            let slotButton = createTimeSlotButton(for: block, at: AvailabilityBlock.GridPosition(day: dayIndex, timeIndex: timeIndex))
            timeSlotsStack.addArrangedSubview(slotButton)
        }
        
        dayView.addSubview(timeLabelsStack)
        dayView.addSubview(timeSlotsStack)
        
        NSLayoutConstraint.activate([
            timeLabelsStack.leadingAnchor.constraint(equalTo: dayView.leadingAnchor, constant: 16),
            timeLabelsStack.topAnchor.constraint(equalTo: dayView.topAnchor, constant: 16),
            timeLabelsStack.bottomAnchor.constraint(equalTo: dayView.bottomAnchor, constant: -16),
            timeLabelsStack.widthAnchor.constraint(equalToConstant: 50),
            
            timeSlotsStack.leadingAnchor.constraint(equalTo: timeLabelsStack.trailingAnchor, constant: 8),
            timeSlotsStack.trailingAnchor.constraint(equalTo: dayView.trailingAnchor, constant: -16),
            timeSlotsStack.topAnchor.constraint(equalTo: dayView.topAnchor, constant: 16),
            timeSlotsStack.bottomAnchor.constraint(equalTo: dayView.bottomAnchor, constant: -16)
        ])
        
        return dayView
    }
    
    private func createTimeSlotButton(for block: AvailabilityBlock, at position: AvailabilityBlock.GridPosition) -> UIButton {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 6
        button.tag = position.day * 100 + position.timeIndex // Encode position in tag
        
        updateTimeSlotButton(button, isSelected: selectedBlocks.contains(position))
        
        button.addTarget(self, action: #selector(timeSlotButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func updateTimeSlotButton(_ button: UIButton, isSelected: Bool) {
        UIView.animate(withDuration: 0.2) {
            if isSelected {
                button.backgroundColor = .systemGreen
                button.setTitle("✓", for: .normal)
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = .systemGray5
                button.setTitle("", for: .normal)
                button.setTitleColor(.clear, for: .normal)
            }
        }
    }
    
    private func showDay(_ dayIndex: Int) {
        currentDayIndex = dayIndex
        
        // Update day label
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: today) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE, MMM d"
            currentDayLabel.text = dayFormatter.string(from: dayDate)
        }
        
        // Update navigation buttons
        previousDayButton.isEnabled = dayIndex > 0
        nextDayButton.isEnabled = dayIndex < numberOfDays - 1
        previousDayButton.alpha = previousDayButton.isEnabled ? 1.0 : 0.3
        nextDayButton.alpha = nextDayButton.isEnabled ? 1.0 : 0.3
        
        // Update page control
        dayPageControl.currentPage = dayIndex
        
        // Scroll to the correct page
        let xOffset = CGFloat(dayIndex) * dayScrollView.bounds.width
        dayScrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: true)
        
        updateConfirmButton()
    }
    
    // MARK: - Gesture Setup
    private func setupGestures() {
        // Gestures are handled by individual buttons now
    }
    
    @objc private func timeSlotButtonTapped(_ sender: UIButton) {
        let dayIndex = sender.tag / 100
        let timeIndex = sender.tag % 100
        let position = AvailabilityBlock.GridPosition(day: dayIndex, timeIndex: timeIndex)
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Toggle selection
        if selectedBlocks.contains(position) {
            selectedBlocks.remove(position)
        } else {
            selectedBlocks.insert(position)
        }
        
        updateTimeSlotButton(sender, isSelected: selectedBlocks.contains(position))
        updateConfirmButton()
    }
    
    private func updateConfirmButton() {
        let hasSelections = !selectedBlocks.isEmpty
        confirmButton.isEnabled = hasSelections
        confirmButton.alpha = hasSelections ? 1.0 : 0.6
        
        if hasSelections {
            confirmButton.setTitle("Confirm \(selectedBlocks.count) time slots", for: .normal)
        } else {
            confirmButton.setTitle("Select availability", for: .normal)
        }
    }
    
    // MARK: - Actions
    @objc private func previousDayTapped() {
        if currentDayIndex > 0 {
            showDay(currentDayIndex - 1)
        }
    }
    
    @objc private func nextDayTapped() {
        if currentDayIndex < numberOfDays - 1 {
            showDay(currentDayIndex + 1)
        }
    }
    
    @objc private func pageControlChanged() {
        showDay(dayPageControl.currentPage)
    }
    
    @objc private func confirmTapped() {
        let selectedTimeSlots = selectedBlocks.compactMap { position in
            availabilityBlocks[position.day]?[safe: position.timeIndex]?.timeSlot
        }
        
        delegate?.customAvailabilityViewController(self, didSelectCustomAvailability: selectedTimeSlots)
    }
    
    @objc private func cancelTapped() {
        delegate?.customAvailabilityViewControllerDidCancel(self)
    }
    
    @objc private func clearAllTapped() {
        selectedBlocks.removeAll()
        
        // Update all buttons across all days
        for dayView in dayScrollView.subviews.first?.subviews ?? [] {
            for subview in dayView.subviews {
                if let stackView = subview as? UIStackView {
                    for arrangedSubview in stackView.arrangedSubviews {
                        if let button = arrangedSubview as? UIButton, button.tag >= 0 {
                            let dayIndex = button.tag / 100
                            let timeIndex = button.tag % 100
                            let position = AvailabilityBlock.GridPosition(day: dayIndex, timeIndex: timeIndex)
                            updateTimeSlotButton(button, isSelected: false)
                        }
                    }
                }
            }
        }
        
        updateConfirmButton()
    }
}

// MARK: - UIScrollViewDelegate
extension CustomAvailabilityViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        if pageIndex != currentDayIndex {
            showDay(pageIndex)
        }
    }
}

// MARK: - Delegate Protocol
protocol CustomAvailabilityViewControllerDelegate: AnyObject {
    func customAvailabilityViewController(_ controller: CustomAvailabilityViewController, didSelectCustomAvailability timeSlots: [TimeSlot])
    func customAvailabilityViewControllerDidCancel(_ controller: CustomAvailabilityViewController)
} 
