//
//  AppearanceMode.swift
//  DeepBlueWeather
//
//  The Settings choice between System, Light and Dark.
//

import UIKit

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "appearance"
    /// The on/off switch used by earlier versions.
    private static let legacyKey = "darkModeEnabled"

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Keeps Dark for anyone who had the old switch on. Everyone else follows the system.
    static func migrate(_ defaults: UserDefaults = .standard) {
        guard defaults.string(forKey: storageKey) == nil, defaults.bool(forKey: legacyKey) else { return }
        defaults.set(AppearanceMode.dark.rawValue, forKey: storageKey)
        defaults.removeObject(forKey: legacyKey)
    }

    /// Applied to the windows rather than with `preferredColorScheme`, which does not
    /// reliably return to System and pins the status bar style over the sea.
    @MainActor
    func apply() {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                window.overrideUserInterfaceStyle = interfaceStyle
            }
        }
    }
}
