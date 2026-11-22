//
//  WeatherInfoView.swift
//  DeepBlueWeather
//

import SwiftUI

struct WeatherInfoView: View {
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @EnvironmentObject var divePlannerViewModel: DivePlannerViewModel

    @State private var searchText = ""
    @State private var selectedHourID: UUID?

    private var upcomingHours: [HourlyWeather] {
        guard let data = weatherViewModel.weatherData else { return [] }
        let now = Date().addingTimeInterval(-3600)
        return Array(data.hours.filter { hour in
            guard let date = DateFormatter.iso8601Full.date(from: hour.time) else { return false }
            return date >= now
        }.prefix(24))
    }

    /// Calmest daylight hour in the next 24 h (lowest waves + wind).
    private var bestHourID: UUID? {
        upcomingHours
            .filter { h in
                guard let d = h.date else { return false }
                let hr = Calendar.current.component(.hour, from: d)
                return (7...18).contains(hr)
            }
            .min { score($0) < score($1) }?.id
    }

    private func score(_ h: HourlyWeather) -> Double {
        (h.waveHeight ?? 0) * 10 + h.windSpeed * 0.3 + (h.precipitationProbability ?? 0) * 0.05
    }

    private var selectedHour: HourlyWeather? {
        upcomingHours.first { $0.id == selectedHourID } ?? upcomingHours.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                if let hour = selectedHour {
                    ConditionsHeroCard(location: weatherViewModel.currentLocation, hour: hour)
                        .appear()

                    if let bestID = bestHourID, let best = upcomingHours.first(where: { $0.id == bestID }) {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 1)) { selectedHourID = bestID }
                        } label: {
                            HStack(spacing: Theme.Spacing.md) {
                                IconBadge(systemName: "star.fill", color: Theme.sand, size: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Best dive window")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("\(best.dayLabel) at \(best.timeLabel) · calmest water")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                ConditionPill(condition: DiveCondition(waveHeight: best.waveHeight, windSpeed: best.windSpeed))
                            }
                            .card(padding: Theme.Spacing.md)
                        }
                        .buttonStyle(PressableStyle())
                        .appear(delay: 0.08)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader(title: "Hourly forecast", trailing: "Next 24 h")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.sm) {
                                ForEach(upcomingHours) { item in
                                    Button {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 1)) { selectedHourID = item.id }
                                    } label: {
                                        HourChip(hour: item, isSelected: item.id == hour.id, isBest: item.id == bestHourID)
                                    }
                                    .buttonStyle(PressableStyle(scale: 0.94))
                                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                        content
                                            .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                            .opacity(phase.isIdentity ? 1 : 0.6)
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal, -Theme.Spacing.lg)
                        .sensoryFeedback(.selection, trigger: selectedHourID)
                    }
                    .appear(delay: 0.14)

                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader(title: "Details", trailing: hour.timeLabel)
                        ConditionsGrid(hour: hour)
                    }
                    .appear(delay: 0.2)

                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader(title: "Tide & daylight")
                        TideSunCard(
                            hours: upcomingHours,
                            sunDays: weatherViewModel.weatherData?.sunDays ?? [],
                            highlight: hour.date
                        )
                    }
                    .appear(delay: 0.26)
                } else if weatherViewModel.isLoading {
                    ProgressView("Loading conditions…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 120)
                } else if let message = weatherViewModel.errorMessage {
                    StatusStateView(
                        icon: "exclamationmark.triangle.fill",
                        title: "Couldn’t load conditions",
                        message: message,
                        tint: Theme.coral
                    )
                    .padding(.top, 80)
                } else {
                    StatusStateView(
                        icon: "magnifyingglass",
                        title: "Find a dive site",
                        message: "Search any coastal location to see water temperature, waves, wind and visibility."
                    )
                    .padding(.top, 80)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Conditions")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search a dive location")
        .onSubmit(of: .search) {
            let query = searchText.trimmingCharacters(in: .whitespaces)
            guard !query.isEmpty else { return }
            selectedHourID = nil
            Task { await weatherViewModel.fetchWeatherDataByLocation(location: query) }
        }
        .refreshable {
            let location = weatherViewModel.currentLocation
            guard !location.isEmpty else { return }
            await weatherViewModel.fetchWeatherDataByLocation(location: location)
        }
        .onAppear {
            if let location = divePlannerViewModel.selectedDivePlan?.location {
                Task { await weatherViewModel.fetchWeatherDataByLocation(location: location) }
            }
        }
    }
}

// MARK: - Hero card

private struct ConditionsHeroCard: View {
    let location: String
    let hour: HourlyWeather

