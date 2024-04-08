//
//  HomeScreenView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct HomeScreen: View {
    
    @Binding var selectedDivePlan: DivePlan?

    @State private var selectedTab = 0
    @State private var showingDivePlannerSheet = false
    @State private var showingChecklistSheet = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WeatherInfoView()
                .tabItem {
                    Label ("Weather", systemImage: "sun.haze.circle.fill")
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
        HomeScreen(selectedDivePlan: .constant(DivePlan(userId: "ajgisguewfjaka", location: "Abhu Dahbi", date: "22.09.2025", depth: 20, duration: 45, deepDive: true, nightDive: false)))
    }
}
