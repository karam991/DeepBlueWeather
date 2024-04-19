//
//  DeepBlueWeatherApp.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI
import Firebase

@main
struct DeepBlueWeatherApp: App {
    
    @StateObject var loginViewModel = LoginViewModel()
    
    init() {
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if loginViewModel.userIsLoggedIn {
                HomeScreen(selectedDivePlan: .constant(DivePlan(userId: "jgrfwsgdejfgjsgfjs", location: "Abhu Dahbi", date: "22.09.2025", depth: 20, duration: 45, deepDive: true, nightDive: false)))
                    .environmentObject(loginViewModel)
                    .environmentObject(DivePlannerViewModel(weatherViewModel: WeatherViewModel())) 
            } else {
                LoginRegisterView()
                    .environmentObject(loginViewModel)
            }
        }
    }
}
