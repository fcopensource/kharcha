import SwiftUI

struct MonthPicker: View {
    @Binding var month: Date

    var body: some View {
        HStack {
            Button { month = month.addingMonths(-1) } label: {
                Image(systemName: "chevron.left").padding(8)
            }
            Spacer()
            Text(month, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button { month = month.addingMonths(1) } label: {
                Image(systemName: "chevron.right").padding(8)
            }
            .disabled(month.addingMonths(1) > .now)
        }
        .buttonStyle(.borderless)
    }
}

struct TxnRow: View {
    let txn: Txn

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: txn.category.icon)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(txn.category.color, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(txn.merchant)
                    .lineLimit(1)
                Text("\(txn.category.rawValue) · \(txn.date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text((txn.kind == .debit ? "−" : "+") + txn.amount.inr)
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(txn.kind == .debit ? Color.primary : Color.green)
        }
    }
}

struct CategoryPicker: View {
    @Binding var selection: Category

    var body: some View {
        Picker("Category", selection: $selection) {
            ForEach(Category.allCases) { category in
                Label(category.rawValue, systemImage: category.icon).tag(category)
            }
        }
    }
}

struct KindPicker: View {
    @Binding var selection: TransactionKind

    var body: some View {
        Picker("Type", selection: $selection) {
            Text("Paid").tag(TransactionKind.debit)
            Text("Received").tag(TransactionKind.credit)
        }
        .pickerStyle(.segmented)
    }
}
