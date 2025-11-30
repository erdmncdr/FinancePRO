import SwiftUI

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(Environment(\.colorScheme).wrappedValue)
                    .ignoresSafeArea()

                List {
                    Section("Raporlar") {
                        Button {
                            HapticManager.shared.impact(style: .light)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundStyle(.blue)
                                Text("CSV olarak dışa aktar")
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                        }

                        Button {
                            HapticManager.shared.impact(style: .light)
                        } label: {
                            HStack {
                                Image(systemName: "doc.richtext.fill")
                                    .foregroundStyle(.green)
                                Text("PDF raporu oluştur")
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                        }
                    }

                    Section("Açıklama") {
                        Text("İşlemlerinizi CSV veya PDF formatında dışa aktarabilirsiniz. CSV dosyaları elektronik tablo uygulamalarıyla uyumludur; PDF raporları ise paylaşım için idealdir.")
                            .font(Theme.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Veri Dışa Aktarma")
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
    DataExportView()
}
