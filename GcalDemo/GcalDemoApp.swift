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
    // Add @StateObject with error handling
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var calendarViewModel = CalendarViewModel()
    @StateObject private var appleCalendarViewModel = AppleCalendarViewModel()
    @StateObject private var calendarSettings = CalendarSettings()
    
    @State private var hasInitialized = false
    @State private var initializationError: String?

    init() {
        print("GcalDemoApp: Starting app initialization...")
        
        // Wrap Google Sign-In configuration in error handling
        do {
            // Configure Google Sign-In using the manager
            GoogleSignInManager.shared.configure(clientID: "945056809530-0oq4hm1dtaf0p326k1r7aeb3ldm82313.apps.googleusercontent.com")
            print("GcalDemoApp: Google Sign-In configured successfully")
        } catch {
            print("GcalDemoApp: Error configuring Google Sign-In: \(error)")
        }
        
        print("GcalDemoApp: App initialization completed")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let error = initializationError {
                    // Show error view if initialization failed
                    VStack {
                        Text("Initialization Error")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        Text(error)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            initializationError = nil
                            hasInitialized = false
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else if hasInitialized {
                    // Show main content once initialized
                    ContentView()
                        .environmentObject(authViewModel)
                        .environmentObject(calendarViewModel)
                        .environmentObject(appleCalendarViewModel)
                        .environmentObject(calendarSettings)
                        .onOpenURL { url in
                            // Let the GoogleSignInManager handle the URL
                            _ = GoogleSignInManager.shared.handle(url)
                        }
                } else {
                    // Show loading view during initialization
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("Initializing GcalDemo...")
                            .font(.headline)
                            .padding()
                    }
                    .onAppear {
                        initializeApp()
                    }
                }
            }
        }
    }
    
    private func initializeApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                // Perform any additional initialization here
                print("GcalDemoApp: Completing app initialization...")
                
                // Mark as initialized
                hasInitialized = true
                print("GcalDemoApp: App fully initialized and ready")
                
            } catch {
                print("GcalDemoApp: Initialization error: \(error)")
                initializationError = "Failed to initialize app: \(error.localizedDescription)"
            }
        }
    }
}
