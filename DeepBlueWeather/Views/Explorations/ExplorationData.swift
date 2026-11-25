//
//  ExplorationData.swift
//  DeepBlueWeather
//
//  Design exploration: presentation model and sample data for the three
//  Conditions variants. Views only read from here; no networking.
//

import Foundation

// MARK: - Sea state (data → visuals)

/// Visual parameters derived from one forecast hour.
struct SeaState: Equatable {
    /// Wave height in metres.
    var waveHeight: Double
    /// 0…1, from wind speed.
    var chop: Double
    /// 1 = solar noon, 0 = horizon, negative = night.
    var sunElevation: Double
    /// 0…1, from rain probability.
    var cloud: Double

    var isNight: Bool { sunElevation < -0.1 }

    init(hour: HourlyWeather, sunDays: [SunDay]) {
        waveHeight = min(hour.waveHeight ?? 0, 3)
        chop = min(hour.windSpeed / 45, 1)
        cloud = min(max(((hour.precipitationProbability ?? 0) - 10) / 70, 0), 1)
        sunElevation = Self.elevation(at: hour.date, sunDays: sunDays)
    }

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

// MARK: - One screen's worth of data

struct ConditionsSnapshot {
    let location: String
    let hours: [HourlyWeather]
    let sunDays: [SunDay]

    func hour(_ index: Int) -> HourlyWeather { hours[min(max(index, 0), hours.count - 1)] }

    func sea(_ index: Int) -> SeaState { SeaState(hour: hour(index), sunDays: sunDays) }

    func condition(_ index: Int) -> DiveCondition {
        DiveCondition(waveHeight: hour(index).waveHeight, windSpeed: hour(index).windSpeed)
    }

    /// Same scoring as the current Conditions screen.
    var bestIndex: Int? {
        func score(_ h: HourlyWeather) -> Double {
            (h.waveHeight ?? 0) * 10 + h.windSpeed * 0.3 + (h.precipitationProbability ?? 0) * 0.05
        }
        return hours.indices
            .filter { i in
                guard let d = hours[i].date else { return false }
                return (7...18).contains(Calendar.current.component(.hour, from: d))
            }
            .min { score(hours[$0]) < score(hours[$1]) }
    }

    func index(nearest date: Date) -> Int {
        hours.indices.min {
            abs((hours[$0].date ?? .distantPast).timeIntervalSince(date))
                < abs((hours[$1].date ?? .distantPast).timeIntervalSince(date))
        } ?? 0
    }

    /// "tomorrow at 13:00" — only relative day names are lowercased.
    func when(_ index: Int) -> String {
        let h = hour(index)
        let day = ["Today", "Tomorrow"].contains(h.dayLabel) ? h.dayLabel.lowercased() : h.dayLabel
        return "\(day) at \(h.timeLabel)"
    }

    /// Headline word for the editorial variant.
    func verdict(_ index: Int) -> String {
        let night = sea(index).isNight
        switch condition(index) {
        case .excellent: return night ? "Still night." : "Glassy."
        case .good: return night ? "Quiet night." : "Go dive."
        case .fair: return "Choppy."
        case .poor: return "Stay dry."
        }
    }

    /// Water temperature → exposure suit (same bands as SmartGearEngine).
    func suit(_ index: Int) -> String? {
        guard let water = hour(index).waterTemperature?.rounded() else { return nil }
        switch water {
        case ..<12: return "Drysuit"
        case 12..<18: return "7 mm wetsuit"
        case 18..<24: return "5 mm wetsuit"
        case 24..<28: return "3 mm wetsuit"
        default: return "Shorty"
        }
    }

    var tideExtremes: [TideExtreme] { WeatherService.tideExtremes(in: hours) }
}

// MARK: - Sample data

extension ConditionsSnapshot {
    static let calm = sample(location: "Nice, France", startHour: 11, wave: 0.25, wind: 7, water: 22.4, air: 25.2, rain: 0, uv: 7)
    static let rough = sample(location: "Biarritz, France", startHour: 16, wave: 2.1, wind: 37, water: 16.2, air: 14.1, rain: 75, uv: 1)
    static let night = sample(location: "Hurghada, Egypt", startHour: 23, wave: 0.65, wind: 13, water: 24.8, air: 21.3, rain: 0, uv: 0)

    private static func sample(location: String, startHour: Int, wave: Double, wind: Double,
                               water: Double, air: Double, rain: Double, uv: Double) -> ConditionsSnapshot {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: Date())
        func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let d = calendar.date(byAdding: .day, value: dayOffset, to: day)!
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: d)!
        }
        let sunDays = (0...2).map { SunDay(sunrise: at($0, 6, 5), sunset: at($0, 20, 40)) }

        let hours: [HourlyWeather] = (0..<24).map { i in
            let date = at(0, startHour).addingTimeInterval(Double(i) * 3600)
            let t = Double(i)
            let swing = sin(t / 24 * 2 * .pi + 0.4) - sin(0.4)
            let daytime = max(0, sin((Double(calendar.component(.hour, from: date)) - 6) / 15 * .pi))
            return HourlyWeather(
                time: DateFormatter.iso8601Full.string(from: date),
                airTemperature: air + swing * 2.6,
                windSpeed: max(2, wind * (1 + 0.35 * sin(t / 5.5))),
                humidity: 68 + 10 * sin(t / 7),
                pressure: rain > 40 ? 1002 : 1019,
                visibility: rain > 40 ? 9_000 : 38_000,
                waveHeight: max(0.1, wave * (1 + 0.38 * sin(t / 4.2) + 0.12 * sin(t / 1.9))),
                waterTemperature: water + swing * 0.7,
                precipitationProbability: rain == 0 ? 0 : max(0, rain + 15 * sin(t / 3)),
                precipitation: rain > 40 ? 1.2 : 0,
                uvIndex: uv * daytime,
                seaLevel: 0.42 * sin(t / 12.4 * 2 * .pi + 0.9)
            )
        }
        return ConditionsSnapshot(location: location, hours: hours, sunDays: sunDays)
    }
}
