//
//  GcalDemoApp.swift
//  GcalDemo
//
//  Created by Dezmond Blair on 5/26/25.
//

import SwiftUI
import GoogleSignIn // Ensure this is imported

@main
struct GcalDemoApp: App {
    @StateObject var authViewModel = AuthViewModel() // Manages auth state for Google
    @StateObject var calendarViewModel = CalendarViewModel() // Manages Google calendar data
    @StateObject var appleCalendarViewModel = AppleCalendarViewModel() // Manages Apple calendar data
    @StateObject var calendarSettings = CalendarSettings() // Manages calendar service selection

    init() {
        // Configure Google Sign-In using the manager
        // IMPORTANT: Replace "YOUR_CLIENT_ID_HERE" with your actual Client ID
        // from the Google Cloud Console.
        GoogleSignInManager.shared.configure(clientID: "945056809530-0oq4hm1dtaf0p326k1r7aeb3ldm82313.apps.googleusercontent.com")
    }

    var body: some Scene {
        WindowGroup {
            // The ContentView will now decide which view to show based on calendarSettings
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(calendarViewModel)
                .environmentObject(appleCalendarViewModel) // Make AppleCalendarViewModel available
                .environmentObject(calendarSettings) // Make CalendarSettings available
                // Handle the URL that Google Sign-In redirects back to
                .onOpenURL { url in
                    // Let the GoogleSignInManager handle the URL
                    _ = GoogleSignInManager.shared.handle(url)
                }
        }
    }
}
