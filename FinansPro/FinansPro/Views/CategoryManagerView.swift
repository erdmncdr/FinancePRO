//
//  CategoryManagerView.swift
//  FinansPro
//
//  Kategori yönetimi ekranı
//

import SwiftUI

struct CategoryManagerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddCategory = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Bilgi kartı
                        InfoCard(
                            icon: "folder.badge.plus",
                            title: "Özel Kategoriler",
                            message: "Kendi kategorilerinizi oluşturun ve özelleştirin"
                        )
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // Varsayılan kategoriler
                        VStack(spacing: 12) {
                            SectionHeader("Varsayılan Kategoriler", icon: "folder.fill")

                            VStack(spacing: 8) {
                                ForEach(TransactionCategory.allCases, id: \.self) { category in
                                    DefaultCategoryRow(category: category)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // Özel kategoriler
                        if !dataManager.customCategories.isEmpty {
                            VStack(spacing: 12) {
                                SectionHeader("Özel Kategorilerim", icon: "star.fill")

                                VStack(spacing: 8) {
                                    ForEach(dataManager.customCategories) { category in
                                        CustomCategoryRow(category: category)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Kategoriler")
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
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCustomCategoryView()
            }
        }
    }
}

// Varsayılan kategori satırı (sadece gösterim)
struct DefaultCategoryRow: View {
    let category: TransactionCategory

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: category.icon)
                    .font(.system(size: 22))
                    .foregroundColor(category.color)
            }

            Text(category.rawValue)
                .font(Theme.headline)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .premiumCard()
        .opacity(0.8)
    }
}

// Özel kategori satırı (düzenlenebilir ve silinebilir)
struct CustomCategoryRow: View {
    let category: CustomCategory
    @EnvironmentObject var dataManager: DataManager
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: category.icon)
                    .font(.system(size: 22))
                    .foregroundColor(category.color)
            }

            Text(category.name)
                .font(Theme.headline)
                .foregroundColor(.primary)

            Spacer()

            // Düzenle butonu
            Button {
                HapticManager.shared.impact(style: .light)
                showingEditSheet = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }

            // Sil butonu
            Button {
                HapticManager.shared.impact(style: .light)
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
            }
        }
        .padding()
        .premiumCard()
        .sheet(isPresented: $showingEditSheet) {
            EditCustomCategoryView(category: category)
        }
        .alert("Kategoriyi Sil?", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {
                HapticManager.shared.impact(style: .light)
            }
            Button("Sil", role: .destructive) {
                HapticManager.shared.warning()
                dataManager.deleteCustomCategory(category)
            }
        } message: {
            Text("Bu kategoriyi kullanan tüm işlemler 'Diğer' kategorisine taşınacak.")
        }
    }
}

