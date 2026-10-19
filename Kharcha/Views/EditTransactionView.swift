import SwiftUI
import SwiftData

struct EditTransactionView: View {
    @Bindable var txn: Txn

    private var noteBinding: Binding<String> {
        Binding(
            get: { txn.note ?? "" },
            set: { txn.note = $0.isEmpty ? nil : $0 }
        )
    }

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Amount (₹)") {
                    TextField("Amount", value: $txn.amount, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                KindPicker(selection: $txn.kind)
                LabeledContent(txn.kind == .debit ? "Paid to" : "From") {
                    TextField("Name", text: $txn.merchant)
                        .multilineTextAlignment(.trailing)
                }
                CategoryPicker(selection: $txn.category)
                DatePicker("Date", selection: $txn.date)
                TextField("Note", text: noteBinding)
            }

            if txn.reference != nil || txn.accountHint != nil {
                Section("Bank info") {
                    if let reference = txn.reference {
                        LabeledContent("Reference", value: reference)
                    }
                    if let account = txn.accountHint {
                        LabeledContent("Account / Card", value: "••\(account)")
                    }
                }
            }

            if let raw = txn.rawMessage {
                Section("Original SMS") {
                    Text(raw)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle(txn.merchant)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: txn.categoryRaw) {
            // Learn: next SMS from this merchant gets the same category.
            CategoryMemory.remember(txn.category, for: txn.merchant)
        }
    }
}
