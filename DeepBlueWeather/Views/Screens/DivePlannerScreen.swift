//
//  DivePlannerScreen.swift
//  DeepBlueWeather
//
//  Created by Karam Alnaser on 26.02.24.
//

import SwiftUI
import MapKit

struct DivePlannerScreen: View {
    @EnvironmentObject var viewModel: DivePlannerViewModel
    @Namespace private var zoom
    @State private var planToDelete: DivePlan?

    var body: some View {
        ScrollView {
            if viewModel.divePlans.isEmpty {
                emptyState
                    .padding(.top, 100)
            } else {
                let upcoming = viewModel.upcomingPlans
                let past = viewModel.pastPlans

                LazyVStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    if let next = upcoming.first {
                        SectionHeader(title: "Next dive")
                            .appear()
                        planLink(next, style: .featured)
                            .appear(delay: 0.05)
                    }

                    Divider()
                    FactsStrip(facts: viewModel.totals)
                        .appear(delay: 0.1)
                    Divider()

                    if upcoming.count > 1 {
                        SectionHeader(title: "Upcoming")
                            .padding(.top, Theme.Spacing.sm)
                        ForEach(Array(upcoming.dropFirst().enumerated()), id: \.element.id) { index, plan in
                            planLink(plan, style: .card)
                                .appear(delay: 0.12 + Double(index) * 0.05)
                        }
                    }

                    if !past.isEmpty {
                        SectionHeader(title: "Past dives")
                            .padding(.top, Theme.Spacing.sm)
                        VStack(spacing: 0) {
                            ForEach(past, id: \.id) { plan in
                                planLink(plan, style: .quiet)
                                if plan.id != past.last?.id { Divider() }
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Dive Planner")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showingDivePlannerSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel("Plan a dive")
            }
        }
        .navigationDestination(for: String.self) { planId in
            if let plan = viewModel.divePlans.first(where: { $0.id == planId }) {
                DiveDetailView(plan: plan, onDelete: { delete(plan) })
                    .zoomDestination(id: planId, in: zoom)
            }
        }
        .sheet(isPresented: $viewModel.showingDivePlannerSheet) {
            DivePlannerSheetView(divePlannerViewModel: viewModel)
        }
        .confirmationDialog("Delete this dive plan?", isPresented: Binding(get: { planToDelete != nil }, set: { if !$0 { planToDelete = nil } }), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let plan = planToDelete { delete(plan) }
            }
        }
        .onAppear {
            viewModel.readDivePlans()
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.xl) {
            StatusStateView(
                icon: "figure.open.water.swim",
                title: "No dives planned",
                message: "Plan a dive and DeepBlue builds a gear list from the forecast for that exact day."
            )
            Button {
                viewModel.showingDivePlannerSheet = true
            } label: {
                Label("Plan a Dive", systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(maxWidth: 240)
        }
        .appear()
    }

    private enum CardStyle { case featured, card, quiet }

    @ViewBuilder
    private func planLink(_ plan: DivePlan, style: CardStyle) -> some View {
        if let id = plan.id {
            NavigationLink(value: id) {
                Group {
                    switch style {
                    case .featured: NextDiveCard(plan: plan)
                    case .card: DivePlanCard(plan: plan)
                    case .quiet: PastDiveRow(plan: plan)
                    }
                }
                .zoomSource(id: id, in: zoom)
            }
            .buttonStyle(PressableStyle())
            .contextMenu {
                Button(role: .destructive) {
                    planToDelete = plan
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func delete(_ plan: DivePlan) {
        guard let index = viewModel.divePlans.firstIndex(where: { $0.id == plan.id }) else { return }
        if let id = plan.id {
            PlanChecklistStore.remove(planId: id)
            DivePhotoStore.deleteAll(for: id)
        }
        viewModel.deleteDivePlan(at: index)
    }
}

// MARK: - Cards

/// The next dive: a large countdown on flat deep blue. No sea here by design.
private struct NextDiveCard: View {
    let plan: DivePlan
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize = Theme.NumberSize.featured

    var body: some View {
        let countdown = plan.countdownHeadline

        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                Text(countdown.value)
                    .font(.system(size: min(numberSize, 90), weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.OnSea.highlight)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unit = countdown.unit {
                    Text(unit)
                        .font(.headline)
                        .foregroundStyle(Theme.OnSea.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.OnSea.secondary)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(plan.location.capitalized)
                    .font(.title2.weight(.bold))
                Text(plan.parsedDate.map { DateFormatter.readableDate.string(from: $0) } ?? plan.date)
                    .font(.subheadline)
                    .foregroundStyle(Theme.OnSea.secondary)
            }

            PlanTags(plan: plan, inverted: true)

            Label("Tap to see your smart gear list", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.OnSea.secondary)
        }
        .foregroundStyle(Theme.OnSea.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.xl)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                .fill(Theme.deepCard)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// A later upcoming dive.
private struct DivePlanCard: View {
    let plan: DivePlan

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                DateBadge(date: plan.parsedDate)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(plan.location.capitalized)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(plan.dateText)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    if let countdown = plan.countdownLabel {
                        Text(countdown)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.teal)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
            }
            PlanTags(plan: plan)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// A past dive: plain content, no card.
private struct PastDiveRow: View {
    let plan: DivePlan

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            DateBadge(date: plan.parsedDate)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(plan.location.capitalized)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(plan.dateText)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                PlanTags(plan: plan)
                    .padding(.vertical, 2)
                if let log = plan.log {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= log.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(i <= log.rating ? Theme.sand : Theme.textTertiary)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Logged, rated \(log.rating) of 5")
                } else {
                    Text("Tap to log this dive")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.teal)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Theme.Spacing.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Depth, time and dive type. Wraps onto separate lines for large text.
private struct PlanTags: View {
    let plan: DivePlan
    var inverted = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Spacing.sm) { tags }
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) { tags }
        }
    }

    @ViewBuilder
    private var tags: some View {
        DiveTag(icon: "arrow.down.to.line", text: "\(plan.depth) m", color: Theme.ocean, inverted: inverted)
        DiveTag(icon: "timer", text: "\(plan.duration) min", color: Theme.teal, inverted: inverted)
        if plan.deepDive { DiveTag(icon: "chevron.down.2", text: "Deep", color: Theme.coral, inverted: inverted) }
        if plan.nightDive { DiveTag(icon: "moon.stars.fill", text: "Night", color: Theme.sand, inverted: inverted) }
    }
}

private struct DateBadge: View {
    let date: Date?
    @ScaledMetric(relativeTo: .title3) private var side: CGFloat = 48

    var body: some View {
        VStack(spacing: 0) {
            Text(date.map { $0.formatted(.dateTime.month(.abbreviated)) }?.uppercased() ?? "—")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Theme.ocean)
            Text(date.map { $0.formatted(.dateTime.day()) } ?? "")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(width: side, height: side)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.ocean.opacity(0.1))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(date?.formatted(.dateTime.month(.wide).day()) ?? "No date")
    }
}

struct DiveTag: View {
    let icon: String
    let text: String
    let color: Color
    var inverted = false

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(inverted ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(inverted ? .white.opacity(0.16) : color.opacity(0.12)))
    }
}

// MARK: - Dive detail

@MainActor
final class DiveDetailModel: ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var hour: HourlyWeather?
    @Published var isLoading = true
    @Published var outOfRange = false
    @Published var hours: [HourlyWeather] = []
    @Published var sunDays: [SunDay] = []

    func load(plan: DivePlan) async {
        isLoading = true
        defer { isLoading = false }
        guard let coord = try? await WeatherService.coordinate(for: plan.location) else { return }
        coordinate = coord
        guard let data = await WeatherService.weather(latitude: coord.latitude, longitude: coord.longitude),
              let target = plan.parsedDate else { return }
        let hours = data.hours
        self.hours = hours
        self.sunDays = data.sunDays

        let dated = hours.compactMap { h in h.date.map { (h, $0) } }
        guard let first = dated.first?.1, let last = dated.last?.1,
              target >= first.addingTimeInterval(-3600), target <= last.addingTimeInterval(3600) else {
            outOfRange = true
            return
        }
        hour = dated.min { abs($0.1.timeIntervalSince(target)) < abs($1.1.timeIntervalSince(target)) }?.0
    }
}

struct DiveDetailView: View {
    private let initialPlan: DivePlan
    var onDelete: () -> Void

    init(plan: DivePlan, onDelete: @escaping () -> Void) {
        self.initialPlan = plan
        self.onDelete = onDelete
    }

    /// Always reflect the latest Firestore version (e.g. after logging).
    private var plan: DivePlan {
        plannerViewModel.divePlans.first { $0.id == initialPlan.id } ?? initialPlan
    }

    @EnvironmentObject private var plannerViewModel: DivePlannerViewModel
    @State private var showLogSheet = false
    @State private var logPhotos: [URL] = []
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = DiveDetailModel()
    @State private var checked: Set<String> = []
    @State private var showDeleteConfirm = false
    @State private var celebrate = 0
    @State private var logCelebration = 0
    /// True once the hero has scrolled under the navigation bar.
    @State private var heroCollapsed = false

    private var suggestions: [GearSuggestion] { SmartGearEngine.suggestions(for: plan, hour: model.hour) }

    var body: some View {
        GeometryReader { screen in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    hero(topInset: screen.safeAreaInsets.top)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        if plan.log != nil || plan.isPast || (plan.parsedDate ?? .distantFuture) < Date() {
                            logSection
                                .overlay { BubbleBurst(trigger: logCelebration) }
                                .sensoryFeedback(.success, trigger: logCelebration)
                                .appear(delay: 0.06)
                        }
                        conditions
                            .appear(delay: 0.1)
                        tideAndLight
                            .appear(delay: 0.14)
                        smartGear
                            .appear(delay: 0.18)
                        if let coordinate = model.coordinate {
                            map(coordinate)
                                .appear(delay: 0.24)
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Dive Plan", systemImage: "trash")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Theme.coral)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                        .fill(Theme.coral.opacity(0.1))
                                )
                        }
                        .buttonStyle(PressableStyle())
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(heroCollapsed ? plan.location.capitalized : "")
        .navigationBarTitleDisplayMode(.inline)
        // Transparent over the hero, solid material once content scrolls underneath.
        .toolbarBackground(heroCollapsed ? .visible : .hidden, for: .navigationBar)
        // Light status bar text over the dark hero.
        .toolbarColorScheme(heroCollapsed ? nil : .dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    toolbarCircle("chevron.left")
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText, subject: Text("Dive plan: \(plan.location.capitalized)")) {
                    toolbarCircle("square.and.arrow.up")
                }
                .accessibilityLabel("Share with your buddy")
            }
        }
        .sheet(isPresented: $showLogSheet, onDismiss: reloadPhotos) {
            DiveLogSheet(plan: plan, waterTemperatureHint: model.hour?.waterTemperature)
        }
        .confirmationDialog("Delete this dive plan?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        }
        .task {
            reloadPhotos()
            if let id = plan.id { checked = PlanChecklistStore.checkedIDs(for: id) }
            await model.load(plan: plan)
        }
        .onChange(of: plan.log != nil) { wasLogged, isLogged in
            guard isLogged, !wasLogged else { return }
            // Wait for the log sheet to close so the bubbles are visible.
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                logCelebration += 1
            }
        }
        .onChange(of: checked) { _, newValue in
            if let id = plan.id { PlanChecklistStore.save(newValue, for: id) }
        }
    }

    // MARK: Hero

    private func hero(topInset: CGFloat) -> some View {
        DiveHero(plan: plan, hour: model.hour, sunDays: model.sunDays,
                 isLoading: model.isLoading, outOfRange: model.outOfRange, topInset: topInset)
            .background {
                GeometryReader { geo in
                    // Collapse when the hero has scrolled under the navigation bar.
                    Color.clear.onChange(of: geo.frame(in: .global).maxY < topInset + 12) { _, collapsed in
                        withAnimation(.easeInOut(duration: 0.2)) { heroCollapsed = collapsed }
                    }
                }
            }
    }

    /// Round toolbar button: white on the hero, ocean tint once the bar is solid.
    private func toolbarCircle(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(heroCollapsed ? Theme.ocean : .white)
            .frame(width: 34, height: 34)
            .background(Circle().fill(heroCollapsed ? Theme.ocean.opacity(0.12) : .black.opacity(0.25)))
            .contentTransition(.opacity)
    }

    // MARK: Log

    private func reloadPhotos() {
        if let id = plan.id { logPhotos = DivePhotoStore.photoURLs(for: id) }
    }

    @ViewBuilder
    private var logSection: some View {
        if let log = plan.log {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    SectionHeader(title: "Dive log")
                    Label("Logged", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.kelp)
                        .symbolEffect(.bounce, value: logCelebration)
                    Button("Edit") { showLogSheet = true }
                        .font(.subheadline.weight(.semibold))
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= log.rating ? "star.fill" : "star")
                                .foregroundStyle(i <= log.rating ? Theme.sand : Theme.textTertiary)
                                .accessibilityLabel("Rated \(log.rating) of 5")
                                .accessibilityHidden(i != 1)
                        }
                        Spacer()
                        if let buddy = log.buddy {
                            Label(buddy, systemImage: "person.2.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.teal)
                        }
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.sm), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                        MetricTile(icon: "arrow.down.to.line", title: "Max depth", value: "\(log.actualDepth) m", color: Theme.ocean)
                        MetricTile(icon: "timer", title: "Bottom time", value: "\(log.actualDuration) min", color: Theme.teal)
                        MetricTile(icon: "drop.fill", title: "Water", value: log.waterTemperature.map { String(format: "%.0f °C", $0) } ?? "—", color: Theme.ocean)
                        MetricTile(icon: "eye.fill", title: "Visibility", value: log.visibility.map { "\($0) m" } ?? "—", color: Theme.kelp)
                    }
                    if !log.notes.isEmpty {
                        Text(log.notes)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    if !logPhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.sm) {
                                ForEach(logPhotos, id: \.self) { url in
                                    LocalPhoto(url: url)
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                                }
                            }
                        }
                    }
                }
                .card()
            }
        } else {
            Button { showLogSheet = true } label: {
                HStack(spacing: Theme.Spacing.md) {
                    IconBadge(systemName: "book.closed.fill", color: .white, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("How did it go?")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Log depth, time, visibility and photos")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .padding(Theme.Spacing.lg)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous).fill(Theme.teal.gradient))
                .shadow(color: Theme.teal.opacity(0.35), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(PressableStyle())
        }
    }

    // MARK: Tide & light

    @ViewBuilder
    private var tideAndLight: some View {
        let window = model.hours.filter { h in
            guard let d = h.date, let target = plan.parsedDate else { return false }
            return abs(d.timeIntervalSince(target)) <= 12 * 3600
        }
        // Nothing to show for dives outside the forecast.
        if !window.isEmpty {
            let summary = TideLightSummary(plan: plan, hours: model.hours, sunDays: model.sunDays)
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionHeader(title: "Tide & daylight", trailing: summary.tideText)
                if let warning = summary.lightWarning {
                    Label(warning, systemImage: "moon.haze.fill")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.coral)
                        .padding(Theme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.coral.opacity(0.1)))
                }
                TideSunCard(hours: window, sunDays: model.sunDays, highlight: plan.parsedDate)
            }
        }
    }

    // MARK: Share

    private var shareText: String {
        var lines: [String] = []
        lines.append("🤿 Dive plan: \(plan.location.capitalized)")
        if let date = plan.parsedDate {
            lines.append("📅 \(date.formatted(date: .complete, time: .shortened))")
        }
        var profile = "⬇️ \(plan.depth) m · ⏱ \(plan.duration) min"
        if plan.nightDive { profile += " · 🌙 Night" }
        if plan.deepDive { profile += " · Deep" }
        lines.append(profile)
        if let hour = model.hour {
            let condition = DiveCondition(waveHeight: hour.waveHeight, windSpeed: hour.windSpeed)
            var forecast = "🌊 Forecast: \(condition.label)"
            if let w = hour.waterTemperature { forecast += String(format: " · water %.0f °C", w) }
            if let wave = hour.waveHeight { forecast += String(format: " · waves %.1f m", wave) }
            forecast += String(format: " · wind %.0f km/h", hour.windSpeed)
            lines.append(forecast)
        }
        let summary = TideLightSummary(plan: plan, hours: model.hours, sunDays: model.sunDays)
        if let tide = summary.tideText { lines.append("🌗 \(tide)") }
        let gear = suggestions.map(\.title)
        if !gear.isEmpty {
            lines.append("")
            lines.append("🎒 Bring:")
            lines.append(contentsOf: gear.map { "• \($0)" })
        }
        if let c = model.coordinate {
            lines.append("")
            lines.append("📍 https://maps.apple.com/?ll=\(c.latitude),\(c.longitude)&q=\(plan.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        lines.append("")
        lines.append("Planned with DeepBlue")
        return lines.joined(separator: "\n")
    }

    // MARK: Conditions

    @ViewBuilder
    private var conditions: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Conditions at dive time")

            if model.isLoading {
                HStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                    Text("Reading the forecast…")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 60)
            } else if let hour = model.hour {
                Divider()
                FactsStrip(facts: hour.secondaryFacts)
                Divider()
            } else {
                Label(model.outOfRange
                      ? (plan.isPast
                         ? "The forecast no longer covers this date."
                         : "The forecast reaches 7 days ahead. Gear for weather will appear closer to the dive.")
                      : "No forecast available for this location.",
                      systemImage: "calendar.badge.clock")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .animation(Theme.Motion.state, value: model.isLoading)
    }

    // MARK: Smart gear

    private var smartGear: some View {
        let items = suggestions
        let done = items.filter { checked.contains($0.id) }.count
        let progress = items.isEmpty ? 0 : Double(done) / Double(items.count)

        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Label("Smart gear for this dive", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if !items.isEmpty {
                    if done == items.count {
                        Label("Kit packed", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.kelp)
                            .symbolEffect(.bounce, value: celebrate)
                            .transition(.scale(scale: 1.6).combined(with: .opacity))
                    } else {
                        Text("\(done)/\(items.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .monospacedDigit()
                            .contentTransition(.numericText(value: Double(done)))
                            .accessibilityLabel("\(done) of \(items.count) packed")
                    }
                }
            }

            Text("Added automatically from the forecast and your dive settings. Your standard kit lives in the Checklist tab.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)

            if !items.isEmpty {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.ocean.opacity(0.12))
                        Capsule()
                            .fill(progress == 1 ? Theme.kelp.gradient : Theme.ocean.gradient)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 6)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: progress)
                .accessibilityHidden(true)
            }

            if model.isLoading && items.isEmpty {
                ProgressView().frame(maxWidth: .infinity, minHeight: 60)
            } else if items.isEmpty {
                Label("Conditions look standard — your regular checklist has you covered.", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.kelp)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        GearRow(item: item, isChecked: checked.contains(item.id)) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                if checked.contains(item.id) { checked.remove(item.id) } else { checked.insert(item.id) }
                            }
                            if items.allSatisfy({ checked.contains($0.id) }) { celebrate += 1 }
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        if index < items.count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .card(padding: 0)
                .overlay { BubbleBurst(trigger: celebrate) }
                .sensoryFeedback(.success, trigger: celebrate)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: items.map(\.id))
    }

    // MARK: Map

    private func map(_ coordinate: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Dive site")
            Map(initialPosition: .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))) {
                Marker(plan.location.capitalized, systemImage: "water.waves", coordinate: coordinate)
                    .tint(Theme.ocean)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        }
    }
}

private struct GearRow: View {
    let item: GearSuggestion
    let isChecked: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: Theme.Spacing.md) {
                IconBadge(systemName: item.icon, color: isChecked ? Theme.textTertiary : item.tint, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isChecked ? Theme.textTertiary : Theme.textPrimary)
                        .strikethrough(isChecked, color: Theme.textTertiary)
                    Text(item.reason)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Theme.kelp : Theme.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: isChecked)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.98))
        .accessibilityValue(isChecked ? "Packed" : "Not packed")
        .accessibilityIdentifier("gear-row")
        .sensoryFeedback(.selection, trigger: isChecked)
    }
}

// MARK: - Swipe-back with a custom back button

/// Hiding the system back button (dive detail) also disables the edge swipe.
/// Re-enable it for every pushed screen; root screens are unaffected.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
