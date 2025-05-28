import Foundation
import GoogleSignIn
import GoogleSignInSwift // For SwiftUI helpers

// Define the calendar scope for accessing events
private let calendarScope = "https://www.googleapis.com/auth/calendar.events"

@MainActor
class GoogleSignInManager: ObservableObject {
    static let shared = GoogleSignInManager()
    private let gidSignIn: GIDSignIn

    private init() {
        self.gidSignIn = GIDSignIn.sharedInstance
    }

    // Call this from your App's init() or early in the lifecycle
    func configure(clientID: String) {
        guard gidSignIn.configuration == nil else {
            print("Google Sign-In is already configured.")
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        gidSignIn.configuration = config
        print("Google Sign-In configured with Client ID: \(clientID)")
    }

    // MARK: - Simple Sign In
    func signIn() async throws -> GIDGoogleUser {
        guard gidSignIn.configuration != nil else {
            throw GoogleSignInError.notConfigured
        }
        
        guard let presentingVC = await topViewController() else {
            throw GoogleSignInError.noPresentingViewController
        }

        let additionalScopes = [calendarScope]

        return try await withCheckedThrowingContinuation { continuation in
            gidSignIn.signIn(withPresenting: presentingVC, hint: nil, additionalScopes: additionalScopes) { signInResult, error in
                if let error = error {
                    if (error as NSError).code == GIDSignInError.canceled.rawValue {
                        print("Sign-in was cancelled.")
                        continuation.resume(throwing: GoogleSignInError.cancelled)
                    } else {
                        print("Sign-in error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard let result = signInResult else {
                    continuation.resume(throwing: GoogleSignInError.invalidResult)
                    return
                }
                
                let user = result.user
                print("User signed in successfully: \(user.profile?.name ?? "Unknown User")")
                continuation.resume(returning: user)
            }
        }
    }

    // MARK: - Backward Compatibility Methods
    func signIn(presentingViewController: UIViewController? = nil, completion: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
        Task {
            do {
                let user = try await signIn()
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // SwiftUI specific sign-in helper
    func signInWithSwiftUI(completion: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
        Task {
            do {
                let user = try await signIn()
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func signOut() {
        gidSignIn.signOut()
        print("User signed out.")
    }

    // MARK: - Simple Restore Previous Sign In
    func restorePreviousSignIn() async throws -> GIDGoogleUser {
        return try await withCheckedThrowingContinuation { continuation in
            gidSignIn.restorePreviousSignIn { user, error in
                if let error = error {
                    print("Error restoring previous sign-in: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                guard let user = user else {
                    continuation.resume(throwing: GoogleSignInError.noPreviousUser)
                    return
                }
                print("Restored previous sign-in for: \(user.profile?.name ?? "Unknown User")")
                continuation.resume(returning: user)
            }
        }
    }

    // MARK: - Backward Compatibility for Restore
    func restorePreviousSignIn(completion: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
        Task {
            do {
                let user = try await restorePreviousSignIn()
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Simple Top View Controller
    private func topViewController() async -> UIViewController? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                    continuation.resume(returning: nil)
                    return
                }

                var topController = rootViewController
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                continuation.resume(returning: topController)
            }
        }
    }
}

// MARK: - Simple Error Handling
enum GoogleSignInError: LocalizedError {
    case notConfigured
    case noPresentingViewController
    case cancelled
    case invalidResult
    case noPreviousUser
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google Sign-In not configured. Call configure() first."
        case .noPresentingViewController:
            return "Could not get a presenting view controller for sign-in."
        case .cancelled:
            return "Sign-in was cancelled by user."
        case .invalidResult:
            return "Invalid sign-in result."
        case .noPreviousUser:
            return "No previous user to restore."
        }
    }
} 