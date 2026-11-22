//
//  SharedDiveStore.swift
//  DeepBlueWeather
//
//  Compiled into BOTH the app and the widget extension.
//  The app writes the next upcoming dive into the shared App Group,
//  the widget reads it.
//

import Foundation

struct SharedNextDive: Codable, Equatable {
    var location: String
    var date: Date
    var depth: Int
    var duration: Int
    var nightDive: Bool
    var deepDive: Bool
}

enum SharedDiveStore {
    static let appGroup = "group.Syntax.DeepBlueWeather"
    private static let key = "nextDive"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func load() -> SharedNextDive? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SharedNextDive.self, from: data)
    }

    /// Returns true when the stored value actually changed.
    @discardableResult
    static func save(_ dive: SharedNextDive?) -> Bool {
        guard dive != load() else { return false }
        if let dive, let data = try? JSONEncoder().encode(dive) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
        return true
    }
}
