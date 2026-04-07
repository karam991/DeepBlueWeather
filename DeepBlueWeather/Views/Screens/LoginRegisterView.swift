//
//  LoginRegisterView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 06.04.24.
//

import SwiftUI

struct LoginRegisterView: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @State private var isLoggingIn = true
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Ocean gradient background
            LinearGradient(
                colors: [Color("OceanBlue"), Color("SoftTeal").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + Title
                VStack(spacing: 12) {
                    Image(systemName: "water.waves")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    Text("DeepBlue Weather")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Dive conditions at your fingertips")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 48)

                // Card
                VStack(spacing: 20) {
                    // Segmented picker
                    Picker("", selection: $isLoggingIn) {
                        Text("Login").tag(true)
                        Text("Register").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    // Email field
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                        TextField("Email", text: $loginViewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // Password field
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        SecureField("Password", text: $loginViewModel.password)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // Action button
                    Button(action: {
                        if isLoggingIn {
                            loginViewModel.login()
                        } else {
                            loginViewModel.register()
                        }
                    }) {
                        Text(isLoggingIn ? "Login" : "Create Account")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("OceanBlue"))
                            .cornerRadius(12)
                    }

                    if isLoggingIn {
                        Button("Forgot Password?") {
                            // TODO: implement password reset
                        }
                        .foregroundColor(Color("OceanBlue"))
                        .font(.subheadline)
                    }
                }
                .padding(24)
                .background(Color(.systemBackground).opacity(0.95))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 24)

                Spacer()

                Text("Weather data by Open-Meteo")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 24)
            }
        }
    }
}

struct LoginRegisterView_Previews: PreviewProvider {
    static var previews: some View {
        LoginRegisterView()
            .environmentObject(LoginViewModel())
    }
}
