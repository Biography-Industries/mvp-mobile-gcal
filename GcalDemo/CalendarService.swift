import Foundation
import SwiftUI // Import SwiftUI for @AppStorage

enum CalendarServiceType: String, CaseIterable, Identifiable {
    case google = "Google Calendar"
    case apple = "Apple Calendar"
    // case none = "Not Selected" // Could be an initial state

    var id: String { self.rawValue }
}

class CalendarSettings: ObservableObject {
    @AppStorage("selectedCalendarService") private var selectedServiceRawValue: String = CalendarServiceType.google.rawValue // Default to Google or .none

    @Published var selectedService: CalendarServiceType = .google {
        didSet {
            selectedServiceRawValue = selectedService.rawValue
        }
    }
    
    init() {
        // Load the saved value on initialization
        selectedService = CalendarServiceType(rawValue: selectedServiceRawValue) ?? .google
    }
} 