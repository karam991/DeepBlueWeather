//
//  DeepBlueWidget.swift
//  DeepBlueWidget
//
//  Home-screen & lock-screen widget showing the next planned dive.
//  Data comes from SharedDiveStore (App Group), written by the app.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline

struct NextDiveEntry: TimelineEntry {
    let date: Date
    let dive: SharedNextDive?
}

struct NextDiveProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextDiveEntry {
        NextDiveEntry(date: Date(), dive: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextDiveEntry) -> Void) {
        completion(NextDiveEntry(date: Date(), dive: SharedDiveStore.load() ?? (context.isPreview ? .sample : nil)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextDiveEntry>) -> Void) {
        let dive = SharedDiveStore.load()
        let now = Date()
        // One entry per hour for the next 12 hours keeps the countdown fresh.
        let entries = (0..<12).compactMap { offset in
            Calendar.current.date(byAdding: .hour, value: offset, to: now).map { NextDiveEntry(date: $0, dive: dive) }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

extension SharedNextDive {
    static let sample = SharedNextDive(location: "Nice", date: Date().addingTimeInterval(86_400 * 2),
                                       depth: 18, duration: 45, nightDive: false, deepDive: false)
}

// MARK: - Style

private enum WidgetStyle {
    static let gradient = LinearGradient(
        colors: [Color(red: 0.02, green: 0.13, blue: 0.25), Color(red: 0.04, green: 0.30, blue: 0.55), Color(red: 0.06, green: 0.55, blue: 0.60)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func countdown(to date: Date, from now: Date) -> String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: date)).day ?? 0
        switch days {
        case ..<0: return "Today"
        case 0:
            let hours = Int(date.timeIntervalSince(now) / 3600)
            return hours > 0 ? "In \(hours) h" : "Now"
        case 1: return "Tomorrow"
        default: return "In \(days) days"
        }
    }
}

// MARK: - Views

struct NextDiveWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextDiveEntry

    var body: some View {
        Group {
            if let dive = entry.dive {
                switch family {
                case .accessoryRectangular: lockScreen(dive)
                case .accessoryInline: Text("🤿 \(dive.location) · \(WidgetStyle.countdown(to: dive.date, from: entry.date))")
                case .systemMedium: medium(dive)
                default: small(dive)
                }
            } else {
                empty
            }
        }
        .containerBackground(for: .widget) {
            if family == .systemSmall || family == .systemMedium {
                ZStack(alignment: .bottom) {
                    WidgetStyle.gradient
                    Wave().fill(.white.opacity(0.08)).frame(height: 40)
                }
            } else {
                Color.clear
            }
        }
    }

    private func small(_ dive: SharedNextDive) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("NEXT DIVE", systemImage: "water.waves")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
            Spacer(minLength: 0)
            Text(WidgetStyle.countdown(to: dive.date, from: entry.date))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
            Text(dive.location)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("\(dive.depth) m · \(dive.duration) min")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func medium(_ dive: SharedNextDive) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label("NEXT DIVE", systemImage: "water.waves")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer(minLength: 0)
                Text(dive.location)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(dive.date.formatted(.dateTime.weekday(.wide).day().month().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 8) {
                Text(WidgetStyle.countdown(to: dive.date, from: entry.date))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.white.opacity(0.18)))
                Spacer(minLength: 0)
                stat("arrow.down.to.line", "\(dive.depth) m")
                stat("timer", "\(dive.duration) min")
                if dive.nightDive { stat("moon.stars.fill", "Night") }
            }
        }
    }

    private func stat(_ icon: String, _ text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.9))
    }

    private func lockScreen(_ dive: SharedNextDive) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Label("Next dive · \(WidgetStyle.countdown(to: dive.date, from: entry.date))", systemImage: "water.waves")
                .font(.caption2.weight(.semibold))
                .widgetAccentable()
            Text(dive.location).font(.headline).lineLimit(1)
            Text("\(dive.depth) m · \(dive.duration) min · \(dive.date.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "figure.open.water.swim")
                .font(.title2)
            Text("No dive planned")
                .font(.headline)
            Text("Open DeepBlue to plan one.")
                .font(.caption)
                .opacity(0.75)
        }
        .foregroundStyle(family == .systemSmall || family == .systemMedium ? .white : .primary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Wave: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        for x in stride(from: 0, through: rect.width, by: 4) {
            p.addLine(to: CGPoint(x: x, y: rect.midY + sin(x / rect.width * .pi * 3) * 8))
        }
        p.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Widget

struct NextDiveWidget: Widget {
    let kind = "NextDiveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextDiveProvider()) { entry in
            NextDiveWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Dive")
        .description("Countdown and profile of your next planned dive.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct DeepBlueWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextDiveWidget()
    }
}
