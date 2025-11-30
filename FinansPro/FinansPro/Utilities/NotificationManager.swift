//
//  NotificationManager.swift
//  FinanceTracker
//
//  Bildirim yönetimi - Gelecek ödemeler için hatırlatıcılar
//

import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var notificationSettings = NotificationSettings()

    private init() {
        checkAuthorization()
        loadSettings()
    }

    // Bildirim izni kontrolü
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // Bildirim izni iste
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])

            DispatchQueue.main.async {
                self.isAuthorized = granted
            }

            return granted
        } catch {
            print("Bildirim izni hatası: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Settings Management

    /// Bildirim ayarlarını yükler
    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "notificationSettings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.notificationSettings = settings
        }
    }

    /// Bildirim ayarlarını kaydeder
    func saveSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            UserDefaults.standard.set(data, forKey: "notificationSettings")
        }
    }

    // Tüm bildirimleri temizle
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // Gelecek ödemeler için bildirim planla
    func scheduleNotifications(for transactions: [Transaction]) {
        // Önce mevcut bildirimleri temizle
        clearAllNotifications()

        guard isAuthorized else {
            print("Bildirim izni verilmemiş")
            return
        }

        _ = Calendar.current
        let now = Date()

        for transaction in transactions {
            guard let dueDate = transaction.dueDate, !transaction.isPaid else {
                continue
            }

            // Sadece gelecekteki tarihlere bildirim oluştur
            guard dueDate > now else { continue }

            // 3 farklı bildirim zamanı: 3 gün önce, 1 gün önce, ödeme günü
            scheduleNotification(
                for: transaction,
                on: dueDate,
                daysBefore: 3,
                title: "Yaklaşan Ödeme",
                body: "\(transaction.title) - 3 gün içinde: \(transaction.amount.toCurrency())"
            )

            scheduleNotification(
                for: transaction,
                on: dueDate,
                daysBefore: 1,
                title: "Yarın Ödeme Var!",
                body: "\(transaction.title) - \(transaction.amount.toCurrency())"
            )

            scheduleNotification(
                for: transaction,
                on: dueDate,
                daysBefore: 0,
                title: "Bugün Ödeme Günü!",
                body: "\(transaction.title) - \(transaction.amount.toCurrency()) ödenmeli"
            )
        }
    }

    // Belirli bir işlem için bildirim planla
    private func scheduleNotification(
        for transaction: Transaction,
        on dueDate: Date,
        daysBefore days: Int,
        title: String,
        body: String
    ) {
        let calendar = Calendar.current
        guard let notificationDate = calendar.date(byAdding: .day, value: -days, to: dueDate) else {
            return
        }

        // Geçmiş tarihlere bildirim oluşturma
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        // Kategori bilgisi ekle
        content.categoryIdentifier = "PAYMENT_REMINDER"
        content.userInfo = [
            "transactionId": transaction.id.uuidString,
            "amount": transaction.amount,
            "type": transaction.type.rawValue
        ]

        // Bildirim zamanını ayarla (sabah 9:00)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // Benzersiz identifier oluştur
        let identifier = "\(transaction.id.uuidString)-\(days)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim ekleme hatası: \(error.localizedDescription)")
            } else {
                print("Bildirim planlandı: \(title) - \(notificationDate)")
            }
        }
    }

    // Acil ödemeler için anında bildirim
    func sendImmediateNotification(for transaction: Transaction) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Acil Ödeme!"
        content.body = "\(transaction.title) - \(transaction.amount.toCurrency()) bugün ödenmeli!"
        content.sound = .defaultCritical
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // Taksit ödemeleri için bildirim planla
    func scheduleInstallmentNotification(
        paymentTitle: String,
        installmentNumber: Int,
        amount: Double,
        dueDate: Date
    ) {
        guard isAuthorized else { return }

        let calendar = Calendar.current
        let now = Date()

        // Sadece gelecekteki tarihlere bildirim oluştur
        guard dueDate > now else { return }

        // 3 gün önce bildirim
        if let threeDaysBefore = calendar.date(byAdding: .day, value: -3, to: dueDate),
           threeDaysBefore > now {
            scheduleInstallmentNotificationAt(
                date: threeDaysBefore,
                title: "Yaklaşan Taksit",
                body: "\(paymentTitle) - \(installmentNumber). taksit 3 gün içinde: \(amount.toCurrency())",
                identifier: "installment-3-\(installmentNumber)-\(UUID().uuidString)"
            )
        }

        // 1 gün önce bildirim
        if let oneDayBefore = calendar.date(byAdding: .day, value: -1, to: dueDate),
           oneDayBefore > now {
            scheduleInstallmentNotificationAt(
                date: oneDayBefore,
                title: "Yarın Taksit Var!",
                body: "\(paymentTitle) - \(installmentNumber). taksit: \(amount.toCurrency())",
                identifier: "installment-1-\(installmentNumber)-\(UUID().uuidString)"
            )
        }

        // Taksit günü bildirim
        if dueDate > now {
            scheduleInstallmentNotificationAt(
                date: dueDate,
                title: "Bugün Taksit Günü!",
                body: "\(paymentTitle) - \(installmentNumber). taksit ödenmeli: \(amount.toCurrency())",
                identifier: "installment-0-\(installmentNumber)-\(UUID().uuidString)"
            )
        }
    }

    // Belirli bir tarihte taksit bildirimi planla
    private func scheduleInstallmentNotificationAt(
        date: Date,
        title: String,
        body: String,
        identifier: String
    ) {
        let calendar = Calendar.current
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "INSTALLMENT_REMINDER"

        // Bildirim zamanını ayarla (sabah 9:00)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Taksit bildirimi ekleme hatası: \(error.localizedDescription)")
            } else {
                print("Taksit bildirimi planlandı: \(title) - \(date)")
            }
        }
    }

    // Planlanmış bildirimleri listele (debug için)
    func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📬 Planlanmış bildirimler: \(requests.count)")
            for request in requests {
                print("- \(request.content.title): \(request.content.body)")
            }
        }
    }

    // MARK: - Recurring Payments Notifications

    /// Tekrarlayan ödemeler için bildirim planla
    func scheduleRecurringPaymentNotifications(recurringPayments: [RecurringTransaction]) {
        guard isAuthorized && notificationSettings.recurringPaymentsEnabled else { return }

        let activePayments = recurringPayments.filter { $0.isActive }

        for payment in activePayments {
            let nextPaymentDate = payment.nextPaymentDate

            // Ödeme gününden X gün önce hatırlat
            let daysBeforeArray = notificationSettings.recurringReminderDays
            for daysBefore in daysBeforeArray {
                if let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: nextPaymentDate),
                   reminderDate > Date() {
                    scheduleRecurringNotification(
                        id: "recurring_\(payment.id)_\(daysBefore)",
                        title: "💳 Yaklaşan Tekrarlayan Ödeme",
                        body: "\(payment.title) - \(daysBefore) gün sonra (\(payment.amount.toCurrency()))",
                        date: reminderDate
                    )
                }
            }
        }
    }

    /// Tekrarlayan ödeme bildirimi planla
    private func scheduleRecurringNotification(
        id: String,
        title: String,
        body: String,
        date: Date
    ) {
        let calendar = Calendar.current
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "RECURRING_PAYMENT"

        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Tekrarlayan ödeme bildirimi hatası: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Daily Summary

    /// Günlük özet bildirimi planla
    func scheduleDailySummary() {
        guard isAuthorized && notificationSettings.dailySummaryEnabled else {
            // Eğer kapalıysa mevcut bildirimi iptal et
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_summary"])
            return
        }

        var dateComponents = DateComponents()
        dateComponents.hour = notificationSettings.dailySummaryTime.hour
        dateComponents.minute = notificationSettings.dailySummaryTime.minute

        let content = UNMutableNotificationContent()
        content.title = "📊 Günlük Finansal Özet"
        content.body = "Bugünün harcamalarını kontrol etmeyi unutmayın!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_SUMMARY"

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_summary", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Günlük özet bildirimi hatası: \(error.localizedDescription)")
            }
        }
    }

    /// Tüm bildirimleri yeniden planla
    func scheduleAllNotifications(
        recurringPayments: [RecurringTransaction],
        installmentPayments: [InstallmentPayment]
    ) {
        guard isAuthorized else { return }

        // Tekrarlayan ödemeler
        if notificationSettings.recurringPaymentsEnabled {
            scheduleRecurringPaymentNotifications(recurringPayments: recurringPayments)
        }

        // Taksitli ödemeler
        if notificationSettings.installmentPaymentsEnabled {
            for payment in installmentPayments where !payment.isCompleted {
                for installment in payment.installments where !installment.isPaid {
                    scheduleInstallmentNotification(
                        paymentTitle: payment.title,
                        installmentNumber: installment.installmentNumber,
                        amount: installment.amount,
                        dueDate: installment.dueDate
                    )
                }
            }
        }

        // Günlük özet
        scheduleDailySummary()
    }

    /// Planlanmış bildirim sayısını getir
    func getPendingNotificationCount(completion: @escaping (Int) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests.count)
            }
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable {
    var recurringPaymentsEnabled = true
    var installmentPaymentsEnabled = true
    var overdueNotificationsEnabled = true
    var dailySummaryEnabled = false

    var recurringReminderDays = [1, 3] // 1 ve 3 gün önce
    var installmentReminderDays = [1, 3, 7] // 1, 3 ve 7 gün önce

    var dailySummaryTime = NotificationTime(hour: 20, minute: 0)
}

