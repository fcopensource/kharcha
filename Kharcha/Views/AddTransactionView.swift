import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private enum Mode: String, CaseIterable {
        case sms = "Paste SMS"
        case manual = "Manual"
    }

    @State private var mode = Mode.sms
    @State private var smsText = ""
    @State private var parseFailed = false
    @State private var isDuplicate = false
    @State private var parsedFromSMS = false

    @State private var amount: Double?
    @State private var kind = TransactionKind.debit
    @State private var merchant = ""
    @State private var category = Category.other
    @State private var date = Date.now
    @State private var note = ""
    @State private var reference: String?
    @State private var accountHint: String?

    private var canSave: Bool { (amount ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                if mode == .sms {
                    smsSection
                }

                if mode == .manual || parsedFromSMS {
                    Section("Details") {
                        TextField("Amount (₹)", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                        KindPicker(selection: $kind)
                        TextField(kind == .debit ? "Paid to" : "Received from", text: $merchant)
                        CategoryPicker(selection: $category)
                        DatePicker("Date", selection: $date)
                        TextField("Note (optional)", text: $note)
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
        }
    }

    private var smsSection: some View {
        Section {
            TextEditor(text: $smsText)
                .frame(minHeight: 110)
                .font(.callout)
            HStack {
                PasteButton(payloadType: String.self) { strings in
                    guard let text = strings.first else { return }
                    DispatchQueue.main.async {
                        smsText = text
                        parse()
                    }
                }
                .labelStyle(.titleAndIcon)
                Spacer()
                Button("Read SMS", action: parse)
                    .disabled(smsText.trimmed.isEmpty)
            }
            .buttonStyle(.borderless)
        } header: {
            Text("Bank / UPI message")
        } footer: {
            if parseFailed {
                Text("Couldn't find a transaction in this message. Check the text or switch to Manual.")
                    .foregroundStyle(.red)
            } else if isDuplicate {
                Text("This SMS looks like it's already saved.")
                    .foregroundStyle(.orange)
            } else {
                Text("In Messages, long-press the bank SMS → Copy, then tap Paste.")
            }
        }
    }

    private func parse() {
        guard let parsed = SMSParser.parse(smsText) else {
            parseFailed = true
            parsedFromSMS = false
            return
        }
        parseFailed = false
        parsedFromSMS = true
        isDuplicate = DataStore.isDuplicate(reference: parsed.reference, rawMessage: smsText, in: context)
        amount = parsed.amount
        kind = parsed.kind
        merchant = parsed.merchant
        category = parsed.category
        reference = parsed.reference
        accountHint = parsed.accountHint
    }

    private func save() {
        guard let amount, amount > 0 else { return }
        let name = merchant.trimmed.isEmpty ? (kind == .debit ? "UPI payment" : "Money received") : merchant.trimmed
        let fromSMS = mode == .sms && parsedFromSMS
        context.insert(Txn(
            amount: amount,
            kind: kind,
            merchant: name,
            category: category,
            date: date,
            source: fromSMS ? .sms : .manual,
            rawMessage: fromSMS ? smsText : nil,
            reference: fromSMS ? reference : nil,
            accountHint: fromSMS ? accountHint : nil,
            note: note.trimmed.isEmpty ? nil : note.trimmed
        ))
        CategoryMemory.remember(category, for: name)
        dismiss()
    }
}
