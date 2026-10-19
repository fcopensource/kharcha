import SwiftUI

struct ContentView: View {
    @State private var month = Date.now.startOfMonth

    var body: some View {
        TabView {
            DashboardView(month: $month)
                .tabItem { Label("Home", systemImage: "indianrupeesign.circle.fill") }
            TransactionsView(month: $month)
                .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle") }
            InsightsView(month: $month)
                .tabItem { Label("Insights", systemImage: "lightbulb.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Txn.self, inMemory: true)
}
