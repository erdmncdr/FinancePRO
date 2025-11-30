//
//  UpcomingPaymentsView.swift
//  FinanceTracker
//
//  Gelecek ödemeler ekranı
//

import SwiftUI

struct UpcomingPaymentsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddSheet = false
    @State private var showingRecurringPayments = false
    @State private var selectedTransaction: Transaction?
    @State private var selectedPaymentType: PaymentType = .upcoming
    @State private var searchText = ""
    @State private var filterOptions = FilterOptions()
    @State private var showingFilterSheet = false
    @Environment(\.colorScheme) var colorScheme

    enum PaymentType: String, CaseIterable {
        case upcoming = "Tek Seferlik"
        case installments = "Taksitli"
        case recurring = "Düzenli Ödemeler"
    }

    private var upcomingPayments: [Transaction] {
        let allUpcoming = dataManager.getUpcomingPayments()

        // Filtre aktifse filtrele, değilse sadece arama yap
        if filterOptions.isActive {
            // Gelecek ödemeler için filtre
            let lowercasedQuery = searchText.lowercased()
            var result = allUpcoming

            // Arama
            if !searchText.isEmpty {
                result = result.filter { transaction in
                    transaction.title.lowercased().contains(lowercasedQuery) ||
                    transaction.note.lowercased().contains(lowercasedQuery) ||
                    transaction.category.rawValue.lowercased().contains(lowercasedQuery)
                }
            }

            // Kategori filtresi
            if !filterOptions.categories.isEmpty {
                result = result.filter { filterOptions.categories.contains($0.category) }
            }

            // Miktar filtresi
            if let minAmount = filterOptions.minAmount {
                result = result.filter { $0.amount >= minAmount }
            }
            if let maxAmount = filterOptions.maxAmount {
                result = result.filter { $0.amount <= maxAmount }
            }

            return result
        } else if !searchText.isEmpty {
            let lowercasedQuery = searchText.lowercased()
            return allUpcoming.filter { transaction in
                transaction.title.lowercased().contains(lowercasedQuery) ||
                transaction.note.lowercased().contains(lowercasedQuery) ||
                transaction.category.rawValue.lowercased().contains(lowercasedQuery)
            }
        } else {
            return allUpcoming
        }
    }

    private var totalUpcoming: Double {
        upcomingPayments.reduce(0) { $0 + $1.amount }
    }

    private var thisWeekPayments: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) ?? now

        return upcomingPayments.filter { transaction in
            guard let dueDate = transaction.dueDate else { return false }
            return dueDate >= now && dueDate <= weekFromNow
        }
    }

    private var thisWeekTotal: Double {
        thisWeekPayments.reduce(0) { $0 + $1.amount }
    }

    private var activeRecurringCount: Int {
        dataManager.recurringTransactions.filter { $0.isActive }.count
    }

    private var activeInstallmentCount: Int {
        dataManager.getActiveInstallmentPayments().count
    }

    private var searchPlaceholder: String {
        switch selectedPaymentType {
        case .upcoming:
            return "Ödeme ara..."
        case .installments:
            return "Taksit ara..."
        case .recurring:
            return "Tekrarlayan ödeme ara..."
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Başlık
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ödemeler")
                                .font(Theme.largeTitle)
                                .fontWeight(.bold)

                            if activeRecurringCount > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "repeat.circle.fill")
                                        .font(.system(size: 14))
                                    Text("\(activeRecurringCount) tekrarlayan ödeme aktif")
                                }
                                .font(Theme.caption)
                                .foregroundColor(.orange)
                            } else {
                                Text("Yaklaşan ödemeleriniz")
                                    .font(Theme.subheadline)
                                    .foregroundColor(.secondary)
                            }
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

                        // Ödeme ekle butonu
                        Button {
                            HapticManager.shared.impact(style: .medium)
                            showingAddSheet = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Theme.primaryGradient)
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color.blue.opacity(0.4), radius: 15, x: 0, y: 8)

                                Image(systemName: "plus")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)

                                // Tekrarlayan ödeme badge'i
                                if activeRecurringCount > 0 {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 20, height: 20)

                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 20, height: 20)

                                        Image(systemName: "repeat")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .offset(x: 20, y: -20)
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Arama çubuğu
                    SearchBar(text: $searchText, placeholder: searchPlaceholder)
                        .padding(.horizontal)

                    // Segmented Picker
                    Picker("Ödeme Tipi", selection: $selectedPaymentType) {
                        ForEach(PaymentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedPaymentType) { _, _ in
                        // Klavyeyi kapat
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        HapticManager.shared.selection()
                    }

                    // Özet kartları - seçime göre
                    switch selectedPaymentType {
                    case .upcoming:
                        HStack(spacing: 15) {
                            SummaryCard(
                                title: "Toplam",
                                amount: totalUpcoming,
                                icon: "calendar.badge.clock",
                                gradient: Theme.primaryGradient
                            )

                            SummaryCard(
                                title: "Bu Hafta",
                                amount: thisWeekTotal,
                                icon: "calendar.badge.exclamationmark",
                                gradient: LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        .padding(.horizontal)

                    case .installments:
                        HStack(spacing: 15) {
                            SummaryCard(
                                title: "Aktif",
                                amount: Double(activeInstallmentCount),
                                icon: "creditcard.fill",
                                gradient: LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                            SummaryCard(
                                title: "Toplam",
                                amount: Double(dataManager.installmentPayments.count),
                                icon: "list.bullet",
                                gradient: Theme.primaryGradient
                            )
                        }
                        .padding(.horizontal)

                    case .recurring:
                        HStack(spacing: 15) {
                            SummaryCard(
                                title: "Aktif",
                                amount: Double(activeRecurringCount),
                                icon: "repeat.circle.fill",
                                gradient: LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                            SummaryCard(
                                title: "Toplam",
                                amount: Double(dataManager.recurringTransactions.count),
                                icon: "list.bullet",
                                gradient: Theme.primaryGradient
                            )
                        }
                        .padding(.horizontal)
                    }

                    // İçerik - seçime göre
                    switch selectedPaymentType {
                    case .upcoming:
                        oneTimePaymentsList
                    case .installments:
                        installmentPaymentsList
                    case .recurring:
                        recurringPaymentsList
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            PaymentSelectionView()
        }
        .sheet(isPresented: $showingRecurringPayments) {
            RecurringPaymentsView()
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterView(filterOptions: $filterOptions)
        }
    }

    private func markAsPaid(_ transaction: Transaction) {
        HapticManager.shared.success()
        var updated = transaction
        updated.isPaid = true
        dataManager.updateTransaction(updated)
    }

    // MARK: - One-Time Payments List
    private var oneTimePaymentsList: some View {
        Group {
            // Bu haftaki ödemeler
            if !thisWeekPayments.isEmpty {
                VStack(spacing: 12) {
                    SectionHeader("Bu Hafta", icon: "exclamationmark.triangle.fill")

                    ForEach(thisWeekPayments) { transaction in
                        UpcomingPaymentCard(transaction: transaction) {
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

            // Diğer ödemeler
            let otherPayments = upcomingPayments.filter { !thisWeekPayments.contains($0) }
            if !otherPayments.isEmpty {
                VStack(spacing: 12) {
                    SectionHeader("Daha Sonra", icon: "calendar")

                    ForEach(otherPayments) { transaction in
                        UpcomingPaymentCard(transaction: transaction) {
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

            if upcomingPayments.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "Gelecek ödeme yok",
                    message: "Yaklaşan ödemeleriniz burada görünecek"
                )
                .padding(.top, 60)
            }
        }
    }

    // MARK: - Installment Payments List
    private var installmentPaymentsList: some View {
        Group {
            let activeInstallments = dataManager.getActiveInstallmentPayments()
            let completedInstallments = dataManager.getCompletedInstallmentPayments()

            // Aktif taksitli ödemeler
            if !activeInstallments.isEmpty {
                VStack(spacing: 12) {
                    SectionHeader("Aktif", icon: "creditcard.fill")

                    ForEach(activeInstallments) { payment in
                        NavigationLink(destination: InstallmentPaymentDetailView(payment: payment)) {
                            InstallmentPaymentListCard(payment: payment)
                                .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            // Tamamlanmış taksitli ödemeler
            if !completedInstallments.isEmpty {
                VStack(spacing: 12) {
                    SectionHeader("Tamamlandı", icon: "checkmark.circle.fill")

                    ForEach(completedInstallments) { payment in
                        NavigationLink(destination: InstallmentPaymentDetailView(payment: payment)) {
                            InstallmentPaymentListCard(payment: payment)
                                .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            if dataManager.installmentPayments.isEmpty {
                EmptyStateView(
                    icon: "creditcard",
                    title: "Taksitli ödeme yok",
                    message: "Taksitli ödemeleriniz burada görünecek"
                )
                .padding(.top, 60)
            }
        }
    }

    // MARK: - Recurring Payments List
    private var recurringPaymentsList: some View {
        Group {
            let activeRecurring = dataManager.recurringTransactions.filter { $0.isActive }
            let inactiveRecurring = dataManager.recurringTransactions.filter { !$0.isActive }

            // Aktif tekrarlayan ödemeler
            if !activeRecurring.isEmpty {
                VStack(spacing: 12) {
                    SectionHeader("Aktif", icon: "checkmark.circle.fill")

                    ForEach(activeRecurring) { recurring in
                        RecurringPaymentCard(recurring: recurring)
                            .padding(.horizontal)
                            .onTapGesture {
                                HapticManager.shared.impact(style: .light)
                                showingRecurringPayments = true
                            }
                    }
                }
            }

            // Pasif tekrarlayan ödemeler
            if !inactiveRecurring.isEmpty {
                VStack(spacing: 12) {
                    SectionHeader("Pasif", icon: "pause.circle.fill")

                    ForEach(inactiveRecurring) { recurring in
                        RecurringPaymentCard(recurring: recurring)
                            .padding(.horizontal)
                            .onTapGesture {
                                HapticManager.shared.impact(style: .light)
                                showingRecurringPayments = true
                            }
                    }
                }
            }

            if dataManager.recurringTransactions.isEmpty {
                EmptyStateView(
                    icon: "repeat.circle",
                    title: "Tekrarlayan ödeme yok",
                    message: "Tekrarlayan ödemeleriniz burada görünecek"
                )
                .padding(.top, 60)
            }
        }
    }
}

// Gelecek ödeme kartı
struct UpcomingPaymentCard: View {
    let transaction: Transaction
    let onMarkPaid: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var daysUntilDue: Int {
        guard let dueDate = transaction.dueDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day ?? 0
    }

    private var isUrgent: Bool {
        daysUntilDue <= 3 && daysUntilDue >= 0
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // İkon ve gün sayacı
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(isUrgent ? Color.red.opacity(0.2) : transaction.category.color.opacity(0.2))
                            .frame(width: 50, height: 50)

                        if isUrgent {
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: transaction.category.icon)
                                .font(.system(size: 22))
                                .foregroundColor(transaction.category.color)
                        }
                    }

                    Text("\(daysUntilDue) gün")
                        .font(Theme.caption)
                        .foregroundColor(isUrgent ? .red : .secondary)
                        .fontWeight(isUrgent ? .bold : .regular)
                }

                // Bilgiler
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(Theme.headline)
                        .foregroundColor(.primary)

                    Text(transaction.category.rawValue)
                        .font(Theme.caption)
                        .foregroundColor(.secondary)

                    if let dueDate = transaction.dueDate {
                        Label(dueDate.toShortString(), systemImage: "calendar")
                            .font(Theme.caption)
                            .foregroundColor(isUrgent ? .red : .orange)
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

                    Text("Ödendi")
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isUrgent ? Color.red.opacity(0.6) : Color(.systemGray).opacity(0.3), lineWidth: 2)
        )
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.08),
            radius: 15,
            x: 0,
            y: 5
        )
    }
}

// Ödeme tipi seçim ekranı
struct PaymentSelectionView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Fatura veya ödeme ekle")
                    .font(Theme.title3)
                    .multilineTextAlignment(.center)
                    .padding()

                VStack(spacing: 16) {
                    NavigationLink(destination: AddTransactionView(transactionType: .upcoming)) {
                        PaymentTypeCard(
                            title: "Tek Seferlik Ödeme",
                            description: "Bir kez ödenecek fatura",
                            icon: "doc.text.fill",
                            gradient: Theme.primaryGradient
                        )
                    }

                    NavigationLink(destination: AddInstallmentPaymentView()) {
                        PaymentTypeCard(
                            title: "Taksitli Ödeme",
                            description: "Aylık taksitlerle ödeme",
                            icon: "creditcard.fill",
                            gradient: LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }

                    NavigationLink(destination: RecurringPaymentsView()) {
                        PaymentTypeCard(
                            title: "Tekrarlayan Ödeme",
                            description: "Düzenli tekrar eden fatura",
                            icon: "repeat.circle.fill",
                            gradient: LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Ödeme Ekle")
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

// Ödeme tipi kartı
struct PaymentTypeCard: View {
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

// Installment Payment List Card
struct InstallmentPaymentListCard: View {
    let payment: InstallmentPayment
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 15) {
            // İkon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: payment.isCompleted ? [.green.opacity(0.3), .green.opacity(0.3)] : [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)

                if payment.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }

            // Bilgiler
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.title)
                    .font(Theme.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Text("\(payment.paidCount)/\(payment.installmentCount) taksit")
                        .font(Theme.caption)
                        .foregroundColor(.secondary)

                    if payment.isCompleted {
                        Text("• Tamamlandı")
                            .font(Theme.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("• Devam ediyor")
                            .font(Theme.caption)
                            .foregroundColor(.blue)
                    }
                }

                // İlerleme çubuğu
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray).opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: payment.isCompleted ? [.green, .green] : [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * (payment.progressPercentage / 100),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
            }

            Spacer()

            // Miktar bilgisi
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.totalAmount.toCurrency())
                    .font(Theme.headline)
                    .foregroundColor(payment.isCompleted ? .green : .purple)
                    .fontWeight(.bold)

                if !payment.isCompleted {
                    Text("Kalan: \(payment.remainingAmount.toCurrency())")
                        .font(Theme.caption)
                        .foregroundColor(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(payment.isCompleted ? Color.green.opacity(0.5) : Color.purple.opacity(0.5), lineWidth: 2)
        )
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.08),
            radius: 15,
            x: 0,
            y: 5
        )
    }
}

// Recurring Payment Card
struct RecurringPaymentCard: View {
    let recurring: RecurringTransaction
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 15) {
            // İkon
            ZStack {
                Circle()
                    .fill(recurring.isActive ? AnyShapeStyle(LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )) : AnyShapeStyle(Color(.systemGray).opacity(0.3)))
                    .frame(width: 50, height: 50)

                Image(systemName: "repeat")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            // Bilgiler
            VStack(alignment: .leading, spacing: 4) {
                Text(recurring.title)
                    .font(Theme.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Text(recurring.frequency.rawValue)
                        .font(Theme.caption)
                        .foregroundColor(.secondary)

                    if recurring.isActive {
                        Text("• Aktif")
                            .font(Theme.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("• Pasif")
                            .font(Theme.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            // Miktar
            Text(recurring.amount.toCurrency())
                .font(Theme.headline)
                .foregroundColor(recurring.isActive ? .orange : .gray)
                .fontWeight(.bold)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(recurring.isActive ? Color.orange.opacity(0.5) : Color(.systemGray).opacity(0.3), lineWidth: 2)
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
    UpcomingPaymentsView()
        .environmentObject(DataManager.shared)
}
