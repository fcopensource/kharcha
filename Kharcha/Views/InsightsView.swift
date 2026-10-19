import SwiftUI
import SwiftData

struct InsightsView: View {
    @Binding var month: Date
    @Query(sort: \Txn.date, order: .reverse) private var allTxns: [Txn]
    @AppStorage("monthlyBudget") private var budget: Double = 20000

    private var insights: [Insight] {
        InsightsEngine.insights(
            current: allTxns.inMonth(of: month),
            previous: allTxns.inMonth(of: month.addingMonths(-1)),
            budget: budget,
            month: month
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MonthPicker(month: $month)

                    let items = insights
                    if items.isEmpty {
                        ContentUnavailableView(
                            "No suggestions yet",
                            systemImage: "lightbulb",
                            description: Text("Add a few transactions and Kharcha will show where you can save.")
                        )
                    } else {
                        let saving = items.compactMap(\.potentialSaving).reduce(0, +)
                        if saving > 0 {
                            savingsCard(saving)
                        }
                        ForEach(items) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
        }
    }

    private func savingsCard(_ saving: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("You could save up to")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Text("\(saving.inr) / month")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("That's \((saving * 12).inr) a year if you follow the tips below.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

struct InsightCard: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundStyle(insight.kind.color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.headline)
                Text(insight.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let saving = insight.potentialSaving, saving > 0 {
                    Text("Save up to \(saving.inr)/month")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15), in: Capsule())
                        .foregroundStyle(.green)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
