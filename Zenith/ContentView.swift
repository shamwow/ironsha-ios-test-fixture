import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var showSettings = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showRecognitionResults = false
    @State private var selectedCandidate: FoodCandidate?
    @State private var pendingAddEntry = false
    @State private var addEntryRequest: AddEntryRequest?

    var body: some View {
        NavigationStack {
            DashboardView()
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $capturedImage)
        }
        .sheet(isPresented: $showRecognitionResults, onDismiss: {
            if pendingAddEntry {
                pendingAddEntry = false
                addEntryRequest = AddEntryRequest(candidate: selectedCandidate)
            }
        }) {
            if let image = capturedImage {
                FoodRecognitionResultsView(
                    image: image,
                    onCandidateSelected: { candidate in
                        selectedCandidate = candidate
                        pendingAddEntry = true
                    },
                    onManualEntry: {
                        selectedCandidate = nil
                        pendingAddEntry = true
                    }
                )
                .tint(Color.theme)
            }
        }
        .sheet(item: $addEntryRequest) { request in
            AddEntryView(prefillCandidate: request.candidate)
                .tint(Color.theme)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .tint(Color.theme)
        }
        .onChange(of: capturedImage) { _, newImage in
            if newImage != nil {
                showRecognitionResults = true
            }
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
                capturedImage = nil
                showCamera = true
            }
        }
        .padding(.bottom, 8)
    }

    private func bootstrapSettings() {
        if settings.isEmpty {
            modelContext.insert(UserSettings())
            try? modelContext.save()
        }
    }
}

struct AddEntryRequest: Identifiable {
    let id = UUID()
    let candidate: FoodCandidate?
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
