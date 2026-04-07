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
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var divePlannerViewModel: DivePlannerViewModel

    init() {
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
        let weatherVM = WeatherViewModel()
        _divePlannerViewModel = StateObject(wrappedValue: DivePlannerViewModel(weatherViewModel: weatherVM))
        _weatherViewModel = StateObject(wrappedValue: weatherVM)
    }

    var body: some Scene {
        WindowGroup {
            if loginViewModel.userIsLoggedIn {
                HomeScreen()
                    .environmentObject(loginViewModel)
                    .environmentObject(weatherViewModel)
                    .environmentObject(divePlannerViewModel)
            } else {
                LoginRegisterView()
                    .environmentObject(loginViewModel)
            }
        }
    }
}
