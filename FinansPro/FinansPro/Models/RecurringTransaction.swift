//
//  RecurringTransaction.swift
//  FinansPro
//
//  Tekrarlayan işlemler için model
//

import Foundation

/// Tekrarlama sıklığı
enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily = "Her Gün"
    case weekly = "Her Hafta"
    case biweekly = "İki Haftada Bir"
    case monthly = "Her Ay"
    case quarterly = "Her 3 Ay"
    case yearly = "Her Yıl"

    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar"
        case .biweekly: return "calendar.badge.clock"
        case .monthly: return "calendar.circle.fill"
        case .quarterly: return "calendar.badge.plus"
        case .yearly: return "star.circle.fill"
        }
    }

    /// Bir sonraki ödeme tarihini hesaplar
    func nextDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}

/// Tekrarlayan işlem modeli
struct RecurringTransaction: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var amount: Double
    var type: TransactionType
    var category: TransactionCategory
    var customCategoryId: UUID?
    var frequency: RecurrenceFrequency
    var startDate: Date
    var endDate: Date?
    var note: String
    var isActive: Bool
    var lastGenerated: Date?
    var notifyBeforeDays: Int // Kaç gün önce bildirim gönderilsin

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        type: TransactionType,
        category: TransactionCategory,
        customCategoryId: UUID? = nil,
        frequency: RecurrenceFrequency,
        startDate: Date = Date(),
        endDate: Date? = nil,
        note: String = "",
        isActive: Bool = true,
        lastGenerated: Date? = nil,
        notifyBeforeDays: Int = 1
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.category = category
        self.customCategoryId = customCategoryId
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.note = note
        self.isActive = isActive
        self.lastGenerated = lastGenerated
        self.notifyBeforeDays = notifyBeforeDays
    }

    /// Bir sonraki ödeme tarihi
    var nextPaymentDate: Date {
        if let lastGen = lastGenerated {
            return frequency.nextDate(from: lastGen)
        }
        return startDate
    }

    /// Tekrarlama aktif mi (bitiş tarihi kontrolü)
    var shouldGenerate: Bool {
        guard isActive else { return false }

        // Bitiş tarihi varsa kontrol et
        if let end = endDate {
            return nextPaymentDate <= end
        }

        return true
    }

    /// Kategori bilgisi (özel veya varsayılan)
    func getCategoryItem(customCategories: [CustomCategory]) -> CategoryItem {
        if let customId = customCategoryId,
           let customCategory = customCategories.first(where: { $0.id == customId }) {
            return .custom(customCategory)
        }
        return .standard(category)
    }
}
