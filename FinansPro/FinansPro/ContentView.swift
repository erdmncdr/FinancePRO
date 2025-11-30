//
//  ContentView.swift
//  FinanceTracker
//
//  Ana görünüm - Tab Navigation
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .expenses
    @State private var showingSettings = false
    @State private var showingAnalytics = false
    @Environment(\.colorScheme) var colorScheme

    enum Tab: String, CaseIterable {
        case expenses = "Giderler"
        case income = "Gelirler"
        case upcoming = "Ödemeler"
        case debts = "Borçlar"

        var icon: String {
            switch self {
            case .expenses: return "cart.fill"
            case .income: return "banknote.fill"
            case .debts: return "creditcard.fill"
            case .upcoming: return "calendar.badge.clock"
            }
        }

        var gradient: LinearGradient {
            switch self {
            case .expenses: return Theme.accentGradient
            case .income: return Theme.successGradient
            case .debts: return LinearGradient(
                colors: [.orange, .red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            case .upcoming: return Theme.primaryGradient
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan gradient - optimized
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Ana içerik - lazy loading
                    TabView(selection: $selectedTab) {
                        LazyView(ExpensesView())
                            .tag(Tab.expenses)

                        LazyView(IncomeView())
                            .tag(Tab.income)

                        LazyView(UpcomingPaymentsView())
                            .tag(Tab.upcoming)

                        LazyView(DebtsView())
                            .tag(Tab.debts)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Custom Bottom Navigation
                    CustomTabBar(selectedTab: $selectedTab)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .padding(.top, 5)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .background(
                // Navbar blur overlay - sadece blur için
                VStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(height: 90)
                        .ignoresSafeArea(.container, edges: .top)
                    Spacer()
                }
                .allowsHitTesting(false)
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("FinansPro")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Analitik butonu
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showingAnalytics = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)

                                Image(systemName: "chart.pie.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.purple)
                            }
                            .contentShape(Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())

                        // Ayarlar butonu
                        Button {
                            HapticManager.shared.impact(style: .light)
                            showingSettings = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)

                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }
                            .contentShape(Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }

            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAnalytics) {
                AnalyticsView()
            }
        }
    }
}

// Özel Tab Bar - Premium Liquid Glass
struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    HapticManager.shared.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            ZStack {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.5),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                        .drawingGroup()
                } else {
                    // Light mode: higher contrast, solid-like background
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(
                            color: Color.black.opacity(0.08),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                }
            }
        )
    }
}

// Tab Bar butonu
struct TabBarButton: View {
    let tab: ContentView.Tab
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Arka plan - basit fade animasyonu
                    RoundedRectangle(cornerRadius: 15)
                        .fill(tab.gradient)
                        .frame(width: 50, height: 50)
                        .opacity(isSelected ? 1.0 : 0.0)
                        .scaleEffect(isSelected ? 1.0 : 0.8)
                        .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0), radius: 8, x: 0, y: 4)

                    // İkon
                    Image(systemName: tab.icon)
                        .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                        .foregroundColor(
                            isSelected
                            ? .white
                            : (colorScheme == .light ? .primary : .secondary)
                        )
                }

                // Label
                Text(tab.rawValue)
                    .font(Theme.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(
                        isSelected
                        ? .primary
                        : (colorScheme == .light ? .primary.opacity(0.9) : .secondary)
                    )
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Lazy loading wrapper for performance optimization
struct LazyView<Content: View>: View {
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}
