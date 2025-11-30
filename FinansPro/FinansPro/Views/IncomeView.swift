//
//  IncomeView.swift
//  FinanceTracker
//
//  Gelirler ekranı
//

import SwiftUI

struct IncomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSheet = false
    @State private var selectedTransaction: Transaction?
    @State private var searchText = ""
    @State private var filterOptions = FilterOptions()
    @State private var showingFilterSheet = false
    @Environment(\.colorScheme) var colorScheme

    private var incomes: [Transaction] {
        let allIncomes = dataManager.getTransactions(ofType: .income)

        // Filtre aktifse filtrele, değilse sadece arama yap
        if filterOptions.isActive {
            var options = filterOptions
            // Sadece gelir tipini göster
            options.types = [.income]
            return dataManager.filterTransactions(searchQuery: searchText, filters: options)
        } else if !searchText.isEmpty {
            return dataManager.searchTransactions(query: searchText)
                .filter { $0.type == .income }
        } else {
            return allIncomes
        }
    }

    private var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }

    private var thisMonthIncome: Double {
        let calendar = Calendar.current
        let now = Date()

        return incomes.filter { transaction in
            calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var groupedIncomesByDay: [(date: Date, items: [Transaction])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: incomes) { (t: Transaction) -> Date in
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
                            Text("Gelirler")
                                .font(Theme.largeTitle)
                                .fontWeight(.bold)

                            Text("Kazançlarınızı takip edin")
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
                    SearchBar(text: $searchText, placeholder: "Gelir ara...")
                        .padding(.horizontal)

                    // Özet kartları
                    HStack(spacing: 15) {
                        SummaryCard(
                            title: "Toplam Gelir",
                            amount: totalIncome,
                            icon: "banknote.fill",
                            gradient: Theme.successGradient
                        )

                        SummaryCard(
                            title: "Bu Ay",
                            amount: thisMonthIncome,
                            icon: "calendar",
                            gradient: Theme.primaryGradient
                        )
                    }
                    .padding(.horizontal)

                    // Bakiye kartı
                    let summary = dataManager.getFinancialSummary()
                    BalanceCard(balance: summary.balance)
                        .padding(.horizontal)

                    // Tüm gelirler
                    if !incomes.isEmpty {
                        VStack(spacing: 12) {
                            SectionHeader("Gelir Geçmişi", icon: "clock.arrow.circlepath")

                            ForEach(groupedIncomesByDay, id: \.date) { section in
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
                            icon: "banknote",
                            title: "Henüz gelir yok",
                            message: "Kazançlarınızı kaydetmeye başlayın"
                        )
                        .padding(.top, 60)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTransactionView(transactionType: .income)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterView(filterOptions: $filterOptions)
        }
    }
}

// Bakiye kartı
struct BalanceCard: View {
    let balance: Double
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Net Bakiye")
                        .font(Theme.headline)
                        .foregroundColor(.secondary)

                    Text(balance.toCurrency())
                        .font(Theme.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(balance >= 0 ? Theme.successGradient : Theme.accentGradient)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(balance >= 0 ? Theme.successGradient : Theme.accentGradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                    Image(systemName: balance >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            if balance < 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("Giderleriniz gelirlerinizi aşıyor")
                        .font(Theme.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }
        }
        .padding(20)
        .glassEffect()
    }
}

#Preview {
    IncomeView()
        .environmentObject(DataManager.shared)
}
