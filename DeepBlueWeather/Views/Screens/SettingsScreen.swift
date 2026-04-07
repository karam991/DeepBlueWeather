//
//  SettingsScreen.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color("SoftTeal")))
                }

                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(Color("OceanBlue"))
                        Text(loginViewModel.email.isEmpty ? "Logged in" : loginViewModel.email)
                            .foregroundColor(.primary)
                    }

                    Button(action: {
                        loginViewModel.logout()
                    }) {
                        HStack {
                            Image(systemName: "arrow.backward.circle")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color("OceanBlue"))
                        Text("DeepBlueWeather v1.0")
                            .foregroundColor(.primary)
                    }
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(Color("OceanBlue"))
                        Text("Weather data by Open-Meteo")
                            .foregroundColor(.primary)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Settings", displayMode: .large)
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
            .environmentObject(LoginViewModel())
    }
}
