//
//  DesignGalleryView.swift
//  DeepBlueWeather
//
//  Debug only: run with the `-designGallery` launch argument to try the
//  Conditions explorations with sample data. No login or network needed.
//

#if DEBUG
import SwiftUI

struct DesignGalleryView: View {
    private enum Variant: String, CaseIterable { case a = "A", b = "B", c = "C" }
    private enum Scenario: String, CaseIterable {
        case calm = "Calm", rough = "Rough", night = "Night"

        var data: ConditionsSnapshot {
            switch self {
            case .calm: return .calm
            case .rough: return .rough
            case .night: return .night
            }
        }
    }

    @State private var variant = Variant.a
    @State private var scenario = Scenario.calm
    @State private var dark = false

    var body: some View {
        Group {
            switch variant {
            case .a: ConditionsVariantA(data: scenario.data)
            case .b: ConditionsVariantB(data: scenario.data)
            case .c: ConditionsVariantC(data: scenario.data)
            }
        }
        // A new scenario or variant starts again at its first hour.
        .id(variant.rawValue + scenario.rawValue)
        .safeAreaInset(edge: .bottom, spacing: 0) { controls }
        .tint(Theme.ocean)
        .preferredColorScheme(dark ? .dark : .light)
    }

    private var controls: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Picker("Variant", selection: $variant) {
                ForEach(Variant.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .frame(width: 110)
            Picker("Scenario", selection: $scenario) {
                ForEach(Scenario.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            Button { dark.toggle() } label: {
                Image(systemName: dark ? "moon.fill" : "sun.max.fill")
                    .frame(width: 36, height: 32)
            }
            .accessibilityLabel(dark ? "Switch to light mode" : "Switch to dark mode")
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.bar)
    }
}

#Preview { DesignGalleryView() }
#endif
