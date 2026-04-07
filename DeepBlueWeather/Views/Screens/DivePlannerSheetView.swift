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
    @ObservedObject var divePlannerViewModel: DivePlannerViewModel
    @EnvironmentObject var weatherViewModel: WeatherViewModel
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
            Form {
                Section(header: Text("Location Details")) {
                    TextField("Location", text: $location)
                        .onSubmit {
                            divePlannerViewModel.fetchCoordinatesAndWeather(for: location)
                        }

                    Map(position: .constant(.region(region)))
                        .frame(height: 200)
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

                Section(header: Text("Weather Information")) {
                    if let weatherData = divePlannerViewModel.weatherViewModel.weatherData {
                        Text("Air Temperature: \(String(format: "%.1f", weatherData.hours.first?.airTemperature ?? 0)) °C")
                        Text("Water Temperature: \(weatherData.hours.first?.waterTemperature.map { String(format: "%.1f", $0) } ?? "N/A") °C")
                    } else {
                        Text("Fetching weather...")
                    }
                }

                Section(header: Text("Dive Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker("Current Condition", selection: $currentCondition) {
                        ForEach(["Calm", "Moderate", "Rough"], id: \.self) {
                            Text($0)
                        }
                    }
                    Stepper("Depth: \(depth) meters", value: $depth, in: 0...100, step: 5)
                    Stepper("Duration: \(duration) minutes", value: $duration, in: 10...180, step: 10)
                    Toggle("Night Dive", isOn: $isNightDive)
                    Toggle("Deep Dive", isOn: $isDeepDive)
                }

                Section {
                    Button("Save Dive Plan") {
                        divePlannerViewModel.createDivePlan(
                            location: location,
                            date: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short),
                            depth: depth,
                            duration: duration,
                            deepDive: isDeepDive,
                            nightDive: isNightDive
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!isFormValid)
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
