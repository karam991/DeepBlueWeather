//
//  ExplorationComponents.swift
//  DeepBlueWeather
//
//  Design exploration: shader-backed sea views and small shared pieces.
//

import SwiftUI

// MARK: - Animation clock

/// Drives a shader. Frozen on one frame when Reduce Motion is on.
private struct ShaderClock<Content: View>: View {
    @ViewBuilder let content: (Float) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || MotionFlags.ambientPaused)) { timeline in
            let frozen = reduceMotion || MotionFlags.ambientPaused
            content(frozen ? 12 : Float(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 900)))
        }
        .accessibilityHidden(true)
    }
}

/// View across the water: sky, sun or moon, and waves.
struct SeaSurfaceView: View {
    let sea: SeaState
    /// Horizon position as a fraction of the height.
    var horizon: Double = 0.42

    var body: some View {
        ShaderClock { time in
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

/// Side-on cross section: sky above the waterline, water column below.
struct WaterlineView: View {
    let sea: SeaState
    /// Waterline distance from the top, in points.
    var surfaceY: CGFloat
    var pointsPerMetre: CGFloat = 34

    var body: some View {
        ShaderClock { time in
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

// MARK: - Shared pieces

struct LocationSearchButton: View {
    var body: some View {
        Button {} label: {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Search a dive location")
    }
}

extension HourlyWeather {
    var waveText: String { waveHeight.map { String(format: "%.1f", $0) } ?? "—" }
    var waterText: String { waterTemperature.map { String(format: "%.0f°", $0) } ?? "—" }
}

// MARK: - Preview helper

/// Frames a variant in a tab bar so previews and snapshots look like the app.
struct ExplorationFrame<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        TabView {
            content
                .tabItem { Label("Conditions", systemImage: "water.waves") }
            Color.clear.tabItem { Label("Dives", systemImage: "figure.open.water.swim") }
            Color.clear.tabItem { Label("Checklist", systemImage: "checklist") }
            Color.clear.tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Theme.ocean)
    }
}
