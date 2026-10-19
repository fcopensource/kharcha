import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Binding var month: Date
    @Query(sort: \Txn.date, order: .reverse) private var allTxns: [Txn]
    @AppStorage("monthlyBudget") private var budget: Double = 20000
    @State private var showingAdd = false

    private var txns: [Txn] { allTxns.inMonth(of: month) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MonthPicker(month: $month)
                    summaryCard
                    if txns.isEmpty {
                        ContentUnavailableView(
                            "No transactions yet",
                            systemImage: "tray",
                            description: Text("Tap + to paste a bank SMS, or turn on automatic tracking in Settings.")
                        )
                    } else {
                        if !txns.debits.isEmpty { categoryCard }
                        recentCard
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Kharcha")
            .toolbar {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddTransactionView()
            }
        }
    }

    private var summaryCard: some View {
        let spent = txns.totalSpent
        let received = txns.totalReceived
        let overBudget = spent > budget
        let budgetText = overBudget
            ? "Over budget by \((spent - budget).inr)"
            : "\((budget - spent).inr) left of \(budget.inr) budget"

        return VStack(alignment: .leading, spacing: 12) {
            Text("Spent this month")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(spent.inr)
                .font(.system(size: 40, weight: .bold, design: .rounded))
            if budget > 0 {
                ProgressView(value: min(spent / budget, 1))
                    .tint(overBudget ? Color.red : Color.accentColor)
                Text(budgetText)
                    .font(.caption)
                    .foregroundStyle(overBudget ? Color.red : Color.secondary)
            }
            Divider()
            HStack {
                Label("Received \(received.inr)", systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
                Text("\(txns.count) transactions")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var categoryCard: some View {
        let totals = txns.spendByCategory
        let spent = txns.totalSpent

        return VStack(alignment: .leading, spacing: 12) {
            Text("Where your money went")
                .font(.headline)
            Chart(totals) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(item.category.color)
            }
            .frame(height: 200)

            ForEach(totals) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .foregroundStyle(item.category.color)
                        .frame(width: 24)
                    Text(item.category.rawValue)
                    Spacer()
                    Text(item.total.inr)
                        .monospacedDigit()
                    Text(percent(item.total, of: spent))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .font(.subheadline)
            }
        }
        .card()
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.headline)
            ForEach(Array(txns.prefix(5))) { txn in
                TxnRow(txn: txn)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func percent(_ value: Double, of total: Double) -> String {
        guard total > 0 else { return "" }
        return "\(Int((value / total * 100).rounded()))%"
    }
}
