//
//  WeatherViewModel.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 16.04.24.
//


import Foundation
import MapKit

class WeatherViewModel: ObservableObject {
    private let baseURL = "https://api.stormglass.io/v2/weather/point"
    private let apiKey = APIConfig.stormGlassAPIKey

    @Published var weatherData: WeatherData?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func fetchWeatherDataByCoordinates(latitude: Double, longitude: Double) async {
        isLoading = true
        let urlString = "\(baseURL)?lat=\(latitude)&lng=\(longitude)"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
                self.isLoading = false
            }
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch weather data: Server error"
                    self.isLoading = false
                }
                return
            }

            let decodedData = try JSONDecoder().decode(WeatherData.self, from: data)
            DispatchQueue.main.async {
                self.weatherData = decodedData
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch weather data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // Fetch weather data by location name using MapKit's geocoding
    func fetchWeatherDataByLocation(location: String) async {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Geocoding error: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }

            guard let coordinate = placemarks?.first?.location?.coordinate else {
                DispatchQueue.main.async {
                    self.errorMessage = "No coordinates found for location"
                    self.isLoading = false
                }
                return
            }

            Task {
                await self.fetchWeatherDataByCoordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
        }
    }
}
