//
//  DiveHero.swift
//  DeepBlueWeather
//
//  Dive detail hero: a cross-section of the sea at the dive hour. The plan sits
//  above the waterline, the water temperature and suit below it.
//

import SwiftUI

struct DiveHero: View {
    let plan: DivePlan
    let hour: HourlyWeather?
    let sunDays: [SunDay]
    let isLoading: Bool
    let outOfRange: Bool
    /// Height covered by the status bar and toolbar.
    let topInset: CGFloat

    @ScaledMetric(relativeTo: .largeTitle) private var numberSize = Theme.NumberSize.hero
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 34
    @State private var skyHeight: CGFloat = 170

    private let waterGap: CGFloat = 76

    private var sea: SeaState? { hour.flatMap { SeaState(hour: $0, sunDays: sunDays) } }

    private var dateText: String {
        plan.parsedDate.map { DateFormatter.readableDate.string(from: $0) } ?? plan.date
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            aboveWater
                .padding(.top, topInset + Theme.Spacing.sm)
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { skyHeight = geo.size.height }
                            .onChange(of: geo.size.height) { _, height in skyHeight = height }
                    }
                }
            Spacer(minLength: waterGap)
            belowWater
        }
        .foregroundStyle(Theme.OnSea.primary)
        .shadow(color: .black.opacity(0.35), radius: 5, y: 1)
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.bottom, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, minHeight: Theme.Hero.sectionMinHeight, alignment: .leading)
        .background {
            // Grows upwards when the page is pulled down.
            GeometryReader { geo in
                let stretch = max(0, geo.frame(in: .scrollView).minY)
                Group {
                    if let sea {
                        WaterlineView(sea: sea, surfaceY: skyHeight + stretch + waterGap * 0.45)
                    } else {
                        Theme.heroGradient
                    }
                }
                .frame(height: geo.size.height + stretch)
                .offset(y: -stretch)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityIdentifier("dive-hero")
    }

    private var aboveWater: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if let countdown = plan.countdownLabel {
                Text(countdown.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.OnSea.secondary)
            }
            Text(plan.location.capitalized)
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(dateText)
                .font(.subheadline)
                .foregroundStyle(Theme.OnSea.secondary)
        }
    }

    @ViewBuilder
    private var belowWater: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if let hour, sea != nil {
                Text(hour.waterText)
                    .font(.system(size: min(numberSize, 160) * 0.85, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(["water", hour.suit?.label].compactMap { $0 }.joined(separator: " · "))
                    .font(.headline)
                    .foregroundStyle(Theme.OnSea.secondary)
                Label(hour.condition.label + " to dive", systemImage: hour.condition.icon)
                    .font(.title3.weight(.bold))
                    .padding(.top, Theme.Spacing.sm)
                Text(hour.seaSummary)
                    .font(.subheadline.weight(.medium))
            } else {
                Label(unavailableText, systemImage: isLoading ? "hourglass" : "water.waves.slash")
                    .font(.subheadline.weight(.semibold))
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Spacing.sm) { tags }
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) { tags }
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    @ViewBuilder
    private var tags: some View {
        DiveTag(icon: "arrow.down.to.line", text: "\(plan.depth) m", color: Theme.ocean, inverted: true)
        DiveTag(icon: "timer", text: "\(plan.duration) min", color: Theme.teal, inverted: true)
        if plan.nightDive { DiveTag(icon: "moon.stars.fill", text: "Night", color: Theme.sand, inverted: true) }
        if plan.deepDive { DiveTag(icon: "chevron.down.2", text: "Deep", color: Theme.coral, inverted: true) }
    }

    private var unavailableText: String {
        if isLoading { return "Reading the forecast…" }
        if outOfRange { return "No forecast for this date" }
        return "No marine data for this site"
    }

    private var spoken: String {
        var parts = [plan.countdownLabel, plan.location.capitalized, dateText,
                     "\(plan.depth) metres", "\(plan.duration) minutes",
                     plan.nightDive ? "Night dive" : nil, plan.deepDive ? "Deep dive" : nil]
            .compactMap { $0 }
        if let hour, sea != nil {
            parts.append("Dive conditions \(hour.condition.label)")
            if let water = hour.waterTemperature { parts.append(String(format: "Water %.0f degrees", water)) }
            if let suit = hour.suit { parts.append(suit.label) }
            parts.append(hour.seaSummary)
        } else {
            parts.append(unavailableText)
        }
        return parts.joined(separator: ", ")
    }
}
