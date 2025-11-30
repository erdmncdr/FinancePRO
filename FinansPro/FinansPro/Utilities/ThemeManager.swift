//
//  ThemeManager.swift
//  FinanceTracker
//
//  Liquid glass tema ve stil sistemi
//

import SwiftUI

struct Theme {
    // Premium renkler - Liquid glass uyumlu
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.4, green: 0.6, blue: 1.0),
            Color(red: 0.6, green: 0.4, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.4, blue: 0.6),
            Color(red: 1.0, green: 0.6, blue: 0.4)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.9, blue: 0.6),
            Color(red: 0.4, green: 0.8, blue: 0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Glass efektleri için renkler
    static func glassBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.white.opacity(0.95)
    }

    static func cardBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(white: 0.15)
            : Color.white
    }

    // Arka plan gradientleri
    static func backgroundGradient(_ colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.05, blue: 0.15),
                    Color(red: 0.05, green: 0.1, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.98),
                    Color(red: 0.92, green: 0.94, blue: 0.97),
                    Color(red: 0.94, green: 0.95, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // Premium fontlar
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
}

// Glass efekt modifier
struct GlassEffect: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.7

    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if colorScheme == .dark {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Theme.glassBackground(colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(
                                color: Color.black.opacity(0.3),
                                radius: 20,
                                x: 0,
                                y: 10
                            )
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(.ultraThinMaterial)
                            )
                    } else {
                        // Light mode: increase contrast with solid background and subtle border
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(
                                color: Color.black.opacity(0.12),
                                radius: 18,
                                x: 0,
                                y: 8
                            )
                    }
                }
            )
    }
}

// Premium kart efekti
struct PremiumCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Theme.cardBackground(colorScheme))

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            colorScheme == .dark
                                ? Color.white.opacity(0.1)
                                : Color.black.opacity(0.1),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: colorScheme == .dark
                        ? Color.black.opacity(0.5)
                        : Color.black.opacity(0.12),
                    radius: 15,
                    x: 0,
                    y: 5
                )
            )
    }
}

// View extension'ları
extension View {
    func glassEffect(cornerRadius: CGFloat = 20, opacity: Double = 0.7) -> some View {
        self.modifier(GlassEffect(cornerRadius: cornerRadius, opacity: opacity))
    }

    func premiumCard(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(PremiumCard(cornerRadius: cornerRadius))
    }

    // Premium animasyon
    func premiumAnimation() -> some View {
        self.animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0), value: UUID())
    }

    // Bounce animasyonu
    func bounceEffect() -> some View {
        self.animation(.interpolatingSpring(stiffness: 170, damping: 10), value: UUID())
    }
}

// Para formatı için yardımcı
extension Double {
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.currencySymbol = "₺"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "₺0,00"
    }
}

// Tarih formatı için yardımcı
extension Date {
    func toShortString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    func toRelativeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

