//
//  PDFReportGenerator.swift
//  FinansPro
//
//  Created by Claude on 30.11.2025.
//

import Foundation
import PDFKit
import UIKit

/// PDF rapor oluşturucu
class PDFReportGenerator {
    static let shared = PDFReportGenerator()

    private init() {}

    // MARK: - Public Methods

    /// Aylık finansal rapor oluşturur
    func generateMonthlyReport(
        month: Date,
        transactions: [Transaction],
        installments: [InstallmentPayment],
        recurringPayments: [RecurringTransaction]
    ) -> Result<URL, ExportError> {
        let pdfMetaData = [
            kCGPDFContextCreator: "FinansPro",
            kCGPDFContextAuthor: "FinansPro App",
            kCGPDFContextTitle: "Aylık Finansal Rapor"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 50

            // Header
            yPosition = drawHeader(in: context, at: yPosition, month: month)
            yPosition += 30

            // Summary
            yPosition = drawSummary(in: context, at: yPosition, transactions: transactions)
            yPosition += 30

            // Category Breakdown
            yPosition = drawCategoryBreakdown(in: context, at: yPosition, transactions: transactions, pageRect: pageRect, context: context)

            // Transactions Table (may span multiple pages)
            drawTransactionsTable(in: context, startY: yPosition, transactions: transactions, pageRect: pageRect)
        }

        return saveToTemporaryFile(data: data, filename: "FinansPro_AylikRapor_\(getMonthString(month)).pdf")
    }

    /// Yıllık finansal rapor oluşturur
    func generateYearlyReport(
        year: Int,
        transactions: [Transaction]
    ) -> Result<URL, ExportError> {
        let pdfMetaData = [
            kCGPDFContextCreator: "FinansPro",
            kCGPDFContextAuthor: "FinansPro App",
            kCGPDFContextTitle: "Yıllık Finansal Rapor"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 50

            // Header
            drawText("FİNANSPRO YILLIK RAPOR", at: CGPoint(x: 50, y: yPosition), fontSize: 24, bold: true)
            yPosition += 30
            drawText("\(year) Yılı", at: CGPoint(x: 50, y: yPosition), fontSize: 18, bold: false)
            yPosition += 40

            // Yearly summary
            let totalIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let totalExpense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let balance = totalIncome - totalExpense

            yPosition = drawKeyValue("Toplam Gelir:", value: formatCurrency(totalIncome), at: yPosition)
            yPosition = drawKeyValue("Toplam Gider:", value: formatCurrency(totalExpense), at: yPosition)
            yPosition = drawKeyValue("Net Bakiye:", value: formatCurrency(balance), at: yPosition, valueColor: balance >= 0 ? .systemGreen : .systemRed)
            yPosition += 30

            // Monthly breakdown
            drawText("Aylık Dağılım", at: CGPoint(x: 50, y: yPosition), fontSize: 18, bold: true)
            yPosition += 25

            let calendar = Calendar.current
            for month in 1...12 {
                guard let monthDate = calendar.date(from: DateComponents(year: year, month: month)) else { continue }

                let monthTransactions = transactions.filter { transaction in
                    let components = calendar.dateComponents([.year, .month], from: transaction.date)
                    return components.year == year && components.month == month
                }

                let monthIncome = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let monthExpense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let monthName = getMonthName(month)
                drawText("\(monthName):", at: CGPoint(x: 70, y: yPosition), fontSize: 12, bold: false)
                drawText("Gelir: \(formatCurrency(monthIncome))", at: CGPoint(x: 200, y: yPosition), fontSize: 12, bold: false, color: .systemGreen)
                drawText("Gider: \(formatCurrency(monthExpense))", at: CGPoint(x: 350, y: yPosition), fontSize: 12, bold: false, color: .systemRed)
                yPosition += 20

                if yPosition > 750 {
                    context.beginPage()
                    yPosition = 50
                }
            }
        }

        return saveToTemporaryFile(data: data, filename: "FinansPro_YillikRapor_\(year).pdf")
    }

    /// Özel dönem raporu oluşturur
    func generateCustomReport(
        startDate: Date,
        endDate: Date,
        transactions: [Transaction]
    ) -> Result<URL, ExportError> {
        let pdfMetaData = [
            kCGPDFContextCreator: "FinansPro",
            kCGPDFContextAuthor: "FinansPro App",
            kCGPDFContextTitle: "Özel Dönem Raporu"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 50

            // Header
            drawText("FİNANSPRO ÖZEL DÖNEM RAPORU", at: CGPoint(x: 50, y: yPosition), fontSize: 22, bold: true)
            yPosition += 30
            drawText("\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))", at: CGPoint(x: 50, y: yPosition), fontSize: 16, bold: false)
            yPosition += 40

            // Summary
            yPosition = drawSummary(in: context, at: yPosition, transactions: transactions)
            yPosition += 30

            // Category Breakdown
            yPosition = drawCategoryBreakdown(in: context, at: yPosition, transactions: transactions, pageRect: pageRect, context: context)

            // Transactions
            drawTransactionsTable(in: context, startY: yPosition, transactions: transactions, pageRect: pageRect)
        }

        return saveToTemporaryFile(data: data, filename: "FinansPro_DonemRaporu_\(dateFormatter.string(from: startDate))_\(dateFormatter.string(from: endDate)).pdf")
    }

    // MARK: - Drawing Methods

    private func drawHeader(in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat, month: Date) -> CGFloat {
        var y = yPosition

        drawText("FİNANSPRO AYLIK RAPOR", at: CGPoint(x: 50, y: y), fontSize: 24, bold: true)
        y += 30

        let monthString = getMonthYearString(month)
        drawText(monthString, at: CGPoint(x: 50, y: y), fontSize: 18, bold: false)
        y += 25

        return y
    }

