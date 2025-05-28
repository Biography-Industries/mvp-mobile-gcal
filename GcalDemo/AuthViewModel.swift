import Foundation
import SwiftUI // For @Published
import GoogleSignIn // So we can hold a GIDGoogleUser

@MainActor
class AuthViewModel: ObservableObject {
    @Published var googleUser: GIDGoogleUser? = nil // Holds the signed-in user object
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isSigningIn: Bool = false

    private var signInManager = GoogleSignInManager.shared

    init() {
        checkAuthenticationStatus()
    }

    func signInWithSwiftUI() {
        isSigningIn = true
        errorMessage = nil
        
        signInManager.signInWithSwiftUI { [weak self] result in
            Task { @MainActor in
                self?.isSigningIn = false
                switch result {
                case .success(let user):
                    self?.googleUser = user
                    self?.isAuthenticated = true
                    self?.errorMessage = nil
                    print("AuthViewModel: User signed in successfully")
                case .failure(let error):
                    self?.googleUser = nil
                    self?.isAuthenticated = false
                    self?.errorMessage = error.localizedDescription
                    print("AuthViewModel: Sign-in failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func signOut() {
        signInManager.signOut()
        googleUser = nil
        isAuthenticated = false
        errorMessage = nil
        print("AuthViewModel: User signed out")
    }

    private func checkAuthenticationStatus() {
        signInManager.restorePreviousSignIn { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let user):
                    self?.googleUser = user
                    self?.isAuthenticated = true
                    print("AuthViewModel: Previous sign-in restored")
                case .failure(let error):
                    self?.googleUser = nil
                    self?.isAuthenticated = false
                    print("AuthViewModel: No previous sign-in found: \(error.localizedDescription)")
                }
            }
        }
    }

    func clearErrorMessage() {
        errorMessage = nil
    }
} 