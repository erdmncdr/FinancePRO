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
            let lowercasedLine = line.lowercased()

            // NAKİT, PARA ÜSTÜ gibi kelimeleri içeren satırları ATLA
            if lowercasedLine.contains("nakit") ||
               lowercasedLine.contains("nakıt") ||
               lowercasedLine.contains("cash") ||
               lowercasedLine.contains("para üstü") ||
               lowercasedLine.contains("para ustu") ||
               lowercasedLine.contains("change") ||
               lowercasedLine.contains("verilen") {
                continue  // Bu satırı atla
            }

            // "TOPLAM", "TOTAL", "ÖDENECEK", "TUTAR" gibi kelimeleri ara
            if lowercasedLine.contains("toplam") ||
               lowercasedLine.contains("total") ||
               lowercasedLine.contains("ödenecek") ||
               lowercasedLine.contains("odenecek") ||
               lowercasedLine.contains("tutar") ||
               lowercasedLine.contains("amount") {

                // Bu satırdan tutarları çıkar
                let lineAmounts = extractAmounts(from: line)
                amounts.append(contentsOf: lineAmounts)
            }
        }

        // Toplam bulunamadıysa, tüm satırlardan en büyük tutarı al (nakit/para üstü hariç)
        if amounts.isEmpty {
            for line in lines {
                let lowercasedLine = line.lowercased()

                // NAKİT, PARA ÜSTÜ içeren satırları atla
                if lowercasedLine.contains("nakit") ||
                   lowercasedLine.contains("nakıt") ||
                   lowercasedLine.contains("cash") ||
                   lowercasedLine.contains("para üstü") ||
                   lowercasedLine.contains("para ustu") ||
                   lowercasedLine.contains("change") ||
                   lowercasedLine.contains("verilen") {
                    continue
                }

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

    /// Kategori öner (ML tabanlı + Geliştirilmiş keyword kontrolü)
    private func suggestCategory(merchantName: String?, text: String) -> TransactionCategory {
        let fullText = (merchantName ?? "") + " " + text
        let lowercased = fullText.lowercased()

        // ÖNCELİKLE keyword tabanlı kontrol yap (daha güvenilir)
        // Marketler ve Süpermarketler -> FOOD
        let supermarkets = [
            "migros", "bim", "a101", "şok", "sok", "carrefour", "carrefoursa",
            "metro", "makro", "macro", "kiler", "kim market", "tansas",
            "file", "onur", "yeni onur", "dia", "ekomini", "ucuzamı", "ucuzami"
        ]

        for market in supermarkets {
            if lowercased.contains(market) {
                return .food
            }
        }

        // Restoranlar, Kafeler, Fast Food -> FOOD
        let restaurants = [
            "restaurant", "restoran", "cafe", "kafe", "kahve", "coffee",
            "mcdonald", "burger king", "kfc", "domino", "pizza",
            "starbucks", "kahve dünyası", "kahve dunyasi", "gloria jean",
            "popeyes", "sbarro", "tavuk dünyası", "tavuk dunyasi",
            "yemek", "food", "lokanta", "aşevi", "asevi", "kebap", "döner",
            "bakery", "fırın", "pastane", "patisserie"
        ]

        for restaurant in restaurants {
            if lowercased.contains(restaurant) {
                return .food
            }
        }

        // Yakıt İstasyonları -> TRANSPORT
        let fuelStations = [
            "opet", "shell", "bp", "petrol ofisi", "po", "total",
            "aytemiz", "turkpetrol", "moil", "benzin", "akaryakıt",
            "lpg", "motorin", "fuel", "gas station"
        ]

        for station in fuelStations {
            if lowercased.contains(station) {
                return .transport
            }
        }

        // Ulaşım -> TRANSPORT
        if lowercased.contains("otopark") || lowercased.contains("parking") ||
           lowercased.contains("taksi") || lowercased.contains("taxi") ||
           lowercased.contains("uber") || lowercased.contains("bitaksi") ||
           lowercased.contains("otobüs") || lowercased.contains("otobus") ||
           lowercased.contains("metro") || lowercased.contains("tramvay") ||
           lowercased.contains("dolmuş") || lowercased.contains("dolmus") ||
           lowercased.contains("ulaşım") || lowercased.contains("ulasim") {
            return .transport
        }

        // Faturalar -> BILLS
        if lowercased.contains("elektrik") || lowercased.contains("electric") ||
           lowercased.contains("su") || lowercased.contains("water") ||
           lowercased.contains("doğalgaz") || lowercased.contains("dogalgaz") ||
           lowercased.contains("internet") || lowercased.contains("ttnet") ||
           lowercased.contains("superonline") || lowercased.contains("türk telekom") ||
           lowercased.contains("turk telekom") || lowercased.contains("vodafone") ||
           lowercased.contains("turkcell") || lowercased.contains("avea") ||
           lowercased.contains("fatura") || lowercased.contains("invoice") ||
           lowercased.contains("bill") || lowercased.contains("ödeme") {
            return .bills
        }

        // Eczane ve Sağlık -> HEALTH
        let healthPlaces = [
            "eczane", "pharmacy", "eczacı", "eczaci", "sağlık",
            "saglik", "hastane", "hospital", "klinik", "clinic",
            "doktor", "doctor", "poliklinik", "muayenehane",
            "tıbbi", "tibbi", "medikal", "medical"
        ]

        for place in healthPlaces {
            if lowercased.contains(place) {
                return .health
            }
        }

        // Eğlence -> ENTERTAINMENT
        if lowercased.contains("sinema") || lowercased.contains("cinema") ||
           lowercased.contains("bilet") || lowercased.contains("ticket") ||
           lowercased.contains("konser") || lowercased.contains("concert") ||
           lowercased.contains("tiyatro") || lowercased.contains("theater") ||
           lowercased.contains("müze") || lowercased.contains("muze") ||
           lowercased.contains("eğlence") || lowercased.contains("eglence") {
            return .entertainment
        }

        // Giyim -> SHOPPING
        let clothingStores = [
            "zara", "h&m", "mango", "koton", "lcwaikiki", "defacto",
            "pull&bear", "bershka", "stradivarius", "mavi", "nike",
            "adidas", "puma", "colin's", "watsons", "gratis"
        ]

        for store in clothingStores {
            if lowercased.contains(store) {
                return .shopping
            }
        }

        // Elektronik -> SHOPPING
        let electronicStores = [
            "teknosa", "vatan", "media markt", "mediamarkt",
            "gold", "d&r", "apple", "samsung", "bimeks"
        ]

        for store in electronicStores {
            if lowercased.contains(store) {
                return .shopping
            }
        }

        // Keyword kontrolden sonra ML tahminini kullan
        let prediction = MLCategoryPredictor.shared.predictCategory(from: fullText, merchantName: merchantName)

        // Orta-yüksek güvenle tahmin varsa onu kullan
        if prediction.confidence > 0.5 {
            return prediction.category
        }

        // Hiçbir eşleşme yoksa, ML tahmini döndür veya varsayılan kategori
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
