//
//  StyleConstants.swift
//  DeepBlueWeather
//
//  Created by Karam Alnaser on 26.04.24.
//
//  Central design system: colors, spacing, radii and reusable components.
//  Colors are defined in code with explicit light/dark variants so the app
//  looks right in both appearances.
//

import SwiftUI
import UIKit

// MARK: - Theme

enum Theme {

    // MARK: Colors
    /// Primary brand color — deep ocean blue.
    static let ocean = Color(light: 0x0A4D8C, dark: 0x4DA3FF)
    /// Darkest navy, used for hero backgrounds.
    static let abyss = Color(light: 0x04213F, dark: 0x020B16)
    /// Secondary accent — lagoon teal.
    static let teal = Color(light: 0x0F9D9A, dark: 0x3FD6CF)
    static let coral = Color(light: 0xE8604C, dark: 0xFF7D69)
    static let sand = Color(light: 0xD9922E, dark: 0xF2B35E)
    static let kelp = Color(light: 0x2E8B57, dark: 0x5BD18D)

    static let background = Color(light: 0xF3F6FA, dark: 0x070D16)
    static let surface = Color(light: 0xFFFFFF, dark: 0x111A27)
    static let surfaceRaised = Color(light: 0xF7F9FC, dark: 0x182334)
    static let stroke = Color(light: 0xE3E8EF, dark: 0x223047)

    static let textPrimary = Color(light: 0x0E1726, dark: 0xF2F5FA)
    static let textSecondary = Color(light: 0x5B6779, dark: 0x9AA7BA)
    static let textTertiary = Color(light: 0x8C97A8, dark: 0x6B788C)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x04213F), Color(hex: 0x0A4D8C), Color(hex: 0x0F8C9A)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Metrics
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }
}

// MARK: - Color helpers

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// Adaptive color with separate light and dark appearance values.
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

// MARK: - Card

struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.Spacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func card(padding: CGFloat = Theme.Spacing.lg) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(Theme.ocean.gradient) : AnyShapeStyle(Theme.textTertiary.opacity(0.4)))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Icon badge (iOS Settings style)

struct IconBadge: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 30

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(color.opacity(0.14))
            )
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

// MARK: - Metric tile

struct MetricTile: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.4)
            }
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.surfaceRaised)
        )
    }
}

// MARK: - Empty / status state

struct StatusStateView: View {
    let icon: String
    let title: String
    let message: String
    var tint: Color = Theme.ocean

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 76, height: 76)
                .background(Circle().fill(tint.opacity(0.12)))
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Dive condition rating

enum DiveCondition {
    case excellent, good, fair, poor

    init(waveHeight: Double?, windSpeed: Double) {
        let wave = waveHeight ?? 0
        switch (wave, windSpeed) {
        case (..<0.5, ..<15): self = .excellent
        case (..<1.0, ..<25): self = .good
        case (..<1.8, ..<35): self = .fair
        default: self = .poor
        }
    }

    var label: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }

    var color: Color {
        switch self {
        case .excellent: return Theme.kelp
        case .good: return Theme.teal
        case .fair: return Theme.sand
        case .poor: return Theme.coral
        }
    }

    var icon: String {
        switch self {
        case .excellent, .good: return "checkmark.seal.fill"
        case .fair: return "exclamationmark.triangle.fill"
        case .poor: return "xmark.octagon.fill"
        }
    }
}

struct ConditionPill: View {
    let condition: DiveCondition

    var body: some View {
        Label(condition.label, systemImage: condition.icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(condition.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(condition.color.opacity(0.14)))
    }
}
