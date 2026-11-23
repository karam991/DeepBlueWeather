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

    private var sortedPlans: [DivePlan] {
        viewModel.divePlans.sorted { ($0.parsedDate ?? .distantFuture) < ($1.parsedDate ?? .distantFuture) }
    }
    private var upcoming: [DivePlan] { sortedPlans.filter { !$0.isPast && $0.log == nil } }
    private var past: [DivePlan] { sortedPlans.filter { $0.isPast || $0.log != nil }.reversed() }

    private var totalMinutes: Int { viewModel.divePlans.reduce(0) { $0 + $1.duration } }
    private var maxDepth: Int { viewModel.divePlans.map(\.depth).max() ?? 0 }

    var body: some View {
        ScrollView {
            if viewModel.divePlans.isEmpty {
                emptyState
                    .padding(.top, 100)
            } else {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack(spacing: Theme.Spacing.sm) {
                        MetricTile(icon: "list.number", title: "Dives", value: "\(viewModel.divePlans.count)", color: Theme.ocean)
                        MetricTile(icon: "timer", title: "Bottom", value: "\(totalMinutes) min", color: Theme.teal)
                        MetricTile(icon: "arrow.down.to.line", title: "Max", value: "\(maxDepth) m", color: Theme.coral)
                    }
                    .appear()

                    if let next = upcoming.first {
                        SectionHeader(title: "Next dive", trailing: next.countdownLabel)
                            .padding(.top, Theme.Spacing.sm)
                            .appear(delay: 0.05)
                        planLink(next, featured: true)
                            .appear(delay: 0.1)
                    }

                    if upcoming.count > 1 {
                        SectionHeader(title: "Upcoming")
                            .padding(.top, Theme.Spacing.sm)
                        ForEach(Array(upcoming.dropFirst().enumerated()), id: \.element.id) { index, plan in
                            planLink(plan)
                                .appear(delay: 0.12 + Double(index) * 0.05)
                        }
                    }

                    if !past.isEmpty {
                        SectionHeader(title: "Logged")
                            .padding(.top, Theme.Spacing.sm)
                        ForEach(past, id: \.id) { plan in
                            planLink(plan)
                                .opacity(0.75)
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

    @ViewBuilder
    private func planLink(_ plan: DivePlan, featured: Bool = false) -> some View {
        if let id = plan.id {
            NavigationLink(value: id) {
                DivePlanCard(plan: plan, featured: featured)
                    .zoomSource(id: id, in: zoom)
            }
            .buttonStyle(PressableStyle())
            .scrollReveal()
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

// MARK: - Plan card

struct DivePlanCard: View {
    var plan: DivePlan
    var featured = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                DateBadge(date: plan.parsedDate, inverted: featured)

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.location.capitalized)
                        .font(.headline)
                        .foregroundStyle(featured ? .white : Theme.textPrimary)
                        .lineLimit(1)
                    Text(plan.parsedDate.map { DateFormatter.readableDate.string(from: $0) } ?? plan.date)
                        .font(.subheadline)
                        .foregroundStyle(featured ? .white.opacity(0.75) : Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(featured ? .white.opacity(0.6) : Theme.textTertiary)
            }

            HStack(spacing: Theme.Spacing.sm) {
                Tag(icon: "arrow.down.to.line", text: "\(plan.depth) m", color: Theme.ocean, inverted: featured)
                Tag(icon: "timer", text: "\(plan.duration) min", color: Theme.teal, inverted: featured)
                if plan.deepDive {
                    Tag(icon: "chevron.down.2", text: "Deep", color: Theme.coral, inverted: featured)
                }
                if plan.nightDive {
                    Tag(icon: "moon.stars.fill", text: "Night", color: Theme.sand, inverted: featured)
                }
                Spacer(minLength: 0)
            }

            if let log = plan.log {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= log.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(i <= log.rating ? Theme.sand : Theme.textTertiary)
                    }
                    Text("· Logged")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            } else if plan.isPast {
                Label("Tap to log this dive", systemImage: "book.closed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.teal)
            }

            if featured {
                Label("Tap to see your smart gear list", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(Theme.Spacing.lg)
        .background {
            if featured {
                OceanBackground(showBubbles: true, waveOpacity: 0.07)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                    .shadow(color: Theme.ocean.opacity(0.35), radius: 18, x: 0, y: 10)
            } else {
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                            .strokeBorder(Theme.stroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
    }
}

private struct DateBadge: View {
    let date: Date?
    var inverted = false

    var body: some View {
        VStack(spacing: 0) {
            Text(date.map { $0.formatted(.dateTime.month(.abbreviated)) }?.uppercased() ?? "—")
                .font(.caption2.weight(.bold))
                .foregroundStyle(inverted ? .white.opacity(0.8) : Theme.ocean)
            Text(date.map { $0.formatted(.dateTime.day()) } ?? "")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(inverted ? .white : Theme.textPrimary)
        }
        .frame(width: 48, height: 48)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(inverted ? .white.opacity(0.16) : Theme.ocean.opacity(0.1))
        )
    }
}

private struct Tag: View {
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
    /// True once the hero has scrolled under the navigation bar.
    @State private var heroCollapsed = false

    private var suggestions: [GearSuggestion] { SmartGearEngine.suggestions(for: plan, hour: model.hour) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                hero

                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    if plan.log != nil || plan.isPast || (plan.parsedDate ?? .distantFuture) < Date() {
                        logSection
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
        .onChange(of: checked) { _, newValue in
            if let id = plan.id { PlanChecklistStore.save(newValue, for: id) }
        }
    }

    // MARK: Hero

    private var hero: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .scrollView).minY
            let stretch = max(0, minY)

            ZStack(alignment: .bottomLeading) {
                OceanBackground()
                    .frame(height: geo.size.height + stretch)
                    .offset(y: -stretch)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    if let countdown = plan.countdownLabel {
                        Text(countdown.uppercased())
                            .font(.caption.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Text(plan.location.capitalized)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(plan.parsedDate.map { DateFormatter.readableDate.string(from: $0) } ?? plan.date)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))

                    HStack(spacing: Theme.Spacing.sm) {
                        Tag(icon: "arrow.down.to.line", text: "\(plan.depth) m", color: Theme.ocean, inverted: true)
                        Tag(icon: "timer", text: "\(plan.duration) min", color: Theme.teal, inverted: true)
                        if plan.nightDive { Tag(icon: "moon.stars.fill", text: "Night", color: Theme.sand, inverted: true) }
                        if plan.deepDive { Tag(icon: "chevron.down.2", text: "Deep", color: Theme.coral, inverted: true) }
                    }
                    .padding(.top, 4)
                }
                .padding(Theme.Spacing.xl)
                .offset(y: -stretch * 0.15)
            }
            // Collapse when less than ~nav-bar height of the hero is still visible.
            .onChange(of: minY < -(geo.size.height - 110)) { _, collapsed in
                withAnimation(.easeInOut(duration: 0.2)) { heroCollapsed = collapsed }
            }
        }
        .frame(height: 300)
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
                    Button("Edit") { showLogSheet = true }
                        .font(.subheadline.weight(.semibold))
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= log.rating ? "star.fill" : "star")
                                .foregroundStyle(i <= log.rating ? Theme.sand : Theme.textTertiary)
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
        if !model.hours.isEmpty {
            let summary = TideLightSummary(plan: plan, hours: model.hours, sunDays: model.sunDays)
            let window = model.hours.filter { h in
                guard let d = h.date, let target = plan.parsedDate else { return false }
                return abs(d.timeIntervalSince(target)) <= 12 * 3600
            }
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
                if !window.isEmpty {
                    TideSunCard(hours: window, sunDays: model.sunDays, highlight: plan.parsedDate)
                }
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
            HStack {
                SectionHeader(title: "Conditions at dive time")
                if let hour = model.hour {
                    ConditionPill(condition: DiveCondition(waveHeight: hour.waveHeight, windSpeed: hour.windSpeed))
                        .transition(.scale.combined(with: .opacity))
                }
            }

            if model.isLoading {
                HStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                    Text("Reading the forecast…")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .card()
            } else if let hour = model.hour {
                ConditionsGrid(hour: hour)
            } else {
                Label(model.outOfRange
                      ? "The forecast reaches 7 days ahead. Gear for weather will appear closer to the dive."
                      : "No forecast available for this location.",
                      systemImage: "calendar.badge.clock")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 1), value: model.isLoading)
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
                    Text("\(done)/\(items.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(done)))
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
