//
//  HomeScreenView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct HomeScreen: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WeatherInfoView()
                .tabItem {
                    Label("Weather", systemImage: "sun.haze.circle.fill")
                }
                .tag(0)

            NavigationView {
                DivePlannerScreen()
            }
            .tabItem {
                Label("Dive Planner", systemImage: "square.and.pencil")
            }
            .tag(1)

            NavigationView {
                ChecklistScreen()
            }
            .tabItem {
                Label("Checklist", systemImage: "list.bullet")
            }
            .tag(2)

            NavigationView {
                SettingsScreen()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(3)
        }
        .accentColor(.yellow)
        .edgesIgnoringSafeArea(.all)
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
