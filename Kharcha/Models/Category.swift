import SwiftUI

enum Category: String, Codable, CaseIterable, Identifiable {
    case food = "Food & Dining"
    case groceries = "Groceries"
    case shopping = "Shopping"
    case travel = "Travel"
    case fuel = "Fuel"
    case bills = "Bills & Recharge"
    case subscriptions = "Subscriptions"
    case health = "Health"
    case entertainment = "Entertainment"
    case rent = "Rent"
    case emi = "EMI & Loans"
    case transfers = "Transfers"
    case income = "Income"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food: "fork.knife"
        case .groceries: "cart.fill"
        case .shopping: "bag.fill"
        case .travel: "car.fill"
        case .fuel: "fuelpump.fill"
        case .bills: "bolt.fill"
        case .subscriptions: "play.rectangle.fill"
        case .health: "cross.case.fill"
        case .entertainment: "film.fill"
        case .rent: "house.fill"
        case .emi: "building.columns.fill"
        case .transfers: "arrow.left.arrow.right"
        case .income: "arrow.down.circle.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: .orange
        case .groceries: .green
        case .shopping: .pink
        case .travel: .blue
        case .fuel: .brown
        case .bills: .yellow
        case .subscriptions: .purple
        case .health: .red
        case .entertainment: .indigo
        case .rent: .teal
        case .emi: .gray
        case .transfers: .cyan
        case .income: .mint
        case .other: .secondary
        }
    }

    /// Whole-word keywords (lowercase) used to guess a category from merchant names and SMS text.
    var keywords: [String] {
        switch self {
        case .groceries:
            ["bigbasket", "blinkit", "zepto", "dmart", "instamart", "jiomart", "grofers", "reliance fresh",
             "more retail", "spencers", "nature's basket", "kirana", "supermarket", "milkbasket", "country delight"]
        case .subscriptions:
            ["netflix", "hotstar", "spotify", "prime video", "amazon prime", "youtube premium", "jiocinema",
             "sonyliv", "zee5", "apple.com", "apple services", "google play", "icloud", "gaana", "wynk", "audible"]
        case .food:
            ["swiggy", "zomato", "dominos", "domino's", "pizza", "mcdonalds", "mcdonald's", "kfc", "burger",
             "cafe", "restaurant", "starbucks", "eatsure", "haldiram", "chai", "bakery", "dhaba", "biryani"]
        case .fuel:
            ["petrol", "fuel", "hpcl", "bpcl", "iocl", "indian oil", "bharat petroleum", "hindustan petroleum", "shell"]
        case .travel:
            ["uber", "olacabs", "ola cabs", "rapido", "irctc", "makemytrip", "goibibo", "redbus", "indigo",
             "air india", "akasa", "metro", "fastag", "cleartrip", "yatra", "ixigo", "namma yatri", "blusmart"]
        case .bills:
            ["airtel", "jio", "vodafone", "bsnl", "electricity", "bescom", "msedcl", "tata power", "adani electricity",
             "torrent power", "gas", "broadband", "recharge", "billdesk", "dth", "tata play", "water bill", "act fibernet"]
        case .health:
            ["apollo", "pharmeasy", "1mg", "netmeds", "medplus", "hospital", "clinic", "pharmacy", "medical",
             "practo", "diagnostics", "lab"]
        case .entertainment:
            ["bookmyshow", "pvr", "inox", "cinema", "cinepolis", "steam", "playstation", "dream11", "district"]
        case .shopping:
            ["amazon", "flipkart", "myntra", "meesho", "ajio", "nykaa", "croma", "reliance digital", "tata cliq",
             "decathlon", "lifestyle", "westside", "zudio", "pantaloons", "lenskart", "ikea"]
        case .rent:
            ["rent", "nobroker", "house rent", "pg rent"]
        case .emi:
            ["emi", "loan", "bajaj finance", "bajaj finserv", "nach", "home credit", "credit card bill"]
        case .transfers, .income, .other:
            []
        }
    }

    /// Order matters: more specific categories are checked first (e.g. "Swiggy Instamart" is groceries, not food).
    private static let guessOrder: [Category] = [
        .groceries, .subscriptions, .food, .fuel, .travel, .bills, .health, .entertainment, .shopping, .rent, .emi
    ]

    static func guess(from text: String) -> Category? {
        for category in guessOrder where category.keywords.contains(where: { text.containsWord($0) }) {
            return category
        }
        return nil
    }
}
