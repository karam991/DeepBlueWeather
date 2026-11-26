//
//  ConditionsForecast.swift
//  DeepBlueWeather
//
//  What the Conditions screen shows: the next 24 hours, the best dive window
//  and the text that describes an hour.
//

import Foundation

struct ConditionsForecast {
    let location: String
    let hours: [HourlyWeather]
    let sunDays: [SunDay]

    init(location: String, data: WeatherData?, now: Date = Date()) {
        self.location = location.isEmpty ? "Current location" : location.capitalized
        let earliest = now.addingTimeInterval(-3600)
        hours = Array((data?.hours ?? []).filter { ($0.date ?? .distantPast) >= earliest }.prefix(24))
        sunDays = data?.sunDays ?? []
    }

    func hour(id: UUID?) -> HourlyWeather? {
        hours.first { $0.id == id } ?? hours.first
    }

    func hour(nearest date: Date) -> HourlyWeather? {
        hours.min {
            abs(($0.date ?? .distantPast).timeIntervalSince(date))
                < abs(($1.date ?? .distantPast).timeIntervalSince(date))
        }
    }

    /// The hour `offset` steps after (or before) the given one, kept in range.
    func hour(after id: UUID?, offset: Int) -> HourlyWeather? {
        guard let current = hours.firstIndex(where: { $0.id == hour(id: id)?.id }) else { return nil }
        return hours[min(max(current + offset, 0), hours.count - 1)]
    }

    /// Calmest daylight hour in the next 24 h (lowest waves, wind and rain).
    var bestHour: HourlyWeather? {
        func score(_ h: HourlyWeather) -> Double {
            (h.waveHeight ?? 0) * 10 + h.windSpeed * 0.3 + (h.precipitationProbability ?? 0) * 0.05
        }
        return hours
            .filter { h in
                guard let date = h.date else { return false }
                return (7...18).contains(Calendar.current.component(.hour, from: date))
            }
            .min { score($0) < score($1) }
    }
}

extension HourlyWeather {
    var condition: DiveCondition { DiveCondition(waveHeight: waveHeight, windSpeed: windSpeed) }
    var hasMarineData: Bool { waveHeight != nil }
    var waterText: String { waterTemperature.map { String(format: "%.0f°", $0) } ?? "—" }
    var airText: String { String(format: "%.0f°", airTemperature) }
    var suit: ExposureSuit? { waterTemperature.map { ExposureSuit(water: $0) } }

    var seaSummary: String {
        // Word joiners keep "km/h" on one line at large text sizes.
        let wind = String(format: "%.0f km\u{2060}/\u{2060}h wind", windSpeed)
        guard let waveHeight else { return wind }
        return String(format: "%.1f m waves", waveHeight) + " · " + wind
    }

    /// "tomorrow at 13:00": only relative day names are lowercased.
    var whenText: String {
        let day = ["Today", "Tomorrow"].contains(dayLabel) ? dayLabel.lowercased() : dayLabel
        return "\(day) at \(timeLabel)"
    }

    /// Values the hero does not show.
    var secondaryFacts: [Fact] {
        var facts = [Fact(title: "Air", value: airText, spoken: String(format: "Air %.0f degrees", airTemperature))]
        if let rain = precipitationProbability {
            facts.append(Fact(title: "Rain", value: String(format: "%.0f%%", rain), spoken: String(format: "Rain probability %.0f percent", rain)))
        } else {
            facts.append(Fact(title: "Humidity", value: String(format: "%.0f%%", humidity), spoken: String(format: "Humidity %.0f percent", humidity)))
        }
        if let uv = uvIndex {
            facts.append(Fact(title: "UV", value: String(format: "%.0f", uv), spoken: String(format: "UV index %.0f", uv)))
        }
        facts.append(Fact(title: "Air visibility", value: visibilityLabel, spoken: "Air visibility \(visibilityLabel)"))
        return facts
    }

    /// One VoiceOver sentence for a hero.
    func spokenSummary(location: String) -> String {
        var parts = [location, "\(dayLabel) \(timeLabel)"]
        if hasMarineData {
            parts.append("Dive conditions \(condition.label)")
            if let water = waterTemperature { parts.append(String(format: "Water %.0f degrees", water)) }
            if let suit { parts.append(suit.label) }
            if let waveHeight { parts.append(String(format: "Waves %.1f metres", waveHeight)) }
        } else {
            parts.append("No marine data")
            parts.append(String(format: "Air %.0f degrees", airTemperature))
        }
        parts.append(String(format: "Wind %.0f kilometres per hour", windSpeed))
        return parts.joined(separator: ", ")
    }
}

struct Fact: Identifiable {
    var id: String { title }
    let title: String
    let value: String
    let spoken: String
}

/// Remembers that the "excellent conditions" glint already played today.
enum GlintLog {
    private static let key = "delight.glint"

    static func claim(location: String, now: Date = Date(), defaults: UserDefaults = .standard) -> Bool {
        let stamp = location.lowercased() + "|" + now.formatted(.iso8601.year().month().day())
        var seen = defaults.stringArray(forKey: key) ?? []
        guard !seen.contains(stamp) else { return false }
        seen.append(stamp)
        defaults.set(Array(seen.suffix(20)), forKey: key)
        return true
    }
}
