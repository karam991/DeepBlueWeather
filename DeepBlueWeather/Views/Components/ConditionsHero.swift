//
//  ConditionsHero.swift
//  DeepBlueWeather
//
//  The one hero of the Conditions screen: the sea at the selected hour.
//

import SwiftUI

struct ConditionsHero: View {
    let location: String
    let hour: HourlyWeather
    let sunDays: [SunDay]
    /// Height covered by the status bar, title and search field.
    let topInset: CGFloat

    @ScaledMetric(relativeTo: .largeTitle) private var numberSize = Theme.NumberSize.hero
    @State private var glint = 0

    var body: some View {
        let sea = SeaState(hour: hour, sunDays: sunDays)

        VStack(alignment: .leading, spacing: 0) {
            Text(location)
                .font(.title2.weight(.bold))
            Text("\(hour.dayLabel) · \(hour.timeLabel)")
                .font(.subheadline)
                .foregroundStyle(Theme.OnSea.secondary)

            Text(sea == nil ? hour.airText : hour.waterText)
                .font(.system(size: min(numberSize, 160), weight: .thin, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .padding(.top, Theme.Spacing.sm)
            Text(caption(hasSea: sea != nil))
                .font(.headline)
                .foregroundStyle(Theme.OnSea.secondary)

            Spacer(minLength: Theme.Spacing.xxl)

            if sea != nil {
                Label(hour.condition.label, systemImage: hour.condition.icon)
                    .font(.title2.weight(.bold))
                    .contentTransition(.symbolEffect(.replace))
            } else {
                Label("No marine data here", systemImage: "water.waves.slash")
                    .font(.title3.weight(.bold))
            }
            Text(hour.seaSummary)
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(Theme.OnSea.primary)
        .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, topInset + Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xl)
        .frame(maxWidth: .infinity, minHeight: Theme.Hero.surfaceMinHeight, alignment: .leading)
        .background {
            Group {
                if let sea {
                    SeaSurfaceView(sea: sea)
                } else {
                    Theme.heroGradient
                }
            }
            .overlay(LinearGradient(colors: [Theme.OnSea.scrimTop, .clear, .clear, Theme.OnSea.scrimBottom],
                                    startPoint: .top, endPoint: .bottom))
            .overlay { Glint(trigger: glint) }
        }
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: Theme.Radius.xl,
                                          bottomTrailingRadius: Theme.Radius.xl, style: .continuous))
        .animation(.easeInOut(duration: Theme.Motion.seaChange), value: hour.id)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(hour.spokenSummary(location: location))
        .accessibilityIdentifier("conditions-hero")
        .sensoryFeedback(.success, trigger: glint)
        .task(id: location) {
            guard hour.hasMarineData, hour.condition == .excellent, GlintLog.claim(location: location) else { return }
            try? await Task.sleep(for: .seconds(0.5))
            glint += 1
        }
    }

    private func caption(hasSea: Bool) -> String {
        guard hasSea else { return "air" }
        return ["water", hour.suit?.label].compactMap { $0 }.joined(separator: " · ")
    }
}

/// A single band of light crossing the water when conditions are excellent.
private struct Glint: View {
    let trigger: Int
    @State private var progress: CGFloat = 0
    @State private var visible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            if visible {
                LinearGradient(colors: [.clear, .white.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: geometry.size.width * 0.45)
                    .rotationEffect(.degrees(14))
                    .scaleEffect(y: 1.4)
                    .offset(x: -geometry.size.width * 0.6 + progress * geometry.size.width * 1.8)
                    .blendMode(.plusLighter)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            guard !reduceMotion else { return }
            progress = 0
            visible = true
            withAnimation(.easeInOut(duration: Theme.Motion.delightDuration)) {
                progress = 1
            } completion: {
                visible = false
            }
        }
    }
}
