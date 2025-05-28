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
    @State private var hasInitialized = false
    @State private var initializationError: String?
    @State private var viewModelsReady = false
    
    // Lazy initialization of ViewModels to prevent crashes during startup
    @State private var authViewModel: AuthViewModel?
    @State private var calendarViewModel: CalendarViewModel?
    @State private var appleCalendarViewModel: AppleCalendarViewModel?
    @State private var calendarSettings: CalendarSettings?

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
                            viewModelsReady = false
                            retryInitialization()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else if hasInitialized && viewModelsReady {
                    // Show main content once everything is initialized
                    ContentView()
                        .environmentObject(authViewModel!)
                        .environmentObject(calendarViewModel!)
                        .environmentObject(appleCalendarViewModel!)
                        .environmentObject(calendarSettings!)
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
                        
                        Text(viewModelsReady ? "Finalizing..." : "Initializing GcalDemo...")
                            .font(.headline)
                            .padding()
                    }
                    .onAppear {
                        if !hasInitialized {
                            initializeApp()
                        }
                    }
                }
            }
        }
    }
    
    private func initializeApp() {
        Task {
            do {
                print("GcalDemoApp: Starting ViewModel initialization...")
                
                // Initialize ViewModels with error handling
                await initializeViewModels()
                
                // Small delay to ensure everything is ready
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                await MainActor.run {
                    hasInitialized = true
                    print("GcalDemoApp: App fully initialized and ready")
                }
                
            } catch {
                print("GcalDemoApp: Initialization error: \(error)")
                await MainActor.run {
                    initializationError = "Failed to initialize app: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func initializeViewModels() async {
        await MainActor.run {
            do {
                print("GcalDemoApp: Creating AuthViewModel...")
                authViewModel = AuthViewModel()
                
                print("GcalDemoApp: Creating CalendarViewModel...")
                calendarViewModel = CalendarViewModel()
                
                print("GcalDemoApp: Creating CalendarSettings...")
                calendarSettings = CalendarSettings()
                
                print("GcalDemoApp: Creating AppleCalendarViewModel...")
                appleCalendarViewModel = AppleCalendarViewModel()
                
                viewModelsReady = true
                print("GcalDemoApp: All ViewModels created successfully")
                
            } catch {
                print("GcalDemoApp: Error creating ViewModels: \(error)")
                initializationError = "Failed to create app components: \(error.localizedDescription)"
            }
        }
    }
    
    private func retryInitialization() {
        // Reset ViewModels
        authViewModel = nil
        calendarViewModel = nil
        appleCalendarViewModel = nil
        calendarSettings = nil
        
        // Retry initialization
        initializeApp()
    }
}
