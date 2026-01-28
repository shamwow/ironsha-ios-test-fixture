import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var showAddEntry = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            DashboardView()
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .sheet(isPresented: $showAddEntry) {
            AddEntryView()
                .tint(Color.theme)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .tint(Color.theme)
        }
        .tint(Color.theme)
        .onAppear {
            bootstrapSettings()
        }
    }

    private var bottomBar: some View {
        ZStack {
            // Background pill
            HStack(spacing: 0) {
                Button {
                    // Social — placeholder
                } label: {
                    Image(systemName: "person.2")
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 48, height: 48)
                }
                .tint(.white)

                Spacer()
                    .frame(width: 120)

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 48, height: 48)
                }
                .tint(.white)
            }
            .padding(.horizontal, 44)
            .padding(.vertical, 8)
            .background(Color.theme, in: Capsule())
            .shadow(color: Color.theme.opacity(0.3), radius: 12, y: 4)

            // Plus button centered, extending above and below
            AddButton {
                showAddEntry = true
            }
        }
        .padding(.bottom, 8)
    }

    private func bootstrapSettings() {
        if settings.isEmpty {
            modelContext.insert(UserSettings())
        }
    }
}

private struct AddButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(isPressed ? .white : Color.theme)
            .frame(width: 55, height: 55)
            .background(isPressed ? Color.themeDark : .white, in: Circle())
            .frame(width: 80, height: 80)
            .background(isPressed ? Color.themeDark : Color.theme, in: Circle())
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .simultaneousGesture(TapGesture().onEnded {
                action()
            })
    }
}
