//
//  WeatherData.swift
//  DeepBlueWeather
//

import Foundation

// MARK: - Combined weather model used by the UI
struct WeatherData: Identifiable {
    let id = UUID()
    let hours: [HourlyWeather]
    var sunDays: [SunDay] = []
}

// MARK: - Sunrise / sunset for one day
struct SunDay: Hashable {
    let sunrise: Date
    let sunset: Date
}

// MARK: - High / low tide derived from sea level
struct TideExtreme: Identifiable, Hashable {
    enum Kind { case high, low }
    let id = UUID()
    let kind: Kind
    let date: Date
    let height: Double
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
    var precipitationProbability: Double? = nil   // %
    var precipitation: Double? = nil              // mm
    var uvIndex: Double? = nil
    var seaLevel: Double? = nil                   // m above mean sea level (tide)
}

// MARK: - Open-Meteo Marine API response
struct MarineResponse: Codable {
    let hourly: MarineHourly
}

struct MarineHourly: Codable {
    let time: [String]
    let waveHeight: [Double?]
    let seaSurfaceTemperature: [Double?]
    let seaLevelHeight: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case waveHeight = "wave_height"
        case seaSurfaceTemperature = "sea_surface_temperature"
        case seaLevelHeight = "sea_level_height_msl"
    }
}

// MARK: - Open-Meteo Forecast API response
struct ForecastResponse: Codable {
    let hourly: ForecastHourly
    let daily: ForecastDaily?
}

struct ForecastDaily: Codable {
    let sunrise: [String]
    let sunset: [String]
}

struct ForecastHourly: Codable {
    let time: [String]
    let temperature2m: [Double]
    let windSpeed10m: [Double]
    let relativeHumidity2m: [Double]
    let pressureMsl: [Double]
    let visibility: [Double]
    let precipitationProbability: [Double?]?
    let precipitation: [Double?]?
    let uvIndex: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case windSpeed10m = "wind_speed_10m"
        case relativeHumidity2m = "relative_humidity_2m"
        case pressureMsl = "pressure_msl"
        case visibility
        case precipitationProbability = "precipitation_probability"
        case precipitation
        case uvIndex = "uv_index"
    }
}
