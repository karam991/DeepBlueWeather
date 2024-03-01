//
//  HomeScreenView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct HomeScreen: View {
    var body: some View {
        TabView {
            DivePlannerScreen()
                .tabItem {
                    Label("Dive Planner", systemImage: "square.and.pencil")
                }
            ChecklistScreen()
                .tabItem {
                    Label("Checklist", systemImage: "list.bullet")
                }
            SettingsScreen()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .accentColor(.yellow) // Optional: Set the accent color of the tab items
        .edgesIgnoringSafeArea(.all) // Optional: Ignore safe area edges for full-screen content
        .background(
            BackgroundImageView()
                .edgesIgnoringSafeArea(.all) // Ensure background image fills the entire screen
        )
        .overlay(
            WeatherInfoView() // Add WeatherInfoView on top of the content
                .padding(.top, 16) // Adjust top padding as needed
                .frame(maxWidth: .infinity, alignment: .top) // Ensure WeatherInfoView spans the entire width
        )
        
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}


