//
//  SearchBar.swift
//  FinansPro
//
//  Arama çubuğu komponenti
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    var placeholder: String = "Ara..."

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button(action: {
                    HapticManager.shared.impact(style: .light)
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    SearchBar(text: .constant(""))
        .padding()
}
