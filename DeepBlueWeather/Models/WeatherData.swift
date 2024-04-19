//
//  WeatherData.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 16.04.24.
//

import Foundation

struct WeatherData: Codable {
    let time: String
    let waveHeight: Double
    let windSpeed: Double
    let temperature: Double
    let humidity: Double
    let pressure: Double
    let visibility: Double
    let uvIndex: Double
    let precipitation: Double
    let weatherCondition: [WeatherCondition]

    enum WeatherCondition: String, Codable {
        case sunny
        case cloudy
        case rainy
        case snowy
        case foggy
        case thunderstorm
    }
}
