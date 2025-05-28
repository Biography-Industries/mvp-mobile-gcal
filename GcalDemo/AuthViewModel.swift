import Foundation
import SwiftUI // For @Published
import GoogleSignIn // So we can hold a GIDGoogleUser

class AuthViewModel: ObservableObject {
    @Published var googleUser: GIDGoogleUser? // Holds the signed-in user object
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isSigningIn: Bool = false

    private var signInManager = GoogleSignInManager.shared

    init() {
        // Attempt to restore a previous sign-in when the app starts
        restorePreviousSignIn()
    }

    func signInWithSwiftUI() {
        guard !isSigningIn else { return }
        isSigningIn = true
        errorMessage = nil
        
        signInManager.signInWithSwiftUI { [weak self] result in
            DispatchQueue.main.async {
                self?.isSigningIn = false
                switch result {
                case .success(let user):
                    self?.googleUser = user
                    self?.isAuthenticated = true
                    print("AuthViewModel: Sign-in successful. User: \(user.profile?.email ?? "N/A")")
                case .failure(let error):
                    if (error as NSError).code == GIDSignInError.canceled.rawValue {
                        self?.errorMessage = "Sign-in was cancelled."
                        print("AuthViewModel: Sign-in cancelled by user.")
                    } else {
                        self?.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                        print("AuthViewModel: Sign-in error: \(error.localizedDescription)")
                    }
                    self?.isAuthenticated = false
                }
            }
        }
    }

    func signOut() {
        signInManager.signOut()
        DispatchQueue.main.async {
            self.googleUser = nil
            self.isAuthenticated = false
            print("AuthViewModel: User signed out.")
        }
    }

    func restorePreviousSignIn() {
        signInManager.restorePreviousSignIn { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.googleUser = user
                    self?.isAuthenticated = true
                    print("AuthViewModel: Restored previous sign-in. User: \(user.profile?.email ?? "N/A")")
                case .failure(let error):
                     // It's normal for this to fail if there's no previous user or session is expired.
                    print("AuthViewModel: Could not restore previous sign-in: \(error.localizedDescription)")
                    self?.isAuthenticated = false
                }
            }
        }
    }
} 