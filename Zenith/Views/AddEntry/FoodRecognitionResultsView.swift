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
    @State private var mealType = "snack"

    private let mealTypes = ["breakfast", "lunch", "dinner", "snack"]

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

                        Section {
                            HStack(spacing: 10) {
                                ForEach(mealTypes, id: \.self) { type in
                                    mealButton(type)
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        } header: {
                            Text("Meal")
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 12) {
                            Button {
                                logSelected()
                            } label: {
                                Text("Log Selected (\(selectedIDs.count))")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedIDs.isEmpty ? Color.gray : Color.theme, in: Capsule())
                                    .shadow(color: selectedIDs.isEmpty ? Color.clear : Color.theme.opacity(0.4), radius: 8, y: 4)
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

                HStack(spacing: 6) {
                    nutrientPill(value: "\(candidate.calories)", label: "kcal", color: Color.theme)
                    nutrientPill(value: "\(String(format: "%.0f", candidate.proteinGrams))g", label: "P", color: .proteinColor)
                    nutrientPill(value: "\(String(format: "%.0f", candidate.fatGrams))g", label: "F", color: .fatColor)
                    nutrientPill(value: "\(String(format: "%.0f", candidate.carbsGrams))g", label: "C", color: .carbsColor)
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
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color, in: RoundedRectangle(cornerRadius: 6))
    }

    private func mealButton(_ type: String) -> some View {
        let isSelected = mealType == type
        let icon: String = switch type {
        case "breakfast": "sunrise.fill"
        case "lunch": "sun.max.fill"
        case "dinner": "moon.stars.fill"
        default: "carrot.fill"
        }
        return Button {
            mealType = type
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(height: 22)
                Text(type.capitalized)
                    .font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.theme.opacity(0.1) : .white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.theme : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .foregroundStyle(isSelected ? Color.theme : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func logSelected() {
        for id in selectedIDs {
            if let candidate = candidates.first(where: { $0.id == id }) {
                let entry = FoodEntry(
                    name: candidate.name,
                    calories: candidate.calories,
                    proteinGrams: candidate.proteinGrams,
                    fatGrams: candidate.fatGrams,
                    carbsGrams: candidate.carbsGrams,
                    mealType: mealType
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
