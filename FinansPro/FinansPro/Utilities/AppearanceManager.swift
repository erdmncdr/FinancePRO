//
//  AppearanceManager.swift
//  FinansPro
//
//  Görünüm (Dark/Light mode) yöneticisi
//

import Foundation
import SwiftUI

@MainActor
class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    @Published var selectedAppearance: AppearanceMode {
        didSet {
            UserDefaults.standard.set(selectedAppearance.rawValue, forKey: "AppearanceMode")
        }
    }

    private init() {
        let savedValue = UserDefaults.standard.string(forKey: "AppearanceMode")
        self.selectedAppearance = AppearanceMode(rawValue: savedValue ?? "system") ?? .system
    }

    var colorScheme: ColorScheme? {
        switch selectedAppearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return "Sistem"
        case .light: return "Açık"
        case .dark: return "Koyu"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}
