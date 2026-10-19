import Foundation
import SwiftData

/// One shared database, used by both the app UI and the Shortcuts intent.
enum DataStore {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Txn.self)
        } catch {
            fatalError("Could not create the Kharcha database: \(error)")
        }
    }()

    /// True if this SMS (same bank reference number or same text) was already saved.
    static func isDuplicate(reference: String?, rawMessage: String, in context: ModelContext) -> Bool {
        if let reference {
            let ref: String? = reference
            let byReference = FetchDescriptor<Txn>(predicate: #Predicate { $0.reference == ref })
            if ((try? context.fetchCount(byReference)) ?? 0) > 0 { return true }
        }
        let raw: String? = rawMessage
        let byText = FetchDescriptor<Txn>(predicate: #Predicate { $0.rawMessage == raw })
        return ((try? context.fetchCount(byText)) ?? 0) > 0
    }
}

/// Remembers the category you pick for a merchant so the next SMS from them is categorised correctly.
enum CategoryMemory {
    private static let key = "merchantCategories"
    private static let genericMerchants: Set<String> = [
        "upi payment", "card payment", "money received", "unknown", "upi merchant", "atm withdrawal"
    ]

    static func category(for merchant: String) -> Category? {
        let map = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        return map[normalized(merchant)].flatMap(Category.init(rawValue:))
    }

    static func remember(_ category: Category, for merchant: String) {
        let name = normalized(merchant)
        guard !name.isEmpty, !genericMerchants.contains(name) else { return }
        var map = UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
        map[name] = category.rawValue
        UserDefaults.standard.set(map, forKey: key)
    }

    private static func normalized(_ merchant: String) -> String {
        merchant.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
