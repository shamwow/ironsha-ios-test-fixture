import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]
    @State private var isSyncing = false
    @State private var showHeaderTitle = false
    @State private var editingGoal: GoalType?
    @State private var editText = ""

    private var userSettings: UserSettings? {
        settings.first
    }

    var body: some View {
        ZStack(alignment: .top) {
            Form {
                Section {
                    Text("Settings")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color.theme)
                        .opacity(showHeaderTitle ? 0 : 1)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowBackground(Color.clear)
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        let maxY = geo.frame(in: .global).maxY
                                        let shouldShow = maxY < 100
                                        if shouldShow != showHeaderTitle { showHeaderTitle = shouldShow }
                                    }
                                    .onChange(of: geo.frame(in: .global).maxY) { _, newValue in
                                        let shouldShow = newValue < 100
                                        if shouldShow != showHeaderTitle { showHeaderTitle = shouldShow }
                                    }
                            }
                        )
                }

                Section("Nutrition Goals") {
                    if let s = userSettings {
                        GoalRow(label: "Calories", value: "\(s.dailyCalorieGoal)", unit: "kcal") {
                            editingGoal = .calories; editText = "\(s.dailyCalorieGoal)"
                        }
                        GoalRow(label: "Protein", value: "\(Int(s.dailyProteinGoal))", unit: "g") {
                            editingGoal = .protein; editText = "\(Int(s.dailyProteinGoal))"
                        }
                        GoalRow(label: "Fat", value: "\(Int(s.dailyFatGoal))", unit: "g") {
                            editingGoal = .fat; editText = "\(Int(s.dailyFatGoal))"
                        }
                        GoalRow(label: "Carbs", value: "\(Int(s.dailyCarbsGoal))", unit: "g") {
                            editingGoal = .carbs; editText = "\(Int(s.dailyCarbsGoal))"
                        }
                    }
                }

                Section("Sync") {
                    if let s = userSettings {
                        Toggle("Enable Sync", isOn: Binding(
                            get: { s.syncEnabled },
                            set: { s.syncEnabled = $0 }
                        ))

                        if s.syncEnabled {
                            Button {
                                performSync()
                            } label: {
                                HStack {
                                    Text("Sync Now")
                                    Spacer()
                                    if isSyncing {
                                        ProgressView()
                                    }
                                }
                            }
                            .disabled(isSyncing)

                            if let lastSync = s.lastSyncDate {
                                HStack {
                                    Text("Last Synced")
                                    Spacer()
                                    Text(lastSync.shortFormatted)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 28)
            }
            .alert(
                editingGoal?.label ?? "",
                isPresented: Binding(
                    get: { editingGoal != nil },
                    set: { if !$0 { editingGoal = nil } }
                )
            ) {
                TextField("0", text: $editText)
                    .keyboardType(.numberPad)
                Button("Save") {
                    if let s = userSettings, let goal = editingGoal,
                       let val = Double(editText), val > 0 {
                        switch goal {
                        case .calories: s.dailyCalorieGoal = Int(val)
                        case .protein: s.dailyProteinGoal = val
                        case .fat: s.dailyFatGoal = val
                        case .carbs: s.dailyCarbsGoal = val
                        }
                    }
                    editingGoal = nil
                }
                Button("Cancel", role: .cancel) { editingGoal = nil }
            } message: {
                if let goal = editingGoal {
                    Text("Enter your daily \(goal.label.lowercased()) goal in \(goal.unit)")
                }
            }

            // Floating header overlay
            VStack(spacing: 0) {
                ZStack {
                    if showHeaderTitle {
                        Text("Settings")
                            .font(.headline)
                            .foregroundStyle(Color.theme)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: showHeaderTitle)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        stops: [
                            .init(color: Color(.systemGroupedBackground), location: 0),
                            .init(color: Color(.systemGroupedBackground), location: 0.6),
                            .init(color: Color(.systemGroupedBackground).opacity(0), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Spacer()
            }
        }
    }

    private func performSync() {
        guard let s = userSettings else { return }
        isSyncing = true
        let service = SyncService(apiClient: MockAPIClient())
        Task {
            await service.syncAll(modelContext: modelContext, settings: s)
            isSyncing = false
        }
    }
}

private enum GoalType {
    case calories, protein, fat, carbs

    var label: String {
        switch self {
        case .calories: "Calories"
        case .protein: "Protein"
        case .fat: "Fat"
        case .carbs: "Carbs"
        }
    }

    var unit: String {
        switch self {
        case .calories: "kcal"
        case .protein, .fat, .carbs: "grams"
        }
    }
}

private struct GoalRow: View {
    let label: String
    let value: String
    let unit: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value) \(unit)")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
