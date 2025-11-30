//
//  ExpensesView.swift
//  FinanceTracker
//
//  Giderler ekranı
//

import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSheet = false
    @State private var selectedTransaction: Transaction?
    @State private var searchText = ""
    @State private var filterOptions = FilterOptions()
    @State private var showingFilterSheet = false
    @State private var showingReceiptScanner = false
    @Environment(\.colorScheme) var colorScheme

    private var expenses: [Transaction] {
        let allExpenses = dataManager.getTransactions(ofType: .expense)

        // Filtre aktifse filtrele, değilse sadece arama yap
        if filterOptions.isActive {
            var options = filterOptions
            // Sadece gider tipini göster
            options.types = [.expense]
            return dataManager.filterTransactions(searchQuery: searchText, filters: options)
        } else if !searchText.isEmpty {
            return dataManager.searchTransactions(query: searchText)
                .filter { $0.type == .expense }
        } else {
            return allExpenses
        }
    }

    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var groupedExpensesByDay: [(date: Date, items: [Transaction])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: expenses) { (t: Transaction) -> Date in
            return calendar.startOfDay(for: t.date)
        }
        let sortedKeys = groups.keys.sorted(by: { $0 > $1 })
        return sortedKeys.map { ($0, groups[$0]!.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Başlık
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Giderler")
                                .font(Theme.largeTitle)
                                .fontWeight(.bold)

                            Text("Harcamalarınızı takip edin")
                                .font(Theme.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Fiş Tara butonu
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showingReceiptScanner = true
                        } label: {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.trailing, 8)

                        // Filtre butonu
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showingFilterSheet = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Theme.primaryGradient)

                                // Aktif filtre göstergesi
                                if filterOptions.isActive {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                        .padding(.trailing, 8)

                        AddTransactionButton {
                            HapticManager.shared.impact(style: .medium)
                            showingAddSheet = true
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Arama çubuğu
                    SearchBar(text: $searchText, placeholder: "Gider ara...")
                        .padding(.horizontal)

                    // Özet kartları
                    HStack(spacing: 15) {
                        SummaryCard(
                            title: "Toplam Gider",
                            amount: totalExpenses,
                            icon: "cart.fill",
                            gradient: Theme.accentGradient
                        )

                        SummaryCard(
                            title: "Bu Ay",
                            amount: expenses.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }.reduce(0) { $0 + $1.amount },
                            icon: "calendar",
                            gradient: Theme.primaryGradient
                        )
                    }
                    .padding(.horizontal)

                    // Tüm giderler
                    if !expenses.isEmpty {
                        VStack(spacing: 12) {
                            SectionHeader("Tüm Giderler", icon: "list.bullet")

                            ForEach(groupedExpensesByDay, id: \.date) { section in
                                // Date header
                                HStack {
                                    Text(section.date.toShortString())
                                        .font(Theme.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)

                                ForEach(section.items) { transaction in
                                    TransactionCard(transaction: transaction)
                                        .padding(.horizontal)
                                        .onTapGesture {
                                            HapticManager.shared.impact(style: .light)
                                            selectedTransaction = transaction
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                HapticManager.shared.warning()
                                                withAnimation {
                                                    dataManager.deleteTransaction(transaction)
                                                }
                                            } label: {
                                                Label("Sil", systemImage: "trash")
                                            }
                                        }
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                            }
                        }
                    } else {
                        EmptyStateView(
                            icon: "cart",
                            title: "Henüz gider yok",
                            message: "Harcamalarınızı kaydetmeye başlayın"
                        )
                        .padding(.top, 60)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTransactionView(transactionType: .expense)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterView(filterOptions: $filterOptions)
        }
        .sheet(isPresented: $showingReceiptScanner) {
            ReceiptScannerView()
        }
    }
}

// Yeni işlem ekleme ekranı
struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager

    let transactionType: TransactionType

    @State private var title = ""
    @State private var amount: Double = 0
    @State private var selectedCategory: TransactionCategory = .other
    @State private var selectedCustomCategoryId: UUID? = nil
    @State private var date = Date()
    @State private var note = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var trackInCashFlow = false // Borç/alacak için nakit akışı takibi
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

                        DatePicker("Tarih", selection: $date, displayedComponents: .date)
                    }

                    // Nakit akışı takibi - Miktar girişinden hemen sonra
                    if transactionType == .debt || transactionType == .lent {
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $trackInCashFlow) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(transactionType == .debt ? "Gelir olarak da kaydet" : "Gider olarak da kaydet")
                                            .font(Theme.body)

                                        Text(transactionType == .debt ?
                                            "Para girişi olduğu için gelire eklensin mi?" :
                                            "Para çıkışı olduğu için gidere eklensin mi?")
                                            .font(Theme.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tint(.orange)

                                if trackInCashFlow {
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text(transactionType == .debt ?
                                            "Ödeme yaptığınızda gider olarak da kaydedilecek" :
                                            "Geri aldığınızda gelir olarak da kaydedilecek")
                                            .font(Theme.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        } header: {
                            Text("Nakit Akışı Takibi")
                        }
                    }

                    Section("Kategori") {
                        SmartCategoryPicker(
                            selectedStandardCategory: $selectedCategory,
                            selectedCustomCategoryId: $selectedCustomCategoryId
                        )
                    }

                    if transactionType == .debt || transactionType == .upcoming {
                        Section("Son Ödeme Tarihi") {
                            Toggle("Son ödeme tarihi var", isOn: $hasDueDate)

                            if hasDueDate {
                                DatePicker("Son tarih", selection: $dueDate, displayedComponents: .date)
                            }
                        }
                    }

                    Section("Not (Opsiyonel)") {
                        TextEditor(text: $note)
                            .frame(height: 100)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Yeni \(transactionType.rawValue)")
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
                        HapticManager.shared.success()
                        saveTransaction()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !title.isEmpty && amount > 0
    }

    private func saveTransaction() {
        guard amount > 0 else { return }

        // Borç/alacak işlemi oluştur
        let transaction = Transaction(
            title: title,
            amount: amount,
            type: transactionType,
            category: selectedCategory,
            date: date,
            note: note,
            isPaid: transactionType == .expense || transactionType == .income,
            dueDate: hasDueDate ? dueDate : nil,
            customCategoryId: selectedCustomCategoryId,
            trackedInCashFlow: (transactionType == .debt || transactionType == .lent) ? trackInCashFlow : nil
        )

        dataManager.addTransaction(transaction)

        // Eğer nakit akışı takibi aktifse, gelir/gider kaydı da oluştur
        if (transactionType == .debt || transactionType == .lent) && trackInCashFlow {
            let cashFlowTransaction = Transaction(
                title: title,
                amount: amount,
                type: transactionType == .debt ? .income : .expense,
                category: selectedCategory,
                date: date,
                note: transactionType == .debt ?
                    "Borç girişi: \(title)" :
                    "Borç verme: \(title)",
                isPaid: true,
                customCategoryId: selectedCustomCategoryId
            )
            dataManager.addTransaction(cashFlowTransaction)
        }

        dismiss()
    }
}

