//
//  VariantCWaterline.swift
//  DeepBlueWeather
//
//  Exploration C: "Above / below". The screen is a cross section of the sea.
//  Weather sits in the sky, diving data sits under water, and the waterline
//  between them moves with the real wave height. A time dial turns day to night.
//

import SwiftUI
import Charts

struct ConditionsVariantC: View {
    let data: ConditionsSnapshot
    @State private var index = 0
    @ScaledMetric(relativeTo: .largeTitle) private var depthSize: CGFloat = 104

    private let surfaceY: CGFloat = 270

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                scene
                VStack(spacing: Theme.Spacing.xl) {
                    timeDial
                    TideSunCard(hours: data.hours, sunDays: data.sunDays, highlight: data.hour(index).date)
                }
                .padding(Theme.Spacing.lg)
                .background(Theme.background,
                            in: UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.xl,
                                                       topTrailingRadius: Theme.Radius.xl, style: .continuous))
                .padding(.top, -Theme.Radius.xl)
            }
        }
        .ignoresSafeArea(edges: .top)
        // Water colour behind the top overscroll, page colour behind the bottom.
        .background(LinearGradient(stops: [.init(color: Color(hex: 0x061C30), location: 0.5),
                                           .init(color: Theme.background, location: 0.5)],
                                   startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }

    private var scene: some View {
        let hour = data.hour(index)
        let condition = data.condition(index)

        return ZStack(alignment: .top) {
            WaterlineView(sea: data.sea(index), surfaceY: surfaceY)

            // Above the surface: weather
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.location).font(.title2.weight(.bold))
                        Text("\(hour.dayLabel) · \(hour.timeLabel)").font(.subheadline).opacity(0.85)
                    }
                    Spacer()
                    LocationSearchButton()
                }
                HStack(spacing: Theme.Spacing.lg) {
                    above("thermometer.medium", String(format: "%.0f°", hour.airTemperature), "Air temperature")
                    above("wind", String(format: "%.0f km/h", hour.windSpeed), "Wind")
                    above("cloud.rain", String(format: "%.0f%%", hour.precipitationProbability ?? 0), "Rain probability")
                    above("eye", hour.visibilityLabel, "Air visibility")
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, 64)
            .shadow(color: .black.opacity(0.4), radius: 5, y: 1)

            // Wave height, measured at the waterline
            HStack {
                Spacer()
                Text("\(hour.waveText) m waves")
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .environment(\.colorScheme, .dark)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .offset(y: surfaceY - 74)

            // Below the surface: diving
            VStack(alignment: .leading, spacing: 0) {
                Text(hour.waterText)
                    .font(.system(size: depthSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .accessibilityLabel("Water temperature \(hour.waterText)")
                if let suit = data.suit(index) {
                    Text("water · \(suit)").font(.headline).opacity(0.85)
                }
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: condition.icon).font(.title)
                        .foregroundStyle(condition.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(condition.label) to dive").font(.title3.weight(.bold))
                        if let best = data.bestIndex {
                            Button { index = best } label: {
                                Text("Best \(data.when(best)) ›")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color(hex: 0xF2B35E))
                            }
                        }
                    }
                }
                .padding(.top, Theme.Spacing.xl)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.xl)
            .offset(y: surfaceY + 48)
        }
        .foregroundStyle(.white)
        .frame(height: 600)
    }

    private func above(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.footnote).opacity(0.85)
            Text(value).font(.subheadline.weight(.bold)).monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(value)")
    }

    private var timeDial: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Travel through the day").font(.headline).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(data.hour(index).timeLabel).font(.headline).monospacedDigit().foregroundStyle(Theme.ocean)
            }
            // One bar per hour: height = waves, colour = rating, dim = night.
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(data.hours.enumerated()), id: \.element.id) { i, h in
                    Capsule()
                        .fill(data.condition(i).color.opacity(i == index ? 1 : (data.sea(i).isNight ? 0.28 : 0.6)))
                        .frame(height: 10 + min(h.waveHeight ?? 0, 3) * 18)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 66, alignment: .bottom)
            .accessibilityHidden(true)
            Slider(value: Binding(get: { Double(index) }, set: { index = Int($0.rounded()) }),
                   in: 0...Double(data.hours.count - 1), step: 1)
                .tint(Theme.ocean)
                .accessibilityLabel("Forecast hour")
                .accessibilityValue("\(data.hour(index).dayLabel) \(data.hour(index).timeLabel)")
                .sensoryFeedback(.selection, trigger: index)
        }
        .padding(.top, Theme.Spacing.sm)
    }
}

#Preview("C · Calm · Light") { ExplorationFrame { ConditionsVariantC(data: .calm) }.preferredColorScheme(.light) }
#Preview("C · Calm · Dark") { ExplorationFrame { ConditionsVariantC(data: .calm) }.preferredColorScheme(.dark) }
#Preview("C · Rough · Light") { ExplorationFrame { ConditionsVariantC(data: .rough) }.preferredColorScheme(.light) }
#Preview("C · Rough · Dark") { ExplorationFrame { ConditionsVariantC(data: .rough) }.preferredColorScheme(.dark) }
#Preview("C · Night · Light") { ExplorationFrame { ConditionsVariantC(data: .night) }.preferredColorScheme(.light) }
#Preview("C · Night · Dark") { ExplorationFrame { ConditionsVariantC(data: .night) }.preferredColorScheme(.dark) }
