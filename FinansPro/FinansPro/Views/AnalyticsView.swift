//
//  AnalyticsView.swift
//  FinansPro
//
//  Detaylı grafik ve analiz ekranı
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedChartType: ChartType = .category

    enum TimePeriod: String, CaseIterable {
        case week = "Hafta"
        case month = "Ay"
        case year = "Yıl"
    }

    enum ChartType: String, CaseIterable {
        case category = "Kategoriler"
        case trend = "Trend"
        case comparison = "Karşılaştırma"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Başlık ve dönem seçici
                        headerSection

                        // Özet kartlar
                        summaryCards

                        // Grafik türü seçici
                        chartTypeSelector

                        // Ana grafik
                        mainChart

                        // Detaylı istatistikler
                        detailedStats

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Analiz & Grafikler")
                        .font(.system(size: 18, weight: .bold))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Button {
                        HapticManager.shared.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(selectedPeriod == period ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Group {
                                    if selectedPeriod == period {
                                        Theme.primaryGradient
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                            .cornerRadius(12)
                    }
                }
            }
            .padding(4)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }

    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 12) {
            // Toplam gelir
            StatCard(
                title: "Gelir",
                amount: totalIncome,
                icon: "arrow.down.circle.fill",
                color: .green
            )

            // Toplam gider
            StatCard(
                title: "Gider",
                amount: totalExpense,
                icon: "arrow.up.circle.fill",
                color: .red
            )

            // Net
            StatCard(
                title: "Net",
                amount: totalIncome - totalExpense,
                icon: netAmount >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                color: netAmount >= 0 ? .green : .red
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Chart Type Selector
    private var chartTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Button {
                        HapticManager.shared.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedChartType = type
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: iconForChartType(type))
                                .font(.system(size: 16))
                            Text(type.rawValue)
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(selectedChartType == type ? .white : .primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedChartType == type {
                                    Theme.primaryGradient
                                } else {
                                    Color.primary.opacity(0.1)
                                }
                            }
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Main Chart
    private var mainChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedChartType.rawValue)
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal)

            Group {
                switch selectedChartType {
                case .category:
                    categoryPieChart
                case .trend:
                    trendLineChart
                case .comparison:
                    comparisonBarChart
                }
            }
            .frame(height: 300)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }

    // MARK: - Category Pie Chart
    private var categoryPieChart: some View {
        VStack(spacing: 16) {
            if !categoryData.isEmpty {
                Chart(categoryData) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(8)
                }
                .chartLegend(position: .bottom, spacing: 8) {
                    // Custom legend with matching colors
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(categoryData.prefix(8)) { item in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 10, height: 10)
                                    Text(item.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // En yüksek harcama
                if let topCategory = categoryData.max(by: { $0.amount < $1.amount }) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(topCategory.color)
                        Text("En çok: \(topCategory.name)")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Text("₺\(topCategory.amount, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(topCategory.color)
                    }
                    .padding(.horizontal)
                }
            } else {
                EmptyChartView(message: "Bu dönemde veri yok")
            }
        }
    }

    // MARK: - Trend Line Chart
    private var trendLineChart: some View {
        VStack(spacing: 16) {
            if !trendData.isEmpty {
                Chart {
                    ForEach(trendData) { item in
                        LineMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Amount", item.income)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                        .symbol(.circle)

                        LineMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Amount", item.expense)
                        )
                        .foregroundStyle(.red)
                        .interpolationMethod(.catmullRom)
                        .symbol(.square)

                        AreaMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Amount", item.income)
                        )
                        .foregroundStyle(.green.opacity(0.1))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Amount", item.expense)
                        )
                        .foregroundStyle(.red.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedPeriod == .week ? 1 : 7))
                }
                .chartLegend(position: .top)

                // Trend bilgisi
                HStack {
                    VStack(alignment: .leading) {
                        Text("Ortalama Günlük")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("↓ ₺\(averageDailyIncome, specifier: "%.0f")")
                                .foregroundColor(.green)
                            Text("↑ ₺\(averageDailyExpense, specifier: "%.0f")")
                                .foregroundColor(.red)
                        }
                        .font(.system(size: 14, weight: .semibold))
                    }
                    Spacer()
                }
                .padding(.horizontal)
            } else {
                EmptyChartView(message: "Bu dönemde veri yok")
            }
        }
    }

    // MARK: - Comparison Bar Chart
    private var comparisonBarChart: some View {
        VStack(spacing: 16) {
            if !comparisonData.isEmpty {
                Chart(comparisonData) { item in
                    BarMark(
                        x: .value("Period", item.label),
                        y: .value("Income", item.income)
                    )
                    .foregroundStyle(.green)
                    .cornerRadius(8)

                    BarMark(
                        x: .value("Period", item.label),
                        y: .value("Expense", -item.expense)
                    )
                    .foregroundStyle(.red)
                    .cornerRadius(8)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartLegend(position: .top)

                // Toplam bilgi
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dönem Toplamı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            Text("Gelir: ₺\(totalIncome, specifier: "%.0f")")
                                .foregroundColor(.green)
                            Text("Gider: ₺\(totalExpense, specifier: "%.0f")")
                                .foregroundColor(.red)
                        }
                        .font(.system(size: 13, weight: .semibold))
                    }
                    Spacer()
                }
                .padding(.horizontal)
            } else {
                EmptyChartView(message: "Bu dönemde veri yok")
            }
        }
    }

    // MARK: - Detailed Stats
    private var detailedStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detaylı İstatistikler")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal)

            VStack(spacing: 12) {
                // Kategori bazlı detay
                ForEach(categoryData.prefix(5)) { item in
                    CategoryStatRow(
                        name: item.name,
                        amount: item.amount,
                        percentage: (item.amount / totalExpense) * 100,
                        color: item.color
                    )
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.horizontal)

            // Ek istatistikler
            VStack(spacing: 12) {
                StatisticRow(icon: "chart.line.uptrend.xyaxis", title: "En yüksek gider günü", value: highestExpenseDay)
                StatisticRow(icon: "calendar", title: "İşlem sayısı", value: "\(transactionCount) işlem")
                StatisticRow(icon: "percent", title: "Tasarruf oranı", value: String(format: "%%%.1f", savingsRate))
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding(.horizontal)
        }
    }

    // MARK: - Helper Functions
    private func iconForChartType(_ type: ChartType) -> String {
        switch type {
        case .category: return "chart.pie.fill"
        case .trend: return "chart.xyaxis.line"
        case .comparison: return "chart.bar.fill"
        }
    }

    // MARK: - Data Computed Properties
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        return dataManager.transactions.filter { $0.date >= startDate && $0.date <= now }
    }

    private var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var netAmount: Double {
        totalIncome - totalExpense
    }

    private var categoryData: [CategoryChartData] {
        let expenses = filteredTransactions.filter { $0.type == .expense }
        var categoryDict: [String: Double] = [:]

        for transaction in expenses {
            let name = transaction.customCategoryId != nil ?
                (dataManager.customCategories.first { $0.id == transaction.customCategoryId }?.name ?? transaction.category.rawValue) :
                transaction.category.rawValue
            categoryDict[name, default: 0] += transaction.amount
        }

        return categoryDict.map { CategoryChartData(name: $0.key, amount: $0.value, colorIndex: 0) }
            .sorted { $0.amount > $1.amount }
            .enumerated()
            .map { CategoryChartData(name: $1.name, amount: $1.amount, colorIndex: $0) }
    }

    private var trendData: [TrendChartData] {
        let calendar = Calendar.current
        let now = Date()

        let days: Int
        switch selectedPeriod {
        case .week: days = 7
        case .month: days = 30
        case .year: days = 365
        }

        var result: [TrendChartData] = []

        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -days + i + 1, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

            let dayTransactions = filteredTransactions.filter { $0.date >= startOfDay && $0.date < endOfDay }
            let income = dayTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = dayTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

            result.append(TrendChartData(date: startOfDay, income: income, expense: expense))
        }

        return result
    }

    private var comparisonData: [ComparisonChartData] {
        let calendar = Calendar.current
        let now = Date()

        var result: [ComparisonChartData] = []

        switch selectedPeriod {
        case .week:
            for i in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -6 + i, to: now) else { continue }
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

                let dayTransactions = filteredTransactions.filter { $0.date >= startOfDay && $0.date < endOfDay }
                let income = dayTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = dayTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
                formatter.locale = Locale(identifier: "tr_TR")

                result.append(ComparisonChartData(label: formatter.string(from: date), income: income, expense: expense))
            }
        case .month:
            for i in 0..<4 {
                guard let date = calendar.date(byAdding: .weekOfYear, value: -3 + i, to: now) else { continue }
                let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? startOfWeek

                let weekTransactions = filteredTransactions.filter { $0.date >= startOfWeek && $0.date < endOfWeek }
                let income = weekTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = weekTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                result.append(ComparisonChartData(label: "Hafta \(i+1)", income: income, expense: expense))
            }
        case .year:
            for i in 0..<12 {
                guard let date = calendar.date(byAdding: .month, value: -11 + i, to: now) else { continue }
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? startOfMonth

                let monthTransactions = filteredTransactions.filter { $0.date >= startOfMonth && $0.date < endOfMonth }
                let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                formatter.locale = Locale(identifier: "tr_TR")

                result.append(ComparisonChartData(label: formatter.string(from: date), income: income, expense: expense))
            }
        }

        return result
    }

    private var averageDailyIncome: Double {
        let days = selectedPeriod == .week ? 7 : (selectedPeriod == .month ? 30 : 365)
        return totalIncome / Double(days)
    }

    private var averageDailyExpense: Double {
        let days = selectedPeriod == .week ? 7 : (selectedPeriod == .month ? 30 : 365)
        return totalExpense / Double(days)
    }

    private var transactionCount: Int {
        filteredTransactions.count
    }

    private var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return ((totalIncome - totalExpense) / totalIncome) * 100
    }

    private var highestExpenseDay: String {
        let calendar = Calendar.current
        var dayExpenses: [Date: Double] = [:]

        for transaction in filteredTransactions where transaction.type == .expense {
            let day = calendar.startOfDay(for: transaction.date)
            dayExpenses[day, default: 0] += transaction.amount
        }

        guard let maxDay = dayExpenses.max(by: { $0.value < $1.value }) else {
            return "Veri yok"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")

        return "\(formatter.string(from: maxDay.key)) (₺\(String(format: "%.0f", maxDay.value)))"
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("₺\(amount, specifier: "%.0f")")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct CategoryStatRow: View {
    let name: String
    let amount: Double
    let percentage: Double
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                ProgressView(value: percentage / 100)
                    .tint(color)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("₺\(amount, specifier: "%.0f")")
                    .font(.system(size: 14, weight: .bold))
                Text("%\(percentage, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StatisticRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
    }
}

struct EmptyChartView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Chart Data Models

struct CategoryChartData: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let colorIndex: Int

    var color: Color {
        let colors: [Color] = [
            .blue, .purple, .pink, .orange, .green,
            .red, .yellow, .teal, .cyan, .indigo,
            .mint, .brown
        ]
        return colors[colorIndex % colors.count]
    }
}

struct TrendChartData: Identifiable {
    let id = UUID()
    let date: Date
    let income: Double
    let expense: Double
}

struct ComparisonChartData: Identifiable {
    let id = UUID()
    let label: String
    let income: Double
    let expense: Double
}

#Preview {
    AnalyticsView()
        .environmentObject(DataManager.shared)
}
