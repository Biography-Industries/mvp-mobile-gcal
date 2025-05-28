//
//  ContentView.swift
//  GcalDemo
//
//  Created by Dezmond Blair on 5/26/25.
//

import SwiftUI
import GoogleSignIn // For GIDGoogleUser
import GoogleSignInSwift // For GIDSignInButton
import GoogleAPIClientForREST_Calendar // For GTLRCalendar_Event
import EventKit // For Apple Calendar

enum EventFormMode {
    case add
    case edit
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var appleCalendarViewModel: AppleCalendarViewModel
    @EnvironmentObject var calendarSettings: CalendarSettings

    // States for Google Calendar event management
    @State private var showingAddGoogleEventSheet = false
    @State private var showingEditGoogleEventSheet = false
    @State private var googleEventToEdit: GTLRCalendar_Event? = nil
    @State private var googleEventTitle: String = ""
    @State private var googleEventStartDate: Date = Date()
    @State private var googleEventEndDate: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    
    // States for Apple Calendar event management
    @State private var showingAddAppleEventSheet = false
    @State private var showingEditAppleEventSheet = false
    @State private var appleEventToEdit: EKEvent? = nil
    @State private var appleEventTitle: String = ""
    @State private var appleEventStartDate: Date = Date()
    @State private var appleEventEndDate: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var appleEventNotes: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Select Calendar Service", selection: $calendarSettings.selectedService) {
                    ForEach(CalendarServiceType.allCases) { service in
                        Text(service.rawValue).tag(service)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                switch calendarSettings.selectedService {
                case .google:
                    GoogleCalendarView()
                case .apple:
                    AppleCalendarView()
                }
            }
            .navigationTitle(navigationTitleForSelectedService())
             // Toolbar will now be part of GoogleCalendarView or AppleCalendarView
        }
    }

    private func navigationTitleForSelectedService() -> String {
        switch calendarSettings.selectedService {
        case .google:
            return authViewModel.isAuthenticated ? "Google Calendar" : "Sign In (Google)"
        case .apple:
            return "Apple Calendar"
        }
    }

    // MARK: - Google Calendar View
    @ViewBuilder
    private func GoogleCalendarView() -> some View {
        VStack {
            if authViewModel.isAuthenticated, let user = authViewModel.googleUser {
                googleCalendarListView(user: user)
            } else {
                googleSignInView
            }
        }
        .toolbar {
            if calendarSettings.selectedService == .google && authViewModel.isAuthenticated {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        authViewModel.signOut()
                        calendarViewModel.fetchEvents(forUser: nil) // Clear events on sign out
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        resetGoogleEventFormFields()
                        showingAddGoogleEventSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            if calendarSettings.selectedService == .google {
                if newValue {
                    calendarViewModel.fetchEvents(forUser: authViewModel.googleUser)
                } else {
                    calendarViewModel.fetchEvents(forUser: nil)
                }
            }
        }
        .sheet(isPresented: $showingAddGoogleEventSheet) {
            googleEventFormView(mode: .add, user: authViewModel.googleUser)
        }
        .sheet(isPresented: $showingEditGoogleEventSheet, onDismiss: { googleEventToEdit = nil }) {
            if let eventToEdit = googleEventToEdit {
                googleEventFormView(mode: .edit, event: eventToEdit, user: authViewModel.googleUser)
            }
        }
        .onAppear {
            if calendarSettings.selectedService == .google && authViewModel.isAuthenticated {
                calendarViewModel.fetchEvents(forUser: authViewModel.googleUser)
            }
        }
    }
    
    // MARK: - Google Sign-In View
    private var googleSignInView: some View {
        VStack(spacing: 20) {
            Text("Welcome to GCal Demo")
                .font(.largeTitle)
                .padding()

            Text("Please sign in with your Google Account to access your calendar.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if authViewModel.isSigningIn {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else {
                GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                    authViewModel.signInWithSwiftUI()
                }
                .padding()
            }

            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Spacer()
        }
    }

    // MARK: - Google Calendar List View
    @ViewBuilder
    private func googleCalendarListView(user: GIDGoogleUser) -> some View {
        VStack {
            if let profile = user.profile {
                Text("Hello, \(profile.name ?? "User")!")
                    .font(.title2)
                    .padding(.top)
            }

            if calendarViewModel.isLoading && calendarViewModel.events.isEmpty {
                ProgressView("Loading events...")
                    .padding()
                Spacer()
            } else if let errorMessage = calendarViewModel.errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        calendarViewModel.clearErrorMessage()
                        calendarViewModel.fetchEvents(forUser: user)
                    }
                    .padding()
                    Spacer()
                }
            } else if calendarViewModel.events.isEmpty {
                Text("No upcoming Google events found.")
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(calendarViewModel.events, id: \.identifier) { event in
                        googleEventRow(event)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.googleEventToEdit = event
                                self.googleEventTitle = event.summary ?? ""
                                self.googleEventStartDate = event.start?.dateTime?.date ?? event.start?.date?.date ?? Date()
                                self.googleEventEndDate = event.end?.dateTime?.date ?? event.end?.date?.date ?? (Calendar.current.date(byAdding: .hour, value: 1, to: self.googleEventStartDate) ?? Date())
                                self.showingEditGoogleEventSheet = true
                            }
                    }
                    .onDelete(perform: deleteGoogleEventItems)
                }
                .refreshable {
                     calendarViewModel.fetchEvents(forUser: user)
                }
            }
        }
    }
    
    private func googleEventRow(_ event: GTLRCalendar_Event) -> some View {
        VStack(alignment: .leading) {
            Text(event.summary ?? "No Title")
                .font(.headline)
            if let start = event.start?.dateTime?.date ?? event.start?.date?.date {
                 Text("Start: \(formatDate(start))")
                    .font(.subheadline)
            }
            if let end = event.end?.dateTime?.date ?? event.end?.date?.date {
                 Text("End: \(formatDate(end))")
                    .font(.subheadline)
            }
            if let description = event.descriptionProperty, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
    }

    private func deleteGoogleEventItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { calendarViewModel.events[$0] }.forEach { event in
                if let eventId = event.identifier {
                    calendarViewModel.deleteEvent(eventId: eventId, forUser: authViewModel.googleUser) { success in
                        // ViewModel updates UI
                    }
                }
            }
        }
    }

    // MARK: - Unified Google Event Form View (for Add and Edit)
    enum GoogleEventFormMode { case add, edit }

    private func googleEventFormView(mode: GoogleEventFormMode, event: GTLRCalendar_Event? = nil, user: GIDGoogleUser?) -> some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $googleEventTitle)
                    DatePicker("Start Time", selection: $googleEventStartDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Time", selection: $googleEventEndDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                if let errorMessage = calendarViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button(mode == .add ? "Add Event" : "Update Event") {
                    let eventData = GTLRCalendar_Event()
                    eventData.summary = googleEventTitle
                    
                    let startGTLRDateTime = GTLRDateTime(date: googleEventStartDate)
                    eventData.start = GTLRCalendar_EventDateTime()
                    eventData.start?.dateTime = startGTLRDateTime
                    
                    let endGTLRDateTime = GTLRDateTime(date: googleEventEndDate)
                    eventData.end = GTLRCalendar_EventDateTime()
                    eventData.end?.dateTime = endGTLRDateTime

                    if mode == .add {
                        calendarViewModel.addEvent(title: googleEventTitle, startTime: googleEventStartDate, endTime: googleEventEndDate, forUser: user) { success in
                            if success {
                                showingAddGoogleEventSheet = false
                                resetGoogleEventFormFields()
                                calendarViewModel.clearErrorMessage()
                            }
                        }
                    } else if mode == .edit, let originalEventID = event?.identifier {
                        calendarViewModel.updateEvent(originalEventID: originalEventID, updatedEventData: eventData, forUser: user) { success in
                            if success {
                                showingEditGoogleEventSheet = false
                                googleEventToEdit = nil
                                resetGoogleEventFormFields()
                                calendarViewModel.clearErrorMessage()
                            }
                        }
                    }
                }
                .disabled(googleEventTitle.isEmpty)
            }
            .navigationTitle(mode == .add ? "Add Google Event" : "Edit Google Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if mode == .add {
                            showingAddGoogleEventSheet = false
                        } else {
                            showingEditGoogleEventSheet = false
                        }
                        resetGoogleEventFormFields()
                        calendarViewModel.clearErrorMessage()
                    }
                }
            }
            .onAppear { // Pre-fill form for editing
                if mode == .edit, let eventToEdit = event {
                    googleEventTitle = eventToEdit.summary ?? ""
                    googleEventStartDate = eventToEdit.start?.dateTime?.date ?? eventToEdit.start?.date?.date ?? Date()
                    googleEventEndDate = eventToEdit.end?.dateTime?.date ?? eventToEdit.end?.date?.date ?? (Calendar.current.date(byAdding: .hour, value: 1, to: googleEventStartDate) ?? Date())
                } else {
                     resetGoogleEventFormFields() // Ensure form is clear for add mode
                }
            }
        }
    }
    
    private func resetGoogleEventFormFields() {
        googleEventTitle = ""
        googleEventStartDate = Date()
        googleEventEndDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Apple Calendar View
    @ViewBuilder
    private func AppleCalendarView() -> some View {
        VStack {
            switch appleCalendarViewModel.authorizationStatus {
            case .notDetermined:
                Button("Request Calendar Access") {
                    appleCalendarViewModel.requestCalendarAccess()
                }
                Spacer()
            case .restricted:
                Text("Calendar access is restricted on this device.")
                    .padding()
                Spacer()
            case .denied:
                Text("Calendar access was denied. Please enable it in Settings.")
                    .padding()
                Button("Open Settings") {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Spacer()
            case .authorized, .fullAccess: // .fullAccess is for iOS 17+
                appleCalendarListView()
            @unknown default:
                Text("Unknown calendar authorization status.")
                Spacer()
            }
        }
        .toolbar {
             if calendarSettings.selectedService == .apple && (appleCalendarViewModel.authorizationStatus == .authorized || appleCalendarViewModel.authorizationStatus == .fullAccess) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        resetAppleEventFormFields()
                        showingAddAppleEventSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddAppleEventSheet) {
            appleEventFormView(mode: .add)
        }
        .sheet(isPresented: $showingEditAppleEventSheet, onDismiss: { appleEventToEdit = nil }) {
            if appleEventToEdit != nil {
                appleEventFormView(mode: .edit, event: appleEventToEdit)
            }
        }
        .alert(item: $appleCalendarViewModel.error) { identifiableError in
            Alert(title: Text("Error"), message: Text(identifiableError.error.localizedDescription), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            if calendarSettings.selectedService == .apple {
                // Initial check or refresh for Apple Calendar
                if appleCalendarViewModel.authorizationStatus == .notDetermined {
                    // Prompt for access or guide user. For now, it's handled by the button.
                } else if appleCalendarViewModel.authorizationStatus == .authorized || appleCalendarViewModel.authorizationStatus == .fullAccess {
                    appleCalendarViewModel.refreshEvents()
                }
            }
        }
    }

    @ViewBuilder
    private func appleCalendarListView() -> some View {
        if appleCalendarViewModel.events.isEmpty {
            Text("No upcoming Apple events found.")
                .padding()
            Spacer()
        } else {
            List {
                ForEach(Array(appleCalendarViewModel.events.enumerated()), id: \.offset) { index, event in
                    appleEventRow(event)
                        .onTapGesture {
                            // Tapping an Apple Calendar event shows our custom edit form
                            appleEventToEdit = event
                            appleEventTitle = event.title ?? ""
                            appleEventStartDate = event.startDate ?? Date()
                            appleEventEndDate = event.endDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                            appleEventNotes = event.notes ?? ""
                            showingEditAppleEventSheet = true
                        }
                }
                .onDelete(perform: deleteAppleEventItems)
            }
            .refreshable {
                appleCalendarViewModel.refreshEvents()
            }
        }
    }

    private func appleEventRow(_ event: EKEvent) -> some View {
        VStack(alignment: .leading) {
            Text(event.title ?? "No Title")
                .font(.headline)
            if let startDate = event.startDate {
                Text("Start: \(formatDate(startDate))")
                    .font(.subheadline)
            }
            if let endDate = event.endDate {
                Text("End: \(formatDate(endDate))")
                    .font(.subheadline)
            }
            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
    }

    private func deleteAppleEventItems(offsets: IndexSet) {
        appleCalendarViewModel.deleteAppleEvents(at: offsets)
    }
    
    // MARK: - Apple Calendar Event Form
    @ViewBuilder
    private func appleEventFormView(mode: EventFormMode, event: EKEvent? = nil) -> some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $appleEventTitle)
                    
                    DatePicker("Start Date", selection: $appleEventStartDate, displayedComponents: [.date, .hourAndMinute])
                    
                    DatePicker("End Date", selection: $appleEventEndDate, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Notes", text: $appleEventNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(mode == .add ? "Create Event" : "Update Event") {
                        if mode == .add {
                            addAppleEvent()
                        } else if let eventToEdit = appleEventToEdit {
                            updateAppleEvent(eventToEdit)
                        }
                    }
                    .disabled(appleEventTitle.isEmpty)
                    
                    if mode == .edit {
                        Button("Delete Event", role: .destructive) {
                            if let eventToEdit = appleEventToEdit {
                                deleteAppleEvent(eventToEdit)
                            }
                        }
                    }
                }
            }
            .navigationTitle(mode == .add ? "New Apple Event" : "Edit Apple Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if mode == .add {
                            showingAddAppleEventSheet = false
                        } else {
                            showingEditAppleEventSheet = false
                        }
                        resetAppleEventFormFields()
                    }
                }
            }
            .onAppear {
                if mode == .edit, let eventToEdit = event {
                    appleEventTitle = eventToEdit.title ?? ""
                    appleEventStartDate = eventToEdit.startDate ?? Date()
                    appleEventEndDate = eventToEdit.endDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                    appleEventNotes = eventToEdit.notes ?? ""
                } else {
                    resetAppleEventFormFields()
                }
            }
        }
    }
    
    private func resetAppleEventFormFields() {
        appleEventTitle = ""
        appleEventStartDate = Date()
        appleEventEndDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        appleEventNotes = ""
    }
    
    private func addAppleEvent() {
        Task {
            do {
                try await appleCalendarViewModel.addAppleEvent(
                    title: appleEventTitle,
                    startDate: appleEventStartDate,
                    endDate: appleEventEndDate,
                    notes: appleEventNotes
                )
                showingAddAppleEventSheet = false
                resetAppleEventFormFields()
            } catch {
                // Error handling is done in the view model
            }
        }
    }
    
    private func updateAppleEvent(_ event: EKEvent) {
        Task {
            do {
                try await appleCalendarViewModel.updateAppleEvent(
                    event,
                    title: appleEventTitle,
                    startDate: appleEventStartDate,
                    endDate: appleEventEndDate,
                    notes: appleEventNotes
                )
                showingEditAppleEventSheet = false
                appleEventToEdit = nil
                resetAppleEventFormFields()
            } catch {
                // Error handling is done in the view model
            }
        }
    }
    
    private func deleteAppleEvent(_ event: EKEvent) {
        Task {
            do {
                try await appleCalendarViewModel.deleteAppleEvent(event)
                showingEditAppleEventSheet = false
                appleEventToEdit = nil
                resetAppleEventFormFields()
            } catch {
                // Error handling is done in the view model
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
            .environmentObject(CalendarViewModel())
            .environmentObject(AppleCalendarViewModel())
            .environmentObject(CalendarSettings())
    }
}
