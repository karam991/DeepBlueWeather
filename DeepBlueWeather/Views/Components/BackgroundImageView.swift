//
//  BackgroundImageView.swift
//  DeepBlueWeather
//
//  Created by Karam Alnaser on 26.02.24.
//
//  Motion toolkit: animated ocean background, bubbles, entrance animations,
//  pressable cards, celebration burst and zoom transitions.
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

// MARK: - Animated ocean background

/// Deep gradient with slowly drifting wave layers and rising bubbles.
struct OceanBackground: View {
    var showBubbles = true
    var waveOpacity: Double = 0.08
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.heroGradient

            TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || MotionFlags.ambientPaused)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    drawWaves(in: context, size: size, time: t)
                    if showBubbles {
                        drawBubbles(in: context, size: size, time: t)
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func drawWaves(in context: GraphicsContext, size: CGSize, time: Double) {
        let layers: [(height: CGFloat, amplitude: CGFloat, speed: Double, length: CGFloat, opacity: Double)] = [
            (0.62, 14, 0.35, 1.2, waveOpacity),
            (0.70, 18, -0.25, 0.9, waveOpacity * 1.2),
            (0.80, 12, 0.45, 1.5, waveOpacity * 1.5)
        ]
        for layer in layers {
            var path = Path()
            let baseY = size.height * layer.height
            path.move(to: CGPoint(x: 0, y: size.height))
            for x in stride(from: 0, through: size.width, by: 3) {
                let relative = x / size.width
                let y = baseY + sin(relative * .pi * 2 * layer.length + time * layer.speed) * layer.amplitude
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
            context.fill(path, with: .color(.white.opacity(layer.opacity)))
        }
    }

    private func drawBubbles(in context: GraphicsContext, size: CGSize, time: Double) {
        let count = 14
        for i in 0..<count {
            let seed = Double(i) * 12.9898
            let xBase = (sin(seed) * 43758.5453).truncatingRemainder(dividingBy: 1)
            let speed = 18 + abs((cos(seed) * 1000).truncatingRemainder(dividingBy: 1)) * 30
            let radius = 2 + abs((sin(seed * 2) * 1000).truncatingRemainder(dividingBy: 1)) * 5
            let travel = size.height + 40
            let progress = (time * speed + Double(i) * 97).truncatingRemainder(dividingBy: travel)
            let y = size.height + 20 - progress
            let x = abs(xBase) * size.width + sin(time * 0.8 + seed) * 10
            let fade = min(1, progress / 80) * min(1, (travel - progress) / 120)
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.35 * fade)), lineWidth: 1)
            context.fill(Path(ellipseIn: rect.insetBy(dx: radius * 0.6, dy: radius * 0.6).offsetBy(dx: -radius * 0.25, dy: -radius * 0.25)),
                         with: .color(.white.opacity(0.25 * fade)))
        }
    }
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

    /// Cards subtly scale and fade as they scroll in and out of view.
    func scrollReveal() -> some View {
        scrollTransition(.interactive, axis: .vertical) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.5)
                .scaleEffect(phase.isIdentity ? 1 : 0.94)
                .blur(radius: phase.isIdentity ? 0 : 1.5)
        }
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
