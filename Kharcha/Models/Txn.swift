import Foundation
import SwiftData

enum TransactionKind: String, Codable, CaseIterable {
    case debit
    case credit
}

enum TransactionSource: String, Codable {
    case sms
    case manual
}

/// One money movement: a payment (debit) or money received (credit).
/// Named `Txn` to avoid clashing with SwiftUI's `Transaction` type.
@Model
final class Txn {
    var amount: Double
    var kindRaw: String
    var merchant: String
    var categoryRaw: String
    var date: Date
    var sourceRaw: String
    var rawMessage: String?
    var reference: String?
    var accountHint: String?
    var note: String?

    init(
        amount: Double,
        kind: TransactionKind,
        merchant: String,
        category: Category,
        date: Date,
        source: TransactionSource,
        rawMessage: String? = nil,
        reference: String? = nil,
        accountHint: String? = nil,
        note: String? = nil
    ) {
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.merchant = merchant
        self.categoryRaw = category.rawValue
        self.date = date
        self.sourceRaw = source.rawValue
        self.rawMessage = rawMessage
        self.reference = reference
        self.accountHint = accountHint
        self.note = note
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .debit }
        set { kindRaw = newValue.rawValue }
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var source: TransactionSource {
        TransactionSource(rawValue: sourceRaw) ?? .manual
    }
}
