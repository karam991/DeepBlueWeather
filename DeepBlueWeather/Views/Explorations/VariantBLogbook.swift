//
//  VariantBLogbook.swift
//  DeepBlueWeather
//
//  Exploration B: editorial. A one-word verdict, big serif numbers, hairlines
//  instead of cards, and the sea as a single captioned "photograph".
//

import SwiftUI
import Charts

struct ConditionsVariantB: View {
    let data: ConditionsSnapshot
    @State private var index = 0
    @State private var scrubbed: Date?
    @ScaledMetric(relativeTo: .largeTitle) private var headlineSize: CGFloat = 62
    @ScaledMetric(relativeTo: .largeTitle) private var figureSize: CGFloat = 46

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                masthead
                photograph
                figures
                swell
                tide
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.surface.ignoresSafeArea())
    }

    private var rule: some View { Rectangle().fill(Theme.textPrimary).frame(height: 1.5) }

    private var masthead: some View {
        let hour = data.hour(index)
        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(data.location.uppercased())
                    .font(.footnote.weight(.bold)).tracking(1.6)
                Spacer()
                LocationSearchButton()
            }
            .foregroundStyle(Theme.ocean)
            rule
            Text(data.verdict(index))
                .font(.system(size: headlineSize, weight: .bold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(summary(hour))
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func summary(_ hour: HourlyWeather) -> String {
        var text = "\(hour.dayLabel) at \(hour.timeLabel): \(hour.waveText) m waves over \(hour.waterText) water."
        if let best = data.bestIndex, best != index {
            text += " Calmest \(data.when(best))."
        }
        return text
    }

    private var photograph: some View {
        VStack(alignment: .leading, spacing: 6) {
            SeaSurfaceView(sea: data.sea(index), horizon: 0.34)
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                .padding(.horizontal, -Theme.Spacing.sm)
            Text("The sea at \(data.hour(index).timeLabel), drawn from the forecast.")
                .font(.system(.caption, design: .serif).italic())
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var figures: some View {
        let hour = data.hour(index)
        return VStack(spacing: Theme.Spacing.md) {
            rule
            HStack(alignment: .top) {
                figure(hour.waterText, "Water")
                Divider()
                figure(hour.waveText, "Waves, m")
                Divider()
                figure(String(format: "%.0f", hour.windSpeed), "Wind, km/h")
            }
            .fixedSize(horizontal: false, vertical: true)
            Divider()
            Text(String(format: "Air %.0f°   ·   Rain %.0f%%   ·   UV %.0f   ·   Air visibility %@",
                        hour.airTemperature, hour.precipitationProbability ?? 0, hour.uvIndex ?? 0, hour.visibilityLabel))
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func figure(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(size: figureSize, weight: .regular, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased()).font(.caption2.weight(.bold)).tracking(1).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var swell: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            rule
            Text("The next 24 hours").font(.system(.title2, design: .serif).weight(.bold)).foregroundStyle(Theme.textPrimary)
            Chart(Array(data.hours.enumerated()), id: \.element.id) { i, h in
                if let d = h.date {
                    BarMark(x: .value("Time", d, unit: .hour), y: .value("Wave height", h.waveHeight ?? 0))
                        .foregroundStyle(data.condition(i).color.opacity(i == index ? 1 : 0.4))
                        .cornerRadius(3)
                }
            }
            .chartXSelection(value: $scrubbed)
            .chartXAxis { AxisMarks(values: .stride(by: .hour, count: 6)) { _ in AxisValueLabel(format: .dateTime.hour()) } }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { v in
                    AxisGridLine().foregroundStyle(Theme.stroke)
                    AxisValueLabel { if let n = v.as(Double.self) { Text(String(format: "%.1f m", n)) } }
                }
            }
            .frame(height: 130)
            .onChange(of: scrubbed) { _, date in
                if let date { index = data.index(nearest: date) }
            }
            Text("Bar height is wave height. Colour is the dive rating.")
                .font(.system(.caption, design: .serif).italic())
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private var tide: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            rule
            Text("Tide").font(.system(.title2, design: .serif).weight(.bold)).foregroundStyle(Theme.textPrimary)
            TideSunCard(hours: data.hours, sunDays: data.sunDays, highlight: data.hour(index).date)
        }
    }
}

#Preview("B · Calm · Light") { ExplorationFrame { ConditionsVariantB(data: .calm) }.preferredColorScheme(.light) }
#Preview("B · Calm · Dark") { ExplorationFrame { ConditionsVariantB(data: .calm) }.preferredColorScheme(.dark) }
#Preview("B · Rough · Light") { ExplorationFrame { ConditionsVariantB(data: .rough) }.preferredColorScheme(.light) }
#Preview("B · Rough · Dark") { ExplorationFrame { ConditionsVariantB(data: .rough) }.preferredColorScheme(.dark) }
#Preview("B · Night · Light") { ExplorationFrame { ConditionsVariantB(data: .night) }.preferredColorScheme(.light) }
#Preview("B · Night · Dark") { ExplorationFrame { ConditionsVariantB(data: .night) }.preferredColorScheme(.dark) }
