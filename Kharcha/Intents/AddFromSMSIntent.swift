import AppIntents
import SwiftData

/// Shortcuts action "Add Transaction from SMS".
/// A personal automation (Shortcuts → Automation → Message) passes each bank SMS here.
struct AddFromSMSIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Transaction from SMS"
    static var description = IntentDescription("Reads a bank or UPI SMS and saves the transaction in Kharcha.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Message")
    var message: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$message) to Kharcha")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let parsed = SMSParser.parse(message) else {
            return .result(value: "Not a transaction, ignored")
        }

        let context = DataStore.container.mainContext
        if DataStore.isDuplicate(reference: parsed.reference, rawMessage: message, in: context) {
            return .result(value: "Already saved")
        }

        context.insert(Txn(
            amount: parsed.amount,
            kind: parsed.kind,
            merchant: parsed.merchant,
            category: parsed.category,
            date: .now,
            source: .sms,
            rawMessage: message,
            reference: parsed.reference,
            accountHint: parsed.accountHint
        ))
        try context.save()

        let verb = parsed.kind == .debit ? "paid to" : "received from"
        return .result(value: "Saved \(parsed.amount.inr) \(verb) \(parsed.merchant)")
    }
}

struct KharchaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddFromSMSIntent(),
            phrases: ["Add SMS to \(.applicationName)"],
            shortTitle: "Add from SMS",
            systemImageName: "message.fill"
        )
    }
}
