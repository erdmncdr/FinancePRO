//
//  FilterOptions.swift
//  FinansPro
//
//  Filtreleme seçenekleri
//

import Foundation

struct FilterOptions {
    var dateRange: DateRange?
    var categories: Set<TransactionCategory> = []
    var types: Set<TransactionType> = []
    var minAmount: Double?
    var maxAmount: Double?
    var isPaid: Bool?

    var isActive: Bool {
        dateRange != nil ||
        !categories.isEmpty ||
        !types.isEmpty ||
        minAmount != nil ||
        maxAmount != nil ||
        isPaid != nil
    }

    mutating func reset() {
        dateRange = nil
        categories.removeAll()
        types.removeAll()
        minAmount = nil
        maxAmount = nil
        isPaid = nil
    }
}

enum DateRange {
    case today
    case thisWeek
    case thisMonth
    case last30Days
    case last3Months
    case thisYear
    case custom(start: Date, end: Date)

    var dateInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return DateInterval(start: start, end: end)

        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)!.start
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return DateInterval(start: start, end: end)

        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)!.start
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateInterval(start: start, end: end)

        case .last30Days:
            let end = now
            let start = calendar.date(byAdding: .day, value: -30, to: end)!
            return DateInterval(start: start, end: end)

        case .last3Months:
            let end = now
            let start = calendar.date(byAdding: .month, value: -3, to: end)!
            return DateInterval(start: start, end: end)

        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)!.start
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return DateInterval(start: start, end: end)

        case .custom(let start, let end):
            return DateInterval(start: start, end: end)
        }
    }

    var title: String {
        switch self {
        case .today: return "Bugün"
        case .thisWeek: return "Bu Hafta"
        case .thisMonth: return "Bu Ay"
        case .last30Days: return "Son 30 Gün"
        case .last3Months: return "Son 3 Ay"
        case .thisYear: return "Bu Yıl"
        case .custom: return "Özel Aralık"
        }
    }
}
