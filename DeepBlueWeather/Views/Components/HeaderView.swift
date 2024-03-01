//
//  HeaderView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack {
            Image("DiverAppIcon") // Replace "your_logo" with the name of your image asset
                           .resizable()
                           .aspectRatio(contentMode: .fit)
                           .frame(width: 100, height: 100)
            Text("Deep Blue Weather") // Replace with your app name
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            // Add any additional header content here
        }
        .background(Color.blue) // Replace with your desired background color
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
            .previewLayout(.fixed(width: 375, height: 200)) // Adjust preview size as needed
            .background(Color.black) // Adjust preview background color for better visibility
    }
}
