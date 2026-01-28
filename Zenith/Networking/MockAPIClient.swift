import Foundation

struct MockAPIClient: APIClient {
    func recognizeFood(request: FoodRecognitionRequest) async throws -> FoodRecognitionResponse {
        try await Task.sleep(for: .seconds(1.5))

        return FoodRecognitionResponse(
            requestId: request.requestId,
            recognized: true,
            candidates: [
                FoodCandidate(
                    id: UUID().uuidString,
                    name: "Grilled Chicken Breast",
                    confidence: 0.92,
                    calories: 165,
                    proteinGrams: 31.0,
                    fatGrams: 3.6,
                    carbsGrams: 0.0,
                    servingDescription: "1 breast (120g)"
                ),
                FoodCandidate(
                    id: UUID().uuidString,
                    name: "Baked Chicken Thigh",
                    confidence: 0.74,
                    calories: 209,
                    proteinGrams: 26.0,
                    fatGrams: 10.9,
                    carbsGrams: 0.0,
                    servingDescription: "1 thigh (130g)"
                )
            ],
            errorMessage: nil
        )
    }

    func uploadSync(request: SyncUploadRequest) async throws -> SyncUploadResponse {
        try await Task.sleep(for: .seconds(1))

        return SyncUploadResponse(
            serverTimestamp: .now,
            conflictCount: 0,
            success: true
        )
    }

    func downloadSync(request: SyncDownloadRequest) async throws -> SyncDownloadResponse {
        try await Task.sleep(for: .seconds(1))

        return SyncDownloadResponse(
            serverTimestamp: .now,
            foodItems: [],
            foodEntries: [],
            dailyCalorieGoal: nil
        )
    }
}
