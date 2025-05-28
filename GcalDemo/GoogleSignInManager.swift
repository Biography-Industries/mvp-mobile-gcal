import Foundation
import GoogleSignIn
import GoogleSignInSwift // For SwiftUI helpers
import GTMAppAuth // For fetching an authorizer

// Define the calendar scope for accessing events
private let calendarScope = "https://www.googleapis.com/auth/calendar.events"

class GoogleSignInManager {
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

    func signIn(presentingViewController: UIViewController? = nil, completion: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
        guard gidSignIn.configuration != nil else {
            completion(.failure(NSError(domain: "GoogleSignInManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In not configured. Call configure() first."])))
            return
        }
        
        guard let presentingVC = presentingViewController ?? topViewController() else {
            completion(.failure(NSError(domain: "GoogleSignInManager", code: -6, userInfo: [NSLocalizedDescriptionKey: "Could not get a presenting view controller for sign-in."])))
            return
        }

        // Request the calendar scope
        let additionalScopes = [calendarScope]

        gidSignIn.signIn(withPresenting: presentingVC, hint: nil, additionalScopes: additionalScopes) { signInResult, error in
            if let error = error {
                if (error as NSError).code == GIDSignInError.canceled.rawValue {
                    print("Sign-in was cancelled.")
                    completion(.failure(error))
                } else {
                    print("Sign-in error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                return
            }

            guard let result = signInResult else {
                completion(.failure(NSError(domain: "GoogleSignInManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "GIDSignInResult object is nil after sign-in."])))
                return
            }
            
            let user = result.user
            print("User signed in successfully: \(user.profile?.name ?? "Unknown User")")
            completion(.success(user))
        }
    }
    
    // SwiftUI specific sign-in helper
    func signInWithSwiftUI(completion: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
        guard gidSignIn.configuration != nil else {
            completion(.failure(NSError(domain: "GoogleSignInManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In not configured. Call configure() first."])))
            return
        }

        guard let presentingVC = topViewController() else {
            completion(.failure(NSError(domain: "GoogleSignInManager", code: -6, userInfo: [NSLocalizedDescriptionKey: "Could not get a presenting view controller for SwiftUI sign-in."])))
            return
        }
        
        // Request the calendar scope
        let additionalScopes = [calendarScope]

        // For SwiftUI, GoogleSignInButton handles presentation if used, but if calling signInWithSwiftUI directly,
        // we still need a presenting view controller.
        gidSignIn.signIn(withPresenting: presentingVC, hint: nil, additionalScopes: additionalScopes) { signInResult, error in
            if let error = error {
                 if (error as NSError).code == GIDSignInError.canceled.rawValue {
                    print("Sign-in was cancelled.")
                    completion(.failure(error))
                } else {
                    print("Sign-in error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                return
            }

            guard let result = signInResult else {
                completion(.failure(NSError(domain: "GoogleSignInManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "GIDSignInResult object is nil after sign-in."])))
                return
            }
            
            let user = result.user
            print("User signed in successfully (SwiftUI): \(user.profile?.name ?? "Unknown User")")
            completion(.success(user))
        }
    }


    func signOut() {
        gidSignIn.signOut()
        print("User signed out.")
    }

    func restorePreviousSignIn(completion: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
        gidSignIn.restorePreviousSignIn { user, error in
            if let error = error {
                print("Error restoring previous sign-in: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let user = user else {
                // No previous user signed in, or session expired
                completion(.failure(NSError(domain: "GoogleSignInManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "No previous user to restore."])))
                return
            }
            print("Restored previous sign-in for: \(user.profile?.name ?? "Unknown User")")
            completion(.success(user))
        }
    }

    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // Helper to get the top view controller for UIKit-based sign-in presentation
    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }

        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
    
    // Function to get an authorizer for API calls
    func getAuthorizer(forUser user: GIDGoogleUser, completion: @escaping (Result<GTMFetcherAuthorizationProtocol, Error>) -> Void) {
        user.refreshTokensIfNeeded { refreshedUser, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let finalUser = refreshedUser else {
                // This case should ideally not happen if error is nil.
                // If refreshedUser is nil and error is nil, it implies an unexpected state.
                // The original 'user' object might still be valid if it wasn't updated,
                // but it's safer to expect a user object here or an error.
                completion(.failure(NSError(domain: "GoogleSignInManager", code: -5, userInfo: [NSLocalizedDescriptionKey: "User object is nil after token refresh attempt without an explicit error."])))
                return
            }
            
            // GIDGoogleUser's fetcherAuthorizer property is synchronous.
            // It should be accessed after tokens are confirmed to be fresh.
            let authorizer = finalUser.fetcherAuthorizer
            completion(.success(authorizer))
        }
    }
} 