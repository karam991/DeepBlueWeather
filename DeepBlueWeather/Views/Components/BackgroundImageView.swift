//
//  BackgroundImageView.swift
//  DeepBlueWeather
//
//  Created by Karam Alnaser on 26.02.24.
//
//  Motion toolkit: entrance animations, pressable cards, celebration burst
//  and zoom transitions.
//  Everything respects the "Reduce Motion" accessibility setting.
//

import SwiftUI

// MARK: - Debug switches

enum MotionFlags {
    /// Debug-only: UI tests launch with `-pauseAmbientMotion`. Endless animations
    /// keep the app from ever being "idle", which makes XCUITest wait on every step.
    #if DEBUG
    static let ambientPaused = CommandLine.arguments.contains("-pauseAmbientMotion")
    #else
    static let ambientPaused = false
    #endif
}

// MARK: - Staggered entrance

private struct AppearModifier: ViewModifier {
    let delay: Double
    @State private var visible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : 18)
            .scaleEffect(visible || reduceMotion ? 1 : 0.98)
            .onAppear {
                guard !visible else { return }
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.55, dampingFraction: 0.85).delay(delay)) {
                    visible = true
                }
            }
    }
}

extension View {
    /// Fades and lifts the view in once, optionally delayed for stagger effects.
    func appear(delay: Double = 0) -> some View {
        modifier(AppearModifier(delay: delay))
    }
}

// MARK: - Pressable (cards, tiles)

/// Instant press-down feedback with a critically damped spring back.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(configuration.isPressed ? .easeOut(duration: 0.1) : .spring(response: 0.35, dampingFraction: 1), value: configuration.isPressed)
    }
}

// MARK: - Celebration burst

/// One-shot bubble burst used when a checklist reaches 100%.
struct BubbleBurst: View {
    let trigger: Int
    @State private var particles: [Particle] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Particle: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let color: Color
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                BurstDot(particle: p)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            guard !reduceMotion else { return }
            let colors = [Theme.ocean, Theme.teal, Theme.kelp, Theme.sand, Theme.coral]
            particles = (0..<28).map { i in
                Particle(
                    angle: Double(i) / 28 * 2 * .pi + Double.random(in: -0.2...0.2),
                    distance: .random(in: 60...150),
                    size: .random(in: 5...11),
                    color: colors[i % colors.count]
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { particles = [] }
        }
    }

    private struct BurstDot: View {
        let particle: Particle
        @State private var launched = false

        var body: some View {
            Circle()
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size)
                .offset(
                    x: launched ? cos(particle.angle) * particle.distance : 0,
                    y: launched ? sin(particle.angle) * particle.distance - 30 : 0
                )
                .opacity(launched ? 0 : 1)
                .scaleEffect(launched ? 0.4 : 1)
                .onAppear {
                    withAnimation(.spring(response: 1.1, dampingFraction: 0.9)) { launched = true }
                }
        }
    }
}

// MARK: - Zoom navigation transition (iOS 18+, graceful fallback)

extension View {
    @ViewBuilder
    func zoomSource(id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder
    func zoomDestination(id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
