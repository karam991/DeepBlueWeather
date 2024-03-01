//
//  NavigationOptionsView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct NavigationOptionsView: View {
    var body: some View {
        HStack {
            Button(action: {
                // Action for navigating to dive planner
            }) {
                Text("Dive Planner")
            }
            .padding()
            
            Spacer()
            
            Button(action: {
                // Action for navigating to checklist
            }) {
                Text("Checklist")
            }
            .padding()
            
            Spacer()
            
            Button(action: {
                // Action for navigating to settings
            }) {
                Text("Settings")
            }
            .padding()
        }
        .background(Color.gray.opacity(0.5)) // Placeholder background color
        .padding(.horizontal)
    }
}

struct NavigationOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationOptionsView()
    }
}
