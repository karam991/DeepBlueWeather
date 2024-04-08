//
//  WeatherInfoView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct WeatherInfoView: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Temperature: 23°C")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .padding()

                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Weather Condition: Sunny")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .padding()
            }
            
            HStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Wind Speed: 5 mph")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .padding()

                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Visibility: 10 miles")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .padding()
            }
            
            HStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Water Temperature: 25°C")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .padding()

                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Wave Height: 2 feet")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .padding()
            }
            
            HStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Currents: Mild")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .padding()

                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Tide: Incoming")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .padding()
            }
            
            Spacer()

        }
        .background(
            BackgroundImageView()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

        )
        .onAppear {
            withAnimation(.spring()) {
                // Add any other animations or changes you want to perform
            }
        }
    }
}

struct WeatherInfoView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherInfoView()
    }
}




