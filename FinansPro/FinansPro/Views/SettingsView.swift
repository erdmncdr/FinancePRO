//
//  SettingsView.swift
//  FinansPro
//
//  Ayarlar ekranı
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var biometricAuth: BiometricAuthManager
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appearanceManager: AppearanceManager

    @State private var showingCategoryManager = false
    @State private var showingRecurringPayments = false
    @State private var showingClearDataAlert = false
    @State private var showingNotificationSettings = false
    @State private var showingDataExport = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(colorScheme)
                    .ignoresSafeArea()

                List {
                    // Güvenlik
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: biometricAuth.biometricType().icon)
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.primaryGradient)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Biyometrik Kilit")
                                    .font(Theme.headline)

                                Text(biometricAuth.biometricType().name)
                                    .font(Theme.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $biometricAuth.isBiometricEnabled)
                                .labelsHidden()
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Güvenlik")
                    } footer: {
                        if biometricAuth.biometricType() != .none {
                            Text("Uygulama her açıldığında \(biometricAuth.biometricType().name) ile kimlik doğrulama yapılacak")
                        } else {
                            Text("Bu cihazda biyometrik kimlik doğrulama mevcut değil")
                        }
                    }

                    // Görünüm
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: appearanceManager.selectedAppearance.icon)
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.primaryGradient)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Görünüm")
                                    .font(Theme.headline)

                                Text(appearanceManager.selectedAppearance.displayName)
                                    .font(Theme.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Picker("", selection: $appearanceManager.selectedAppearance) {
                                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                    HStack {
                                        Image(systemName: mode.icon)
                                        Text(mode.displayName)
                                    }
                                    .tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Görünüm")
                    } footer: {
                        Text("Uygulamanın açık veya koyu modda görünmesini seçebilirsiniz")
                    }

                    // Yönetim
                    Section("Yönetim") {
                        // Kategoriler
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showingCategoryManager = true
                        } label: {
                            SettingsRow(
                                icon: "folder.fill",
                                title: "Kategoriler",
                                subtitle: "\(dataManager.customCategories.count) özel kategori",
                                color: .purple
                            )
                        }

                        // Tekrarlayan ödemeler
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showingRecurringPayments = true
                        } label: {
                            SettingsRow(
                                icon: "repeat.circle.fill",
                                title: "Tekrarlayan Ödemeler",
                                subtitle: "\(dataManager.recurringTransactions.count) ödeme",
                                color: .orange
                            )
                        }

                        // Bildirimler
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showingNotificationSettings = true
                        } label: {
                            SettingsRow(
                                icon: "bell.badge.fill",
                                title: "Bildirimler",
                                subtitle: "Ödeme hatırlatıcıları",
                                color: .blue
                            )
                        }

                        // Veri Dışa Aktarma
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showingDataExport = true
                        } label: {
                            SettingsRow(
                                icon: "square.and.arrow.up.fill",
                                title: "Veri Dışa Aktarma",
                                subtitle: "CSV ve PDF rapor",
                                color: .green
                            )
                        }
                    }

                    // Veri Yönetimi
                    Section {
                        Button(role: .destructive) {
                            HapticManager.shared.impact(style: .medium)
                            showingClearDataAlert = true
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.2))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tüm Verileri Sil")
                                        .font(Theme.headline)
                                        .foregroundColor(.red)

                                    Text("\(dataManager.transactions.count) işlem silinecek")
                                        .font(Theme.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("Veri Yönetimi")
                    } footer: {
                        Text("Tüm işlemler, kategoriler ve tekrarlayan ödemeler kalıcı olarak silinecektir. Bu işlem geri alınamaz!")
                    }

                    // Hakkında
                    Section("Uygulama") {
                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "Versiyon",
                            subtitle: "1.0.0",
                            color: .blue
                        )

                        SettingsRow(
                            icon: "star.fill",
                            title: "FinansPro",
                            subtitle: "Premium finans yönetimi",
                            color: .yellow
                        )
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCategoryManager) {
                CategoryManagerView()
            }
            .sheet(isPresented: $showingRecurringPayments) {
                RecurringPaymentsView()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showingDataExport) {
                DataExportView()
            }
            .alert("Tüm Verileri Sil?", isPresented: $showingClearDataAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    HapticManager.shared.warning()
                    dataManager.clearAllData()
                }
            } message: {
                Text("Bu işlem geri alınamaz! Tüm işlemler, kategoriler ve tekrarlayan ödemeler kalıcı olarak silinecektir.")
            }
        }
        .preferredColorScheme(appearanceManager.colorScheme)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(Theme.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SettingsView()
        .environmentObject(BiometricAuthManager.shared)
        .environmentObject(DataManager.shared)
        .environmentObject(AppearanceManager.shared)
}
