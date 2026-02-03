import SwiftData
import SwiftUI
import UIKit

struct FoodRecognitionResultsView: View {
    let image: UIImage
    let onEntriesSaved: () -> Void
    let onManualEntry: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var candidates: [FoodCandidate] = []
    @State private var selectedIDs: Set<String> = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Recognizing food...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if candidates.isEmpty {
                    ContentUnavailableView {
                        Label("No Match Found", systemImage: "fork.knife.circle")
                    } description: {
                        Text("We couldn't identify the food in your photo.")
                    } actions: {
                        Button("Enter Manually") {
                            onManualEntry()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section {} header: {
                            Spacer()
                        }

                        Section {
                            ForEach(candidates) { candidate in
                                candidateRow(candidate)
                                    .contentShape(Rectangle())
                                    .listRowBackground(
                                        selectedIDs.contains(candidate.id)
                                            ? Color.theme.opacity(0.1)
                                            : Color.secondarySurfaceBackground
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            if selectedIDs.contains(candidate.id) {
                                                selectedIDs.remove(candidate.id)
                                            } else {
                                                selectedIDs.insert(candidate.id)
                                            }
                                        }
                                    }
                            }
                        } header: {
                            Text("Photo Matches")
                        }

                    }
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 12) {
                            Button {
                                logSelected()
                            } label: {
                                Text("Log Selected (\(selectedIDs.count))")
                                    .font(.headline)
                                    .foregroundStyle(Color.cardBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedIDs.isEmpty ? Color.subtle : Color.theme, in: Capsule())
                                    .shadow(
                                        color: selectedIDs.isEmpty ? Color.clear : Color.theme.opacity(0.4),
                                        radius: 8,
                                        y: 4
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(selectedIDs.isEmpty)

                            Button {
                                onManualEntry()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "pencil.line")
                                    Text("Enter Manually")
                                }
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.theme, lineWidth: 1.5)
                                )
                            }
                            .foregroundStyle(Color.theme)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .background(.bar)
                    }
                }
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .padding(.trailing, 16)
            .padding(.top, 14)
        }
        .task {
            await recognizeFood()
        }
    }

    private func candidateRow(_ candidate: FoodCandidate) -> some View {
        HStack(spacing: 12) {
            Image(systemName: selectedIDs.contains(candidate.id) ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(selectedIDs.contains(candidate.id) ? Color.theme : .secondary)
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(candidate.name)
                        .font(.headline)

                    Text(candidate.servingDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                FlowLayout(spacing: 6) {
                    nutrientPill(value: "\(candidate.calories)", label: "calories", color: Color.theme)
                    nutrientPill(
                        value: "\(String(format: "%.0f", candidate.proteinGrams))g",
                        label: "protein",
                        color: .proteinColor
                    )
                    nutrientPill(
                        value: "\(String(format: "%.0f", candidate.fatGrams))g",
                        label: "fat",
                        color: .fatColor
                    )
                    nutrientPill(
                        value: "\(String(format: "%.0f", candidate.carbsGrams))g",
                        label: "carbs",
                        color: .carbsColor
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func nutrientPill(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.caption.weight(.semibold))
            Text(label)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(Color.cardBackground)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color, in: RoundedRectangle(cornerRadius: 6))
    }

    private func logSelected() {
        for id in selectedIDs {
            if let candidate = candidates.first(where: { $0.id == id }) {
                let entry = FoodEntry(
                    name: candidate.name,
                    calories: candidate.calories,
                    proteinGrams: candidate.proteinGrams,
                    fatGrams: candidate.fatGrams,
                    carbsGrams: candidate.carbsGrams
                )
                modelContext.insert(entry)
            }
        }
        try? modelContext.save()
        onEntriesSaved()
        dismiss()
    }

    private func recognizeFood() async {
        let service = PhotoRecognitionService(apiClient: LiveAPIClient())
        do {
            let response = try await service.recognize(image: image)
            if response.recognized, !response.candidates.isEmpty {
                candidates = response.candidates
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
