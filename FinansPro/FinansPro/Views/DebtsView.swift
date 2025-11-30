//
//  DebtsView.swift
//  FinanceTracker
//
//  Borçlar ekranı - Hem bizim borçlarımız hem de verdiğimiz borçlar
//

import SwiftUI

struct DebtsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSheet = false
    @State private var selectedTransaction: Transaction?
    @State private var selectedDebtType: DebtType = .owed
    @State private var searchText = ""
    @State private var filterOptions = FilterOptions()
    @State private var showingFilterSheet = false
    @State private var showingPaymentConfirmation = false
    @State private var transactionToMark: Transaction?
    @Environment(\.colorScheme) var colorScheme

    enum DebtType: String, CaseIterable {
        case owed = "Borçlarım"
        case lent = "Alacaklarım"
    }

    // Bizim borçlarımız
    private var debts: [Transaction] {
        let allDebts = dataManager.getTransactions(ofType: .debt)

        // Filtre aktifse filtrele, değilse sadece arama yap
        if filterOptions.isActive {
            var options = filterOptions
            options.types = [.debt]
            return dataManager.filterTransactions(searchQuery: searchText, filters: options)
        } else if !searchText.isEmpty {
            return dataManager.searchTransactions(query: searchText)
                .filter { $0.type == .debt }
        } else {
            return allDebts
        }
    }

    private var unpaidDebts: [Transaction] {
        debts.filter { !$0.isPaid }
    }

    private var paidDebts: [Transaction] {
        debts.filter { $0.isPaid }
    }

    private var totalUnpaidDebts: Double {
        unpaidDebts.reduce(0) { $0 + $1.amount }
    }

    // Verilen borçlar
    private var lentMoney: [Transaction] {
        let allLent = dataManager.getTransactions(ofType: .lent)

        // Filtre aktifse filtrele, değilse sadece arama yap
        if filterOptions.isActive {
            var options = filterOptions
            options.types = [.lent]
            return dataManager.filterTransactions(searchQuery: searchText, filters: options)
        } else if !searchText.isEmpty {
            return dataManager.searchTransactions(query: searchText)
                .filter { $0.type == .lent }
        } else {
            return allLent
        }
    }

    private var unpaidLent: [Transaction] {
        lentMoney.filter { !$0.isPaid }
    }

    private var paidLent: [Transaction] {
        lentMoney.filter { $0.isPaid }
    }

    private var totalUnpaidLent: Double {
        unpaidLent.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Başlık
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Borçlar")
                                .font(Theme.largeTitle)
                                .fontWeight(.bold)

                            Text("Borç takibi ve yönetimi")
                                .font(Theme.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

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
                    SearchBar(text: $searchText, placeholder: selectedDebtType == .owed ? "Borç ara..." : "Alacak ara...")
                        .padding(.horizontal)

                    // Segmented Picker
                    Picker("Borç Tipi", selection: $selectedDebtType) {
                        ForEach(DebtType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedDebtType) { _, _ in
                        HapticManager.shared.selection()
                    }

                    // Özet kartları
                    HStack(spacing: 15) {
                        if selectedDebtType == .owed {
                            SummaryCard(
                                title: "Ödenmemiş",
                                amount: totalUnpaidDebts,
                                icon: "exclamationmark.triangle.fill",
                                gradient: LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                            SummaryCard(
                                title: "Toplam Borç",
                                amount: debts.reduce(0) { $0 + $1.amount },
                                icon: "creditcard.fill",
                                gradient: Theme.accentGradient
                            )
                        } else {
                            SummaryCard(
                                title: "Tahsil Edilecek",
                                amount: totalUnpaidLent,
                                icon: "arrow.down.circle.fill",
                                gradient: Theme.successGradient
                            )

                            SummaryCard(
                                title: "Toplam Alacak",
                                amount: lentMoney.reduce(0) { $0 + $1.amount },
                                icon: "dollarsign.circle.fill",
                                gradient: Theme.primaryGradient
                            )
                        }
                    }
                    .padding(.horizontal)

                    // İçerik
                    if selectedDebtType == .owed {
                        debtsList
                    } else {
                        lentList
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            DebtSelectionView(selectedType: selectedDebtType)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterView(filterOptions: $filterOptions)
        }
        .alert(transactionToMark?.type == .debt ? "Borç Ödeme" : "Alacak Tahsilat", isPresented: $showingPaymentConfirmation) {
            Button("Sadece İşaretle", role: .cancel) {
                confirmPayment(createTransaction: false)
            }
            Button(transactionToMark?.type == .debt ? "Gider Olarak Kaydet" : "Gelir Olarak Kaydet") {
                confirmPayment(createTransaction: true)
            }
        } message: {
            if transactionToMark?.type == .debt {
                Text("Bu ödemeyi gider olarak da kaydetmek ister misiniz?\n\n₺\(transactionToMark?.amount ?? 0, specifier: "%.2f") tutarında gider kaydı oluşturulacak.")
            } else {
                Text("Bu tahsilatı gelir olarak da kaydetmek ister misiniz?\n\n₺\(transactionToMark?.amount ?? 0, specifier: "%.2f") tutarında gelir kaydı oluşturulacak.")
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedDebtType)
    }

    // Bizim borçlarımız listesi
    private var debtsList: some View {
        Group {
            // Ödenmemiş borçlar
            if !unpaidDebts.isEmpty {
                VStack(spacing: 12) {
                    SectionHeader("Ödenmesi Gerekenler", icon: "exclamationmark.circle.fill")

                    ForEach(unpaidDebts) { transaction in
                        DebtCard(transaction: transaction) {
                            markAsPaid(transaction)
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            HapticManager.shared.impact(style: .light)
                            selectedTransaction = transaction
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
            }

            // Ödenen borçlar
            if !paidDebts.isEmpty {
                VStack(spacing: 12) {
                    SectionHeader("Ödenenler", icon: "checkmark.circle")

                    ForEach(paidDebts) { transaction in
                        TransactionCard(transaction: transaction)
                            .padding(.horizontal)
                            .opacity(0.7)
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

            if debts.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "Harika! Borcunuz yok",
                    message: "Finansal durumunuz iyi görünüyor"
                )
                .padding(.top, 60)
            }
        }
    }

    // Verilen borçlar listesi
    private var lentList: some View {
        Group {
            // Geri ödenmemiş
            if !unpaidLent.isEmpty {
                VStack(spacing: 12) {
                    SectionHeader("Tahsil Edilecekler", icon: "arrow.down.circle.fill")

                    ForEach(unpaidLent) { transaction in
                        LentCard(transaction: transaction) {
                            markAsPaid(transaction)
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            HapticManager.shared.impact(style: .light)
                            selectedTransaction = transaction
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
            }

            // Geri ödenenler
            if !paidLent.isEmpty {
                VStack(spacing: 12) {
                    SectionHeader("Geri Ödenenler", icon: "checkmark.circle")

                    ForEach(paidLent) { transaction in
                        TransactionCard(transaction: transaction)
                            .padding(.horizontal)
                            .opacity(0.7)
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

            if lentMoney.isEmpty {
                EmptyStateView(
                    icon: "dollarsign.circle",
                    title: "Henüz alacağınız yok",
                    message: "Alacaklarınız burada görünecek"
                )
                .padding(.top, 60)
            }
        }
    }

    private func markAsPaid(_ transaction: Transaction) {
        transactionToMark = transaction
        showingPaymentConfirmation = true
    }

    private func confirmPayment(createTransaction: Bool) {
        guard let transaction = transactionToMark else { return }

        HapticManager.shared.success()
        var updated = transaction
        updated.isPaid = true
        dataManager.updateTransaction(updated)

        // Gelir/gider kaydı oluştur
        // Eğer nakit akışı takibi yapıldıysa (trackedInCashFlow == true),
        // otomatik olarak gelir/gider kaydı oluştur
        // Yapılmadıysa, kullanıcıya sor (createTransaction parametresi)
        let shouldCreateTransaction = transaction.trackedInCashFlow == true || createTransaction

        if shouldCreateTransaction {
            let newTransaction = Transaction(
                title: transaction.title,
                amount: transaction.amount,
                type: transaction.type == .debt ? .expense : .income,
                category: transaction.category,
                date: Date(),
                note: transaction.type == .debt ?
                    "Borç ödemesi: \(transaction.title)" :
                    "Alacak tahsilatı: \(transaction.title)",
                isPaid: true,
                customCategoryId: transaction.customCategoryId
            )
            dataManager.addTransaction(newTransaction)
        }

        transactionToMark = nil
    }
}

// Borç seçim ekranı
struct DebtSelectionView: View {
    @Environment(\.dismiss) var dismiss
    let selectedType: DebtsView.DebtType

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Hangi tip borç eklemek istersiniz?")
                    .font(Theme.title3)
                    .multilineTextAlignment(.center)
                    .padding()

                VStack(spacing: 16) {
                    NavigationLink(destination: AddTransactionView(transactionType: .debt)) {
                        DebtTypeCard(
                            title: "Borç Aldım",
                            description: "",
                            icon: "creditcard.fill",
                            gradient: LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }

                    NavigationLink(destination: AddTransactionView(transactionType: .lent)) {
                        DebtTypeCard(
                            title: "Borç Verdim",
                            description: "",
                            icon: "dollarsign.circle.fill",
                            gradient: Theme.successGradient
                        )
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Borç Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Borç tipi kartı
struct DebtTypeCard: View {
    let title: String
    let description: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.headline)
                    .foregroundColor(.primary)

                if !description.isEmpty {
                    Text(description)
                        .font(Theme.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .premiumCard()
    }
}

// Verilen borç kartı
struct LentCard: View {
    let transaction: Transaction
    let onMarkPaid: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // İkon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                }

                // Bilgiler
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(Theme.headline)
                        .foregroundColor(.primary)

                    if let dueDate = transaction.dueDate {
                        Label(dueDate.toRelativeString(), systemImage: "clock.fill")
                            .font(Theme.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                // Miktar
                Text(transaction.amount.toCurrency())
                    .font(Theme.headline)
                    .foregroundColor(.green)
                    .fontWeight(.bold)
            }
            .padding()

            // Ödendi butonu
            Button(action: {
                HapticManager.shared.impact(style: .medium)
                onMarkPaid()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))

                    Text("Tahsil Edildi")
                        .font(Theme.callout)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.successGradient)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green.opacity(0.5), lineWidth: 2)
        )
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.08),
            radius: 15,
            x: 0,
            y: 5
        )
    }
}

// Borç kartı - Ödeme butonu ile
struct DebtCard: View {
    let transaction: Transaction
    let onMarkPaid: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // İkon
                ZStack {
                    Circle()
                        .fill(transaction.category.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: transaction.category.icon)
                        .font(.system(size: 22))
                        .foregroundColor(transaction.category.color)
                }

                // Bilgiler
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(Theme.headline)
                        .foregroundColor(.primary)

                    if let dueDate = transaction.dueDate {
                        Label(dueDate.toRelativeString(), systemImage: "clock.fill")
                            .font(Theme.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                // Miktar
                Text(transaction.amount.toCurrency())
                    .font(Theme.headline)
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
            .padding()

            // Ödeme butonu
            Button(action: {
                HapticManager.shared.impact(style: .medium)
                onMarkPaid()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))

                    Text("Ödendi Olarak İşaretle")
                        .font(Theme.callout)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.successGradient)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange.opacity(0.5), lineWidth: 2)
        )
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.08),
            radius: 15,
            x: 0,
            y: 5
        )
    }
}

#Preview {
    DebtsView()
        .environmentObject(DataManager.shared)
}
