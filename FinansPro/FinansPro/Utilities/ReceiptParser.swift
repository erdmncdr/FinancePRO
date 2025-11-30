//
//  ReceiptParser.swift
//  FinansPro
//
//  Fiş/fatura metinlerinden bilgi çıkarır
//  Tutar, tarih, işletme adı, kategori önerisi yapar
//

import Foundation

struct ParsedReceipt {
    var merchantName: String?
    var totalAmount: Double?
    var date: Date?
    var suggestedCategory: TransactionCategory
    var items: [ReceiptItem]
    var rawText: String

    struct ReceiptItem {
        var name: String
        var amount: Double
    }
}

class ReceiptParser {
    static let shared = ReceiptParser()

    private init() {}

    /// Fiş metnini parse eder ve bilgileri çıkarır
    func parse(text: String) -> ParsedReceipt {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let merchantName = extractMerchantName(from: lines)
        let totalAmount = extractTotalAmount(from: lines)
        let date = extractDate(from: lines)
        let items = extractItems(from: lines)
        let suggestedCategory = suggestCategory(merchantName: merchantName, text: text)

        return ParsedReceipt(
            merchantName: merchantName,
            totalAmount: totalAmount,
            date: date,
            suggestedCategory: suggestedCategory,
            items: items,
            rawText: text
        )
    }

    // MARK: - Private Methods

    /// İşletme/mağaza adını bul (genelde ilk birkaç satırda)
    private func extractMerchantName(from lines: [String]) -> String? {
        // İlk 5 satırı kontrol et
        for line in lines.prefix(5) {
            // Çok kısa veya çok uzun satırları atla
            if line.count < 3 || line.count > 50 {
                continue
            }

            // Sayılarla başlayan satırları atla
            if line.first?.isNumber == true {
                continue
            }

            // Tarih veya tutar içeren satırları atla
            if containsDatePattern(line) || containsAmountPattern(line) {
                continue
            }

            // İlk uygun satırı işletme adı olarak kabul et
            return line
        }

        return nil
    }

    /// Toplam tutarı bul
    private func extractTotalAmount(from lines: [String]) -> Double? {
        var amounts: [Double] = []

        for line in lines {
            // "TOPLAM", "TOTAL", "TUTAR" gibi kelimeleri ara
            if line.lowercased().contains("toplam") ||
               line.lowercased().contains("total") ||
               line.lowercased().contains("ödenecek") {

                // Bu satırdan tutarları çıkar
                let lineAmounts = extractAmounts(from: line)
                amounts.append(contentsOf: lineAmounts)
            }
        }

        // Toplam bulunamadıysa, tüm satırlardan en büyük tutarı al
        if amounts.isEmpty {
            for line in lines {
                let lineAmounts = extractAmounts(from: line)
                amounts.append(contentsOf: lineAmounts)
            }
        }

        // En büyük tutarı döndür (genelde toplam tutar en büyük olanıdır)
        return amounts.max()
    }

    /// Satırdan sayısal tutarları çıkar
    private func extractAmounts(from text: String) -> [Double] {
        var amounts: [Double] = []

        // Türk Lirası formatları:
        // 1.234,56 TL
        // 1234,56
        // 42.50
        // 42,50

        let patterns = [
            #"(\d{1,3}(?:\.\d{3})*,\d{2})"#,  // 1.234,56
            #"(\d+,\d{2})"#,                    // 1234,56
            #"(\d+\.\d{2})"#                    // 42.50
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
                let matches = regex.matches(in: text, range: nsRange)

                for match in matches {
                    if let range = Range(match.range(at: 1), in: text) {
                        var amountStr = String(text[range])

                        // Türk formatını standart formata çevir
                        amountStr = amountStr.replacingOccurrences(of: ".", with: "")
                        amountStr = amountStr.replacingOccurrences(of: ",", with: ".")

                        if let amount = Double(amountStr), amount > 0 {
                            amounts.append(amount)
                        }
                    }
                }
            }
        }

