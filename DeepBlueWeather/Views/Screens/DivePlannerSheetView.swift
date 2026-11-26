//
//  DivePlannerSheetView.swift
//  DeepBlueWeather
//
//  Created by Karam Alnaser on 20.03.24.
//

import SwiftUI
import MapKit

struct DivePlannerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @ObservedObject var divePlannerViewModel: DivePlannerViewModel

    @State private var location: String = ""
    @State private var date: Date = Date()
    @State private var depth: Int = 10
    @State private var duration: Int = 40
    @State private var isNightDive: Bool = false
    @State private var isDeepDive: Bool = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    private var isFormValid: Bool {
        !location.trimmingCharacters(in: .whitespaces).isEmpty && depth > 0 && duration > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    locationSection
                    conditionsSection
                    detailsSection
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New Dive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Label("Save Dive Plan", systemImage: "checkmark")
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: isFormValid))
                .disabled(!isFormValid)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(.bar)
            }
        }
        .onAppear {
            if location.isEmpty {
                location = weatherViewModel.currentLocation
                if !location.isEmpty {
                    divePlannerViewModel.fetchCoordinatesAndWeather(for: location)
                }
            }
            if let existingLocation = divePlannerViewModel.selectedDivePlan?.location {
                divePlannerViewModel.fetchCoordinatesAndWeather(for: existingLocation)
            }
        }
        .onChange(of: divePlannerViewModel.currentLocationCoordinate?.latitude) { _, _ in
            if let coordinate = divePlannerViewModel.currentLocationCoordinate {
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
            }
        }
    }

    // MARK: Sections

    private var locationSection: some View {
        FormSection(title: "Dive site", icon: "mappin.and.ellipse", color: Theme.coral) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textTertiary)
                TextField("Search location", text: $location)
                    .submitLabel(.search)
                    .onSubmit {
                        divePlannerViewModel.fetchCoordinatesAndWeather(for: location)
                    }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(Theme.surfaceRaised)
            )

            Map(position: $cameraPosition) {
                if let coordinate = divePlannerViewModel.currentLocationCoordinate {
                    Marker(location.isEmpty ? "Dive site" : location, systemImage: "water.waves", coordinate: coordinate)
                        .tint(Theme.ocean)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .allowsHitTesting(false)
        }
    }

    private var conditionsSection: some View {
        FormSection(title: "Current conditions", icon: "cloud.sun.fill", color: Theme.ocean) {
            if let hour = divePlannerViewModel.weatherViewModel.weatherData?.hours.first {
                let condition = DiveCondition(waveHeight: hour.waveHeight, windSpeed: hour.windSpeed)
                HStack {
                    Text("Dive rating")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    ConditionPill(condition: condition)
                }
                ConditionsGrid(hour: hour)
            } else {
                HStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                    Text("Search a location to load conditions")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
            }
        }
    }

    private var detailsSection: some View {
        FormSection(title: "Dive details", icon: "figure.open.water.swim", color: Theme.teal) {
            VStack(spacing: 0) {
                DatePicker("Date & time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .padding(.vertical, 10)
                Divider()
                valueStepper(title: "Max depth", value: $depth, range: 5...60, step: 1, unit: "m")
                Divider()
                valueStepper(title: "Bottom time", value: $duration, range: 10...180, step: 5, unit: "min")
                Divider()
                Toggle(isOn: $isNightDive) {
                    Label("Night dive", systemImage: "moon.stars.fill")
                }
                .padding(.vertical, 10)
                Divider()
                Toggle(isOn: $isDeepDive) {
                    Label("Deep dive", systemImage: "chevron.down.2")
                }
                .padding(.vertical, 10)
            }
            .tint(Theme.ocean)
            .foregroundStyle(Theme.textPrimary)

            if depth > 40 {
                Label("Depths beyond 40 m exceed recreational limits.", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.coral)
            }
        }
    }

    private func valueStepper(title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int, unit: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue) \(unit)")
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ocean)
            }
        }
        .padding(.vertical, 10)
    }

    private func save() {
        guard isFormValid else { return }
        divePlannerViewModel.createDivePlan(
            location: location,
            date: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short),
            depth: depth,
            duration: duration,
            deepDive: isDeepDive,
            nightDive: isNightDive
        )
        if DiveReminderService.isEnabled {
            Task { _ = await DiveReminderService.requestPermission() }
        }
        dismiss()
    }
}

// MARK: - Form section

struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                IconBadge(systemName: icon, color: color, size: 28)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }
            content
        }
        .card()
    }
}

// MARK: - Conditions grid

private struct ConditionsGrid: View {
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
