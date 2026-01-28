import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]
    @State private var isSyncing = false
    @State private var showHeaderTitle = false

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
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
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

                Section("Daily Goal") {
                    if let s = userSettings {
                        HStack {
                            Text("Calorie Goal")
                            Spacer()
                            Text("\(s.dailyCalorieGoal) kcal")
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(s.dailyCalorieGoal) },
                                set: { s.dailyCalorieGoal = Int($0) }
                            ),
                            in: 1000...5000,
                            step: 50
                        )
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
                Color.clear.frame(height: 44)
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

