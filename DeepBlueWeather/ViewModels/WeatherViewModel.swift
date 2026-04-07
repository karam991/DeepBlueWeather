//
//  WeatherViewModel.swift
//  DeepBlueWeather
//

import Foundation
import MapKit

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weatherData: WeatherData?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentLocation: String = ""

    private let marineBaseURL = "https://marine-api.open-meteo.com/v1/marine"
    private let forecastBaseURL = "https://api.open-meteo.com/v1/forecast"

    func fetchWeatherDataByLocation(location: String) async {
        isLoading = true
        errorMessage = nil
        currentLocation = location

        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(location)
            guard let coordinate = placemarks.first?.location?.coordinate else {
                errorMessage = "Location not found"
                isLoading = false
                return
            }
            await fetchWeatherDataByCoordinates(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            errorMessage = "Could not find location: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func fetchWeatherDataByCoordinates(latitude: Double, longitude: Double) async {
        isLoading = true

        async let forecastResult = fetchForecast(lat: latitude, lng: longitude)
        async let marineResult = fetchMarine(lat: latitude, lng: longitude)

        let forecast = await forecastResult
        let marine = await marineResult

        guard let forecast = forecast else {
            errorMessage = "Failed to fetch weather data"
            isLoading = false
            return
        }

        let hours: [HourlyWeather] = forecast.hourly.time.indices.map { i in
            HourlyWeather(
                time: forecast.hourly.time[i],
                airTemperature: forecast.hourly.temperature2m[i],
                windSpeed: forecast.hourly.windSpeed10m[i],
                humidity: forecast.hourly.relativeHumidity2m[i],
                pressure: forecast.hourly.pressureMsl[i],
                visibility: forecast.hourly.visibility[i],
                waveHeight: marine?.hourly.waveHeight[i] ?? nil,
                waterTemperature: marine?.hourly.seaSurfaceTemperature[i] ?? nil
            )
        }

        weatherData = WeatherData(hours: hours)
        isLoading = false
        errorMessage = nil
    }

    // MARK: - Private fetch helpers

    private func fetchForecast(lat: Double, lng: Double) async -> ForecastResponse? {
        let urlString = "\(forecastBaseURL)?latitude=\(lat)&longitude=\(lng)&hourly=temperature_2m,wind_speed_10m,relative_humidity_2m,pressure_msl,visibility"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(ForecastResponse.self, from: data)
        } catch {
            print("Forecast fetch error: \(error)")
            return nil
        }
    }

    private func fetchMarine(lat: Double, lng: Double) async -> MarineResponse? {
        let urlString = "\(marineBaseURL)?latitude=\(lat)&longitude=\(lng)&hourly=wave_height,sea_surface_temperature"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(MarineResponse.self, from: data)
        } catch {
            print("Marine fetch error: \(error)")
            return nil
        }
    }
}
