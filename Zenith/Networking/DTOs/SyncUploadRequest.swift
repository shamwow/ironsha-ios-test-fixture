import Foundation

struct SyncUploadRequest: Codable {
    let deviceId: String
    let lastSyncTimestamp: Date?
    let foodItems: [SyncFoodItemDTO]
    let foodEntries: [SyncFoodEntryDTO]
    let dailyCalorieGoal: Int
}

struct SyncFoodItemDTO: Codable {
    let id: String
    let name: String
    let calories: Int
    let proteinGrams: Double
    let fatGrams: Double
    let carbsGrams: Double
    let isUserCreated: Bool
    let createdAt: Date
}

struct SyncFoodEntryDTO: Codable {
    let id: String
    let name: String
    let calories: Int
    let proteinGrams: Double
    let fatGrams: Double
    let carbsGrams: Double
    let servings: Double
    let loggedAt: Date
    let mealType: String
}
