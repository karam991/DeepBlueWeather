//
//  HomeScreenView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct HomeScreen: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var divePlannerViewModel: DivePlannerViewModel

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                WeatherInfoView()
            }
            .tabItem { Label("Conditions", systemImage: "water.waves") }
            .tag(0)

            NavigationStack {
                DivePlannerScreen()
            }
            .tabItem { Label("Dives", systemImage: "figure.open.water.swim") }
            .tag(1)

            NavigationStack {
                ChecklistScreen()
            }
            .tabItem { Label("Checklist", systemImage: "checklist") }
            .tag(2)

            NavigationStack {
                SettingsScreen()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(3)
        }
        .tint(Theme.ocean)
        .onAppear {
            // Load plans right away so reminders and the widget are up to date.
            if divePlannerViewModel.divePlans.isEmpty { divePlannerViewModel.readDivePlans() }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
            .environmentObject(WeatherViewModel())
            .environmentObject(DivePlannerViewModel(weatherViewModel: WeatherViewModel()))
            .environmentObject(LoginViewModel())
    }
}
