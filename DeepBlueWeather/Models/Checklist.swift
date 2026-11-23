//
//  Checklist.swift
//  DeepBlueWeather
//
//  Created by Karam Alnaser on 12.04.24.
//

import Foundation
import SwiftUI

struct ChecklistItem: Codable, Identifiable {
    var id = UUID()
    let title: String
    var isChecked: Bool
}

// MARK: - Smart gear (per dive plan, generated from forecast + plan settings)

struct GearSuggestion: Identifiable, Hashable {
    enum Category: String, CaseIterable {
        case weather = "Weather"
        case exposure = "Exposure protection"
        case dive = "Dive profile"
        case comfort = "Comfort"
    }

    /// Stable id so the checked state survives regenerations.
    let id: String
    let title: String
    let reason: String
    let icon: String
    let category: Category
    let tint: Color
}

enum SmartGearEngine {

    /// Builds condition-based gear suggestions for one dive.
    /// - Parameter hour: forecast hour closest to the dive time, nil if the dive is outside the forecast range.
    static func suggestions(for plan: DivePlan, hour: HourlyWeather?) -> [GearSuggestion] {
        var items: [GearSuggestion] = []

        func add(_ id: String, _ title: String, _ reason: String, _ icon: String, _ category: GearSuggestion.Category, _ tint: Color) {
            guard !items.contains(where: { $0.id == id }) else { return }
            items.append(GearSuggestion(id: id, title: title, reason: reason, icon: icon, category: category, tint: tint))
        }

        if let hour {
            // Rain
            let rainChance = hour.precipitationProbability ?? 0
            let rainAmount = hour.precipitation ?? 0
            if rainChance >= 40 || rainAmount >= 0.3 {
                let why = rainChance > 0 ? "\(Int(rainChance))% chance of rain" : String(format: "%.1f mm rain expected", rainAmount)
                add("rain-jacket", "Rain jacket", why, "cloud.rain.fill", .weather, Theme.ocean)
                add("dry-bag", "Dry bag for phone & papers", "Keep electronics dry on the boat or beach", "bag.fill", .weather, Theme.ocean)
            }

            // Wind
            if hour.windSpeed >= 25 {
                add("windbreaker", "Windbreaker", String(format: "Wind up to %.0f km/h", hour.windSpeed), "wind", .weather, Theme.teal)
            }

            // Sun
            if (hour.uvIndex ?? 0) >= 6 || hour.airTemperature >= 28 {
                let why = (hour.uvIndex ?? 0) >= 6 ? String(format: "UV index %.0f", hour.uvIndex ?? 0) : String(format: "%.0f °C air temperature", hour.airTemperature)
                add("reef-sunscreen", "Reef-safe sunscreen", why, "sun.max.fill", .weather, Theme.sand)
                add("hat-sunglasses", "Hat & sunglasses", why, "sunglasses.fill", .weather, Theme.sand)
                add("extra-water", "Extra drinking water", "Diving in heat dehydrates fast", "waterbottle.fill", .comfort, Theme.teal)
            }

            // Cold air
            if hour.airTemperature < 15 {
                add("warm-layer", "Warm jacket / changing poncho", String(format: "Only %.0f °C on the surface", hour.airTemperature), "thermometer.snowflake", .comfort, Theme.ocean)
                add("thermos", "Thermos with hot drink", "Warm up between dives", "cup.and.saucer.fill", .comfort, Theme.coral)
            }

            // Water temperature → exposure suit
            if let rawWater = hour.waterTemperature {
                // Classify on the rounded value the user sees ("Water 18 °C").
                let water = rawWater.rounded()
                let tempText = String(format: "Water %.0f °C", water)
                switch water {
                case ..<12:
                    add("drysuit", "Drysuit + undersuit", tempText, "snowflake", .exposure, Theme.ocean)
                    add("hood", "Hood", tempText, "person.crop.circle.fill", .exposure, Theme.ocean)
                    add("thick-gloves", "Thick gloves", tempText, "hand.raised.fill", .exposure, Theme.ocean)
                case 12..<18:
                    add("wetsuit-7", "7 mm wetsuit", tempText, "figure.open.water.swim", .exposure, Theme.ocean)
                    add("hood", "Hood", tempText, "person.crop.circle.fill", .exposure, Theme.ocean)
                    add("thick-gloves", "Gloves", tempText, "hand.raised.fill", .exposure, Theme.ocean)
                case 18..<24:
                    add("wetsuit-5", "5 mm wetsuit", tempText, "figure.open.water.swim", .exposure, Theme.teal)
                case 24..<28:
                    add("wetsuit-3", "3 mm wetsuit", tempText, "figure.open.water.swim", .exposure, Theme.teal)
                default:
                    add("shorty", "Shorty or rash guard", tempText, "figure.open.water.swim", .exposure, Theme.kelp)
                }
            }

            // Waves
            if let waves = hour.waveHeight {
                if waves >= 1.0 {
                    add("seasick", "Seasickness tablets", String(format: "%.1f m waves", waves), "pills.fill", .comfort, Theme.coral)
                }
                if waves >= 1.5 {
                    add("smb", "SMB & reel", String(format: "%.1f m waves — be visible at the surface", waves), "flag.fill", .dive, Theme.coral)
                }
            }
        }

        // Plan-based rules (always apply, even without forecast)
        if plan.nightDive {
            add("primary-torch", "Primary torch", "Night dive", "flashlight.on.fill", .dive, Theme.sand)
            add("backup-torch", "Backup torch", "Night dive — always carry a spare", "flashlight.off.fill", .dive, Theme.sand)
            add("tank-light", "Tank light / strobe", "So your buddy can find you", "light.beacon.max.fill", .dive, Theme.sand)
        }
        if plan.deepDive || plan.depth > 30 {
            add("smb", "SMB & reel", "Deep dive to \(plan.depth) m", "flag.fill", .dive, Theme.coral)
            add("redundant-gas", "Redundant air source", "Deep dive to \(plan.depth) m", "lungs.fill", .dive, Theme.coral)
            add("computer-check", "Dive computer (charged, set for depth)", "Deep dive to \(plan.depth) m", "gauge.with.dots.needle.67percent", .dive, Theme.coral)
        }
        if plan.duration >= 60 {
            add("snack", "Snack & electrolytes", "\(plan.duration) min bottom time", "fork.knife", .comfort, Theme.kelp)
        }

        return items
    }
}

// MARK: - Per-plan checked state

enum PlanChecklistStore {
    private static func key(_ planId: String) -> String { "planChecklist.\(planId)" }

    static func checkedIDs(for planId: String) -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key(planId)) ?? [])
    }

    static func save(_ ids: Set<String>, for planId: String) {
        UserDefaults.standard.set(Array(ids), forKey: key(planId))
    }

    static func remove(planId: String) {
        UserDefaults.standard.removeObject(forKey: key(planId))
    }
}
