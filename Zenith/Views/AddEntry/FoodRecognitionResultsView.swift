import SwiftUI
import UIKit

struct FoodRecognitionResultsView: View {
    let image: UIImage
    let onCandidateSelected: (FoodCandidate) -> Void
    let onManualEntry: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var candidates: [FoodCandidate] = []
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
                                Button {
                                    onCandidateSelected(candidate)
                                    dismiss()
                                } label: {
                                    candidateRow(candidate)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text("Photo Matches")
                        }

                        Section {
                            Button {
                                onManualEntry()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "pencil.line")
                                    Text("Enter Manually")
                                }
                                .foregroundStyle(Color.theme)
                            }
                        }
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
        VStack(alignment: .leading, spacing: 10) {
            Text(candidate.name)
                .font(.headline)

            Text(candidate.servingDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                nutrientColumn(value: "\(candidate.calories)", label: "Calories")
                Divider().padding(.vertical, 4)
                nutrientColumn(value: "\(String(format: "%.0f", candidate.proteinGrams))g", label: "Protein")
                Divider().padding(.vertical, 4)
                nutrientColumn(value: "\(String(format: "%.0f", candidate.fatGrams))g", label: "Fat")
                Divider().padding(.vertical, 4)
                nutrientColumn(value: "\(String(format: "%.0f", candidate.carbsGrams))g", label: "Carbs")
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private func nutrientColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
