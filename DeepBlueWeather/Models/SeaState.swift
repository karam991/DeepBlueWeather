//
//  SeaState.swift
//  DeepBlueWeather
//
//  Turns forecast data into the visual parameters of the living ocean.
//

import Foundation

struct SeaState: Equatable {
    /// Wave height in metres.
    var waveHeight: Double
    /// 0…1, from wind speed.
    var chop: Double
    /// 1 = solar noon, 0 = horizon, negative = night.
    var sunElevation: Double
    /// 0…1, from rain probability.
    var cloud: Double

    init(waveHeight: Double, chop: Double, sunElevation: Double, cloud: Double) {
        self.waveHeight = waveHeight
        self.chop = chop
        self.sunElevation = sunElevation
        self.cloud = cloud
    }

    /// Nil without marine data: the app never draws a sea it has no numbers for.
    init?(hour: HourlyWeather, sunDays: [SunDay]) {
        guard let waves = hour.waveHeight else { return nil }
        self.init(
            waveHeight: min(waves, 3),
            chop: min(hour.windSpeed / 45, 1),
            sunElevation: Self.elevation(at: hour.date, sunDays: sunDays),
            cloud: min(max(((hour.precipitationProbability ?? 0) - 10) / 70, 0), 1)
        )
    }

    /// A calm sea lit by the device clock, for screens without forecast data (login).
    static func ambient(at date: Date = Date(), calendar: Calendar = .current) -> SeaState {
        let sunrise = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: date) ?? date
        let sunset = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: date) ?? date
        return SeaState(waveHeight: 0.5, chop: 0.2,
                        sunElevation: elevation(at: date, sunDays: [SunDay(sunrise: sunrise, sunset: sunset)]),
                        cloud: 0)
    }

    /// Approximate sun height from sunrise and sunset.
    static func elevation(at date: Date?, sunDays: [SunDay]) -> Double {
        guard let date,
              let day = sunDays.first(where: { Calendar.current.isDate($0.sunrise, inSameDayAs: date) })
        else { return 0.7 }
        if date >= day.sunrise && date <= day.sunset {
            let progress = date.timeIntervalSince(day.sunrise) / day.sunset.timeIntervalSince(day.sunrise)
            return sin(progress * .pi)
        }
        let distance = min(abs(date.timeIntervalSince(day.sunrise)), abs(date.timeIntervalSince(day.sunset)))
        return -min(distance / (90 * 60), 1) * 0.5
    }
}
