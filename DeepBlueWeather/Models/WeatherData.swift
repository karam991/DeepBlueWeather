//
//  WeatherData.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 16.04.24.
//

import Foundation

struct WeatherData: Codable, Identifiable {
    let id = UUID()
    let hours: [Hour]
    var wholeDay : [Hour] {Array(hours[0...23])}
}

struct Hour: Codable, Identifiable{
    
    let id = UUID()
    var time : String
    let airTemperature, waterTemperature, windSpeed, humidity, pressure, visibility, waveHeight: [WeatherValue]
    var temperature: Double { airTemperature.first?.value ?? 0.0 }
    var waterTemp: Double { waterTemperature.first?.value ?? 0.0 }
    var wind: Double { windSpeed.first?.value ?? 0.0 }
    var humidityValue: Double { humidity.first?.value ?? 0.0 }
    var pressureValue: Double { pressure.first?.value ?? 0.0 }
    var visibilityValue: Double { visibility.first?.value ?? 0.0 }
    var waveHeightValue: Double { waveHeight.first?.value ?? 0.0 }
}

struct WeatherValue: Codable, Identifiable {
    let id = UUID()

    let value: Double
    let source: String
}

/*struct WeatherData: Codable {
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
*/