    private func drawSummary(in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat, transactions: [Transaction]) -> CGFloat {
        var y = yPosition

        drawText("Özet", at: CGPoint(x: 50, y: y), fontSize: 18, bold: true)
        y += 25

        let totalIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let totalExpense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let balance = totalIncome - totalExpense

        y = drawKeyValue("Toplam Gelir:", value: formatCurrency(totalIncome), at: y, valueColor: .systemGreen)
        y = drawKeyValue("Toplam Gider:", value: formatCurrency(totalExpense), at: y, valueColor: .systemRed)
        y = drawKeyValue("Net Bakiye:", value: formatCurrency(balance), at: y, valueColor: balance >= 0 ? .systemGreen : .systemRed)
        y = drawKeyValue("Toplam İşlem:", value: "\(transactions.count)", at: y)

        return y
    }

    private func drawCategoryBreakdown(in context: UIGraphicsPDFRendererContext, at yPosition: CGFloat, transactions: [Transaction], pageRect: CGRect, context pdfContext: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        if y > 700 {
            pdfContext.beginPage()
            y = 50
        }

        drawText("Kategori Dağılımı", at: CGPoint(x: 50, y: y), fontSize: 18, bold: true)
        y += 25

        // Group by category
        var categoryTotals: [String: Double] = [:]
        for transaction in transactions where transaction.type == .expense {
            let categoryName = getCategoryName(transaction: transaction)
            categoryTotals[categoryName, default: 0] += transaction.amount
        }

        let sortedCategories = categoryTotals.sorted { $0.value > $1.value }

        for (category, amount) in sortedCategories {
            if y > 750 {
                pdfContext.beginPage()
                y = 50
            }

            let percentage = (amount / transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }) * 100
            drawText("• \(category):", at: CGPoint(x: 70, y: y), fontSize: 12, bold: false)
            drawText("\(formatCurrency(amount)) (%\(String(format: "%.1f", percentage)))", at: CGPoint(x: 300, y: y), fontSize: 12, bold: false)
            y += 20
        }

        return y + 10
    }

    private func drawTransactionsTable(in context: UIGraphicsPDFRendererContext, startY: CGFloat, transactions: [Transaction], pageRect: CGRect) {
        var y = startY

        if y > 700 {
            context.beginPage()
            y = 50
        }

        drawText("İşlem Detayları", at: CGPoint(x: 50, y: y), fontSize: 18, bold: true)
        y += 25

        // Table headers
        drawText("Tarih", at: CGPoint(x: 50, y: y), fontSize: 10, bold: true)
        drawText("Açıklama", at: CGPoint(x: 130, y: y), fontSize: 10, bold: true)
        drawText("Kategori", at: CGPoint(x: 300, y: y), fontSize: 10, bold: true)
        drawText("Tutar", at: CGPoint(x: 450, y: y), fontSize: 10, bold: true)
        y += 20

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"

        for transaction in transactions.sorted(by: { $0.date > $1.date }) {
            if y > 780 {
                context.beginPage()
                y = 50

                // Redraw headers on new page
                drawText("Tarih", at: CGPoint(x: 50, y: y), fontSize: 10, bold: true)
                drawText("Açıklama", at: CGPoint(x: 130, y: y), fontSize: 10, bold: true)
                drawText("Kategori", at: CGPoint(x: 300, y: y), fontSize: 10, bold: true)
                drawText("Tutar", at: CGPoint(x: 450, y: y), fontSize: 10, bold: true)
                y += 20
            }

            let dateString = dateFormatter.string(from: transaction.date)
            let description = String(transaction.description.prefix(25))
            let category = String(getCategoryName(transaction: transaction).prefix(15))
            let amount = formatCurrency(transaction.amount)

            drawText(dateString, at: CGPoint(x: 50, y: y), fontSize: 9, bold: false)
            drawText(description, at: CGPoint(x: 130, y: y), fontSize: 9, bold: false)
            drawText(category, at: CGPoint(x: 300, y: y), fontSize: 9, bold: false)
            drawText(amount, at: CGPoint(x: 450, y: y), fontSize: 9, bold: false, color: transaction.type == .income ? .systemGreen : .systemRed)

            y += 18
        }
    }

    private func drawKeyValue(_ key: String, value: String, at yPosition: CGFloat, valueColor: UIColor = .label) -> CGFloat {
        drawText(key, at: CGPoint(x: 70, y: yPosition), fontSize: 14, bold: true)
        drawText(value, at: CGPoint(x: 300, y: yPosition), fontSize: 14, bold: false, color: valueColor)
        return yPosition + 22
    }

    private func drawText(_ text: String, at point: CGPoint, fontSize: CGFloat, bold: Bool, color: UIColor = .label) {
        let font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        text.draw(at: point, withAttributes: attributes)
    }

    // MARK: - Helper Methods

    private func getCategoryName(transaction: Transaction) -> String {
        if let customId = transaction.customCategoryId,
           let customCategory = DataManager.shared.customCategories.first(where: { $0.id == customId }) {
            return customCategory.name
        }
        return transaction.category.displayName
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) ₺"
    }

    private func getMonthString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-yyyy"
        return formatter.string(from: date)
    }

    private func getMonthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    private func getMonthName(_ month: Int) -> String {
        let monthNames = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
                         "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
        return monthNames[month - 1]
    }

    private func saveToTemporaryFile(data: Data, filename: String) -> Result<URL, ExportError> {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return .success(fileURL)
        } catch {
            return .failure(.fileWriteError(error))
        }
    }
}
