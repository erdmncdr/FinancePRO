//
//  ScannedReceiptReviewView.swift
//  FinansPro
//
//  Taranan fiş bilgilerini önizleme ve düzenleme ekranı
//

import SwiftUI

struct ScannedReceiptReviewView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    let parsedReceipt: ParsedReceipt
    let receiptImage: UIImage
    var onSave: () -> Void

    @State private var title: String
    @State private var amount: Double
    @State private var date: Date
    @State private var selectedStandardCategory: TransactionCategory
    @State private var selectedCustomCategoryId: UUID? = nil
    @State private var note: String = ""
    @State private var showingCategoryPicker = false
    @State private var showingImagePreview = false

    init(parsedReceipt: ParsedReceipt, receiptImage: UIImage, onSave: @escaping () -> Void) {
        self.parsedReceipt = parsedReceipt
        self.receiptImage = receiptImage
        self.onSave = onSave

        _title = State(initialValue: parsedReceipt.merchantName ?? "Fiş")
        _amount = State(initialValue: parsedReceipt.totalAmount ?? 0)
        _date = State(initialValue: parsedReceipt.date ?? Date())
        _selectedStandardCategory = State(initialValue: parsedReceipt.suggestedCategory)
    }

    private var selectedCategoryItem: CategoryItem {
        if let customId = selectedCustomCategoryId,
           let customCategory = dataManager.customCategories.first(where: { $0.id == customId }) {
            return .custom(customCategory)
        }
        return .standard(selectedStandardCategory)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Başlık ve fiş önizlemesi
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Fiş Bilgileri")
                                        .font(Theme.largeTitle)
                                        .fontWeight(.bold)

                                    Text("Tanınan bilgileri kontrol edin ve düzenleyin")
                                        .font(Theme.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // Fiş fotoğrafı önizlemesi
                                Button(action: {
                                    showingImagePreview = true
                                }) {
                                    Image(uiImage: receiptImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // AI başarı göstergesi
                        if parsedReceipt.merchantName != nil || parsedReceipt.totalAmount != nil || parsedReceipt.date != nil {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Otomatik Tanıma Başarılı")
                                        .font(Theme.callout)
                                        .fontWeight(.semibold)

                                    Text(successMessage)
                                        .font(Theme.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(.green.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // Form
                        VStack(spacing: 20) {
                            // İşletme/Açıklama
                            VStack(alignment: .leading, spacing: 8) {
                                Label("İşletme/Açıklama", systemImage: "building.2.fill")
                                    .font(Theme.callout)
                                    .foregroundColor(.secondary)

                                TextField("Örn: Migros", text: $title)
                                    .font(Theme.body)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            }

                            // Tutar
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Tutar", systemImage: "turkishlirasign.circle.fill")
                                    .font(Theme.callout)
                                    .foregroundColor(.secondary)

                                CurrencyTextFieldWithoutFocus(title: "0,00", value: $amount)
                                    .font(Theme.body)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            }

                            // Tarih
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Tarih", systemImage: "calendar")
                                    .font(Theme.callout)
                                    .foregroundColor(.secondary)

                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            }

                            // Kategori
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("Kategori", systemImage: "tag.fill")
                                        .font(Theme.callout)
                                        .foregroundColor(.secondary)

                                    if parsedReceipt.merchantName != nil {
                                        Text("(Otomatik önerildi)")
                                            .font(Theme.caption)
                                            .foregroundColor(.blue)
                                    }
                                }

                                Button(action: {
                                    HapticManager.shared.impact(style: .light)
                                    showingCategoryPicker = true
                                }) {
                                    HStack {
                                        Image(systemName: selectedCategoryItem.icon)
                                            .foregroundColor(selectedCategoryItem.color)

                                        Text(selectedCategoryItem.name)
                                            .foregroundColor(.primary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                                }
                            }

                            // Not
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Not (Opsiyonel)", systemImage: "note.text")
                                    .font(Theme.callout)
                                    .foregroundColor(.secondary)

                                TextField("Örn: Haftalık alışveriş", text: $note, axis: .vertical)
                                    .font(Theme.body)
                                    .lineLimit(3...6)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            }

                            // Tanınan ürünler (varsa)
                            if !parsedReceipt.items.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Tanınan Ürünler", systemImage: "list.bullet")
                                        .font(Theme.callout)
                                        .foregroundColor(.secondary)

                                    VStack(spacing: 8) {
                                        ForEach(Array(parsedReceipt.items.prefix(5).enumerated()), id: \.offset) { _, item in
                                            HStack {
                                                Text(item.name)
                                                    .font(Theme.caption)
                                                    .foregroundColor(.primary)

                                                Spacer()

                                                Text(item.amount.toCurrency())
                                                    .font(Theme.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)

                                    if parsedReceipt.items.count > 5 {
                                        Text("ve \(parsedReceipt.items.count - 5) ürün daha...")
                                            .font(Theme.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Kaydet butonu
                        Button(action: saveTransaction) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))

                                Text("Gider Olarak Kaydet")
                                    .font(Theme.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.6)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                SmartCategoryPicker(
                    selectedStandardCategory: $selectedStandardCategory,
                    selectedCustomCategoryId: $selectedCustomCategoryId
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingImagePreview) {
                NavigationStack {
                    ZStack {
                        Color.black.ignoresSafeArea()

                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                    }
                    .navigationTitle("Fiş Fotoğrafı")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Kapat") {
                                showingImagePreview = false
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        !title.isEmpty && amount > 0
    }

    private var successMessage: String {
        var parts: [String] = []
        if parsedReceipt.merchantName != nil { parts.append("işletme") }
        if parsedReceipt.totalAmount != nil { parts.append("tutar") }
        if parsedReceipt.date != nil { parts.append("tarih") }

        if parts.isEmpty {
            return "Bazı bilgiler tanındı"
        } else {
            return parts.joined(separator: ", ") + " tanındı"
        }
    }

    private func saveTransaction() {
        guard isValid else { return }

        // Fotoğrafı Data'ya çevir
        let imageData = receiptImage.jpegData(compressionQuality: 0.7)

        let transaction = Transaction(
            title: title,
            amount: amount,
            type: .expense,
            category: selectedStandardCategory,
            date: date,
            note: note,
            customCategoryId: selectedCustomCategoryId,
            receiptImageData: imageData
        )

        dataManager.addTransaction(transaction)

        HapticManager.shared.success()
        onSave()
        dismiss()
    }
}

#Preview {
    ScannedReceiptReviewView(
        parsedReceipt: ParsedReceipt(
            merchantName: "Migros",
            totalAmount: 125.50,
            date: Date(),
            suggestedCategory: .food,
            items: [
                ParsedReceipt.ReceiptItem(name: "Süt", amount: 25.00),
                ParsedReceipt.ReceiptItem(name: "Ekmek", amount: 10.00),
                ParsedReceipt.ReceiptItem(name: "Peynir", amount: 45.50)
            ],
            rawText: "Sample text"
        ),
        receiptImage: UIImage(systemName: "doc.text")!,
        onSave: {}
    )
    .environmentObject(DataManager.shared)
}
