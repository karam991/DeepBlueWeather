//
//  VariantALivingOcean.swift
//  DeepBlueWeather
//
//  Exploration A: a full-bleed living sea, then one scrubbable 24 h curve
//  that replaces the hourly tiles and drives the hero.
//

import SwiftUI
import Charts

struct ConditionsVariantA: View {
    enum Metric: String, CaseIterable { case waves = "Waves", water = "Water" }

    let data: ConditionsSnapshot
    @State private var index = 0
    @State private var metric: Metric = .waves
    @State private var scrubbed: Date?
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 108

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                hero
                VStack(spacing: Theme.Spacing.xl) {
                    forecast
                    secondary
                    TideSunCard(hours: data.hours, sunDays: data.sunDays, highlight: data.hour(index).date)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Theme.background.ignoresSafeArea())
    }

    private var hero: some View {
        let hour = data.hour(index)
        let condition = data.condition(index)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.location).font(.title3.weight(.bold))
                    Text("\(hour.dayLabel) · \(hour.timeLabel)").font(.subheadline).opacity(0.85)
                }
                Spacer()
                LocationSearchButton()
            }

            Text(hour.waterText)
                .font(.system(size: heroSize, weight: .thin, design: .rounded))
                .monospacedDigit()
                .padding(.top, Theme.Spacing.md)
                .accessibilityLabel("Water temperature \(hour.waterText)")
            Text("water").font(.headline).opacity(0.85).offset(y: -14).accessibilityHidden(true)

            Spacer(minLength: 0)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(condition.label, systemImage: condition.icon)
                        .font(.title2.weight(.bold))
                    Text("\(hour.waveText) m waves · \(Int(hour.windSpeed)) km/h wind")
                        .font(.subheadline.weight(.medium))
                }
                Spacer()
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, 64)
        .padding(.bottom, Theme.Spacing.xl)
        .frame(height: 490)
        .background {
            SeaSurfaceView(sea: data.sea(index), horizon: 0.50)
                .overlay(LinearGradient(colors: [.black.opacity(0.28), .clear, .clear, .black.opacity(0.45)],
                                        startPoint: .top, endPoint: .bottom))
        }
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: Theme.Radius.xl,
                                          bottomTrailingRadius: Theme.Radius.xl, style: .continuous))
    }

    private func value(_ h: HourlyWeather) -> Double {
        metric == .waves ? (h.waveHeight ?? 0) : (h.waterTemperature ?? 0)
    }

    private var forecast: some View {
        let values = data.hours.map(value)
        let low = metric == .waves ? 0 : (values.min() ?? 0) - 0.8
        let high = (values.max() ?? 1) + (metric == .waves ? 0.3 : 0.8)

        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Next 24 hours").font(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Picker("Chart metric", selection: $metric) {
                    ForEach(Metric.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            if let best = data.bestIndex {
                Button { index = best } label: {
                    Label("Best window \(data.when(best))", systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.sand)
                }
            }

            Chart {
                if let best = data.bestIndex, let d = data.hour(best).date {
                    RectangleMark(xStart: .value("From", d.addingTimeInterval(-3600)),
                                  xEnd: .value("To", d.addingTimeInterval(3600)))
                        .foregroundStyle(Theme.sand.opacity(0.18))
                }
                ForEach(data.hours) { h in
                    if let d = h.date {
                        AreaMark(x: .value("Time", d), yStart: .value("Base", low), yEnd: .value(metric.rawValue, value(h)))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(LinearGradient(colors: [Theme.teal.opacity(0.4), Theme.teal.opacity(0)], startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Time", d), y: .value(metric.rawValue, value(h)))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Theme.teal)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                }
                if let d = data.hour(index).date {
                    RuleMark(x: .value("Selected", d)).foregroundStyle(Theme.textTertiary)
                    PointMark(x: .value("Selected", d), y: .value("Value", value(data.hour(index))))
                        .symbolSize(110)
                        .foregroundStyle(data.condition(index).color)
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
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { v in
                    AxisGridLine().foregroundStyle(Theme.stroke)
                    AxisValueLabel {
                        if let n = v.as(Double.self) {
                            Text(metric == .waves ? String(format: "%.1f m", n) : String(format: "%.0f°", n))
                        }
                    }
                }
            }
            .frame(height: 170)
            .onChange(of: scrubbed) { _, date in
                if let date { index = data.index(nearest: date) }
            }
            .sensoryFeedback(.selection, trigger: index)
        }
    }

    private var secondary: some View {
        let hour = data.hour(index)
        return HStack(spacing: 0) {
            fact("Air", String(format: "%.0f°", hour.airTemperature))
            fact("Rain", String(format: "%.0f%%", hour.precipitationProbability ?? 0))
            fact("UV", String(format: "%.0f", hour.uvIndex ?? 0))
            fact("Air vis.", hour.visibilityLabel)
        }
        .card()
    }

    private func fact(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(.title3, design: .rounded).weight(.semibold)).foregroundStyle(Theme.textPrimary)
            Text(title).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview("A · Calm · Light") { ExplorationFrame { ConditionsVariantA(data: .calm) }.preferredColorScheme(.light) }
#Preview("A · Calm · Dark") { ExplorationFrame { ConditionsVariantA(data: .calm) }.preferredColorScheme(.dark) }
#Preview("A · Rough · Light") { ExplorationFrame { ConditionsVariantA(data: .rough) }.preferredColorScheme(.light) }
#Preview("A · Rough · Dark") { ExplorationFrame { ConditionsVariantA(data: .rough) }.preferredColorScheme(.dark) }
#Preview("A · Night · Light") { ExplorationFrame { ConditionsVariantA(data: .night) }.preferredColorScheme(.light) }
#Preview("A · Night · Dark") { ExplorationFrame { ConditionsVariantA(data: .night) }.preferredColorScheme(.dark) }
