//
//  SmartCategoryPicker.swift
//  FinansPro
//
//  Akıllı kategori seçici - Hem varsayılan hem özel kategorileri destekler
//

import SwiftUI

struct SmartCategoryPicker: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var selectedStandardCategory: TransactionCategory
    @Binding var selectedCustomCategoryId: UUID?
    @State private var showingCategoryManager = false

    private var allCategories: [CategoryItem] {
        dataManager.getAllCategories()
    }

    private var selectedCategoryItem: CategoryItem {
        if let customId = selectedCustomCategoryId,
           let customCategory = dataManager.customCategories.first(where: { $0.id == customId }) {
            return .custom(customCategory)
        }
        return .standard(selectedStandardCategory)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Seçili kategori gösterimi
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(selectedCategoryItem.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: selectedCategoryItem.icon)
                        .font(.system(size: 18))
                        .foregroundColor(selectedCategoryItem.color)
                }

                Text(selectedCategoryItem.name)
                    .font(Theme.body)
                    .foregroundColor(.primary)

                Spacer()

                Text("Seçiniz")
                    .font(Theme.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.5))
            )

            // Kategori grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(allCategories, id: \.id) { item in
                    CategoryButton(
                        item: item,
                        isSelected: item.id == selectedCategoryItem.id
                    ) {
                        HapticManager.shared.selection()
                        selectCategory(item)
                    }
                }

                // Kategori yönetimi butonu
                Button {
                    HapticManager.shared.impact(style: .medium)
                    showingCategoryManager = true
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(height: 70)

                            VStack(spacing: 4) {
                                Image(systemName: "gear")
                                    .font(.system(size: 20))
                                    .foregroundStyle(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))

                                Text("Yönet")
                                    .font(Theme.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.top, 16)
            .sheet(isPresented: $showingCategoryManager) {
                CategoryManagerView()
            }
        }
    }

    private func selectCategory(_ item: CategoryItem) {
        switch item {
        case .standard(let category):
            selectedStandardCategory = category
            selectedCustomCategoryId = nil
        case .custom(let category):
            selectedCustomCategoryId = category.id
            // Keep standard category as fallback
        }
    }
}

struct CategoryButton: View {
    let item: CategoryItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? item.color.opacity(0.2) : Color(.systemGray6).opacity(0.5))
                        .frame(height: 70)

                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? item.color : .secondary)

                        Text(item.name)
                            .font(Theme.caption)
                            .foregroundColor(isSelected ? item.color : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, 4)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? item.color : Color.clear, lineWidth: 2)
                )
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedCategory: TransactionCategory = .food
        @State private var customCategoryId: UUID? = nil

        var body: some View {
            SmartCategoryPicker(
                selectedStandardCategory: $selectedCategory,
                selectedCustomCategoryId: $customCategoryId
            )
            .environmentObject(DataManager.shared)
            .padding()
        }
    }

    return PreviewWrapper()
}
