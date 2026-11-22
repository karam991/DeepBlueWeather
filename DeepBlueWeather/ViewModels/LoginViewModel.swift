//
//  LoginViewModel.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 06.04.24.
//

import Foundation
import Firebase
import FirebaseAuth

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isUserLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String?
    var userIsLoggedIn : Bool {
        Auth.auth().currentUser != nil
    }

    /// Email of the signed-in Firebase user (survives app restarts, unlike `email`).
    var currentUserEmail: String? {
        Auth.auth().currentUser?.email
    }
    
    func register() {
        isLoading = true
        authError = nil
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            self.isLoading = false
            if let error = error {
                self.authError = error.localizedDescription
                print("Error registering user: \(error.localizedDescription)")
            } else if let user = authResult?.user {
                print("User registered successfully: \(user.uid)")
                self.isUserLoggedIn = true
            }
        }
    }
    
    func login() {
        isLoading = true
        authError = nil
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            self.isLoading = false
            if let error = error {
                self.authError = error.localizedDescription
                print("Error logging in: \(error.localizedDescription)")
            } else if authResult != nil {
                print("User logged in successfully")
                self.isUserLoggedIn = true
            }
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            self.password = ""
            self.isUserLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func sendPasswordReset() {
        guard !email.isEmpty else {
            authError = "Enter your email address first."
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            self.authError = error?.localizedDescription ?? "Password reset email sent."
        }
    }
}

