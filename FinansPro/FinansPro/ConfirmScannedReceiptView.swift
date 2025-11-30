import SwiftUI

struct ConfirmScannedReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.colorScheme) private var colorScheme

    let parsed: ParsedReceipt

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var selectedCategory: TransactionCategory = .bills
    @State private var selectedCustomCategoryId: UUID? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                Form {
                    Section("Bilgiler") {
                        TextField("Başlık", text: $title)
                        TextField("Tutar (örn: 123,45)", text: $amountText)
                            .keyboardType(.decimalPad)
                        DatePicker("Tarih", selection: $date, displayedComponents: .date)
                    }

                    Section("Kategori") {
                        SmartCategoryPicker(
                            selectedStandardCategory: $selectedCategory,
                            selectedCustomCategoryId: $selectedCustomCategoryId
                        )
                    }

                    Section("Not") {
                        TextEditor(text: $note)
                            .frame(height: 100)
                    }

                    Section(header: Text("Ham Metin")) {
                        Text(parsed.rawText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(8)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Fişi Onayla")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { saveExpense() }
                        .disabled(!isValid)
                }
            }
            .onAppear { prefill() }
        }
    }

    private var isValid: Bool {
        !title.isEmpty && amountDouble != nil
    }

    private var amountDouble: Double? {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    private var amountCandidates: [String] {
        let text = parsed.rawText
        // 1) Bağlamsal adaylar: pozitif anahtar kelimeleri içeren satırlardaki tutarlar (negatif anahtar kelimeler hariç)
        let contextual = extractContextualAmounts(from: text)

        // 2) Genel adaylar: regex + puanlama
        let pattern = #"(?<!\d)(?:\d{1,3}(?:[.,]\d{3})*|\d+)[.,]\d{2}(?!\d)"#
        let amounts = regexMatches(in: text, pattern: pattern)
        // Negatif bağlam içeren satırlardaki tutarları tamamen çıkar
        let filteredAmounts = amounts.filter { amt in
            let line = lineContaining(amt, in: text).lowercased()
            return !containsNegativeKeyword(line)
        }
        let scored = filteredAmounts.map { amt -> (String, Double) in
            let line = lineContaining(amt, in: text)
            let score = contextScore(for: line) + magnitudeBonus(amt)
            return (amt, score)
        }
        let sorted = scored.sorted { $0.1 > $1.1 }.map { $0.0 }

        // 3) Birleştir: önce bağlamsal, sonra genel; tekilleştir ve ilk 5'i al
        let combined = uniquePreservingOrder(contextual + sorted)
        return Array(combined.prefix(5))
    }

    private func lineContaining(_ substring: String, in text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.contains(substring) {
                return line
            }
        }
        return ""
    }

    private func extractContextualAmounts(from text: String) -> [String] {
        let positiveKeywords = [
            "genel toplam", "toplam", "tutar", "odeme", "ödeme", "total", "grand total", "kdv dahil", "kdv dâhil"
        ]
        let negativeKeywords = [
            "nakit", "cash", "para üstü", "paraustu", "para ustu", "iade", "ara toplam", "aratoplam"
        ]
        var results: [String] = []
        let lines = text.components(separatedBy: .newlines)
        let amountPattern = #"(?<!\d)(?:\d{1,3}(?:[.,]\d{3})*|\d+)[.,]\d{2}(?!\d)"#

        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            let lower = line.lowercased()

            // Pozitif anahtar kelime içermeli
            guard positiveKeywords.contains(where: { lower.contains($0) }) else { continue }
            // Negatif bağlam içermemeli
            guard !negativeKeywords.contains(where: { lower.contains($0) }) else { continue }

            let amounts = regexMatches(in: line, pattern: amountPattern)
            // Bu satırdaki son tutarı tercih et (genelde sağda yer alır)
            if let last = amounts.last { results.append(last) }
        }
        return uniquePreservingOrder(results)
    }

    // Satır içinde negatif bağlam kontrolü
    private func containsNegativeKeyword(_ lowercasedLine: String) -> Bool {
        let negatives = [
            "nakit", "cash", "para üstü", "paraustu", "para ustu", "iade", "ara toplam", "aratoplam"
        ]
        return negatives.contains { lowercasedLine.contains($0) }
    }

    // Deduplicate while preserving the original order
    private func uniquePreservingOrder<T: Hashable>(_ array: [T]) -> [T] {
        var seen = Set<T>()
        var result: [T] = []
        result.reserveCapacity(array.count)
        for element in array {
            if seen.insert(element).inserted {
                result.append(element)
            }
        }
        return result
    }

    private func contextScore(for line: String) -> Double {
        let lower = line.lowercased()
        var score: Double = 0
        let positive = ["genel toplam", "toplam", "tutar", "odeme", "ödeme", "total", "grand total", "kdv", "dahil"]
        let negative = ["nakit", "cash", "para üstü", "paraustu", "ara toplam", "aratoplam", "adet", "kg", "koli", "birim", "no:", "ürün", "urun", "stok"]
        for k in positive { if lower.contains(k) { score += 2.5 } }
        for k in negative { if lower.contains(k) { score -= 2.5 } }
        return score
    }

    private func magnitudeBonus(_ amount: String) -> Double {
        // Assuming amounts over 1000 get a slight bonus (example logic)
        let normalized = amount.replacingOccurrences(of: ",", with: ".")
        if let val = Double(normalized), val > 1000 {
            return 1.0
        }
        return 0.0
    }

    private func regexMatches(in text: String, pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, options: [], range: nsrange)
            return matches.compactMap {
                if let range = Range($0.range, in: text) {
                    return String(text[range])
                }
                return nil
            }
        } catch {
            return []
        }
    }

    private func prefill() {
        title = parsed.title
        note = parsed.rawText
        amountText = parsed.amountString ?? ""

        if let ds = parsed.dateString {
            let fmts = ["dd.MM.yyyy", "dd/MM/yyyy", "d.M.yyyy", "d/M/yyyy", "yyyy-MM-dd"]
            let df = DateFormatter()
            df.locale = Locale(identifier: "tr_TR")
            for f in fmts {
                df.dateFormat = f
                if let d = df.date(from: ds) {
                    date = d
                    break
                }
            }
        }
    }

    private func saveExpense() {
        guard let amount = amountDouble else { return }
        HapticManager.shared.success()

        let transaction = Transaction(
            title: title,
            amount: amount,
            type: .expense,
            category: selectedCategory,
            date: date,
            note: note,
            isPaid: true,
            customCategoryId: selectedCustomCategoryId
        )
        dataManager.addTransaction(transaction)
        dismiss()
    }
}

#Preview {
    ConfirmScannedReceiptView(parsed: ParsedReceipt(title: "MARKET A.Ş.", amountString: "123,45", dateString: "12.11.2025", rawText: "MARKET A.Ş.\nTOPLAM 123,45\n12.11.2025"))
        .environmentObject(DataManager.shared)
}

