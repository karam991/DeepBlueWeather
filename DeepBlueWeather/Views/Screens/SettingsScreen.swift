//
//  SettingsScreen.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        VStack {
            HeaderView()
                .padding(.top, 50) // Adjust padding as needed
            
            // Add settings content here
            
            Spacer()
        }
        .background(
            BackgroundImageView() // Set background image
        )
        .edgesIgnoringSafeArea(.all)
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
    }
}

