//
//  BackgroundImageView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct BackgroundImageView: View {
    var body: some View {
        Image("DiverBackground") // 
            .resizable()
            .scaledToFill()
            .blur(radius: /*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
            .edgesIgnoringSafeArea(.all)
            .opacity(0.5)
    }
}

struct BackgroundImageView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundImageView()
    }
}

