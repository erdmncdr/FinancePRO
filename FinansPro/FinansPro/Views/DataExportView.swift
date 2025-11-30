//
//  DataExportView.swift
//  FinansPro
//
//  Created by Claude on 30.11.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedExportType: ExportType = .csvAll
    @State private var selectedReportType: ReportType = .monthly
    @State private var selectedMonth = Date()
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Veri Dışa Aktarma")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("İşlemlerinizi CSV veya PDF formatında dışa aktarın")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Export Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dosya Formatı")
                            .font(.headline)

                        VStack(spacing: 10) {
                            ExportTypeButton(
                                icon: "tablecells",
                                title: "CSV - Tüm Veriler",
                                description: "Tüm işlemler, taksitler ve tekrarlayan ödemeler",
                                isSelected: selectedExportType == .csvAll
                            ) {
                                selectedExportType = .csvAll
                            }

                            ExportTypeButton(
                                icon: "list.bullet.rectangle",
                                title: "CSV - Sadece İşlemler",
                                description: "Tüm gelir ve gider işlemleri",
                                isSelected: selectedExportType == .csvTransactions
                            ) {
                                selectedExportType = .csvTransactions
                            }

                            ExportTypeButton(
                                icon: "calendar.badge.clock",
                                title: "CSV - Taksitli Ödemeler",
                                description: "Tüm taksitli ödeme planları",
                                isSelected: selectedExportType == .csvInstallments
                            ) {
                                selectedExportType = .csvInstallments
                            }

                            ExportTypeButton(
                                icon: "arrow.triangle.2.circlepath",
                                title: "CSV - Tekrarlayan Ödemeler",
                                description: "Tüm otomatik ödeme planları",
                                isSelected: selectedExportType == .csvRecurring
                            ) {
                                selectedExportType = .csvRecurring
                            }

                            Divider()
                                .padding(.vertical, 5)

                            ExportTypeButton(
                                icon: "doc.richtext",
                                title: "PDF Rapor",
                                description: "Görsel detaylı finansal rapor",
                                isSelected: selectedExportType == .pdf
                            ) {
                                selectedExportType = .pdf
                            }
                        }
                    }
                    .padding(.horizontal)

                    // PDF Report Options
                    if selectedExportType == .pdf {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rapor Dönemi")
                                .font(.headline)

                            VStack(spacing: 10) {
                                ReportTypeButton(
                                    title: "Aylık Rapor",
                                    icon: "calendar",
                                    isSelected: selectedReportType == .monthly
                                ) {
                                    selectedReportType = .monthly
                                }

                                if selectedReportType == .monthly {
                                    DatePicker("Ay Seçin", selection: $selectedMonth, displayedComponents: [.date])
                                        .datePickerStyle(.compact)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                }

                                ReportTypeButton(
                                    title: "Yıllık Rapor",
                                    icon: "calendar.badge.clock",
                                    isSelected: selectedReportType == .yearly
                                ) {
                                    selectedReportType = .yearly
                                }

                                if selectedReportType == .yearly {
                                    Picker("Yıl Seçin", selection: $selectedYear) {
                                        ForEach((2020...Calendar.current.component(.year, from: Date())), id: \.self) { year in
                                            Text("\(year)").tag(year)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .padding(.horizontal)
                                }

                                ReportTypeButton(
                                    title: "Özel Dönem",
                                    icon: "calendar.badge.plus",
                                    isSelected: selectedReportType == .custom
                                ) {
                                    selectedReportType = .custom
                                }

                                if selectedReportType == .custom {
                                    VStack(spacing: 10) {
                                        DatePicker("Başlangıç", selection: $customStartDate, displayedComponents: [.date])
                                            .datePickerStyle(.compact)

                                        DatePicker("Bitiş", selection: $customEndDate, displayedComponents: [.date])
                                            .datePickerStyle(.compact)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Export Button
                    Button(action: exportData) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title3)
                            }

                            Text(isExporting ? "Oluşturuluyor..." : "Dışa Aktar")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    .disabled(isExporting)
                    .padding(.horizontal)
                    .padding(.top, 10)

                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        Label("CSV dosyaları Excel'de açılabilir", systemImage: "info.circle")
                        Label("PDF raporlar detaylı analiz içerir", systemImage: "info.circle")
                        Label("Dosyalar paylaşıma hazır şekilde oluşturulur", systemImage: "info.circle")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Hata", isPresented: $showingError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Export Logic

    private func exportData() {
        isExporting = true

        DispatchQueue.global(qos: .userInitiated).async {
            let result: Result<URL, ExportError>

            switch selectedExportType {
            case .csvAll:
                result = DataExportManager.shared.exportAllDataToCSV(
                    transactions: dataManager.transactions,
                    installments: dataManager.installmentPayments,
                    recurringPayments: dataManager.recurringTransactions
                )

            case .csvTransactions:
                result = DataExportManager.shared.exportTransactionsToCSV(
                    transactions: dataManager.transactions
                )

            case .csvInstallments:
                result = DataExportManager.shared.exportInstallmentsToCSV(
                    installments: dataManager.installmentPayments
                )

            case .csvRecurring:
                result = DataExportManager.shared.exportRecurringPaymentsToCSV(
                    recurringPayments: dataManager.recurringTransactions
                )

            case .pdf:
                result = exportPDFReport()
            }

            DispatchQueue.main.async {
                isExporting = false

                switch result {
                case .success(let url):
                    exportedFileURL = url
                    showingShareSheet = true
                    HapticManager.shared.notification(type: .success)

                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                    HapticManager.shared.notification(type: .error)
                }
            }
        }
    }

    private func exportPDFReport() -> Result<URL, ExportError> {
        let filteredTransactions: [Transaction]

        switch selectedReportType {
        case .monthly:
            filteredTransactions = getTransactionsForMonth(selectedMonth)
            return PDFReportGenerator.shared.generateMonthlyReport(
                month: selectedMonth,
                transactions: filteredTransactions,
                installments: dataManager.installmentPayments,
                recurringPayments: dataManager.recurringTransactions
            )

        case .yearly:
            filteredTransactions = getTransactionsForYear(selectedYear)
            return PDFReportGenerator.shared.generateYearlyReport(
                year: selectedYear,
                transactions: filteredTransactions
            )

        case .custom:
            filteredTransactions = getTransactionsForPeriod(start: customStartDate, end: customEndDate)
            return PDFReportGenerator.shared.generateCustomReport(
                startDate: customStartDate,
                endDate: customEndDate,
                transactions: filteredTransactions
            )
        }
    }

    private func getTransactionsForMonth(_ date: Date) -> [Transaction] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)

        return dataManager.transactions.filter { transaction in
            let txComponents = calendar.dateComponents([.year, .month], from: transaction.date)
            return txComponents.year == components.year && txComponents.month == components.month
        }
    }

    private func getTransactionsForYear(_ year: Int) -> [Transaction] {
        let calendar = Calendar.current

        return dataManager.transactions.filter { transaction in
            let components = calendar.dateComponents([.year], from: transaction.date)
            return components.year == year
        }
    }

    private func getTransactionsForPeriod(start: Date, end: Date) -> [Transaction] {
        return dataManager.transactions.filter { transaction in
            transaction.date >= start && transaction.date <= end
        }
    }
}

// MARK: - Supporting Types

enum ExportType {
    case csvAll
    case csvTransactions
    case csvInstallments
    case csvRecurring
    case pdf
}

enum ReportType {
    case monthly
    case yearly
    case custom
}

// MARK: - Subviews

struct ExportTypeButton: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct ReportTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .white : .purple)

                Text(title)
                    .fontWeight(.medium)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.purple : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DataExportView()
        .environmentObject(DataManager.shared)
}
