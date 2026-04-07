//
//  DivePlannerSheetView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 20.03.24.
//

import SwiftUI
import MapKit

struct DivePlannerSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @ObservedObject var divePlannerViewModel: DivePlannerViewModel

    @State private var location: String = ""
    @State private var date: Date = Date()
    @State private var depth: Int = 0
    @State private var duration: Int = 0
    @State private var isNightDive: Bool = false
    @State private var isDeepDive: Bool = false
    @State private var currentCondition: String = "Calm"
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var isFormValid: Bool {
        !location.trimmingCharacters(in: .whitespaces).isEmpty && depth > 0 && duration > 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // MARK: - Location Section
                        SectionCard(title: "Location", icon: "mappin.circle.fill", color: Color("Coral")) {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    TextField("Enter dive location", text: $location)
                                        .onSubmit {
                                            divePlannerViewModel.fetchCoordinatesAndWeather(for: location)
                                        }
                                }
                                .padding(12)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)

                                Map(position: .constant(.region(region)))
                                    .frame(height: 180)
                                    .cornerRadius(12)
                                    .onChange(of: divePlannerViewModel.currentLocationCoordinate?.latitude) { _, _ in
                                        if let coordinate = divePlannerViewModel.currentLocationCoordinate {
                                            region = MKCoordinateRegion(
                                                center: coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            )
                                        }
                                    }
                            }
                        }

                        // MARK: - Weather Section
                        SectionCard(title: "Current Conditions", icon: "cloud.sun.fill", color: Color("OceanBlue")) {
                            if let weatherData = divePlannerViewModel.weatherViewModel.weatherData,
                               let hour = weatherData.hours.first {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    WeatherDataCell(icon: "thermometer", title: "Air", value: String(format: "%.1f°C", hour.airTemperature), color: Color("Coral"))
                                    WeatherDataCell(icon: "drop.fill", title: "Water", value: hour.waterTemperature.map { String(format: "%.1f°C", $0) } ?? "N/A", color: Color("OceanBlue"))
                                    WeatherDataCell(icon: "wind", title: "Wind", value: String(format: "%.1f km/h", hour.windSpeed), color: Color("SeaGreen"))
                                    WeatherDataCell(icon: "wave.3.forward", title: "Waves", value: hour.waveHeight.map { String(format: "%.2f m", $0) } ?? "N/A", color: Color("SoftTeal"))
                                    WeatherDataCell(icon: "humidity", title: "Humidity", value: String(format: "%.0f%%", hour.humidity), color: Color("Sand"))
                                    WeatherDataCell(icon: "eye", title: "Visibility", value: String(format: "%.0f m", hour.visibility), color: Color("Coral"))
                                }
                            } else {
                                HStack {
                                    ProgressView()
                                    Text("Fetching weather...")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                        }

                        // MARK: - Dive Details Section
                        SectionCard(title: "Dive Details", icon: "figure.open.water.swim", color: Color("SeaGreen")) {
                            VStack(spacing: 0) {
                                DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .padding(.vertical, 12)
                                Divider()
                                Picker("Conditions", selection: $currentCondition) {
                                    ForEach(["Calm", "Moderate", "Rough"], id: \.self) {
                                        Text($0)
                                    }
                                }
                                .padding(.vertical, 4)
                                Divider()
                                Stepper("Depth: \(depth)m", value: $depth, in: 0...100, step: 5)
                                    .padding(.vertical, 12)
                                Divider()
                                Stepper("Duration: \(duration) min", value: $duration, in: 10...180, step: 10)
                                    .padding(.vertical, 12)
                                Divider()
                                Toggle("Night Dive", isOn: $isNightDive)
                                    .tint(Color("OceanBlue"))
                                    .padding(.vertical, 12)
                                Divider()
                                Toggle("Deep Dive", isOn: $isDeepDive)
                                    .tint(Color("OceanBlue"))
                                    .padding(.vertical, 12)
                            }
                        }

                        // MARK: - Save Button
                        Button(action: {
                            divePlannerViewModel.createDivePlan(
                                location: location,
                                date: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short),
                                depth: depth,
                                duration: duration,
                                deepDive: isDeepDive,
                                nightDive: isNightDive
                            )
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Dive Plan")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color("OceanBlue") : Color.gray)
                            .cornerRadius(14)
                            .shadow(color: isFormValid ? Color("OceanBlue").opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                        }
                        .disabled(!isFormValid)
                        .padding(.bottom, 8)
                    }
                    .padding()
                }
            }
            .navigationBarTitle("New Dive Plan", displayMode: .inline)
            .navigationBarItems(trailing: Button("Dismiss") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .onAppear {
            if location.isEmpty {
                location = weatherViewModel.currentLocation
                divePlannerViewModel.fetchCoordinatesAndWeather(for: location)
            }
            if let existingLocation = divePlannerViewModel.selectedDivePlan?.location {
                divePlannerViewModel.fetchCoordinatesAndWeather(for: existingLocation)
            }
        }
    }
}

// MARK: - Section Card Helper
struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            content
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
