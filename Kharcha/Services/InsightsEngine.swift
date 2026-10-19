import SwiftUI

struct Insight: Identifiable {
    enum Kind {
        case warning, tip, good

        var color: Color {
            switch self {
            case .warning: .orange
            case .tip: .blue
            case .good: .green
            }
        }

        var order: Int {
            switch self {
            case .warning: 0
            case .tip: 1
            case .good: 2
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let icon: String
    let title: String
    let detail: String
    /// Estimated rupees per month you could save by acting on this.
    var potentialSaving: Double? = nil
}

/// Looks at a month of spending and suggests where to cut back.
enum InsightsEngine {
    static func insights(current: [Txn], previous: [Txn], budget: Double, month: Date, now: Date = .now) -> [Insight] {
        let spent = current.totalSpent
        guard spent > 0 else { return [] }

        let calendar = Calendar.current
        let debits = current.debits
        var result: [Insight] = []

        var byCategory: [Category: Double] = [:]
        for item in current.spendByCategory { byCategory[item.category] = item.total }
        var previousByCategory: [Category: Double] = [:]
        for item in previous.spendByCategory { previousByCategory[item.category] = item.total }

        func amount(_ category: Category) -> Double { byCategory[category] ?? 0 }
        func share(_ category: Category) -> Double { amount(category) / spent }

        // Budget pace
        if budget > 0 {
            let isCurrentMonth = calendar.isDate(month, equalTo: now, toGranularity: .month)
            let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
            if spent > budget {
                result.append(Insight(
                    kind: .warning, icon: "exclamationmark.triangle.fill",
                    title: "Budget crossed",
                    detail: "You've spent \((spent - budget).inr) more than your \(budget.inr) budget this month."
                ))
            } else if isCurrentMonth {
                let today = calendar.component(.day, from: now)
                let projected = spent / Double(today) * Double(daysInMonth)
                let daysLeft = max(daysInMonth - today + 1, 1)
                if projected > budget * 1.05 {
                    let dailyLimit = (budget - spent) / Double(daysLeft)
                    result.append(Insight(
                        kind: .warning, icon: "speedometer",
                        title: "On pace to overspend",
                        detail: "At this rate you'll spend about \(projected.inr) this month, \((projected - budget).inr) over budget. Keep daily spending under \(dailyLimit.inr) to stay on track.",
                        potentialSaving: projected - budget
                    ))
                } else {
                    result.append(Insight(
                        kind: .good, icon: "checkmark.seal.fill",
                        title: "On track with your budget",
                        detail: "Projected spend is \(projected.inr), within your \(budget.inr) budget. Keep it up!"
                    ))
                }
            }
        }

        // Food delivery
        let food = amount(.food)
        if food >= 1500 && share(.food) >= 0.15 {
            let orders = debits.filter { $0.category == .food }.count
            result.append(Insight(
                kind: .tip, icon: "fork.knife",
                title: "Food is \(percent(share(.food))) of your spending",
                detail: "\(orders) food payments totalling \(food.inr). Cooking at home 2–3 more days a week could cut this by about 40%.",
                potentialSaving: food * 0.4
            ))
        }

        // Subscriptions
        let subscriptions = debits.filter { $0.category == .subscriptions }
        let subscriptionGroups = Dictionary(grouping: subscriptions) { $0.merchant.lowercased() }
        if subscriptionGroups.count >= 2 {
            let total = subscriptions.total
            let biggest = subscriptionGroups.values.map(\.total).max() ?? 0
            result.append(Insight(
                kind: .tip, icon: "play.rectangle.on.rectangle.fill",
                title: "You pay for \(subscriptionGroups.count) subscriptions",
                detail: "That's \(total.inr) this month. Keep the one you use most and pause the rest, or switch to a shared family plan.",
                potentialSaving: total - biggest
            ))
        }

        // Many small payments
        let small = debits.filter { $0.amount < 200 }
        if small.count >= 12 && small.total >= 1000 {
            result.append(Insight(
                kind: .tip, icon: "cup.and.saucer.fill",
                title: "Chhota kharcha adds up",
                detail: "\(small.count) payments under ₹200 added up to \(small.total.inr). Tea, snacks and quick buys are easy to skip. Try a weekly limit.",
                potentialSaving: small.total * 0.3
            ))
        }

        // Shopping
        let shopping = amount(.shopping)
        if shopping >= 3000 && share(.shopping) >= 0.25 {
            result.append(Insight(
                kind: .tip, icon: "bag.fill",
                title: "Shopping is \(percent(share(.shopping))) of your spending",
                detail: "Try the 48-hour rule: keep items in your cart for 2 days before buying. Most impulse buys don't survive it.",
                potentialSaving: shopping * 0.25
            ))
        }

        // Categories that grew a lot vs last month
        var growth: [Insight] = []
        for (category, thisMonth) in byCategory {
            let before = previousByCategory[category] ?? 0
            guard before >= 1000, thisMonth > before * 1.3, category != .rent, category != .emi else { continue }
            growth.append(Insight(
                kind: .warning, icon: "chart.line.uptrend.xyaxis",
                title: "\(category.rawValue) up \(percent((thisMonth - before) / before)) vs last month",
                detail: "You spent \(thisMonth.inr) compared to \(before.inr) last month, \((thisMonth - before).inr) more.",
                potentialSaving: thisMonth - before
            ))
        }
        result += growth.sorted { ($0.potentialSaving ?? 0) > ($1.potentialSaving ?? 0) }.prefix(2)

        // Weekends vs weekdays
        let weekendTotal = debits.filter { calendar.isDateInWeekend($0.date) }.total
        let weekdayPerDay = (spent - weekendTotal) / 5
        let weekendPerDay = weekendTotal / 2
        if weekendTotal >= 2000 && weekdayPerDay > 0 && weekendPerDay > weekdayPerDay * 1.5 {
            let ratio = String(format: "%.1f", weekendPerDay / weekdayPerDay)
            result.append(Insight(
                kind: .tip, icon: "calendar",
                title: "Weekends cost you \(ratio)× more",
                detail: "You spent \(weekendTotal.inr) on weekends. Plan one low-spend weekend activity, like a park, a home movie night or cooking together.",
                potentialSaving: weekendTotal * 0.2
            ))
        }

        // Top merchant
        let byMerchant = Dictionary(grouping: debits, by: \.merchant)
        if let top = byMerchant.max(by: { $0.value.total < $1.value.total }),
           top.value.count >= 3, top.value.total / spent >= 0.2 {
            result.append(Insight(
                kind: .tip, icon: "storefront.fill",
                title: "\(top.key) is your biggest spend",
                detail: "\(top.value.count) payments totalling \(top.value.total.inr), \(percent(top.value.total / spent)) of everything you spent."
            ))
        }

        // Savings rate
        let received = current.totalReceived
        if received > 0 {
            let rate = (received - spent) / received
            if rate < 0 {
                result.append(Insight(
                    kind: .warning, icon: "arrow.down.right.circle.fill",
                    title: "Spending more than you received",
                    detail: "You spent \((spent - received).inr) more than came in this month. Review the biggest categories above."
                ))
            } else if rate < 0.2 {
                result.append(Insight(
                    kind: .tip, icon: "banknote.fill",
                    title: "You saved \(percent(rate)) this month",
                    detail: "Aim for at least 20% (about \((received * 0.2).inr)). Set up a SIP or RD for salary day so saving happens automatically."
                ))
            } else {
                result.append(Insight(
                    kind: .good, icon: "star.fill",
                    title: "Great job, you saved \(percent(rate))",
                    detail: "You kept \((received - spent).inr) of what came in. Consider moving it to an FD, RD or mutual fund."
                ))
            }
        }

        return result.sorted {
            ($0.kind.order, -($0.potentialSaving ?? 0)) < ($1.kind.order, -($1.potentialSaving ?? 0))
        }
    }

    private static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
