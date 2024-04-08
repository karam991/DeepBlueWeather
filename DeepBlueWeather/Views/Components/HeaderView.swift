//
//  HeaderView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack {
            Image("DiverAppIcon")
                           .resizable()
                           .aspectRatio(contentMode: .fit)
                           .frame(width: 100, height: 100)
            Text("Deep Blue Weather")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            
        }
        .background(Color.blue)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
            .previewLayout(.fixed(width: 300, height: 200)) // Adjust preview size as needed
            .background(Color.black) // Adjust preview background color for better visibility
    }
}
