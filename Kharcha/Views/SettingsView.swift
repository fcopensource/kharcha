import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("monthlyBudget") private var budget: Double = 20000
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Monthly budget (₹)") {
                        TextField("Budget", value: $budget, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                } footer: {
                    Text("Used for budget alerts and suggestions.")
                }

                Section("Automatic SMS tracking") {
                    NavigationLink {
                        SetupGuideView()
                    } label: {
                        Label("Set up auto-tracking", systemImage: "wand.and.stars")
                    }
                }

                Section("Testing") {
                    Button {
                        SampleData.load(into: context)
                    } label: {
                        Label("Load sample data", systemImage: "tray.and.arrow.down")
                    }
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete all transactions", systemImage: "trash")
                    }
                }

                Section {
                    Text("Your data stays on this iPhone. Kharcha never uploads your messages.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Delete all transactions?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete All", role: .destructive, action: deleteAll)
            }
        }
    }

    private func deleteAll() {
        let all = (try? context.fetch(FetchDescriptor<Txn>())) ?? []
        for txn in all {
            context.delete(txn)
        }
    }
}

struct SetupGuideView: View {
    private let steps = [
        "Open the **Shortcuts** app and go to the **Automation** tab.",
        "Tap **+** (New Automation) and choose **Message**.",
        "Under **Message Contains**, type **debited**.",
        "Choose **Run Immediately** and turn off **Notify When Run**, then tap **Next**.",
        "Tap **New Blank Automation**, then **Add Action**, and search for **Kharcha**.",
        "Pick **Add Transaction from SMS**. Tap the **Message** field and choose **Shortcut Input**.",
        "Tap **Done**. Repeat steps 2–7 for the words **credited**, **spent** and **sent**.",
    ]

    var body: some View {
        List {
            Section {
                Text("iOS doesn't let apps read your SMS inbox. Instead, a Shortcuts automation hands each new bank SMS to Kharcha automatically, in the background.")
                    .font(.subheadline)
            }

            Section("Steps (one time, about 2 minutes)") {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.accentColor, in: Circle())
                        Text(.init(step))
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Tip") {
                Text("Not every SMS has to be a transaction. Kharcha ignores OTPs, payment requests and bill reminders automatically.")
                    .font(.subheadline)
            }

            Section {
                Link(destination: URL(string: "shortcuts://")!) {
                    Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                }
            }
        }
        .navigationTitle("Auto-tracking")
        .navigationBarTitleDisplayMode(.inline)
    }
}