    var body: some View {
        let condition = DiveCondition(waveHeight: hour.waveHeight, windSpeed: hour.windSpeed)

        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(location.isEmpty ? "Current location" : location.capitalized, systemImage: "location.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(hour.dayLabel + " · " + hour.timeLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Label(condition.label, systemImage: condition.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.18)))
            }

            HStack(alignment: .lastTextBaseline, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Water")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .textCase(.uppercase)
                    Text(hour.waterTemperature.map { String(format: "%.0f°", $0) } ?? "—")
                        .font(.system(size: 72, weight: .semibold, design: .rounded))
                        .tracking(-2)
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: hour.waterTemperature ?? 0))
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("Air")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .textCase(.uppercase)
                    Text(String(format: "%.0f°", hour.airTemperature))
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: hour.airTemperature))
                }
                Spacer()
            }

            HStack(spacing: 0) {
                heroStat("wave.3.forward", hour.waveHeight.map { String(format: "%.1f m", $0) } ?? "—", "Waves")
                divider
                heroStat("wind", String(format: "%.0f km/h", hour.windSpeed), "Wind")
                divider
                heroStat("eye", hour.visibilityLabel, "Visibility")
            }
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(.white.opacity(0.12))
            )
        }
        .padding(Theme.Spacing.xl)
        .background(
            OceanBackground()
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
        )
        .shadow(color: Theme.ocean.opacity(0.35), radius: 24, x: 0, y: 12)
        .animation(.spring(response: 0.45, dampingFraction: 1), value: hour.id)
    }

    private var divider: some View {
        Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 32)
    }

    private func heroStat(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.75))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Hour chip

private struct HourChip: View {
    let hour: HourlyWeather
    let isSelected: Bool
    var isBest = false

    var body: some View {
        let condition = DiveCondition(waveHeight: hour.waveHeight, windSpeed: hour.windSpeed)

        VStack(spacing: Theme.Spacing.sm) {
            Text(hour.timeLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white.opacity(0.85) : Theme.textSecondary)
            Circle()
                .fill(isSelected ? .white : condition.color)
                .frame(width: 8, height: 8)
            Text(String(format: "%.0f°", hour.waterTemperature ?? hour.airTemperature))
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(isSelected ? .white : Theme.textPrimary)
                .monospacedDigit()
            Text(hour.waveHeight.map { String(format: "%.1fm", $0) } ?? "—")
                .font(.caption2)
                .foregroundStyle(isSelected ? .white.opacity(0.75) : Theme.textTertiary)
        }
        .frame(width: 62)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(Theme.ocean) : AnyShapeStyle(Theme.surface))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(isSelected ? .clear : Theme.stroke, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if isBest {
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Circle().fill(Theme.sand))
                    .offset(x: 4, y: -4)
            }
        }
        .shadow(color: isSelected ? Theme.ocean.opacity(0.35) : .clear, radius: 10, x: 0, y: 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Details grid

struct ConditionsGrid: View {
    let hour: HourlyWeather

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.sm), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
            MetricTile(icon: "drop.fill", title: "Water", value: hour.waterTemperature.map { String(format: "%.1f °C", $0) } ?? "N/A", color: Theme.ocean)
            MetricTile(icon: "thermometer.medium", title: "Air", value: String(format: "%.1f °C", hour.airTemperature), color: Theme.coral)
            MetricTile(icon: "wave.3.forward", title: "Waves", value: hour.waveHeight.map { String(format: "%.2f m", $0) } ?? "N/A", color: Theme.teal)
            MetricTile(icon: "wind", title: "Wind", value: String(format: "%.1f km/h", hour.windSpeed), color: Theme.kelp)
            if let rain = hour.precipitationProbability {
                MetricTile(icon: "cloud.rain.fill", title: "Rain", value: String(format: "%.0f %%", rain), color: Theme.sand)
            } else {
                MetricTile(icon: "humidity.fill", title: "Humidity", value: String(format: "%.0f %%", hour.humidity), color: Theme.sand)
            }
            MetricTile(icon: "eye.fill", title: "Visibility", value: hour.visibilityLabel, color: Theme.ocean)
        }
    }
}

// MARK: - Formatting helpers

extension HourlyWeather {
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    var date: Date? { DateFormatter.iso8601Full.date(from: time) }

    var timeLabel: String {
        date.map { Self.timeFormatter.string(from: $0) } ?? ""
    }

    var dayLabel: String {
        guard let date else { return "" }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        return Self.dayFormatter.string(from: date)
    }

    var visibilityLabel: String {
        visibility >= 1000 ? String(format: "%.0f km", visibility / 1000) : String(format: "%.0f m", visibility)
    }
}

struct WeatherInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WeatherInfoView()
        }
        .environmentObject(WeatherViewModel())
        .environmentObject(DivePlannerViewModel(weatherViewModel: WeatherViewModel()))
    }
}