// Yeni kategori ekleme ekranı
struct AddCustomCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager

    @State private var categoryName = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor = Color.blue

    // Popüler ikonlar
    let icons = [
        "tag.fill", "star.fill", "heart.fill", "house.fill", "car.fill",
        "cart.fill", "bag.fill", "gift.fill", "creditcard.fill", "banknote.fill",
        "phone.fill", "gamecontroller.fill", "tv.fill", "laptopcomputer",
        "music.note", "camera.fill", "paintbrush.fill", "books.vertical.fill",
        "dumbbell.fill", "figure.walk", "pawprint.fill", "leaf.fill"
    ]

    let colors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow,
        .green, .mint, .teal, .cyan, .indigo, .brown, .gray
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Önizleme
                        VStack(spacing: 16) {
                            Text("Önizleme")
                                .font(Theme.caption)
                                .foregroundColor(.secondary)

                            ZStack {
                                Circle()
                                    .fill(selectedColor.opacity(0.2))
                                    .frame(width: 100, height: 100)

                                Image(systemName: selectedIcon)
                                    .font(.system(size: 40))
                                    .foregroundColor(selectedColor)
                            }

                            if !categoryName.isEmpty {
                                Text(categoryName)
                                    .font(Theme.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .glassEffect()
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // Kategori adı
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kategori Adı")
                                .font(Theme.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            TextField("Örn: Hobiler, Teknoloji, Pet...", text: $categoryName)
                                .font(Theme.body)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground).opacity(0.6))
                                )
                        }
                        .padding(.horizontal)

                        // İkon seçimi
                        VStack(alignment: .leading, spacing: 12) {
                            Text("İkon Seç")
                                .font(Theme.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                                ForEach(icons, id: \.self) { icon in
                                    IconSelectionButton(
                                        icon: icon,
                                        isSelected: selectedIcon == icon,
                                        color: selectedColor
                                    ) {
                                        HapticManager.shared.selection()
                                        selectedIcon = icon
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Renk seçimi
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Renk Seç")
                                .font(Theme.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                                ForEach(colors, id: \.self) { color in
                                    ColorSelectionButton(
                                        color: color,
                                        isSelected: selectedColor == color
                                    ) {
                                        HapticManager.shared.selection()
                                        selectedColor = color
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("Yeni Kategori")
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
                        saveCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
    }

    private func saveCategory() {
        HapticManager.shared.success()

        let category = CustomCategory(
            name: categoryName,
            iconName: selectedIcon,
            colorHex: selectedColor.toHex() ?? "#6B7280"
        )

        dataManager.addCustomCategory(category)
        dismiss()
    }
}

// Kategori düzenleme ekranı
struct EditCustomCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataManager: DataManager

    let category: CustomCategory
    @State private var categoryName = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor = Color.blue

    let icons = [
        "tag.fill", "star.fill", "heart.fill", "house.fill", "car.fill",
        "cart.fill", "bag.fill", "gift.fill", "creditcard.fill", "banknote.fill",
        "phone.fill", "gamecontroller.fill", "tv.fill", "laptopcomputer",
        "music.note", "camera.fill", "paintbrush.fill", "books.vertical.fill",
        "dumbbell.fill", "figure.walk", "pawprint.fill", "leaf.fill"
    ]

    let colors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow,
        .green, .mint, .teal, .cyan, .indigo, .brown, .gray
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Önizleme (AddCustomCategoryView ile aynı)
                        VStack(spacing: 16) {
                            Text("Önizleme")
                                .font(Theme.caption)
                                .foregroundColor(.secondary)

                            ZStack {
                                Circle()
                                    .fill(selectedColor.opacity(0.2))
                                    .frame(width: 100, height: 100)

                                Image(systemName: selectedIcon)
                                    .font(.system(size: 40))
                                    .foregroundColor(selectedColor)
                            }

                            if !categoryName.isEmpty {
                                Text(categoryName)
                                    .font(Theme.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .glassEffect()
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // Kategori adı
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kategori Adı")
                                .font(Theme.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            TextField("Kategori adı", text: $categoryName)
                                .font(Theme.body)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground).opacity(0.6))
                                )
                        }
                        .padding(.horizontal)

                        // İkon seçimi
                        VStack(alignment: .leading, spacing: 12) {
                            Text("İkon Seç")
                                .font(Theme.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                                ForEach(icons, id: \.self) { icon in
                                    IconSelectionButton(
                                        icon: icon,
                                        isSelected: selectedIcon == icon,
                                        color: selectedColor
                                    ) {
                                        HapticManager.shared.selection()
                                        selectedIcon = icon
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Renk seçimi
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Renk Seç")
                                .font(Theme.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                                ForEach(colors, id: \.self) { color in
                                    ColorSelectionButton(
                                        color: color,
                                        isSelected: selectedColor == color
                                    ) {
                                        HapticManager.shared.selection()
                                        selectedColor = color
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("Kategori Düzenle")
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
                        updateCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
            .onAppear {
                categoryName = category.name
                selectedIcon = category.iconName
                selectedColor = category.color
            }
        }
    }

    private func updateCategory() {
        HapticManager.shared.success()

        var updated = category
        updated.name = categoryName
        updated.iconName = selectedIcon
        updated.colorHex = selectedColor.toHex() ?? "#6B7280"

        dataManager.updateCustomCategory(updated)
        dismiss()
    }
}

// İkon seçim butonu
struct IconSelectionButton: View {
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.2) : Color(.systemGray6))
                    .frame(height: 60)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? color : .secondary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? color : Color.clear, lineWidth: 2)
        )
    }
}

// Renk seçim butonu
struct ColorSelectionButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(height: 50)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
        }
    }
}

// Bilgi kartı
struct InfoCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(Theme.primaryGradient)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.headline)
                    .foregroundColor(.primary)

                Text(message)
                    .font(Theme.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .glassEffect()
    }
}

#Preview {
    CategoryManagerView()
        .environmentObject(DataManager.shared)
}
