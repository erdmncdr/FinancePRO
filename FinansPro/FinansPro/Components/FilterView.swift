//
//  FilterView.swift
//  FinansPro
//
//  Akıllı filtreleme komponenti
//

import SwiftUI

struct FilterView: View {
    @Binding var filterOptions: FilterOptions
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var selectedDateRange: DateRange?
    @State private var selectedCategories: Set<TransactionCategory> = []
    @State private var selectedTypes: Set<TransactionType> = []
    @State private var minAmountText = ""
    @State private var maxAmountText = ""
    @State private var isPaidFilter: Int = 0 // 0: Tümü, 1: Ödendi, 2: Ödenmedi

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Tarih Aralığı - Compact Grid
                        FilterSection(title: "Tarih", icon: "calendar") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach([DateRange.today, .thisWeek, .thisMonth, .last30Days, .last3Months, .thisYear], id: \.title) { range in
                                    CompactFilterChip(
                                        title: range.title,
                                        isSelected: selectedDateRange?.title == range.title
                                    ) {
                                        HapticManager.shared.selection()
                                        selectedDateRange = selectedDateRange?.title == range.title ? nil : range
                                    }
                                }
                            }
                        }

                        // İşlem Tipi - Horizontal Grid
                        FilterSection(title: "İşlem Tipi", icon: "arrow.left.arrow.right") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(TransactionType.allCases, id: \.self) { type in
                                    CompactFilterChip(
                                        title: type.rawValue,
                                        isSelected: selectedTypes.contains(type)
                                    ) {
                                        HapticManager.shared.selection()
                                        if selectedTypes.contains(type) {
                                            selectedTypes.remove(type)
                                        } else {
                                            selectedTypes.insert(type)
                                        }
                                    }
                                }
                            }
                        }

                        // Kategoriler - Wrap Layout
                        FilterSection(title: "Kategoriler", icon: "folder") {
                            FlowLayout(spacing: 8) {
                                ForEach(TransactionCategory.allCases, id: \.self) { category in
                                    CompactFilterChip(
                                        title: category.rawValue,
                                        icon: category.icon,
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        HapticManager.shared.selection()
                                        if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
                                    }
                                }
                            }
                        }

                        // Miktar ve Durum - Tek Satırda
                        HStack(spacing: 12) {
                            // Miktar Aralığı
                            FilterSection(title: "Miktar", icon: "turkishlirasign.circle") {
                                HStack(spacing: 8) {
                                    TextField("Min", text: $minAmountText)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 14))
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                                        )

                                    Text("-")
                                        .foregroundColor(.secondary)

                                    TextField("Max", text: $maxAmountText)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 14))
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                                        )
                                }
                            }
                        }

                        // Ödeme Durumu - Segmented Control
                        FilterSection(title: "Durum", icon: "checkmark.circle") {
                            Picker("", selection: $isPaidFilter) {
                                Text("Tümü").tag(0)
                                Text("Ödendi").tag(1)
                                Text("Ödenmedi").tag(2)
                            }
                            .pickerStyle(.segmented)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Sıfırla") {
                        HapticManager.shared.impact(style: .medium)
                        resetFilters()
                    }
                    .disabled(!hasActiveFilters)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Uygula") {
                        HapticManager.shared.success()
                        applyFilters()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentFilters()
            }
        }
    }

    private var hasActiveFilters: Bool {
        selectedDateRange != nil ||
        !selectedCategories.isEmpty ||
        !selectedTypes.isEmpty ||
        !minAmountText.isEmpty ||
        !maxAmountText.isEmpty ||
        isPaidFilter != 0
    }

    private func loadCurrentFilters() {
        selectedDateRange = filterOptions.dateRange
        selectedCategories = filterOptions.categories
        selectedTypes = filterOptions.types
        minAmountText = filterOptions.minAmount.map { String($0) } ?? ""
        maxAmountText = filterOptions.maxAmount.map { String($0) } ?? ""

        if let isPaid = filterOptions.isPaid {
            isPaidFilter = isPaid ? 1 : 2
        } else {
            isPaidFilter = 0
        }
    }

    private func applyFilters() {
        filterOptions.dateRange = selectedDateRange
        filterOptions.categories = selectedCategories
        filterOptions.types = selectedTypes
        filterOptions.minAmount = Double(minAmountText.replacingOccurrences(of: ",", with: "."))
        filterOptions.maxAmount = Double(maxAmountText.replacingOccurrences(of: ",", with: "."))
        filterOptions.isPaid = isPaidFilter == 0 ? nil : (isPaidFilter == 1)
    }

    private func resetFilters() {
        selectedDateRange = nil
        selectedCategories.removeAll()
        selectedTypes.removeAll()
        minAmountText = ""
        maxAmountText = ""
        isPaidFilter = 0
    }
}

// Filter Section
struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(Theme.headline)
                    .fontWeight(.semibold)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .premiumCard()
    }
}

// Compact Filter Chip
struct CompactFilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ?
                          AnyShapeStyle(Theme.primaryGradient) :
                          AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Flow Layout for wrapping views
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    FilterView(filterOptions: .constant(FilterOptions()))
}
