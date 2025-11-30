//
//  AddInstallmentPaymentView.swift
//  FinansPro
//
//  Taksitli ödeme ekleme ekranı
//

import SwiftUI

struct AddInstallmentPaymentView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var amount: Double = 0
    @State private var installmentCount = 3
    @State private var startDate = Date()
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var selectedStandardCategory: TransactionCategory = .bills
    @State private var selectedCustomCategoryId: UUID? = nil
    @State private var note = ""
    @State private var showingCategoryPicker = false

    private let installmentOptions = [2, 3, 4, 6, 9, 12, 18, 24, 36]

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
                        // Başlık
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Taksitli Ödeme")
                                .font(Theme.largeTitle)
                                .fontWeight(.bold)

                            Text("Aylık taksitlerle ödeme planı oluşturun")
                                .font(Theme.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // Form
                        VStack(spacing: 20) {
                            // Ürün/Hizmet Adı
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Ürün/Hizmet", systemImage: "cart.fill")
                                    .font(Theme.callout)
                                    .foregroundColor(.secondary)

                                TextField("Örn: iPhone 15 Pro", text: $title)
                                    .font(Theme.body)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            }

                            // Toplam Tutar
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Toplam Tutar", systemImage: "turkishlirasign.circle.fill")
                                    .font(Theme.callout)
                                    .foregroundColor(.secondary)

                                CurrencyTextFieldWithoutFocus(title: "0,00", value: $amount)
                                    .font(Theme.body)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            }

                            // Taksit Sayısı
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Taksit Sayısı", systemImage: "number.circle.fill")
                                    .font(Theme.callout)
                                    .foregroundColor(.secondary)

                                Picker("Taksit Sayısı", selection: $installmentCount) {
                                    ForEach(installmentOptions, id: \.self) { count in
                                        Text("\(count) Taksit").tag(count)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .onChange(of: installmentCount) { _, _ in
                                    HapticManager.shared.selection()
                                }
                            }

                            // Taksit tutarı önizlemesi
                            if amount > 0 {
                                HStack {
                                    Image(systemName: "equal.circle.fill")
                                        .foregroundStyle(Theme.primaryGradient)

                                    Text("Her taksit:")
                                        .font(Theme.callout)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text((amount / Double(installmentCount)).toCurrency())
                                        .font(Theme.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Theme.primaryGradient)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            }

                            // İlk Taksit Tarihi
                            VStack(alignment: .leading, spacing: 8) {
                                Label("İlk Taksit Tarihi", systemImage: "calendar")
                                    .font(Theme.callout)
                                    .foregroundColor(.secondary)

                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            }

                            // Taksit Periyodu
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Taksit Aralığı", systemImage: "arrow.triangle.2.circlepath")
                                    .font(Theme.callout)
                                    .foregroundColor(.secondary)

                                Picker("Periyot", selection: $frequency) {
                                    ForEach([RecurrenceFrequency.weekly, .biweekly, .monthly], id: \.self) { freq in
                                        HStack {
                                            Image(systemName: freq.icon)
                                            Text(freq.rawValue)
                                        }
                                        .tag(freq)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .onChange(of: frequency) { _, _ in
                                    HapticManager.shared.selection()
                                }
                            }

                            // Kategori
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Kategori", systemImage: "tag.fill")
                                    .font(Theme.callout)
                                    .foregroundColor(.secondary)

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

                                TextField("Örn: 24 ay vade farksız", text: $note, axis: .vertical)
                                    .font(Theme.body)
                                    .lineLimit(3...6)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)

                        // Kaydet Butonu
                        Button(action: saveInstallmentPayment) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))

                                Text("Taksitli Ödeme Oluştur")
                                    .font(Theme.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.6)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
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
        }
    }

    private var isValid: Bool {
        !title.isEmpty && amount > 0
    }

    private func saveInstallmentPayment() {
        guard isValid else { return }

        let payment = InstallmentPayment(
            title: title,
            totalAmount: amount,
            installmentCount: installmentCount,
            category: selectedStandardCategory,
            customCategoryId: selectedCustomCategoryId,
            startDate: startDate,
            frequency: frequency,
            note: note
        )

        dataManager.addInstallmentPayment(payment)

        HapticManager.shared.success()
        dismiss()
    }
}

#Preview {
    AddInstallmentPaymentView()
        .environmentObject(DataManager.shared)
}
