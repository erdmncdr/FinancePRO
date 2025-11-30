//
//  TransactionModel.swift
//  FinanceTracker
//
//  Veri modelleri
//

import Foundation
import SwiftUI

// Transaction türleri
enum TransactionType: String, Codable, CaseIterable {
    case expense = "Gider"
    case income = "Gelir"
    case debt = "Borç"
    case lent = "Alacak"
    case upcoming = "Gelecek Ödeme"
}

// Kategoriler
enum TransactionCategory: String, Codable, CaseIterable {
    case food = "Yemek"
    case transport = "Ulaşım"
    case shopping = "Alışveriş"
    case bills = "Faturalar"
    case entertainment = "Eğlence"
    case health = "Sağlık"
    case education = "Eğitim"
    case salary = "Maaş"
    case investment = "Yatırım"
    case other = "Diğer"

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "cart.fill"
        case .bills: return "doc.text.fill"
        case .entertainment: return "theatermasks.fill"
        case .health: return "cross.fill"
        case .education: return "book.fill"
        case .salary: return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .shopping: return .purple
        case .bills: return .red
        case .entertainment: return .pink
        case .health: return .green
        case .education: return .indigo
        case .salary: return .mint
        case .investment: return .cyan
        case .other: return .gray
        }
    }
}

// Ana Transaction modeli
struct Transaction: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var amount: Double
    var type: TransactionType
    var category: TransactionCategory
    var date: Date
    var note: String
    var isPaid: Bool
    var dueDate: Date?
    var customCategoryId: UUID? // Özel kategori kullanılıyorsa
    var trackedInCashFlow: Bool? // Borç/alacak için: gelir/gider olarak da kaydedildi mi?
    var receiptImageData: Data? // Fiş/fatura fotoğrafı

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        type: TransactionType,
        category: TransactionCategory,
        date: Date = Date(),
        note: String = "",
        isPaid: Bool = true,
        dueDate: Date? = nil,
        customCategoryId: UUID? = nil,
        trackedInCashFlow: Bool? = nil,
        receiptImageData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.category = category
        self.date = date
        self.note = note
        self.isPaid = isPaid
        self.dueDate = dueDate
        self.customCategoryId = customCategoryId
        self.trackedInCashFlow = trackedInCashFlow
        self.receiptImageData = receiptImageData
    }

    /// İşlemin gerçek kategori bilgisini döndürür (özel veya varsayılan)
    func getCategoryItem(customCategories: [CustomCategory]) -> CategoryItem {
        if let customId = customCategoryId,
           let customCategory = customCategories.first(where: { $0.id == customId }) {
            return .custom(customCategory)
        }
        return .standard(category)
    }
}

// İstatistikler için yardımcı model
struct FinancialSummary {
    var totalIncome: Double
    var totalExpenses: Double
    var totalDebts: Double
    var totalLent: Double
    var upcomingPayments: Double
    var balance: Double {
        totalIncome - totalExpenses - totalDebts + totalLent
    }
}
