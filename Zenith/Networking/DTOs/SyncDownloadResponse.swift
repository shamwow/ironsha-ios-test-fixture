import Foundation

struct SyncDownloadResponse: Codable {
    let serverTimestamp: Date
    let foodItems: [SyncFoodItemDTO]
    let foodEntries: [SyncFoodEntryDTO]
    let dailyCalorieGoal: Int?
}
