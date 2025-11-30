//
//  InstallmentPayment.swift
//  FinansPro
//
//  Taksitli ödemeler için model
//

import Foundation

/// Tek bir taksit bilgisi
struct Installment: Identifiable, Codable, Equatable {
    var id: UUID
    var installmentNumber: Int // Kaçıncı taksit (1, 2, 3...)
    var amount: Double
    var dueDate: Date // Ödeme tarihi
    var isPaid: Bool
    var paidDate: Date? // Ne zaman ödendi

    init(
        id: UUID = UUID(),
        installmentNumber: Int,
        amount: Double,
        dueDate: Date,
        isPaid: Bool = false,
        paidDate: Date? = nil
    ) {
        self.id = id
        self.installmentNumber = installmentNumber
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.paidDate = paidDate
    }

    /// Taksit gecikmiş mi?
    var isOverdue: Bool {
        !isPaid && dueDate < Date()
    }

    /// Taksit yaklaşıyor mu? (7 gün içinde)
    var isUpcoming: Bool {
        if isPaid { return false }
        let calendar = Calendar.current
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return dueDate >= Date() && dueDate <= weekFromNow
    }
}

/// Taksitli ödeme modeli
struct InstallmentPayment: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String // Ürün/Hizmet adı
    var totalAmount: Double // Toplam tutar
    var installmentCount: Int // Kaç taksit
    var category: TransactionCategory
    var customCategoryId: UUID?
    var startDate: Date // İlk taksit tarihi
    var frequency: RecurrenceFrequency // Taksit aralığı (aylık, haftalık vb.)
    var note: String
    var installments: [Installment] // Tüm taksitler
    var createdDate: Date

    init(
        id: UUID = UUID(),
        title: String,
        totalAmount: Double,
        installmentCount: Int,
        category: TransactionCategory,
        customCategoryId: UUID? = nil,
        startDate: Date = Date(),
        frequency: RecurrenceFrequency = .monthly,
        note: String = "",
        createdDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.totalAmount = totalAmount
        self.installmentCount = installmentCount
        self.category = category
        self.customCategoryId = customCategoryId
        self.startDate = startDate
        self.frequency = frequency
        self.note = note
        self.createdDate = createdDate

        // Taksitleri otomatik oluştur
        self.installments = []
        self.installments = Self.generateInstallments(
            count: installmentCount,
            totalAmount: totalAmount,
            startDate: startDate,
            frequency: frequency
        )
    }

    /// Taksitleri otomatik oluşturur
    private static func generateInstallments(
        count: Int,
        totalAmount: Double,
        startDate: Date,
        frequency: RecurrenceFrequency
    ) -> [Installment] {
        guard count > 0 else { return [] }

        let installmentAmount = totalAmount / Double(count)
        var installments: [Installment] = []
        var currentDate = startDate

        for i in 1...count {
            let installment = Installment(
                installmentNumber: i,
                amount: installmentAmount,
                dueDate: currentDate
            )
            installments.append(installment)

            // Bir sonraki taksit tarihi
            currentDate = frequency.nextDate(from: currentDate)
        }

        return installments
    }

    /// Her bir taksit tutarı
    var installmentAmount: Double {
        totalAmount / Double(installmentCount)
    }

    /// Ödenen taksit sayısı
    var paidCount: Int {
        installments.filter { $0.isPaid }.count
    }

    /// Ödenen toplam tutar
    var paidAmount: Double {
        installments.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    /// Kalan taksit sayısı
    var remainingCount: Int {
        installmentCount - paidCount
    }

    /// Kalan toplam tutar
    var remainingAmount: Double {
        totalAmount - paidAmount
    }

    /// Tüm taksitler ödendi mi?
    var isCompleted: Bool {
        paidCount == installmentCount
    }

    /// İlerleme yüzdesi
    var progressPercentage: Double {
        guard installmentCount > 0 else { return 0 }
        return Double(paidCount) / Double(installmentCount) * 100
    }

    /// Gecikmiş taksitler
    var overdueInstallments: [Installment] {
        installments.filter { $0.isOverdue }
    }

    /// Yaklaşan taksitler (7 gün içinde)
    var upcomingInstallments: [Installment] {
        installments.filter { $0.isUpcoming }
    }

    /// Bir sonraki ödenecek taksit
    var nextInstallment: Installment? {
        installments.first { !$0.isPaid }
    }

    /// Kategori bilgisi (özel veya varsayılan)
    func getCategoryItem(customCategories: [CustomCategory]) -> CategoryItem {
        if let customId = customCategoryId,
           let customCategory = customCategories.first(where: { $0.id == customId }) {
            return .custom(customCategory)
        }
        return .standard(category)
    }

    /// Bir taksiti ödendi olarak işaretle
    mutating func markInstallmentAsPaid(_ installmentId: UUID) {
        if let index = installments.firstIndex(where: { $0.id == installmentId }) {
            installments[index].isPaid = true
            installments[index].paidDate = Date()
        }
    }

    /// Bir taksitin ödemesini geri al
    mutating func markInstallmentAsUnpaid(_ installmentId: UUID) {
        if let index = installments.firstIndex(where: { $0.id == installmentId }) {
            installments[index].isPaid = false
            installments[index].paidDate = nil
        }
    }
}
