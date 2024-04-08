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
    var userIsLoggedIn : Bool {
        Auth.auth().currentUser != nil
    }
    
    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error registering user: \(error.localizedDescription)")
            } else if let user = authResult?.user {
                print("User registered successfully: \(user.uid)")
                self.isUserLoggedIn = true
            }
        }
    }
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
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
            self.isUserLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    
}