        return amounts
    }

    /// Tarih bul
    private func extractDate(from lines: [String]) -> Date? {
        let datePatterns = [
            #"(\d{2}[./]\d{2}[./]\d{4})"#,     // 01.01.2024 veya 01/01/2024
            #"(\d{2}[./]\d{2}[./]\d{2})"#,     // 01.01.24
            #"(\d{4}[-]\d{2}[-]\d{2})"#        // 2024-01-01
        ]

        for line in lines.prefix(10) {  // İlk 10 satırda ara
            for pattern in datePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
                    if let match = regex.firstMatch(in: line, range: nsRange),
                       let range = Range(match.range(at: 1), in: line) {
                        let dateStr = String(line[range])

                        if let date = parseDate(from: dateStr) {
                            return date
                        }
                    }
                }
            }
        }

        return nil
    }

    /// Tarih string'ini Date'e çevir
    private func parseDate(from string: String) -> Date? {
        let formatters = [
            "dd.MM.yyyy",
            "dd/MM/yyyy",
            "dd.MM.yy",
            "dd/MM/yy",
            "yyyy-MM-dd"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "tr_TR")

            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }

    /// Ürün/kalem listesini çıkar
    private func extractItems(from lines: [String]) -> [ParsedReceipt.ReceiptItem] {
        var items: [ParsedReceipt.ReceiptItem] = []

        for line in lines {
            // Hem isim hem tutar içeren satırları bul
            let amounts = extractAmounts(from: line)

            if !amounts.isEmpty {
                // Tutarı kaldırıp kalan kısmı isim olarak al
                var itemName = line

                // Sayıları ve sembolleri temizle
                itemName = itemName.replacingOccurrences(of: #"\d+[.,]\d+"#, with: "", options: .regularExpression)
                itemName = itemName.replacingOccurrences(of: "TL", with: "")
                itemName = itemName.replacingOccurrences(of: "₺", with: "")
                itemName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)

                if !itemName.isEmpty && itemName.count > 2 {
                    for amount in amounts {
                        items.append(ParsedReceipt.ReceiptItem(name: itemName, amount: amount))
                    }
                }
            }
        }

        return items
    }

    /// Kategori öner (ML tabanlı)
    private func suggestCategory(merchantName: String?, text: String) -> TransactionCategory {
        let fullText = (merchantName ?? "") + " " + text

        // ML tahminini kullan
        let prediction = MLCategoryPredictor.shared.predictCategory(from: fullText, merchantName: merchantName)

        // Yüksek güvenle tahmin varsa onu kullan
        if prediction.confidence > 0.6 {
            return prediction.category
        }

        // Düşük güven, fallback olarak basit keyword kontrolü
        let lowercased = fullText.lowercased()

        // Yemek
        if lowercased.contains("market") || lowercased.contains("migros") ||
           lowercased.contains("bim") || lowercased.contains("a101") ||
           lowercased.contains("şok") || lowercased.contains("carrefour") ||
           lowercased.contains("restaurant") || lowercased.contains("cafe") ||
           lowercased.contains("yemek") {
            return .food
        }

        // Ulaşım
        if lowercased.contains("benzin") || lowercased.contains("shell") ||
           lowercased.contains("opet") || lowercased.contains("bp") ||
           lowercased.contains("otopark") || lowercased.contains("taksi") {
            return .transport
        }

        // Faturalar
        if lowercased.contains("elektrik") || lowercased.contains("su") ||
           lowercased.contains("doğalgaz") || lowercased.contains("internet") ||
           lowercased.contains("telefon") || lowercased.contains("fatura") {
            return .bills
        }

        // Sağlık
        if lowercased.contains("eczane") || lowercased.contains("pharmacy") ||
           lowercased.contains("hastane") || lowercased.contains("hospital") ||
           lowercased.contains("klinik") || lowercased.contains("doktor") {
            return .health
        }

        // Eğlence
        if lowercased.contains("sinema") || lowercased.contains("cinema") ||
           lowercased.contains("bilet") || lowercased.contains("ticket") ||
           lowercased.contains("konser") {
            return .entertainment
        }

        // ML tahmini döndür (fallback olarak)
        return prediction.category
    }

    // MARK: - Helper Methods

    private func containsDatePattern(_ text: String) -> Bool {
        let datePattern = #"\d{2}[./]\d{2}[./]\d{2,4}"#
        return text.range(of: datePattern, options: .regularExpression) != nil
    }

    private func containsAmountPattern(_ text: String) -> Bool {
        let amountPattern = #"\d+[.,]\d{2}"#
        return text.range(of: amountPattern, options: .regularExpression) != nil
    }
}
