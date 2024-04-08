//
//  SettingsScreen.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var loginViewModel : LoginViewModel
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
            
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
            
            Toggle("Dark Mode", isOn: $darkModeEnabled)
            
            Button(action: {
                loginViewModel.logout()

            }) {
                Text("Sign Out")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
        .background(
            BackgroundImageView()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
        )
        .navigationBarTitle("Settings")
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsScreen()
        }
    }
}

