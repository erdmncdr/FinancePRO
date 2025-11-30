//
//  NotificationSettingsView.swift
//  FinansPro
//
//  Created by Claude on 30.11.2025.
//

import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var notificationManager = NotificationManager.shared
    @EnvironmentObject var dataManager: DataManager

    @State private var showingPermissionRequest = false
    @State private var pendingNotificationCount = 0

    var body: some View {
        NavigationView {
            Form {
                // Authorization Section
                Section {
                    if notificationManager.isAuthorized {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)

                            Text("Bildirimler Aktif")
                                .fontWeight(.medium)

                            Spacer()

                            Text("\(pendingNotificationCount) planlanmış")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bell.slash.fill")
                                    .foregroundColor(.orange)

                                Text("Bildirimler Kapalı")
                                    .fontWeight(.medium)
                            }

                            Text("Yaklaşan ödemelerinizi kaçırmamak için bildirimleri açın")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button(action: {
                                showingPermissionRequest = true
                            }) {
                                Text("İzin Ver")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Bildirim İzni")
                }

                // Recurring Payments
                Section {
                    Toggle("Tekrarlayan Ödemeler", isOn: $notificationManager.notificationSettings.recurringPaymentsEnabled)
                        .onChange(of: notificationManager.notificationSettings.recurringPaymentsEnabled) { _, _ in
                            notificationManager.saveSettings()
                            refreshNotifications()
                        }

                    if notificationManager.notificationSettings.recurringPaymentsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hatırlatma Zamanları")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ReminderDaysSelector(
                                selectedDays: $notificationManager.notificationSettings.recurringReminderDays
                            )
                            .onChange(of: notificationManager.notificationSettings.recurringReminderDays) { _, _ in
                                notificationManager.saveSettings()
                                refreshNotifications()
                            }
                        }
                    }
                } header: {
                    Text("Tekrarlayan Ödemeler")
                } footer: {
                    Text("Otomatik ödemeleriniz için hatırlatıcılar")
                }
                .disabled(!notificationManager.isAuthorized)

                // Installment Payments
                Section {
                    Toggle("Taksitli Ödemeler", isOn: $notificationManager.notificationSettings.installmentPaymentsEnabled)
                        .onChange(of: notificationManager.notificationSettings.installmentPaymentsEnabled) { _, _ in
                            notificationManager.saveSettings()
                            refreshNotifications()
                        }

                    if notificationManager.notificationSettings.installmentPaymentsEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hatırlatma Zamanları")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ReminderDaysSelector(
                                selectedDays: $notificationManager.notificationSettings.installmentReminderDays
                            )
                            .onChange(of: notificationManager.notificationSettings.installmentReminderDays) { _, _ in
                                notificationManager.saveSettings()
                                refreshNotifications()
                            }
                        }
                    }

                    Toggle("Vadesi Geçen Taksitler", isOn: $notificationManager.notificationSettings.overdueNotificationsEnabled)
                        .onChange(of: notificationManager.notificationSettings.overdueNotificationsEnabled) { _, _ in
                            notificationManager.saveSettings()
                            refreshNotifications()
                        }
                } header: {
                    Text("Taksitli Ödemeler")
                } footer: {
                    Text("Taksit ödemeleriniz için hatırlatıcılar")
                }
                .disabled(!notificationManager.isAuthorized)

                // Daily Summary
                Section {
                    Toggle("Günlük Özet", isOn: $notificationManager.notificationSettings.dailySummaryEnabled)
                        .onChange(of: notificationManager.notificationSettings.dailySummaryEnabled) { _, _ in
                            notificationManager.saveSettings()
                            notificationManager.scheduleDailySummary()
                        }

                    if notificationManager.notificationSettings.dailySummaryEnabled {
                        HStack {
                            Text("Bildirim Saati")
                            Spacer()

                            HStack(spacing: 4) {
                                Picker("Saat", selection: $notificationManager.notificationSettings.dailySummaryTime.hour) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(String(format: "%02d", hour)).tag(hour)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 60)

                                Text(":")

                                Picker("Dakika", selection: $notificationManager.notificationSettings.dailySummaryTime.minute) {
                                    ForEach([0, 15, 30, 45], id: \.self) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 60)
                            }
                        }
                        .onChange(of: notificationManager.notificationSettings.dailySummaryTime.hour) { _, _ in
                            notificationManager.saveSettings()
                            notificationManager.scheduleDailySummary()
                        }
                        .onChange(of: notificationManager.notificationSettings.dailySummaryTime.minute) { _, _ in
                            notificationManager.saveSettings()
                            notificationManager.scheduleDailySummary()
                        }
                    }
                } header: {
                    Text("Günlük Özet")
                } footer: {
                    Text("Her gün belirlediğiniz saatte harcama özeti bildirimi")
                }
                .disabled(!notificationManager.isAuthorized)

                // Actions
                Section {
                    Button(action: refreshNotifications) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Bildirimleri Yenile")
                        }
                    }

                    Button(action: {
                        notificationManager.clearAllNotifications()
                        updateNotificationCount()
                        HapticManager.shared.notification(type: .success)
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Tüm Bildirimleri Temizle")
                        }
                        .foregroundColor(.red)
                    }
                } footer: {
                    Text("Son güncelleme: \(Date().formatted(date: .abbreviated, time: .shortened))")
                }
                .disabled(!notificationManager.isAuthorized)
            }
            .navigationTitle("Bildirim Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            notificationManager.checkAuthorization()
            updateNotificationCount()
        }
        .sheet(isPresented: $showingPermissionRequest) {
            NotificationPermissionView()
        }
    }

    // MARK: - Helper Methods

    private func refreshNotifications() {
        guard notificationManager.isAuthorized else { return }

        notificationManager.scheduleAllNotifications(
            recurringPayments: dataManager.recurringTransactions,
            installmentPayments: dataManager.installmentPayments
        )

        // Güncellenmiş sayıyı getir
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateNotificationCount()
        }

        HapticManager.shared.notification(type: .success)
    }

    private func updateNotificationCount() {
        notificationManager.getPendingNotificationCount { count in
            pendingNotificationCount = count
        }
    }
}

// MARK: - Reminder Days Selector

struct ReminderDaysSelector: View {
    @Binding var selectedDays: [Int]

    let availableDays = [1, 3, 7, 14, 30]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(availableDays, id: \.self) { day in
                ReminderDayButton(
                    day: day,
                    isSelected: selectedDays.contains(day)
                ) {
                    if selectedDays.contains(day) {
                        selectedDays.removeAll { $0 == day }
                    } else {
                        selectedDays.append(day)
                        selectedDays.sort()
                    }
                }
            }
        }
    }
}

struct ReminderDayButton: View {
    let day: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(day)")
                    .fontWeight(.semibold)
                    .font(.subheadline)

                Text(day == 1 ? "gün" : "gün")
                    .font(.caption2)
            }
            .frame(width: 50, height: 50)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    NotificationSettingsView()
        .environmentObject(DataManager.shared)
}
