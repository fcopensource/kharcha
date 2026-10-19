import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Binding var month: Date
    @Environment(\.modelContext) private var context
    @Query(sort: \Txn.date, order: .reverse) private var allTxns: [Txn]
    @State private var search = ""
    @State private var showingAdd = false

    private struct DayGroup: Identifiable {
        let day: Date
        let txns: [Txn]
        var id: Date { day }
    }

    private var groups: [DayGroup] {
        var txns = allTxns.inMonth(of: month)
        if !search.isEmpty {
            txns = txns.filter {
                $0.merchant.localizedCaseInsensitiveContains(search)
                    || $0.category.rawValue.localizedCaseInsensitiveContains(search)
            }
        }
        return Dictionary(grouping: txns) { Calendar.current.startOfDay(for: $0.date) }
            .map { DayGroup(day: $0.key, txns: $0.value) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MonthPicker(month: $month)
                }

                if groups.isEmpty {
                    Text(search.isEmpty ? "No transactions this month." : "No matches.")
                        .foregroundStyle(.secondary)
                }

                ForEach(groups) { group in
                    Section(group.day.formatted(date: .complete, time: .omitted)) {
                        ForEach(group.txns) { txn in
                            NavigationLink {
                                EditTransactionView(txn: txn)
                            } label: {
                                TxnRow(txn: txn)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                context.delete(group.txns[index])
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search merchant or category")
            .navigationTitle("Transactions")
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
}
