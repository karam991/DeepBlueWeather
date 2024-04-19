//
//  WeatherInfoView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct WeatherInfoView: View {
    @ObservedObject var weatherViewModel: WeatherViewModel

    @State private var searchText = ""

    @EnvironmentObject var divePlannerViewModel: DivePlannerViewModel

    var body: some View {
        VStack {
            SearchBarView(text: $searchText, isSearching: .constant(false))
                .padding(.top)
                .onChange(of: searchText) { newValue in
                    Task {
                        await weatherViewModel.fetchWeatherDataByLocation(location: newValue) // <- Using weatherViewModel
                    }
                }

            if let weatherData = weatherViewModel.weatherData {
                Text("Weather Information")
                    .font(.title)
                    .padding()

                HStack {
                    WeatherInfoBox(title: "Temperature", value: "\(weatherData.temperature) °C")
                    WeatherInfoBox(title: "Humidity", value: "\(weatherData.humidity)%")
                }
                .padding()

                HStack {
                    WeatherInfoBox(title: "Pressure", value: "\(weatherData.pressure) hPa")
                    WeatherInfoBox(title: "Visibility", value: "\(weatherData.visibility) m")
                }
                .padding()

                HStack {
                    WeatherInfoBox(title: "UV Index", value: "\(weatherData.uvIndex)")
                    WeatherInfoBox(title: "Precipitation", value: "\(weatherData.precipitation) mm")
                }
                .padding()

                Text("Weather Conditions:")
                    .padding(.top)
                ForEach(weatherData.weatherCondition, id: \.self) { condition in
                    Text(condition.rawValue.capitalized)
                }
            } else if weatherViewModel.isLoading {
                ProgressView("Loading Weather...")
            } else if let message = weatherViewModel.errorMessage {
                Text(message)
                    .foregroundColor(.red)
            } else {
                Text("Please enter a location to see the weather.")
            }
        }
        .onAppear {
            if let location = divePlannerViewModel.selectedDivePlan?.location {
                Task {
                    await weatherViewModel.fetchWeatherDataByLocation(location: location) // <- Using weatherViewModel
                }
            }
        }
    }
}

struct WeatherInfoBox: View {
    var title: String
    var value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.body)
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(10)
    }
}

struct WeatherInfoView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherInfoView(weatherViewModel: WeatherViewModel())
            .environmentObject(WeatherViewModel()) // <- Providing WeatherViewModel
    }
}

