//
//  HourlyForecastChart.swift
//  DeepBlueWeather
//
//  The next 24 hours as one draggable curve. Selecting an hour drives the hero.
//

import SwiftUI
import Charts

struct HourlyForecastChart: View {
    enum Metric: String, CaseIterable { case waves = "Waves", water = "Water", air = "Air" }

    let forecast: ConditionsForecast
    let selected: HourlyWeather
    let select: (HourlyWeather) -> Void

    @State private var choice: Metric = .waves
    @State private var scrubbed: Date?

    /// Inland places only have air temperature.
    private var metrics: [Metric] { selected.hasMarineData ? [.waves, .water] : [.air] }
    private var metric: Metric { metrics.contains(choice) ? choice : metrics[0] }

    private func value(_ hour: HourlyWeather) -> Double? {
        switch metric {
        case .waves: return hour.waveHeight
        case .water: return hour.waterTemperature
        case .air: return hour.airTemperature
        }
    }

    private func text(_ value: Double) -> String {
        metric == .waves ? String(format: "%.1f m", value) : String(format: "%.0f°", value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            ViewThatFits(in: .horizontal) {
                HStack { title; Spacer(); picker.frame(width: 150) }
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) { title; picker }
            }

            if let best = forecast.bestHour {
                Button { select(best) } label: {
                    Label("Best dive window \(best.whenText)", systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.sand)
                        .frame(minHeight: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityIdentifier("best-window")
            }

            chart
        }
        .sensoryFeedback(.selection, trigger: selected.id)
    }

    private var title: some View {
        Text("Hourly forecast")
            .font(.title3.weight(.bold))
            .foregroundStyle(Theme.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var picker: some View {
        if metrics.count > 1 {
            Picker("Chart shows", selection: $choice) {
                ForEach(metrics, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var chart: some View {
        let values = forecast.hours.compactMap(value)
        let low = metric == .waves ? 0 : (values.min() ?? 0) - 1
        let high = (values.max() ?? 1) + (metric == .waves ? 0.3 : 1)

        return Chart {
            if let best = forecast.bestHour?.date {
                RectangleMark(xStart: .value("From", best.addingTimeInterval(-1800)),
                              xEnd: .value("To", best.addingTimeInterval(1800)))
                    .foregroundStyle(Theme.sand.opacity(0.25))
            }
            ForEach(forecast.hours) { hour in
                if let date = hour.date, let y = value(hour) {
                    AreaMark(x: .value("Time", date), yStart: .value("Base", low), yEnd: .value(metric.rawValue, y))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(LinearGradient(colors: [Theme.teal.opacity(0.4), Theme.teal.opacity(0)],
                                                        startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Time", date), y: .value(metric.rawValue, y))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Theme.teal)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }
            }
            if let date = selected.date, let y = value(selected) {
                RuleMark(x: .value("Selected", date)).foregroundStyle(Theme.textTertiary)
                PointMark(x: .value("Selected", date), y: .value("Value", y))
                    .symbolSize(120)
                    .foregroundStyle(selected.hasMarineData ? selected.condition.color : Theme.teal)
            }
        }
        .chartYScale(domain: low...high)
        .chartXSelection(value: $scrubbed)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { mark in
                AxisGridLine().foregroundStyle(Theme.stroke)
                AxisValueLabel {
                    if let n = mark.as(Double.self) { Text(text(n)) }
                }
            }
        }
        .frame(height: 180)
        .onChange(of: scrubbed) { _, date in
            if let date, let hour = forecast.hour(nearest: date) { select(hour) }
        }
        // VoiceOver: one adjustable element instead of 24 chart marks.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric.rawValue) over the next 24 hours")
        .accessibilityValue("\(selected.whenText), \(value(selected).map(text) ?? "no data")")
        .accessibilityHint("Swipe up or down to change the hour")
        .accessibilityAdjustableAction { direction in
            let offset = direction == .increment ? 1 : -1
            if let hour = forecast.hour(after: selected.id, offset: offset) { select(hour) }
        }
        .accessibilityIdentifier("hourly-chart")
    }
}
