//
//  DivePlannerScreen.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct DivePlannerScreen: View {
    var body: some View {
        VStack {
            HeaderView()
                .padding(.top, 50) // Adjust padding as needed
            
            // Add dive planner content here
            
            Spacer()
        }
        .background(
            BackgroundImageView() // Set background image
        )
        .edgesIgnoringSafeArea(.all)
    }
}

struct DivePlannerScreen_Previews: PreviewProvider {
    static var previews: some View {
        DivePlannerScreen()
    }
}
