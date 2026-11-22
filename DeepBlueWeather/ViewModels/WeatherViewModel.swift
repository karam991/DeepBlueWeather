//
//  WeatherViewModel.swift
//  DeepBlueWeather
//

import Foundation
import MapKit

// MARK: - Weather service (shared fetching logic)

enum WeatherService {
    private static let marineBaseURL = "https://marine-api.open-meteo.com/v1/marine"
    private static let forecastBaseURL = "https://api.open-meteo.com/v1/forecast"

    static func coordinate(for location: String) async throws -> CLLocationCoordinate2D? {
        let placemarks = try await CLGeocoder().geocodeAddressString(location)
        return placemarks.first?.location?.coordinate
    }

    /// Fetches forecast + marine data and merges them per hour. Returns nil if the forecast fails.
    static func hours(latitude: Double, longitude: Double) async -> [HourlyWeather]? {
        await weather(latitude: latitude, longitude: longitude)?.hours
    }

    static func weather(latitude: Double, longitude: Double) async -> WeatherData? {
        async let forecastResult = fetchForecast(lat: latitude, lng: longitude)
        async let marineResult = fetchMarine(lat: latitude, lng: longitude)

        guard let forecast = await forecastResult else { return nil }
        let marine = await marineResult
        let f = forecast.hourly

        // Marine data is matched by timestamp so differing array lengths can never crash.
        var marineByTime: [String: (wave: Double?, water: Double?, level: Double?)] = [:]
        if let m = marine?.hourly {
            for (i, t) in m.time.enumerated() {
                marineByTime[t] = (m.waveHeight[safe: i] ?? nil,
                                   m.seaSurfaceTemperature[safe: i] ?? nil,
                                   m.seaLevelHeight?[safe: i] ?? nil)
            }
        }

        var sunDays: [SunDay] = []
        if let daily = forecast.daily {
            for (rise, set) in zip(daily.sunrise, daily.sunset) {
                if let r = DateFormatter.iso8601Full.date(from: rise), let s = DateFormatter.iso8601Full.date(from: set) {
                    sunDays.append(SunDay(sunrise: r, sunset: s))
                }
            }
        }

        let hours: [HourlyWeather] = f.time.indices.map { i in
            let marineHour = marineByTime[f.time[i]]
            return HourlyWeather(
                time: f.time[i],
                airTemperature: f.temperature2m[i],
                windSpeed: f.windSpeed10m[i],
                humidity: f.relativeHumidity2m[i],
                pressure: f.pressureMsl[i],
                visibility: f.visibility[i],
                waveHeight: marineHour?.wave ?? nil,
                waterTemperature: marineHour?.water ?? nil,
                precipitationProbability: f.precipitationProbability?[safe: i] ?? nil,
                precipitation: f.precipitation?[safe: i] ?? nil,
                uvIndex: f.uvIndex?[safe: i] ?? nil,
                seaLevel: marineHour?.level ?? nil
            )
        }
        return WeatherData(hours: hours, sunDays: sunDays)
    }

    /// Local highs and lows of the sea level curve.
    static func tideExtremes(in hours: [HourlyWeather]) -> [TideExtreme] {
        let points = hours.compactMap { h -> (Date, Double)? in
            guard let d = h.date, let l = h.seaLevel else { return nil }
            return (d, l)
        }
        guard points.count >= 3 else { return [] }
        var result: [TideExtreme] = []
        for i in 1..<(points.count - 1) {
            let (prev, cur, next) = (points[i - 1].1, points[i].1, points[i + 1].1)
            if cur > prev && cur >= next {
                result.append(TideExtreme(kind: .high, date: points[i].0, height: cur))
            } else if cur < prev && cur <= next {
                result.append(TideExtreme(kind: .low, date: points[i].0, height: cur))
            }
        }
        return result
    }

    private static func fetchForecast(lat: Double, lng: Double) async -> ForecastResponse? {
        let urlString = "\(forecastBaseURL)?latitude=\(lat)&longitude=\(lng)&hourly=temperature_2m,wind_speed_10m,relative_humidity_2m,pressure_msl,visibility,precipitation_probability,precipitation,uv_index&daily=sunrise,sunset&forecast_days=7"
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(ForecastResponse.self, from: data)
        } catch {
            print("Forecast fetch error: \(error)")
            return nil
        }
    }

    private static func fetchMarine(lat: Double, lng: Double) async -> MarineResponse? {
        let urlString = "\(marineBaseURL)?latitude=\(lat)&longitude=\(lng)&hourly=wave_height,sea_surface_temperature,sea_level_height_msl&forecast_days=7"
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

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - View model

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weatherData: WeatherData?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentLocation: String = ""

    func fetchWeatherDataByLocation(location: String) async {
        isLoading = true
        errorMessage = nil
        currentLocation = location

        do {
            guard let coordinate = try await WeatherService.coordinate(for: location) else {
                errorMessage = "Location not found"
                isLoading = false
                return
            }
            await fetchWeatherDataByCoordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        } catch {
            errorMessage = "Could not find location: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func fetchWeatherDataByCoordinates(latitude: Double, longitude: Double) async {
        isLoading = true

        guard let data = await WeatherService.weather(latitude: latitude, longitude: longitude) else {
            errorMessage = "Failed to fetch weather data"
            isLoading = false
            return
        }

        weatherData = data
        isLoading = false
        errorMessage = nil
    }
}
