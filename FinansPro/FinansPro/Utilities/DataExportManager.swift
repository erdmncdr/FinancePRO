//
//  DataExportManager.swift
//  FinansPro
//
//  Created by Claude on 30.11.2025.
//

import Foundation
import UniformTypeIdentifiers

/// Veri dışa aktarma yöneticisi - CSV/Excel export işlemleri
class DataExportManager {
    static let shared = DataExportManager()

    private init() {}

    // MARK: - CSV Export

    /// Tüm işlemleri CSV formatında dışa aktarır
    func exportTransactionsToCSV(transactions: [Transaction]) -> Result<URL, ExportError> {
        var csvText = "Tarih,Tür,Kategori,Tutar,Para Birimi,Açıklama,Etiketler,Satıcı\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"

        for transaction in transactions.sorted(by: { $0.date > $1.date }) {
            let dateString = dateFormatter.string(from: transaction.date)
            let type = transaction.type == .income ? "Gelir" : "Gider"
            let category = getCategoryName(transaction: transaction)
            let amount = String(format: "%.2f", transaction.amount)
            let currency = transaction.currency.rawValue
            let description = escapeCSV(transaction.description)
            let tags = transaction.tags.joined(separator: "; ")
            let merchant = escapeCSV(transaction.merchantName ?? "")

            let row = "\(dateString),\(type),\(category),\(amount),\(currency),\(description),\(tags),\(merchant)\n"
            csvText.append(row)
        }

        return saveToTemporaryFile(content: csvText, filename: "FinansPro_Islemler_\(getCurrentDateString()).csv")
    }

    /// Taksitli ödemeleri CSV formatında dışa aktarır
    func exportInstallmentsToCSV(installments: [InstallmentPayment]) -> Result<URL, ExportError> {
        var csvText = "Başlık,Toplam Tutar,Taksit Sayısı,Ödenen Taksit,Başlangıç,Kategori,Durum\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"

        for installment in installments.sorted(by: { $0.startDate > $1.startDate }) {
            let title = escapeCSV(installment.title)
            let totalAmount = String(format: "%.2f", installment.totalAmount)
            let totalInstallments = "\(installment.totalInstallments)"
            let paidInstallments = "\(installment.installments.filter { $0.isPaid }.count)"
            let startDate = dateFormatter.string(from: installment.startDate)
            let category = installment.category.displayName
            let status = installment.isCompleted ? "Tamamlandı" : "Devam Ediyor"

            let row = "\(title),\(totalAmount),\(totalInstallments),\(paidInstallments),\(startDate),\(category),\(status)\n"
            csvText.append(row)
        }

        return saveToTemporaryFile(content: csvText, filename: "FinansPro_Taksitler_\(getCurrentDateString()).csv")
    }

    /// Tekrarlayan ödemeleri CSV formatında dışa aktarır
    func exportRecurringPaymentsToCSV(recurringPayments: [RecurringTransaction]) -> Result<URL, ExportError> {
        var csvText = "Başlık,Tutar,Periyot,Başlangıç,Bitiş,Kategori,Durum\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"

        for payment in recurringPayments.sorted(by: { $0.startDate > $1.startDate }) {
            let title = escapeCSV(payment.title)
            let amount = String(format: "%.2f", payment.amount)
            let frequency = getFrequencyName(payment.frequency)
            let startDate = dateFormatter.string(from: payment.startDate)
            let endDate = payment.endDate.map { dateFormatter.string(from: $0) } ?? "Belirsiz"
            let category = payment.category.displayName
            let status = payment.isActive ? "Aktif" : "Pasif"

            let row = "\(title),\(amount),\(frequency),\(startDate),\(endDate),\(category),\(status)\n"
            csvText.append(row)
        }

        return saveToTemporaryFile(content: csvText, filename: "FinansPro_TekrarlayanOdemeler_\(getCurrentDateString()).csv")
    }

    /// Tüm verileri tek bir CSV dosyasında dışa aktarır
    func exportAllDataToCSV(transactions: [Transaction], installments: [InstallmentPayment], recurringPayments: [RecurringTransaction]) -> Result<URL, ExportError> {
        var csvText = "=== FİNANSPRO TAM RAPOR ===\n"
        csvText += "Oluşturulma Tarihi: \(getCurrentDateTimeString())\n\n"

        // Özet bilgiler
        let totalIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let totalExpense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let balance = totalIncome - totalExpense

        csvText += "=== ÖZET ===\n"
        csvText += "Toplam Gelir,\(String(format: "%.2f", totalIncome)) TL\n"
        csvText += "Toplam Gider,\(String(format: "%.2f", totalExpense)) TL\n"
        csvText += "Bakiye,\(String(format: "%.2f", balance)) TL\n"
        csvText += "Toplam İşlem,\(transactions.count)\n"
        csvText += "Aktif Taksit,\(installments.filter { !$0.isCompleted }.count)\n"
        csvText += "Aktif Tekrarlayan,\(recurringPayments.filter { $0.isActive }.count)\n\n"

        // İşlemler
        csvText += "=== İŞLEMLER ===\n"
        csvText += "Tarih,Tür,Kategori,Tutar,Para Birimi,Açıklama,Etiketler,Satıcı\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"

        for transaction in transactions.sorted(by: { $0.date > $1.date }) {
            let dateString = dateFormatter.string(from: transaction.date)
            let type = transaction.type == .income ? "Gelir" : "Gider"
            let category = getCategoryName(transaction: transaction)
            let amount = String(format: "%.2f", transaction.amount)
            let currency = transaction.currency.rawValue
            let description = escapeCSV(transaction.description)
            let tags = transaction.tags.joined(separator: "; ")
            let merchant = escapeCSV(transaction.merchantName ?? "")

            csvText += "\(dateString),\(type),\(category),\(amount),\(currency),\(description),\(tags),\(merchant)\n"
        }

        return saveToTemporaryFile(content: csvText, filename: "FinansPro_TamRapor_\(getCurrentDateString()).csv")
    }

    // MARK: - Helper Methods

    private func getCategoryName(transaction: Transaction) -> String {
        if let customId = transaction.customCategoryId,
           let customCategory = DataManager.shared.customCategories.first(where: { $0.id == customId }) {
            return escapeCSV(customCategory.name)
        }
        return transaction.category.displayName
    }

    private func getFrequencyName(_ frequency: RecurringFrequency) -> String {
        switch frequency {
        case .daily: return "Günlük"
        case .weekly: return "Haftalık"
        case .monthly: return "Aylık"
        case .yearly: return "Yıllık"
        }
    }

    private func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }

    private func saveToTemporaryFile(content: String, filename: String) -> Result<URL, ExportError> {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(fileURL)
        } catch {
            return .failure(.fileWriteError(error))
        }
    }

    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: Date())
    }

    private func getCurrentDateTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - Export Error

enum ExportError: LocalizedError {
    case noData
    case fileWriteError(Error)
    case pdfGenerationError

    var errorDescription: String? {
        switch self {
        case .noData:
            return "Dışa aktarılacak veri bulunamadı"
        case .fileWriteError(let error):
            return "Dosya yazma hatası: \(error.localizedDescription)"
        case .pdfGenerationError:
            return "PDF oluşturma hatası"
        }
    }
}
