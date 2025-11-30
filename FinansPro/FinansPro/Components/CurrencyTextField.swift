//
//  CurrencyTextField.swift
//  FinansPro
//
//  Türk Lirası formatında para girişi
//  Format: 1.500,50 (binlik ayraç: nokta, ondalık: virgül)
//

import SwiftUI

struct CurrencyTextField: View {
    let title: String
    @Binding var value: Double
    @FocusState.Binding var isFocused: Bool

    @State private var textValue: String = ""

    var body: some View {
        TextField(title, text: $textValue)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onChange(of: textValue) { oldValue, newValue in
                formatCurrency(newValue)
            }
            .onChange(of: value) { oldValue, newValue in
                if !isFocused {
                    textValue = formatDoubleToString(newValue)
                }
            }
            .onAppear {
                textValue = formatDoubleToString(value)
            }
    }

    private func formatCurrency(_ input: String) {
        // Sadece rakamlar ve virgül
        let filtered = input.filter { $0.isNumber || $0 == "," }

        // Virgül sayısını kontrol et (max 1)
        let commaCount = filtered.filter { $0 == "," }.count
        if commaCount > 1 {
            textValue = String(filtered.dropLast())
            return
        }

        // Virgülden sonra max 2 hane
        if let commaIndex = filtered.firstIndex(of: ",") {
            let afterComma = filtered[filtered.index(after: commaIndex)...]
            if afterComma.count > 2 {
                textValue = String(filtered.dropLast())
                return
            }
        }

        // String'i Double'a çevir
        let cleanNumber = filtered.replacingOccurrences(of: ",", with: ".")
        if let doubleValue = Double(cleanNumber) {
            value = doubleValue
        } else if filtered.isEmpty {
            value = 0
        }

        // Formatla ve göster
        textValue = formatWithThousandSeparator(filtered)
    }

    private func formatWithThousandSeparator(_ input: String) -> String {
        // Boş input kontrolü
        guard !input.isEmpty else { return "" }

        // Virgüle göre ayır
        let parts = input.split(separator: ",", maxSplits: 1)
        guard !parts.isEmpty else { return "" }

        let integerPart = String(parts[0])
        let decimalPart = parts.count > 1 ? String(parts[1]) : ""

        // Tam kısma binlik ayracı ekle
        let formattedInteger = addThousandSeparators(integerPart)

        // Birleştir
        if decimalPart.isEmpty {
            return formattedInteger
        } else {
            return "\(formattedInteger),\(decimalPart)"
        }
    }

    private func addThousandSeparators(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        if digits.isEmpty { return "" }

        var result = ""
        var count = 0

        for char in digits.reversed() {
            if count > 0 && count % 3 == 0 {
                result.insert(".", at: result.startIndex)
            }
            result.insert(char, at: result.startIndex)
            count += 1
        }

        return result
    }

    private func formatDoubleToString(_ value: Double) -> String {
        if value == 0 { return "" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
}

// Binding helper for optional focus state
struct CurrencyTextFieldWithoutFocus: View {
    let title: String
    @Binding var value: Double

    @FocusState private var isFocused: Bool

    var body: some View {
        CurrencyTextField(title: title, value: $value, isFocused: $isFocused)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var amount: Double = 1500.50
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack(spacing: 20) {
                CurrencyTextField(title: "Miktar", value: $amount, isFocused: $isFocused)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Text("Değer: ₺\(amount, specifier: "%.2f")")
                    .font(.headline)

                Button("Temizle") {
                    amount = 0
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
