//
//  CustomCategory.swift
//  FinansPro
//
//  Kullanıcı tanımlı özel kategoriler
//

import Foundation
import SwiftUI

/// Kullanıcının oluşturduğu özel kategori
struct CustomCategory: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String // Renk hex formatında saklanır
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "tag.fill",
        colorHex: String = "#6B7280", // Varsayılan gri
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = createdAt
    }

    /// Hex string'i Color'a çevirir
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    /// SF Symbol icon adı
    var icon: String {
        iconName
    }
}

/// Hem varsayılan hem de özel kategorileri temsil eden birleşik model
enum CategoryItem: Identifiable, Hashable {
    case standard(TransactionCategory)
    case custom(CustomCategory)

    var id: String {
        switch self {
        case .standard(let category):
            return "standard_\(category.rawValue)"
        case .custom(let category):
            return "custom_\(category.id.uuidString)"
        }
    }

    var name: String {
        switch self {
        case .standard(let category):
            return category.rawValue
        case .custom(let category):
            return category.name
        }
    }

    var icon: String {
        switch self {
        case .standard(let category):
            return category.icon
        case .custom(let category):
            return category.icon
        }
    }

    var color: Color {
        switch self {
        case .standard(let category):
            return category.color
        case .custom(let category):
            return category.color
        }
    }
}

// Color extension - Hex desteği
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count
        let r, g, b, a: Double

        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}
