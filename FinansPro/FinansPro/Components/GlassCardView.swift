//
//  GlassCardView.swift
//  FinanceTracker
//
//  Yeniden kullanılabilir glass card bileşenleri
//

import SwiftUI

// Transaction card - Liquid glass tasarımı
struct TransactionCard: View {
    let transaction: Transaction
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager

    private var categoryItem: CategoryItem {
        transaction.getCategoryItem(customCategories: dataManager.customCategories)
    }

    var body: some View {
        HStack(spacing: 15) {
            // İkon
            ZStack {
                Circle()
                    .fill(categoryItem.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: categoryItem.icon)
                    .font(.system(size: 22))
                    .foregroundColor(categoryItem.color)
            }

            // Bilgiler
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(Theme.headline)
                    .foregroundColor(.primary)

                Text(categoryItem.name)
                    .font(Theme.caption)
                    .foregroundColor(.secondary)

                if let dueDate = transaction.dueDate, !transaction.isPaid {
                    Label(dueDate.toRelativeString(), systemImage: "clock")
                        .font(Theme.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Miktar
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.amount.toCurrency())
                    .font(Theme.headline)
                    .foregroundColor(amountColor)
                    .fontWeight(.bold)

                if !transaction.isPaid {
                    Text("Ödenmedi")
                        .font(Theme.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .premiumCard()
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income:
            return .green
        case .expense, .debt, .lent, .upcoming:
            return .red
        }
    }
}

// Özet kart
struct SummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let gradient: LinearGradient
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(gradient)

                Spacer()

                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(gradient)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.subheadline)
                    .foregroundColor(.secondary)

                Text(amount.toCurrency())
                    .font(Theme.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(gradient)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect()
    }
}

// Hızlı aksiyon butonu
struct QuickActionButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(Theme.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Ekle butonu
struct AddTransactionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Theme.primaryGradient)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.blue.opacity(0.4), radius: 15, x: 0, y: 8)

                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Buton stil
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Boş durum görseli
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.primaryGradient.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(Theme.primaryGradient)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(Theme.title3)
                    .fontWeight(.bold)

                Text(message)
                    .font(Theme.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Section başlığı
struct SectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(Theme.headline)
            }

            Text(title)
                .font(Theme.title3)
                .fontWeight(.bold)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
