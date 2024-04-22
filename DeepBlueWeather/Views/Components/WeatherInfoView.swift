//
//  WeatherInfoView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct WeatherInfoView: View {
    @StateObject var weatherViewModel: WeatherViewModel = WeatherViewModel()
    
    @State private var searchText = ""
    @State var hours = 0
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
            
            if let weatherData = weatherViewModel.weatherData, let hourData = weatherData.wholeDay.first {
                Text("Weather Information")
                    .font(.title)
                    .padding()
                List(){
                    ForEach(weatherData.wholeDay){ hour in
                        hourlyWeather( hour: hour)
                        
                    }
                }
            } else if weatherViewModel.isLoading {
                ProgressView("Loading Weather...")
            } else if let message = weatherViewModel.errorMessage {
                Text(message).foregroundColor(.red)
            } else {
                Text("Please enter a location to see the weather.")
            }
        }
        .onAppear {
            if let location = divePlannerViewModel.selectedDivePlan?.location {
                Task {
                    await weatherViewModel.fetchWeatherDataByLocation(location: location)
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
            Text(title).font(.headline)
            Text(value).font(.body)
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(10)
    }
}

struct hourlyWeather : View {
    var hour : Hour
    var body: some View {
        Text("\(hour.time)Uhr")
        HStack {
            WeatherInfoBox(title: "Air Temp", value: "\(hour.temperature) °C")
            WeatherInfoBox(title: "Water Temp", value: "\(hour.waterTemp) °C")
        }
        HStack {
            WeatherInfoBox(title: "Wind Speed", value: "\(hour.wind) km/h")
            WeatherInfoBox(title: "Wave Height", value: "\(hour.waveHeightValue) m")
        }
        HStack {
            WeatherInfoBox(title: "Humidity", value: "\(hour.humidityValue)%")
            WeatherInfoBox(title: "Visibility", value: "\(hour.visibilityValue) m")
        }
    }
}

struct WeatherInfoView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherInfoView(weatherViewModel: WeatherViewModel())
            .environmentObject(WeatherViewModel()) // <- Providing WeatherViewModel
    }
}

