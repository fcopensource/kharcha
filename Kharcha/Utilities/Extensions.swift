import SwiftUI

enum Money {
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN") // ₹1,00,000 style grouping
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

extension Double {
    /// Formats as Indian rupees, e.g. ₹1,25,000.
    var inr: String {
        Money.formatter.string(from: NSNumber(value: self)) ?? "₹\(Int(self))"
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Case-insensitive whole-word match, so "rent" doesn't match "current".
    func containsWord(_ word: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        return range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

extension Date {
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
}

struct CategoryTotal: Identifiable {
    let category: Category
    let total: Double
    var id: Category { category }
}

extension Array where Element == Txn {
    func inMonth(of month: Date) -> [Txn] {
        filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    var debits: [Txn] { filter { $0.kind == .debit } }
    var credits: [Txn] { filter { $0.kind == .credit } }
    var total: Double { reduce(0) { $0 + $1.amount } }
    var totalSpent: Double { debits.total }
    var totalReceived: Double { credits.total }

    var spendByCategory: [CategoryTotal] {
        Dictionary(grouping: debits, by: \.category)
            .map { CategoryTotal(category: $0.key, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }
}

extension View {
    func card() -> some View {
        padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
