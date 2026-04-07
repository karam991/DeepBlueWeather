//
//  WeatherData.swift
//  DeepBlueWeather
//

import Foundation

// MARK: - Combined weather model used by the UI
struct WeatherData: Identifiable {
    let id = UUID()
    let hours: [HourlyWeather]
}

// MARK: - One hour of combined marine + forecast data
struct HourlyWeather: Identifiable {
    let id = UUID()
    let time: String
    let airTemperature: Double
    let windSpeed: Double
    let humidity: Double
    let pressure: Double
    let visibility: Double
    let waveHeight: Double?         // nil for inland locations
    let waterTemperature: Double?   // nil for inland locations
}

// MARK: - Open-Meteo Marine API response
struct MarineResponse: Codable {
    let hourly: MarineHourly
}

struct MarineHourly: Codable {
    let time: [String]
    let waveHeight: [Double?]
    let seaSurfaceTemperature: [Double?]

    enum CodingKeys: String, CodingKey {
        case time
        case waveHeight = "wave_height"
        case seaSurfaceTemperature = "sea_surface_temperature"
    }
}

// MARK: - Open-Meteo Forecast API response
struct ForecastResponse: Codable {
    let hourly: ForecastHourly
}

struct ForecastHourly: Codable {
    let time: [String]
    let temperature2m: [Double]
    let windSpeed10m: [Double]
    let relativeHumidity2m: [Double]
    let pressureMsl: [Double]
    let visibility: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case windSpeed10m = "wind_speed_10m"
        case relativeHumidity2m = "relative_humidity_2m"
        case pressureMsl = "pressure_msl"
        case visibility
    }
}
