//
//  HapticManager.swift
//  FinanceTracker
//
//  Haptic feedback yönetimi
//

import UIKit

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // Hafif dokunuş (buton tıklamaları için)
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    // Başarı titreşimi
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // Uyarı titreşimi
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    // Hata titreşimi
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // Seçim titreşimi (picker, segment control için)
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
