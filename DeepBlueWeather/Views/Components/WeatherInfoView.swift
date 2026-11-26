//
//  WeatherInfoView.swift
//  DeepBlueWeather
//

import SwiftUI

struct WeatherInfoView: View {
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @EnvironmentObject var divePlannerViewModel: DivePlannerViewModel

    @State private var searchText = ""
    @State private var searching = false
    @State private var selectedHourID: UUID?
    /// True once the hero has scrolled under the navigation bar.
    @State private var heroCollapsed = false

    var body: some View {
        let forecast = ConditionsForecast(location: weatherViewModel.currentLocation, data: weatherViewModel.weatherData)
        let selected = forecast.hour(id: selectedHourID)
        let overSea = selected != nil && !heroCollapsed

        GeometryReader { screen in
            ScrollView {
                if let hour = selected {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        ConditionsHero(location: forecast.location, hour: hour, sunDays: forecast.sunDays,
                                       topInset: screen.safeAreaInsets.top)
                            .background {
                                GeometryReader { hero in
                                    Color.clear.onChange(of: hero.frame(in: .global).maxY < screen.safeAreaInsets.top + 24) { _, collapsed in
                                        withAnimation(.easeInOut(duration: 0.2)) { heroCollapsed = collapsed }
                                    }
                                }
                            }
                        details(forecast: forecast, hour: hour)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.bottom, Theme.Spacing.xl)
                    }
                } else {
                    placeholder
                        .padding(.top, screen.safeAreaInsets.top + 80)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Conditions")
        .navigationBarTitleDisplayMode(.inline)
        // Transparent with light text over the sea, solid once content scrolls underneath.
        // A plain colour (not a material) lets iOS 17 apply the dark scheme to the whole bar.
        .toolbarBackground(overSea ? Theme.abyss.opacity(0.25) : Theme.background.opacity(0.96), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(overSea ? .dark : nil, for: .navigationBar)
        .searchable(text: $searchText, isPresented: $searching, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search a dive location")
        .onSubmit(of: .search) {
            let query = searchText.trimmingCharacters(in: .whitespaces)
            guard !query.isEmpty else { return }
            selectedHourID = nil
            // Close the search so the new place's sea is shown full screen.
            searching = false
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

    private func details(forecast: ConditionsForecast, hour: HourlyWeather) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            HourlyForecastChart(forecast: forecast, selected: hour) { picked in
                withAnimation(Theme.Motion.state) { selectedHourID = picked.id }
            }
            .appear(delay: 0.08)

            Divider()
            FactsStrip(facts: hour.secondaryFacts)
                .appear(delay: 0.12)
            Divider()

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                SectionHeader(title: "Tide & daylight")
                TideSunCard(hours: forecast.hours, sunDays: forecast.sunDays, highlight: hour.date)
            }
            .appear(delay: 0.16)
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if weatherViewModel.isLoading {
            ProgressView("Loading conditions…")
                .frame(maxWidth: .infinity)
        } else if let message = weatherViewModel.errorMessage {
            StatusStateView(
                icon: "exclamationmark.triangle.fill",
                title: "Couldn’t load conditions",
                message: message,
                tint: Theme.coral
            )
        } else {
            StatusStateView(
                icon: "magnifyingglass",
                title: "Find a dive site",
                message: "Search any coastal location to see water temperature, waves, wind and visibility."
            )
        }
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
