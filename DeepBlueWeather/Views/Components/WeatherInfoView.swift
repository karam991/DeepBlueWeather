//
//  WeatherInfoView.swift
//  DeepBlueWeather
//

import SwiftUI

struct WeatherInfoView: View {
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @EnvironmentObject var divePlannerViewModel: DivePlannerViewModel

    @State private var searchText = ""

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color("OceanBlue").opacity(0.15), Color("SoftTeal").opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "water.waves")
                            .foregroundColor(Color("OceanBlue"))
                            .font(.title2)
                        Text("DeepBlue Weather")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("OceanBlue"))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search a dive location...", text: $searchText)
                            .onSubmit {
                                Task {
                                    await weatherViewModel.fetchWeatherDataByLocation(location: searchText)
                                }
                            }
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                weatherViewModel.weatherData = nil
                                weatherViewModel.errorMessage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }

                // Content
                if let weatherData = weatherViewModel.weatherData {
                    // Location header
                    if !weatherViewModel.currentLocation.isEmpty {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(Color("Coral"))
                                .font(.caption)
                            Text(weatherViewModel.currentLocation.capitalized)
                                .font(.headline)
                                .foregroundColor(Color("OceanBlue"))
                            Spacer()
                            Text("Next 24 hours")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(weatherData.hours.filter { hour in
                                guard let date = DateFormatter.iso8601Full.date(from: hour.time) else { return false }
                                return date >= Date()
                            }.prefix(24)), id: \.id) { hour in
                                HourlyWeatherRow(hour: hour)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }

                } else if weatherViewModel.isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Fetching weather data...")
                            .foregroundColor(.gray)
                    }
                    Spacer()

                } else if let message = weatherViewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(Color("Coral"))
                        Text(message)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()

                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "water.waves")
                            .font(.system(size: 60))
                            .foregroundColor(Color("OceanBlue").opacity(0.3))
                        Text("Search a location to see\ndive weather conditions")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            if let location = divePlannerViewModel.selectedDivePlan?.location {
                Task {
                    await weatherViewModel.fetchWeatherDataByLocation(location: location)
                }
            }
        }
    }
}

// MARK: - Hourly Weather Row
struct HourlyWeatherRow: View {
    var hour: HourlyWeather

    var formattedTime: String {
        guard let date = DateFormatter.iso8601Full.date(from: hour.time) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    var formattedDate: String {
        guard let date = DateFormatter.iso8601Full.date(from: hour.time) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Time header
            HStack {
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(formattedTime)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("OceanBlue"))
            }

            Divider()

            // Weather data grid
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
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Weather Data Cell
struct WeatherDataCell: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeatherInfoView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherInfoView()
            .environmentObject(WeatherViewModel())
            .environmentObject(DivePlannerViewModel(weatherViewModel: WeatherViewModel()))
    }
}
