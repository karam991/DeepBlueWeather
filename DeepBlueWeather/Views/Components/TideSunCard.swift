//
//  TideSunCard.swift
//  DeepBlueWeather
//
//  Tide curve (sea level) with high/low markers plus sunrise & sunset.
//

import SwiftUI
import Charts

struct TideSunCard: View {
    let hours: [HourlyWeather]
    let sunDays: [SunDay]
    var highlight: Date? = nil

    @State private var drawn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var points: [(date: Date, level: Double)] {
        hours.compactMap { h in
            guard let d = h.date, let l = h.seaLevel else { return nil }
            return (d, l)
        }
    }

    private var extremes: [TideExtreme] { WeatherService.tideExtremes(in: hours) }

    private var range: ClosedRange<Date>? {
        guard let first = points.first?.date, let last = points.last?.date, first < last else { return nil }
        return first...last
    }

    private var sunMarks: [(date: Date, isSunrise: Bool)] {
        guard let range else { return [] }
        return sunDays.flatMap { [($0.sunrise, true), ($0.sunset, false)] }
            .filter { range.contains($0.0) }
            .map { (date: $0.0, isSunrise: $0.1) }
    }

    private var today: SunDay? {
        sunDays.first { Calendar.current.isDate($0.sunrise, inSameDayAs: highlight ?? Date()) } ?? sunDays.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            if points.count > 2 {
                tideChart
                tideList
            } else {
                Label("No tide data for this location.", systemImage: "water.waves.slash")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }

            if let day = today {
                Divider()
                HStack(spacing: Theme.Spacing.md) {
                    sunItem(icon: "sunrise.fill", title: "Sunrise", date: day.sunrise, color: Theme.sand)
                    sunItem(icon: "sunset.fill", title: "Sunset", date: day.sunset, color: Theme.coral)
                    sunItem(icon: "sun.max.fill", title: "Daylight", text: daylight(day), color: Theme.kelp)
                }
            }
        }
        .card()
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 1.1)) { drawn = true }
        }
    }

    // MARK: Chart

    private var tideChart: some View {
        let levels = points.map(\.level)
        let minL = (levels.min() ?? 0) - 0.05
        let maxL = (levels.max() ?? 1) + 0.05

        return Chart {
            ForEach(points, id: \.date) { p in
                AreaMark(
                    x: .value("Time", p.date),
                    yStart: .value("Base", minL),
                    yEnd: .value("Level", drawn ? p.level : minL)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(colors: [Theme.ocean.opacity(0.35), Theme.ocean.opacity(0.02)], startPoint: .top, endPoint: .bottom))

                LineMark(x: .value("Time", p.date), y: .value("Level", drawn ? p.level : minL))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.ocean)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }

            ForEach(sunMarks, id: \.date) { mark in
                RuleMark(x: .value("Sun", mark.date))
                    .foregroundStyle((mark.isSunrise ? Theme.sand : Theme.coral).opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, spacing: 2) {
                        Image(systemName: mark.isSunrise ? "sunrise.fill" : "sunset.fill")
                            .font(.caption2)
                            .foregroundStyle(mark.isSunrise ? Theme.sand : Theme.coral)
                    }
            }

            ForEach(extremes) { e in
                PointMark(x: .value("Time", e.date), y: .value("Level", drawn ? e.height : minL))
                    .symbolSize(40)
                    .foregroundStyle(e.kind == .high ? Theme.ocean : Theme.teal)
            }

            if let highlight, let range, range.contains(highlight) {
                RuleMark(x: .value("Selected", highlight))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
        }
        .chartYScale(domain: minL...maxL)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine().foregroundStyle(Theme.stroke)
                AxisValueLabel {
                    if let v = value.as(Double.self) { Text(String(format: "%.1f m", v)) }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisGridLine().foregroundStyle(Theme.stroke)
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .frame(height: 150)
        .animation(.spring(response: 0.4, dampingFraction: 1), value: highlight)
    }

    private var tideList: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(extremes.prefix(4)) { e in
                VStack(alignment: .leading, spacing: 2) {
                    Label(e.kind == .high ? "High" : "Low", systemImage: e.kind == .high ? "arrow.up" : "arrow.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(e.kind == .high ? Theme.ocean : Theme.teal)
                    Text(e.date.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                    Text(String(format: "%.2f m", e.height))
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func sunItem(icon: String, title: String, date: Date? = nil, text: String? = nil, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(color)
            Text(text ?? date?.formatted(date: .omitted, time: .shortened) ?? "—")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func daylight(_ day: SunDay) -> String {
        let minutes = Int(day.sunset.timeIntervalSince(day.sunrise) / 60)
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

// MARK: - Dive-time tide & light summary

struct TideLightSummary {
    let tideText: String?
    let lightWarning: String?

    init(plan: DivePlan, hours: [HourlyWeather], sunDays: [SunDay]) {
        guard let start = plan.parsedDate else { tideText = nil; lightWarning = nil; return }
        let end = start.addingTimeInterval(Double(plan.duration) * 60)

        // Tide: rising/falling and next extreme after the dive start
        let extremes = WeatherService.tideExtremes(in: hours)
        if let next = extremes.first(where: { $0.date > start }) {
            let state = next.kind == .high ? "Rising" : "Falling"
            let kind = next.kind == .high ? "high" : "low"
            tideText = "\(state) tide · \(kind) at \(next.date.formatted(date: .omitted, time: .shortened))"
        } else {
            tideText = nil
        }

        // Daylight
        if let day = sunDays.first(where: { Calendar.current.isDate($0.sunrise, inSameDayAs: start) }) {
            if !plan.nightDive && (end > day.sunset || start < day.sunrise) {
                lightWarning = "This dive runs outside daylight (sunset \(day.sunset.formatted(date: .omitted, time: .shortened))). Bring torches or mark it as a night dive."
            } else if !plan.nightDive && day.sunset.timeIntervalSince(end) < 45 * 60 {
                lightWarning = "You surface within 45 min of sunset (\(day.sunset.formatted(date: .omitted, time: .shortened)))."
            } else {
                lightWarning = nil
            }
        } else {
            lightWarning = nil
        }
    }
}
