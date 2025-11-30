//
//  RecurringPaymentsView.swift
//  FinansPro
//
//  Tekrarlayan ödemeler yönetim ekranı
//

import SwiftUI

struct RecurringPaymentsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddRecurring = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                if dataManager.recurringTransactions.isEmpty {
                    EmptyStateView(
                        icon: "repeat.circle",
                        title: "Henüz tekrarlayan ödeme yok",
                        message: "Aylık faturalar veya düzenli ödemelerinizi ekleyin"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Özet kart
                            RecurringSummaryCard()
                                .padding(.horizontal)
                                .padding(.top, 20)

                            // Aktif tekrarlayan ödemeler
                            let activeRecurring = dataManager.recurringTransactions.filter { $0.isActive }
                            if !activeRecurring.isEmpty {
                                VStack(spacing: 12) {
                                    SectionHeader("Aktif Ödemeler", icon: "checkmark.circle.fill")

                                    ForEach(activeRecurring) { recurring in
                                        RecurringTransactionCard(recurring: recurring)
                                            .padding(.horizontal)
                                    }
                                }
                            }

                            // Pasif tekrarlayan ödemeler
                            let inactiveRecurring = dataManager.recurringTransactions.filter { !$0.isActive }
                            if !inactiveRecurring.isEmpty {
                                VStack(spacing: 12) {
                                    SectionHeader("Duraklatılmış", icon: "pause.circle")

                                    ForEach(inactiveRecurring) { recurring in
                                        RecurringTransactionCard(recurring: recurring)
                                            .padding(.horizontal)
                                            .opacity(0.6)
                                    }
                                }
                            }

                            Spacer(minLength: 100)
                        }
                    }
                }
            }
            .navigationTitle("Tekrarlayan Ödemeler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticManager.shared.impact(style: .medium)
                        showingAddRecurring = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddRecurring) {
                AddRecurringTransactionView()
            }
        }
    }
}

// Özet kart
struct RecurringSummaryCard: View {
    @EnvironmentObject var dataManager: DataManager

    private var monthlyTotal: Double {
        dataManager.recurringTransactions
            .filter { $0.isActive && $0.frequency == .monthly }
            .reduce(0) { $0 + $1.amount }
    }

    private var activeCount: Int {
        dataManager.recurringTransactions.filter { $0.isActive }.count
    }

    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Aylık Toplam")
                    .font(Theme.subheadline)
                    .foregroundColor(.secondary)

                Text(monthlyTotal.toCurrency())
                    .font(Theme.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.accentGradient)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text("Aktif")
                    .font(Theme.subheadline)
                    .foregroundColor(.secondary)

                Text("\(activeCount)")
                    .font(Theme.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.primaryGradient)
            }
        }
        .padding(20)
        .glassEffect()
    }
}

// Tekrarlayan işlem kartı
struct RecurringTransactionCard: View {
    let recurring: RecurringTransaction
    @EnvironmentObject var dataManager: DataManager
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    private var categoryItem: CategoryItem {
        recurring.getCategoryItem(customCategories: dataManager.customCategories)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // İkon
                ZStack {
                    Circle()
                        .fill(categoryItem.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: categoryItem.icon)
                        .font(.system(size: 22))
                        .foregroundColor(categoryItem.color)
                }

                // Bilgiler
                VStack(alignment: .leading, spacing: 4) {
                    Text(recurring.title)
                        .font(Theme.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Image(systemName: recurring.frequency.icon)
                            .font(.system(size: 12))
                        Text(recurring.frequency.rawValue)
                            .font(Theme.caption)
                    }
                    .foregroundColor(.secondary)

                    Text("Sonraki: \(recurring.nextPaymentDate.toShortString())")
                        .font(Theme.caption)
                        .foregroundColor(.orange)
                }

                Spacer()

                // Miktar
                Text(recurring.amount.toCurrency())
                    .font(Theme.headline)
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
            .padding()

            // Alt butonlar
            HStack(spacing: 0) {
                // Aktif/Pasif
                Button {
                    HapticManager.shared.impact(style: .medium)
                    dataManager.toggleRecurringTransaction(recurring)
                } label: {
                    HStack {
                        Image(systemName: recurring.isActive ? "pause.fill" : "play.fill")
                        Text(recurring.isActive ? "Duraklat" : "Aktifleştir")
                    }
                    .font(Theme.callout)
                    .foregroundColor(recurring.isActive ? .orange : .green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Divider()
                    .frame(height: 30)

                // Düzenle
                Button {
                    HapticManager.shared.impact(style: .light)
                    showingEditSheet = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Düzenle")
                    }
                    .font(Theme.callout)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Divider()
                    .frame(height: 30)

                // Sil
                Button {
                    HapticManager.shared.impact(style: .light)
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Sil")
                    }
                    .font(Theme.callout)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .premiumCard()
        .sheet(isPresented: $showingEditSheet) {
            EditRecurringTransactionView(recurring: recurring)
        }
        .alert("Tekrarlayan ödemeyi sil?", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                HapticManager.shared.warning()
                dataManager.deleteRecurringTransaction(recurring)
            }
        } message: {
            Text("Bu tekrarlayan ödeme silinecek. Mevcut işlemler etkilenmez.")
        }
    }
}

// Yeni tekrarlayan işlem ekleme
struct AddRecurringTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager

    @State private var title = ""
    @State private var amount: Double = 0
    @State private var selectedCategory: TransactionCategory = .bills
    @State private var selectedCustomCategoryId: UUID?
    @State private var selectedFrequency: RecurrenceFrequency = .monthly
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var note = ""
    @State private var notifyDays = 1
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                Form {
                    Section("Bilgiler") {
                        TextField("Başlık (örn: Netflix)", text: $title)

                        CurrencyTextField(title: "Miktar (₺)", value: $amount, isFocused: $isAmountFocused)

                        // Slider ile hızlı seçim
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text("Hızlı Seçim")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(amount.toCurrency())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.primaryGradient)
                            }

                            Slider(value: $amount, in: 0...20000, step: 50) {
                                Text("Miktar")
                            } minimumValueLabel: {
                                Text("0")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } maximumValueLabel: {
                                Text("20K")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .tint(Color.orange)
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Kategori") {
                        SmartCategoryPicker(
                            selectedStandardCategory: $selectedCategory,
                            selectedCustomCategoryId: $selectedCustomCategoryId
                        )
                    }

                    Section("Tekrarlama") {
                        Picker("Sıklık", selection: $selectedFrequency) {
                            ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                                HStack {
                                    Image(systemName: freq.icon)
                                    Text(freq.rawValue)
                                }
                                .tag(freq)
                            }
                        }

                        DatePicker("Başlangıç", selection: $startDate, displayedComponents: .date)

                        Toggle("Bitiş tarihi belirle", isOn: $hasEndDate)
                        if hasEndDate {
                            DatePicker("Bitiş", selection: $endDate, displayedComponents: .date)
                        }
                    }

