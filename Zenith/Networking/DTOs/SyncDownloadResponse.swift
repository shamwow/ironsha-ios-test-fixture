import Foundation

struct SyncDownloadResponse: Codable {
    let serverTimestamp: Date
    let foodEntries: [SyncFoodEntryDTO]
    let dailyCalorieGoal: Int?
}
