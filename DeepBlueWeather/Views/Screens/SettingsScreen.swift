//
//  SettingsScreen.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage(DiveReminderService.enabledKey) private var remindersEnabled = true
    @EnvironmentObject private var plannerViewModel: DivePlannerViewModel
    @State private var notificationsDenied = false
    @State private var showingSignOutConfirm = false

    private var accountEmail: String {
        loginViewModel.currentUserEmail ?? loginViewModel.email
    }

    private var displayEmail: String {
        accountEmail.isEmpty ? "Signed in" : accountEmail
    }

    private var initial: String {
        accountEmail.first.map { String($0).uppercased() } ?? "D"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: Theme.Spacing.lg) {
                    Text(initial)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Theme.heroGradient))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Diver Account")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text(displayEmail)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Appearance") {
                Toggle(isOn: $darkModeEnabled) {
                    SettingsRow(icon: "moon.fill", color: Theme.ocean, title: "Dark Mode")
                }
                .tint(Theme.ocean)
            }

            Section {
                Toggle(isOn: $remindersEnabled) {
                    SettingsRow(icon: "bell.badge.fill", color: Theme.coral, title: "Dive reminders")
                }
                .tint(Theme.ocean)
                .onChange(of: remindersEnabled) { _, enabled in
                    Task {
                        if enabled {
                            let granted = await DiveReminderService.requestPermission()
                            await MainActor.run { notificationsDenied = !granted }
                        }
                        DiveReminderService.sync(with: plannerViewModel.divePlans)
                    }
                }
            } header: {
                Text("Notifications")
            } footer: {
                if notificationsDenied {
                    Text("Notifications are turned off for DeepBlue. Enable them in the iOS Settings app.")
                        .foregroundStyle(Theme.coral)
                } else {
                    Text("A reminder at 19:00 the evening before each dive, with what to pack.")
                }
            }

            Section("About") {
                LabeledContent {
                    Text(appVersion).foregroundStyle(Theme.textSecondary)
                } label: {
                    SettingsRow(icon: "info.circle.fill", color: Theme.teal, title: "Version")
                }

                Link(destination: URL(string: "https://open-meteo.com")!) {
                    HStack {
                        SettingsRow(icon: "waveform.path.ecg", color: Theme.kelp, title: "Weather data by Open-Meteo")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showingSignOutConfirm = true
                } label: {
                    SettingsRow(icon: "rectangle.portrait.and.arrow.right", color: Theme.coral, title: "Sign Out", titleColor: Theme.coral)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .confirmationDialog("Sign out of DeepBlue?", isPresented: $showingSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { loginViewModel.logout() }
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    var titleColor: Color = Theme.textPrimary

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            IconBadge(systemName: icon, color: color, size: 30)
            Text(title)
                .foregroundStyle(titleColor)
        }
    }
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { SettingsScreen() }
            .environmentObject(LoginViewModel())
            .environmentObject(DivePlannerViewModel(weatherViewModel: WeatherViewModel()))
    }
}