// İşlem detay ekranı
struct TransactionDetailView: View {
    let transaction: Transaction
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // İkon ve miktar
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(transaction.category.color.opacity(0.2))
                                    .frame(width: 100, height: 100)

                                Image(systemName: transaction.category.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(transaction.category.color)
                            }

                            Text(transaction.amount.toCurrency())
                                .font(Theme.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    transaction.type == .income
                                        ? Theme.successGradient
                                        : Theme.accentGradient
                                )
                        }
                        .padding(.top, 30)

                        // Bilgiler
                        VStack(spacing: 16) {
                            DetailRow(icon: "tag.fill", title: "Başlık", value: transaction.title)
                            DetailRow(icon: "folder.fill", title: "Kategori", value: transaction.category.rawValue)
                            DetailRow(icon: "calendar", title: "Tarih", value: transaction.date.toShortString())

                            if let dueDate = transaction.dueDate {
                                DetailRow(icon: "clock.fill", title: "Son Tarih", value: dueDate.toShortString())
                            }

                            if !transaction.note.isEmpty {
                                DetailRow(icon: "note.text", title: "Not", value: transaction.note)
                            }

                            DetailRow(
                                icon: transaction.isPaid ? "checkmark.circle.fill" : "xmark.circle.fill",
                                title: "Durum",
                                value: transaction.isPaid ? "Ödendi" : "Ödenmedi"
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle(transaction.type.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        HapticManager.shared.impact(style: .medium)
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .alert("Silmek istediğinizden emin misiniz?", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) {
                    HapticManager.shared.impact(style: .light)
                }
                Button("Sil", role: .destructive) {
                    HapticManager.shared.warning()
                    dataManager.deleteTransaction(transaction)
                    dismiss()
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(Theme.body)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .premiumCard()
    }
}

#Preview {
    ExpensesView()
        .environmentObject(DataManager.shared)
}
