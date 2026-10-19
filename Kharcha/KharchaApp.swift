import SwiftUI
import SwiftData

@main
struct KharchaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataStore.container)
    }
}
