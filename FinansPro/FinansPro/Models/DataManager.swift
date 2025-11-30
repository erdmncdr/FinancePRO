//
//  DataManager.swift
//  FinanceTracker
//
//  Veri yönetimi ve persistence
//

import Foundation
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published var transactions: [Transaction] = []
    @Published var customCategories: [CustomCategory] = []
    @Published var recurringTransactions: [RecurringTransaction] = []
    @Published var installmentPayments: [InstallmentPayment] = []

    private let saveKey = "SavedTransactions"
    private let customCategoriesKey = "CustomCategories"
    private let recurringKey = "RecurringTransactions"
    private let installmentsKey = "InstallmentPayments"

    init() {
        loadData()
        loadCustomCategories()
        loadRecurringTransactions()
        loadInstallmentPayments()
        // Demo data ekle (ilk açılışta)
        if transactions.isEmpty {
            addDemoData()
        }
        // Tekrarlayan işlemleri kontrol et ve oluştur
        generateRecurringTransactions()
    }

    // CRUD İşlemleri
    func addTransaction(_ transaction: Transaction) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            transactions.append(transaction)
        }
        saveData()
        scheduleNotificationsForUpcomingPayments()
    }

    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                transactions[index] = transaction
            }
            saveData()
            scheduleNotificationsForUpcomingPayments()
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            transactions.removeAll { $0.id == transaction.id }
        }
        saveData()
        scheduleNotificationsForUpcomingPayments()
    }

    // Gelecek ödemeler için bildirimleri planla
    private func scheduleNotificationsForUpcomingPayments() {
        let upcomingPayments = getUpcomingPayments()

        // Ayrıca ödenmemiş borçları da ekle
        let unpaidDebts = transactions.filter { ($0.type == .debt || $0.type == .lent) && !$0.isPaid }

        let allPayments = upcomingPayments + unpaidDebts

        NotificationManager.shared.scheduleNotifications(for: allPayments)
    }

    func deleteTransaction(at offsets: IndexSet, from list: [Transaction]) {
        let transactionsToDelete = offsets.map { list[$0] }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            transactions.removeAll { transaction in
                transactionsToDelete.contains(where: { $0.id == transaction.id })
            }
        }
        saveData()
    }

    // Filtreleme
    func getTransactions(ofType type: TransactionType) -> [Transaction] {
        transactions.filter { $0.type == type }
            .sorted { $0.date > $1.date }
    }

    func getUpcomingPayments() -> [Transaction] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return transactions.filter { transaction in
            guard let dueDate = transaction.dueDate else { return false }
            let transactionDay = calendar.startOfDay(for: dueDate)
            return transactionDay >= today && !transaction.isPaid
        }.sorted {
            ($0.dueDate ?? Date()) < ($1.dueDate ?? Date())
        }
    }

    // İstatistikler
    func getFinancialSummary() -> FinancialSummary {
        let income = transactions
            .filter { $0.type == .income && $0.isPaid }
            .reduce(0) { $0 + $1.amount }

        let expenses = transactions
            .filter { $0.type == .expense && $0.isPaid }
            .reduce(0) { $0 + $1.amount }

        // Sadece nakit akışı takibi YAPILMAYAN borçları bakiyeye dahil et
        // (Yapılanlar zaten income/expense'de sayılıyor)
        let debts = transactions
            .filter { $0.type == .debt && !$0.isPaid && $0.trackedInCashFlow != true }
            .reduce(0) { $0 + $1.amount }

        let lent = transactions
            .filter { $0.type == .lent && !$0.isPaid && $0.trackedInCashFlow != true }
            .reduce(0) { $0 + $1.amount }

        let upcoming = getUpcomingPayments()
            .reduce(0) { $0 + $1.amount }

        return FinancialSummary(
            totalIncome: income,
            totalExpenses: expenses,
            totalDebts: debts,
            totalLent: lent,
            upcomingPayments: upcoming
        )
    }

    func getTodayTransactions() -> [Transaction] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return transactions.filter { transaction in
            calendar.isDate(transaction.date, inSameDayAs: today)
        }.sorted { $0.date > $1.date }
    }

    // MARK: - Arama ve Filtreleme

    /// Metinde arama yapar
    func searchTransactions(query: String) -> [Transaction] {
        guard !query.isEmpty else { return transactions }

        let lowercasedQuery = query.lowercased()

        return transactions.filter { transaction in
            transaction.title.lowercased().contains(lowercasedQuery) ||
            transaction.note.lowercased().contains(lowercasedQuery) ||
            transaction.category.rawValue.lowercased().contains(lowercasedQuery) ||
            transaction.amount.toCurrency().contains(query)
        }.sorted { $0.date > $1.date }
    }

    /// Gelişmiş filtreleme
    func filterTransactions(
        searchQuery: String = "",
        filters: FilterOptions
    ) -> [Transaction] {
        var result = transactions

        // Arama
        if !searchQuery.isEmpty {
            let lowercasedQuery = searchQuery.lowercased()
            result = result.filter { transaction in
                transaction.title.lowercased().contains(lowercasedQuery) ||
                transaction.note.lowercased().contains(lowercasedQuery) ||
                transaction.category.rawValue.lowercased().contains(lowercasedQuery)
            }
        }

        // Tarih aralığı
        if let dateRange = filters.dateRange {
            let interval = dateRange.dateInterval
            result = result.filter { transaction in
                interval.contains(transaction.date)
            }
        }

        // Kategoriler
        if !filters.categories.isEmpty {
            result = result.filter { transaction in
                filters.categories.contains(transaction.category)
            }
        }

        // Türler
        if !filters.types.isEmpty {
            result = result.filter { transaction in
                filters.types.contains(transaction.type)
            }
        }

        // Miktar aralığı
        if let minAmount = filters.minAmount {
            result = result.filter { $0.amount >= minAmount }
        }

        if let maxAmount = filters.maxAmount {
            result = result.filter { $0.amount <= maxAmount }
        }

        // Ödeme durumu
        if let isPaid = filters.isPaid {
            result = result.filter { $0.isPaid == isPaid }
        }

        return result.sorted { $0.date > $1.date }
    }

    /// Akıllı öneriler (en çok kullanılan kategoriler vs.)
    func getMostUsedCategories(limit: Int = 5) -> [TransactionCategory] {
        let categoryCount = Dictionary(grouping: transactions, by: { $0.category })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        return Array(categoryCount.prefix(limit).map { $0.key })
    }

    /// En yüksek harcama kategorisi
    func getHighestExpenseCategory() -> (category: TransactionCategory, amount: Double)? {
        let expenses = transactions.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return nil }

        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        let totals = grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }
        guard let highest = totals.max(by: { $0.value < $1.value }) else { return nil }

        return (highest.key, highest.value)
    }


    // MARK: - Özel Kategori Yönetimi

    /// Yeni özel kategori ekler
    func addCustomCategory(_ category: CustomCategory) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            customCategories.append(category)
        }
        saveCustomCategories()
    }

    /// Özel kategoriyi günceller
    func updateCustomCategory(_ category: CustomCategory) {
        if let index = customCategories.firstIndex(where: { $0.id == category.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                customCategories[index] = category
            }
            saveCustomCategories()
        }
    }

    /// Özel kategoriyi siler
    func deleteCustomCategory(_ category: CustomCategory) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            customCategories.removeAll { $0.id == category.id }
        }

        // Bu kategoriyi kullanan işlemleri "Diğer" kategorisine çevir
        for (index, transaction) in transactions.enumerated() {
            if transaction.customCategoryId == category.id {
                transactions[index].customCategoryId = nil
                transactions[index].category = .other
            }
        }

        saveCustomCategories()
        saveData()
    }

    /// Tüm kategorileri döndürür (varsayılan + özel)
    func getAllCategories() -> [CategoryItem] {
        let standardCategories = TransactionCategory.allCases.map { CategoryItem.standard($0) }
        let customCategoryItems = customCategories.map { CategoryItem.custom($0) }
        return standardCategories + customCategoryItems
    }

    // MARK: - Persistence

    private func saveData() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
            transactions = decoded
        }
    }

    private func saveCustomCategories() {
        if let encoded = try? JSONEncoder().encode(customCategories) {
            UserDefaults.standard.set(encoded, forKey: customCategoriesKey)
        }
    }

    private func loadCustomCategories() {
        if let data = UserDefaults.standard.data(forKey: customCategoriesKey),
           let decoded = try? JSONDecoder().decode([CustomCategory].self, from: data) {
            customCategories = decoded
        }
    }

    // MARK: - Tekrarlayan İşlemler

    /// Yeni tekrarlayan işlem ekler
    func addRecurringTransaction(_ recurring: RecurringTransaction) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            recurringTransactions.append(recurring)
        }
        saveRecurringTransactions()
    }

    /// Tekrarlayan işlemi günceller
    func updateRecurringTransaction(_ recurring: RecurringTransaction) {
        if let index = recurringTransactions.firstIndex(where: { $0.id == recurring.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                recurringTransactions[index] = recurring
            }
            saveRecurringTransactions()
        }
    }

    /// Tekrarlayan işlemi siler
    func deleteRecurringTransaction(_ recurring: RecurringTransaction) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            recurringTransactions.removeAll { $0.id == recurring.id }
        }
        saveRecurringTransactions()
    }

    /// Tekrarlayan işlemi aktif/pasif yapar
    func toggleRecurringTransaction(_ recurring: RecurringTransaction) {
        if let index = recurringTransactions.firstIndex(where: { $0.id == recurring.id }) {
            recurringTransactions[index].isActive.toggle()
            saveRecurringTransactions()
        }
    }

    /// TÜM VERİLERİ SİLER - GERİ ALINAMAZ!
    func clearAllData() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            transactions.removeAll()
            customCategories.removeAll()
            recurringTransactions.removeAll()
        }
        saveData()
        saveCustomCategories()
        saveRecurringTransactions()

        // Bildirimleri de temizle
        NotificationManager.shared.clearAllNotifications()
    }

    /// Otomatik işlem oluşturma
    func generateRecurringTransactions() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for (index, recurring) in recurringTransactions.enumerated() {
            guard recurring.shouldGenerate else { continue }

            let nextDate = recurring.nextPaymentDate

            // Eğer bir sonraki ödeme tarihi bugün veya geçmişte ise işlem oluştur
            if nextDate <= today {
                // İşlemi oluştur
                let transaction = Transaction(
                    title: recurring.title,
                    amount: recurring.amount,
                    type: recurring.type,
                    category: recurring.category,
                    date: nextDate,
                    note: recurring.note + " (Otomatik)",
                    isPaid: false,
                    dueDate: nextDate,
                    customCategoryId: recurring.customCategoryId
                )

                addTransaction(transaction)

                // Son oluşturma tarihini güncelle
                recurringTransactions[index].lastGenerated = nextDate
                saveRecurringTransactions()
            }
        }
    }

    private func saveRecurringTransactions() {
        if let encoded = try? JSONEncoder().encode(recurringTransactions) {
            UserDefaults.standard.set(encoded, forKey: recurringKey)
        }
    }

    private func loadRecurringTransactions() {
        if let data = UserDefaults.standard.data(forKey: recurringKey),
           let decoded = try? JSONDecoder().decode([RecurringTransaction].self, from: data) {
            recurringTransactions = decoded
        }
    }

    // MARK: - Demo data
    private func addDemoData() {
        let calendar = Calendar.current

        // Gelirler
        transactions.append(Transaction(
            title: "Maaş",
            amount: 25000,
            type: .income,
            category: .salary,
            date: calendar.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        ))

        // Giderler
        transactions.append(Transaction(
            title: "Market Alışverişi",
            amount: 850,
            type: .expense,
            category: .food,
            date: calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        ))

        transactions.append(Transaction(
            title: "Benzin",
            amount: 500,
            type: .expense,
            category: .transport,
            date: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ))

        transactions.append(Transaction(
            title: "Netflix",
            amount: 150,
            type: .expense,
            category: .entertainment,
            date: Date()
        ))

        // Borçlar (Nakit akışı takibi KAPALI - bakiyeyi etkiler)
        transactions.append(Transaction(
            title: "Kredi Kartı Borcu",
            amount: 3500,
            type: .debt,
            category: .bills,
            date: calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            isPaid: false,
            dueDate: calendar.date(byAdding: .day, value: 15, to: Date()),
            trackedInCashFlow: false
        ))

        // Borç (Nakit akışı takibi AÇIK - gelir olarak da kaydedildi)
        transactions.append(Transaction(
            title: "Arkadaştan Borç Aldım",
            amount: 2000,
            type: .debt,
            category: .other,
            date: calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            note: "Gelir olarak da kaydedildi, bakiyeyi etkilemez",
            isPaid: false,
            dueDate: calendar.date(byAdding: .day, value: 10, to: Date()),
            trackedInCashFlow: true
        ))

        // Bu borç için gelir kaydı (nakit akışı takibi)
        transactions.append(Transaction(
            title: "Arkadaştan Borç Aldım",
            amount: 2000,
            type: .income,
            category: .other,
            date: calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            note: "Borç girişi: Arkadaştan Borç Aldım",
            isPaid: true
        ))

        // Verilen borçlar (Nakit akışı takibi KAPALI - bakiyeyi etkiler)
        transactions.append(Transaction(
            title: "Mehmet'e Borç Verdim",
            amount: 1000,
            type: .lent,
            category: .other,
            date: calendar.date(byAdding: .day, value: -12, to: Date()) ?? Date(),
            note: "Gider olarak kaydedilmedi",
            isPaid: false,
            dueDate: calendar.date(byAdding: .day, value: 18, to: Date()),
            trackedInCashFlow: false
        ))

        // Verilen borç (Nakit akışı takibi AÇIK - gider olarak da kaydedildi)
        transactions.append(Transaction(
            title: "İş Arkadaşına Ödünç",
            amount: 750,
            type: .lent,
            category: .other,
            date: calendar.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            note: "Gider olarak da kaydedildi, bakiyeyi etkilemez",
            isPaid: false,
            dueDate: calendar.date(byAdding: .day, value: 2, to: Date()),
            trackedInCashFlow: true
        ))

        // Bu borç için gider kaydı (nakit akışı takibi)
        transactions.append(Transaction(
            title: "İş Arkadaşına Ödünç",
            amount: 750,
            type: .expense,
            category: .other,
            date: calendar.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            note: "Borç verme: İş Arkadaşına Ödünç",
            isPaid: true
        ))

        // Gelecek ödemeler
        transactions.append(Transaction(
            title: "Elektrik Faturası",
            amount: 450,
            type: .upcoming,
            category: .bills,
            date: Date(),
            isPaid: false,
            dueDate: calendar.date(byAdding: .day, value: 5, to: Date())
        ))

        transactions.append(Transaction(
            title: "İnternet Faturası",
            amount: 250,
            type: .upcoming,
            category: .bills,
            date: Date(),
            isPaid: false,
            dueDate: calendar.date(byAdding: .day, value: 8, to: Date())
        ))

        saveData()
    }

    // MARK: - Taksitli Ödemeler

    /// Taksitli ödeme ekle
    func addInstallmentPayment(_ payment: InstallmentPayment) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            installmentPayments.append(payment)
        }
        saveInstallmentPayments()
        scheduleInstallmentNotifications()
    }

    /// Taksitli ödeme güncelle
    func updateInstallmentPayment(_ payment: InstallmentPayment) {
        if let index = installmentPayments.firstIndex(where: { $0.id == payment.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                installmentPayments[index] = payment
            }
            saveInstallmentPayments()
            scheduleInstallmentNotifications()
        }
    }

    /// Taksitli ödeme sil
    func deleteInstallmentPayment(_ payment: InstallmentPayment) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            installmentPayments.removeAll { $0.id == payment.id }
        }
        saveInstallmentPayments()
        scheduleInstallmentNotifications()
    }

    /// Taksiti ödendi olarak işaretle
    func markInstallmentAsPaid(paymentId: UUID, installmentId: UUID) {
        if let paymentIndex = installmentPayments.firstIndex(where: { $0.id == paymentId }) {
            var payment = installmentPayments[paymentIndex]
            payment.markInstallmentAsPaid(installmentId)
            installmentPayments[paymentIndex] = payment
            saveInstallmentPayments()
            scheduleInstallmentNotifications()
        }
    }

    /// Taksit ödemesini geri al
    func markInstallmentAsUnpaid(paymentId: UUID, installmentId: UUID) {
        if let paymentIndex = installmentPayments.firstIndex(where: { $0.id == paymentId }) {
            var payment = installmentPayments[paymentIndex]
            payment.markInstallmentAsUnpaid(installmentId)
            installmentPayments[paymentIndex] = payment
            saveInstallmentPayments()
            scheduleInstallmentNotifications()
        }
    }

    /// Aktif (tamamlanmamış) taksitli ödemeleri getir
    func getActiveInstallmentPayments() -> [InstallmentPayment] {
        installmentPayments.filter { !$0.isCompleted }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Tamamlanmış taksitli ödemeleri getir
    func getCompletedInstallmentPayments() -> [InstallmentPayment] {
        installmentPayments.filter { $0.isCompleted }
            .sorted { $0.startDate > $1.startDate }
    }

    /// Yaklaşan taksitleri getir (7 gün içinde)
    func getUpcomingInstallments() -> [(payment: InstallmentPayment, installment: Installment)] {
        var result: [(payment: InstallmentPayment, installment: Installment)] = []

        for payment in installmentPayments.filter({ !$0.isCompleted }) {
            for installment in payment.upcomingInstallments {
                result.append((payment, installment))
            }
        }

        return result.sorted { $0.installment.dueDate < $1.installment.dueDate }
    }

    /// Gecikmiş taksitleri getir
    func getOverdueInstallments() -> [(payment: InstallmentPayment, installment: Installment)] {
        var result: [(payment: InstallmentPayment, installment: Installment)] = []

        for payment in installmentPayments.filter({ !$0.isCompleted }) {
            for installment in payment.overdueInstallments {
                result.append((payment, installment))
            }
        }

        return result.sorted { $0.installment.dueDate < $1.installment.dueDate }
    }

    /// Taksitler için bildirim planla
    private func scheduleInstallmentNotifications() {
        let upcomingInstallments = getUpcomingInstallments()

        // Her taksit için bildirim oluştur
        for (payment, installment) in upcomingInstallments {
            // Bildirimi planla (3 gün önce, 1 gün önce, taksit günü)
            NotificationManager.shared.scheduleInstallmentNotification(
                paymentTitle: payment.title,
                installmentNumber: installment.installmentNumber,
                amount: installment.amount,
                dueDate: installment.dueDate
            )
        }
    }

    // MARK: - Taksitli Ödemeler Persistence

    /// Taksitli ödemeleri yükle
    private func loadInstallmentPayments() {
        if let data = UserDefaults.standard.data(forKey: installmentsKey) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([InstallmentPayment].self, from: data) {
                installmentPayments = decoded
            }
        }
    }

    /// Taksitli ödemeleri kaydet
    private func saveInstallmentPayments() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(installmentPayments) {
            UserDefaults.standard.set(encoded, forKey: installmentsKey)
        }
    }
}
