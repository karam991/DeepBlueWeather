//
//  LoginRegisterView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 06.04.24.
//

import SwiftUI

struct LoginRegisterView: View {
    @EnvironmentObject private var loginViewModel : LoginViewModel
    @State private var isLoggingIn = true
    
    var body: some View {
        VStack {
            
            Image("DiverAppIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            Text("DEEP BLUE WEATHER")
                .font(.title)
                .fontWeight(.bold)
            
            
            Picker(selection: $isLoggingIn, label: Text("")) {
                Text("Login").tag(true)
                Text("Register").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Text Fields
            TextField("Email", text: $loginViewModel.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Password", text: $loginViewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                if isLoggingIn {
                    loginViewModel.login()
                } else {
                    loginViewModel.register()                 }
            }) {
                Text(isLoggingIn ? "Login" : "Register")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()
            
            if isLoggingIn {
                Button(action: {
                    // func
                }) {
                    Text("Forgot Password?")
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            BackgroundImageView()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
        )
    }
}

struct LoginRegisterView_Previews: PreviewProvider {
    static var previews: some View {
        LoginRegisterView()
    }
}
