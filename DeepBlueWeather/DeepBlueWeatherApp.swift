//
//  DeepBlueWeatherApp.swift
//  DeepBlueWeather
//
//  Created by Karam Alnaser on 26.02.24.
//
import SwiftUI
import Firebase

@main
struct DeepBlueWeatherApp: App {
    @StateObject private var loginViewModel = LoginViewModel()
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var divePlannerViewModel: DivePlannerViewModel
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    /// Debug-only: `-showLogin` launch argument shows the login screen (used for README screenshots).
    #if DEBUG
    private static let forceLoginScreen = CommandLine.arguments.contains("-showLogin")
    #else
    private static let forceLoginScreen = false
    #endif

    init() {
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
        let weatherVM = WeatherViewModel()
        _divePlannerViewModel = StateObject(wrappedValue: DivePlannerViewModel(weatherViewModel: weatherVM))
        _weatherViewModel = StateObject(wrappedValue: weatherVM)
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if CommandLine.arguments.contains("-designGallery") {
                DesignGalleryView()
            } else {
                appContent
            }
            #else
            appContent
            #endif
        }
    }

    private var appContent: some View {
        Group {
            if loginViewModel.userIsLoggedIn && !Self.forceLoginScreen {
                HomeScreen()
                    .environmentObject(loginViewModel)
                    .environmentObject(weatherViewModel)
                    .environmentObject(divePlannerViewModel)
                    .transition(.opacity)
            } else {
                LoginRegisterView()
                    .environmentObject(loginViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: loginViewModel.userIsLoggedIn)
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}
