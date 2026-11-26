//
//  SeaView.swift
//  DeepBlueWeather
//
//  The living ocean: Metal-drawn sea views driven by a `SeaState`.
//  They hold one frame with Reduce Motion or Low Power Mode, and stop
//  animating while off screen.
//

import SwiftUI

// MARK: - Animation clock

private struct SeaClock<Content: View>: View {
    @ViewBuilder let content: (Float) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var appeared = false
    @State private var inViewport = true

    private var frozen: Bool { reduceMotion || lowPower || MotionFlags.ambientPaused }

    var body: some View {
        TimelineView(.animation(minimumInterval: Theme.Motion.seaFrameInterval,
                                paused: frozen || !appeared || !inViewport || scenePhase != .active)) { timeline in
            content(frozen ? 12 : Float(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 900)))
        }
        .background {
            GeometryReader { geometry in
                Color.clear.onChange(of: geometry.frame(in: .global).maxY > 0) { _, visible in
                    inViewport = visible
                }
            }
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange).receive(on: RunLoop.main)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .accessibilityHidden(true)
    }
}

private typealias SeaVector = AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>>

private extension SeaState {
    var vector: SeaVector {
        get { SeaVector(.init(waveHeight, chop), .init(sunElevation, cloud)) }
        set {
            waveHeight = newValue.first.first
            chop = newValue.first.second
            sunElevation = newValue.second.first
            cloud = newValue.second.second
        }
    }
}

// MARK: - Surface

/// View across the water: sky, sun or moon, and waves.
struct SeaSurfaceView: View, Animatable {
    var sea: SeaState
    /// Horizon position as a fraction of the height.
    var horizon: Double = 0.5

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>> {
        get { sea.vector }
        set { sea.vector = newValue }
    }

    var body: some View {
        SeaClock { time in
            Rectangle().colorEffect(ShaderLibrary.oceanSurface(
                .boundingRect,
                .float(time),
                .float(horizon),
                .float(sea.waveHeight),
                .float(sea.chop),
                .float(sea.sunElevation),
                .float(sea.cloud)
            ))
        }
    }
}

// MARK: - Cross-section

/// Side-on view: sky above the waterline, water column below.
struct WaterlineView: View, Animatable {
    var sea: SeaState
    /// Waterline distance from the top, in points.
    var surfaceY: CGFloat
    var pointsPerMetre: CGFloat = 26

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>> {
        get { sea.vector }
        set { sea.vector = newValue }
    }

    var body: some View {
        SeaClock { time in
            Rectangle().colorEffect(ShaderLibrary.waterline(
                .boundingRect,
                .float(time),
                .float(surfaceY),
                .float(pointsPerMetre),
                .float(sea.waveHeight),
                .float(sea.chop),
                .float(sea.sunElevation),
                .float(sea.cloud)
            ))
        }
    }
}

#Preview("Surface · rough") {
    SeaSurfaceView(sea: SeaState(waveHeight: 2, chop: 0.8, sunElevation: 0.5, cloud: 0.8)).frame(height: 400)
}

#Preview("Cross-section · night") {
    WaterlineView(sea: SeaState(waveHeight: 0.6, chop: 0.3, sunElevation: -0.5, cloud: 0), surfaceY: 160).frame(height: 400)
}