struct NotificationTime: Codable {
    var hour: Int
    var minute: Int

    var displayString: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

// Bildirim izin görünümü
struct NotificationPermissionView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // İkon
                ZStack {
                    Circle()
                        .fill(Theme.primaryGradient.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Theme.primaryGradient)
                }
                .padding(.top, 40)

                // Açıklama
                VStack(spacing: 16) {
                    Text("Ödeme Hatırlatıcıları")
                        .font(Theme.title)
                        .fontWeight(.bold)

                    Text("Yaklaşan ödemelerinizi kaçırmayın! Bildirim izni vererek:")
                        .font(Theme.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(
                            icon: "calendar.badge.clock",
                            text: "3 gün önceden hatırlatma"
                        )
                        FeatureRow(
                            icon: "clock.badge.exclamationmark",
                            text: "1 gün önceden hatırlatma"
                        )
                        FeatureRow(
                            icon: "bell.badge.fill",
                            text: "Ödeme günü hatırlatması"
                        )
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                }

                Spacer()

                // Butonlar
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await notificationManager.requestAuthorization()
                            dismiss()
                        }
                    }) {
                        Text("Bildirimlere İzin Ver")
                            .font(Theme.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primaryGradient)
                            .cornerRadius(15)
                    }

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Daha Sonra")
                            .font(Theme.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.primaryGradient)
                .frame(width: 30)

            Text(text)
                .font(Theme.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview {
    NotificationPermissionView()
}
