import Foundation

struct ParsedTransaction {
    var amount: Double
    var kind: TransactionKind
    var merchant: String
    var category: Category
    var reference: String?
    var accountHint: String?
}

/// Reads Indian bank, card and UPI SMS alerts (HDFC, SBI, ICICI, Axis, Kotak, PhonePe/GPay/Paytm UPI, …).
enum SMSParser {
    /// Messages with these phrases are not completed transactions.
    private static let ignorePhrases = [
        "otp", "one time password", "verification code", "requested", "request of", "collect request",
        "payment request", "will be debited", "will be auto-debited", "is due", "due on", "due date",
        "minimum amount", "failed", "declined", "unsuccessful", "pre-approved"
    ]

    private static let debitWords = [
        "debited", "spent", "paid", "sent", "withdrawn", "purchase", "payment of", "txn of",
        "transferred", "deducted", "dr "
    ]
    private static let creditWords = [
        "credited", "received", "deposited", "refund", "reversed", " cr "
    ]

    private static let amountPatterns = [
        #"\b(?:debited|credited|spent|paid|sent|received)\s+(?:by|with|for|of)?\s*(?:\brs\.?|\binr|₹)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)"#,
        #"(?:\brs\.?|\binr|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)"#
    ]

    private static let stop = #"(?=\s+(?:on|ref|refno|upi|via|at|for|avl|using|thru|through|txn|from)\b|[.,;:]|$)"#

    private static var debitMerchantPatterns: [String] {
        [
            #"upi/(?:p2m|p2a|dr|cr)?/?[0-9]+/([a-z0-9 .&'-]{2,40})"#,
            #"\b(?:to|vpa)\s+(?:vpa\s+)?([a-z0-9._-]+@[a-z0-9]+)"#,
            #"\b(?:trf to|transfer to|transferred to|paid to|sent to|payment to|to)\s+([a-z][a-z0-9 .&'-]{1,40}?)"# + stop,
            #"\bat\s+([a-z0-9][a-z0-9 .&'_-]{1,40}?)"# + stop,
        ]
    }

    private static var creditMerchantPatterns: [String] {
        [
            #"upi/(?:p2m|p2a|dr|cr)?/?[0-9]+/([a-z0-9 .&'-]{2,40})"#,
            #"\b(?:from|by)\s+(?:vpa\s+)?([a-z0-9._-]+@[a-z0-9]+)"#,
            #"\b(?:from|by)\s+([a-z][a-z0-9 .&'-]{1,40}?)"# + stop,
        ]
    }

    private static let referencePattern = #"(?:\bref(?:erence)?(?:\s*no)?|\brefno|\butr|\brrn|\btxn\s*id|\bupi\s*ref)[\s.:#-]*([0-9]{6,})"#
    private static let accountPattern = #"(?:\ba/c|\bac|\bacct|\baccount|\bcard)\s*(?:no\.?)?\s*(?:ending\s*)?[x*]+([0-9]{3,4})"#

    static func parse(_ message: String) -> ParsedTransaction? {
        let text = message.replacingOccurrences(of: "\n", with: " ")
        let lower = text.lowercased()

        guard !ignorePhrases.contains(where: { lower.contains($0) }) else { return nil }
        guard let amount = extractAmount(from: text) else { return nil }

        // When a message has both words ("debited from you and credited to Swiggy"), the first one wins.
        let kind: TransactionKind
        switch (firstIndex(of: debitWords, in: lower), firstIndex(of: creditWords, in: lower)) {
        case let (debit?, credit?): kind = debit <= credit ? .debit : .credit
        case (_?, nil): kind = .debit
        case (nil, _?): kind = .credit
        case (nil, nil): return nil
        }

        let merchant = extractMerchant(from: text, kind: kind) ?? fallbackMerchant(lower: lower, kind: kind)
        let category = CategoryMemory.category(for: merchant)
            ?? (kind == .credit ? Category.income : nil)
            ?? Category.guess(from: merchant)
            ?? Category.guess(from: lower)
            ?? .other

        return ParsedTransaction(
            amount: amount,
            kind: kind,
            merchant: merchant,
            category: category,
            reference: captures(referencePattern, in: text).first,
            accountHint: captures(accountPattern, in: text).first
        )
    }

    // MARK: - Pieces

    private static func extractAmount(from text: String) -> Double? {
        for pattern in amountPatterns {
            for value in captures(pattern, in: text) {
                if let amount = Double(value.replacingOccurrences(of: ",", with: "")), amount > 0 {
                    return amount
                }
            }
        }
        return nil
    }

    private static func extractMerchant(from text: String, kind: TransactionKind) -> String? {
        let patterns = kind == .debit ? debitMerchantPatterns : creditMerchantPatterns
        for pattern in patterns {
            for candidate in captures(pattern, in: text) {
                if let name = clean(candidate) { return name }
            }
        }
        return nil
    }

    private static func clean(_ raw: String) -> String? {
        var name = raw.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))

        // UPI ID: "swiggy@icici" → "swiggy"; numeric merchant IDs are not useful names.
        if let at = name.firstIndex(of: "@") {
            name = String(name[..<at])
            let digits = name.filter(\.isNumber).count
            if digits >= 5 { return "UPI merchant" }
            name = name.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "_", with: " ")
        }

        // "NEFT from ACME PVT LTD" → "ACME PVT LTD"
        if let range = name.range(of: " from ", options: .caseInsensitive) {
            name = String(name[range.upperBound...])
        }
        for prefix in ["neft ", "imps ", "rtgs ", "upi ", "mr ", "mrs ", "ms "] where name.lowercased().hasPrefix(prefix) {
            name = String(name.dropFirst(prefix.count))
        }

        name = name.split(separator: " ").joined(separator: " ")
        let lower = name.lowercased()
        let rejected = ["your", "a/c", "account", "acct", "xx", "bank a", "self", "beneficiary"]
        guard name.count >= 2, !rejected.contains(where: { lower.contains($0) }), name.contains(where: \.isLetter) else {
            return nil
        }

        if name == name.uppercased() || name == name.lowercased() {
            name = name.capitalized
        }
        return String(name.prefix(32))
    }

    private static func fallbackMerchant(lower: String, kind: TransactionKind) -> String {
        if kind == .credit { return "Money received" }
        if lower.contains("atm") || lower.contains("withdrawn") { return "ATM withdrawal" }
        if lower.contains("card") { return "Card payment" }
        return "UPI payment"
    }

    private static func firstIndex(of words: [String], in text: String) -> String.Index? {
        words.compactMap { text.range(of: $0)?.lowerBound }.min()
    }

    /// All values of capture group 1 for `pattern` in `text`, in order.
    private static func captures(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard match.numberOfRanges > 1, let r = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[r])
        }
    }
}
