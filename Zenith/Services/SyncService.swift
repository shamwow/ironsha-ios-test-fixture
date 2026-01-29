import Foundation
import SwiftData
import UIKit

@MainActor
struct SyncService {
    let apiClient: APIClient

    func syncAll(modelContext: ModelContext, settings: UserSettings) async {
        do {
            try await upload(modelContext: modelContext, settings: settings)
            try await download(modelContext: modelContext, settings: settings)
            settings.lastSyncDate = .now
        } catch {
            print("Sync failed: \(error)")
        }
    }

    private func upload(modelContext: ModelContext, settings: UserSettings) async throws {
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { $0.needsSync }
        )
        let unsyncedEntries = (try? modelContext.fetch(descriptor)) ?? []

        let request = SyncUploadRequest(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            lastSyncTimestamp: settings.lastSyncDate,
            foodEntries: unsyncedEntries.map { entry in
                SyncFoodEntryDTO(
                    id: entry.id.uuidString,
                    name: entry.name,
                    calories: entry.calories,
                    proteinGrams: entry.proteinGrams,
                    fatGrams: entry.fatGrams,
                    carbsGrams: entry.carbsGrams,
                    servings: entry.servings,
                    loggedAt: entry.loggedAt,
                    mealType: entry.mealType
                )
            },
            dailyCalorieGoal: settings.dailyCalorieGoal
        )

        let response = try await apiClient.uploadSync(request: request)
        if response.success {
            for entry in unsyncedEntries {
                entry.needsSync = false
                entry.syncedAt = .now
            }
        }
    }

    private func download(modelContext: ModelContext, settings: UserSettings) async throws {
        let request = SyncDownloadRequest(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            lastSyncTimestamp: settings.lastSyncDate
        )

        let response = try await apiClient.downloadSync(request: request)

        if let goal = response.dailyCalorieGoal {
            settings.dailyCalorieGoal = goal
        }
    }
}
