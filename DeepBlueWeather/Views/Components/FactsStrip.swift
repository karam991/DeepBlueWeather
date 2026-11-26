//
//  FactsStrip.swift
//  DeepBlueWeather
//
//  Plain supporting numbers (no card). Stacks into rows at accessibility sizes.
//

import SwiftUI

struct FactsStrip: View {
    let facts: [Fact]

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title3) private var statSize = Theme.NumberSize.stat

    var body: some View {
        let stacked = typeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.md))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Theme.Spacing.sm))

        layout {
            ForEach(facts) { fact in
                VStack(alignment: stacked ? .leading : .center, spacing: Theme.Spacing.xs) {
                    Text(fact.value)
                        .font(.system(size: statSize, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                    Text(fact.title)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(stacked ? .leading : .center)
                }
                .frame(maxWidth: .infinity, alignment: stacked ? .leading : .center)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(fact.spoken)
            }
        }
    }
}