                    Section("Bildirim") {
                        Stepper("Hatırlatma: \(notifyDays) gün önce", value: $notifyDays, in: 0...7)
                    }

                    Section("Not (Opsiyonel)") {
                        TextEditor(text: $note)
                            .frame(height: 80)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Tekrarlayan Ödeme Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveRecurring()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !title.isEmpty && amount > 0
    }

    private func saveRecurring() {
        guard amount > 0 else { return }

        HapticManager.shared.success()

        let recurring = RecurringTransaction(
            title: title,
            amount: amount,
            type: .upcoming,
            category: selectedCategory,
            customCategoryId: selectedCustomCategoryId,
            frequency: selectedFrequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            note: note,
            notifyBeforeDays: notifyDays
        )

        dataManager.addRecurringTransaction(recurring)
        dismiss()
    }
}

// Düzenleme ekranı
struct EditRecurringTransactionView: View {
    let recurring: RecurringTransaction
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager

    @State private var title = ""
    @State private var amount: Double = 0
    @State private var selectedCategory: TransactionCategory = .bills
    @State private var selectedCustomCategoryId: UUID?
    @State private var selectedFrequency: RecurrenceFrequency = .monthly
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var note = ""
    @State private var notifyDays = 1
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                Form {
                    Section("Bilgiler") {
                        TextField("Başlık", text: $title)

                        CurrencyTextField(title: "Miktar (₺)", value: $amount, isFocused: $isAmountFocused)

                        // Slider ile hızlı seçim
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text("Hızlı Seçim")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(amount.toCurrency())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.primaryGradient)
                            }

                            Slider(value: $amount, in: 0...20000, step: 50) {
                                Text("Miktar")
                            } minimumValueLabel: {
                                Text("0")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } maximumValueLabel: {
                                Text("20K")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .tint(Color.orange)
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Kategori") {
                        SmartCategoryPicker(
                            selectedStandardCategory: $selectedCategory,
                            selectedCustomCategoryId: $selectedCustomCategoryId
                        )
                    }

                    Section("Tekrarlama") {
                        Picker("Sıklık", selection: $selectedFrequency) {
                            ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                                HStack {
                                    Image(systemName: freq.icon)
                                    Text(freq.rawValue)
                                }
                                .tag(freq)
                            }
                        }

                        DatePicker("Başlangıç", selection: $startDate, displayedComponents: .date)

                        Toggle("Bitiş tarihi belirle", isOn: $hasEndDate)
                        if hasEndDate {
                            DatePicker("Bitiş", selection: $endDate, displayedComponents: .date)
                        }
                    }

                    Section("Bildirim") {
                        Stepper("Hatırlatma: \(notifyDays) gün önce", value: $notifyDays, in: 0...7)
                    }

                    Section("Not (Opsiyonel)") {
                        TextEditor(text: $note)
                            .frame(height: 80)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        updateRecurring()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                title = recurring.title
                amount = recurring.amount
                selectedCategory = recurring.category
                selectedCustomCategoryId = recurring.customCategoryId
                selectedFrequency = recurring.frequency
                startDate = recurring.startDate
                hasEndDate = recurring.endDate != nil
                endDate = recurring.endDate ?? Date()
                note = recurring.note
                notifyDays = recurring.notifyBeforeDays
            }
        }
    }

    private var isValid: Bool {
        !title.isEmpty && amount > 0
    }

    private func updateRecurring() {
        guard amount > 0 else { return }

        HapticManager.shared.success()

        var updated = recurring
        updated.title = title
        updated.amount = amount
        updated.category = selectedCategory
        updated.customCategoryId = selectedCustomCategoryId
        updated.frequency = selectedFrequency
        updated.startDate = startDate
        updated.endDate = hasEndDate ? endDate : nil
        updated.note = note
        updated.notifyBeforeDays = notifyDays

        dataManager.updateRecurringTransaction(updated)
        dismiss()
    }
}

#Preview {
    RecurringPaymentsView()
        .environmentObject(DataManager.shared)
}
