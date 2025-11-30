import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var remindersEnabled: Bool = true
    @State private var reminderTime: Date = {
        var comps = DateComponents()
        comps.hour = 9
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(Environment(\.colorScheme).wrappedValue)
                    .ignoresSafeArea()

                List {
                    Section {
                        Toggle("Ödeme hatırlatıcılarını etkinleştir", isOn: $remindersEnabled)
                        DatePicker("Hatırlatma saati", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                    } header: {
                        Text("Bildirimler")
                    } footer: {
                        Text("Etkinleştirildiğinde, yaklaşan tekrarlayan ödemeler için bildirim alırsınız.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Bildirim Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
