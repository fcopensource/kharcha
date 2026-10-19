import Foundation
import SwiftData

/// Fake transactions for this month and last month, so you can try the app in the Simulator.
enum SampleData {
    private static let merchants: [(name: String, category: Category, range: ClosedRange<Int>, count: Int)] = [
        ("Swiggy", .food, 180...650, 9),
        ("Zomato", .food, 200...700, 6),
        ("Blinkit", .groceries, 150...900, 7),
        ("Uber", .travel, 120...450, 6),
        ("Amazon", .shopping, 300...2500, 3),
        ("Netflix", .subscriptions, 649...649, 1),
        ("Spotify", .subscriptions, 119...119, 1),
        ("Hotstar", .subscriptions, 299...299, 1),
        ("Chai Point", .food, 30...120, 14),
        ("Airtel", .bills, 399...399, 1),
        ("HP Petrol Pump", .fuel, 500...1500, 3),
        ("Apollo Pharmacy", .health, 150...800, 1),
    ]

    static func load(into context: ModelContext, now: Date = .now) {
        let calendar = Calendar.current
        for monthOffset in [-1, 0] {
            guard let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: now),
                  let interval = calendar.dateInterval(of: .month, for: monthDate) else { continue }
            let end = min(interval.end, now)
            let span = end.timeIntervalSince(interval.start)
            guard span > 3600 else { continue }

            let firstMorning = interval.start.addingTimeInterval(min(span / 2, 10 * 3600))
            context.insert(Txn(amount: 55000, kind: .credit, merchant: "Salary – Acme Pvt Ltd",
                               category: .income, date: firstMorning, source: .manual, note: "Sample"))
            context.insert(Txn(amount: 15000, kind: .debit, merchant: "House Rent",
                               category: .rent, date: firstMorning.addingTimeInterval(1800), source: .manual, note: "Sample"))

            for merchant in merchants {
                // Last month had a bit less spending, so "up vs last month" insights show.
                let count = monthOffset == 0 ? merchant.count : max(1, merchant.count * 3 / 4)
                for _ in 0..<count {
                    context.insert(Txn(
                        amount: Double(Int.random(in: merchant.range)),
                        kind: .debit,
                        merchant: merchant.name,
                        category: merchant.category,
                        date: interval.start.addingTimeInterval(Double.random(in: 0..<span)),
                        source: .manual,
                        note: "Sample"
                    ))
                }
            }
        }
    }
}
