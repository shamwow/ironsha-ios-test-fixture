import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var showSettings = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showRecognitionResults = false
    @State private var pendingManualEntry = false
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
            if pendingManualEntry {
                pendingManualEntry = false
                addEntryRequest = AddEntryRequest(candidate: nil)
            }
        }) {
            if let image = capturedImage {
                FoodRecognitionResultsView(
                    image: image,
                    onEntriesSaved: {
                        // entries already saved via modelContext; just dismiss
                    },
                    onManualEntry: {
                        pendingManualEntry = true
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
        HStack {
            HStack(spacing: 16) {
                Button {
                    // Social — placeholder
                } label: {
                    Image(systemName: "person.2")
                        .font(.system(size: 24, weight: .medium))
                        .frame(width: 60, height: 60)
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 24, weight: .medium))
                        .frame(width: 60, height: 60)
                }
            }
            .modify { view in
                if #available(iOS 26.0, *) {
                    view.glassEffect(.regular.interactive(), in: Capsule())
                } else {
                    view
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            
            Spacer()
            
            AddButton {
                capturedImage = nil
                showCamera = true
            }
        }
        .padding(.horizontal, 16)
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

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.white)
                .frame(width: 60, height: 60)
        }
        .modify { view in
            if #available(iOS 26.0, *) {
                view.glassEffect(.clear.interactive().tint(Color.theme.opacity(0.9)), in: Circle())
            } else {
                view.background(.ultraThinMaterial, in: Circle())
            }
        }
    }
}
