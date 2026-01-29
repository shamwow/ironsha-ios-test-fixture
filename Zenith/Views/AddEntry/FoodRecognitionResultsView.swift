import SwiftUI
import SwiftData
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
                        Section { } header: {
                            Spacer()
                        }

                        Section {
                            ForEach(candidates) { candidate in
                                candidateRow(candidate)
                                    .contentShape(Rectangle())
                                    .listRowBackground(
                                        selectedIDs.contains(candidate.id)
                                        ? Color.theme.opacity(0.1)
                                        : Color(.secondarySystemGroupedBackground)
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
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)
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
                                    RoundedRectangle(cornerRadius: 10)
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

                HStack(spacing: 0) {
                    nutrientColumn(value: "\(candidate.calories)", label: "Calories")
                    Divider().padding(.all, 4)
                    nutrientColumn(value: "\(String(format: "%.0f", candidate.proteinGrams))g", label: "Protein")
                    Divider().padding(.all, 4)
                    nutrientColumn(value: "\(String(format: "%.0f", candidate.fatGrams))g", label: "Fat")
                    Divider().padding(.all, 4)
                    nutrientColumn(value: "\(String(format: "%.0f", candidate.carbsGrams))g", label: "Carbs")
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
    }

    private func nutrientColumn(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            if response.recognized && !response.candidates.isEmpty {
                candidates = response.candidates
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
