import Foundation
import SwiftData

@Model
final class FoodEntry {
    @Attribute(.unique) var id: UUID
    var name: String
    var calories: Int
    var proteinGrams: Double
    var fatGrams: Double
    var carbsGrams: Double
    var servings: Double
    var loggedAt: Date
    var mealType: String
    var syncedAt: Date?
    var needsSync: Bool

    var totalCalories: Int {
        Int(Double(calories) * servings)
    }

    var totalProtein: Double {
        proteinGrams * servings
    }

    var totalFat: Double {
        fatGrams * servings
    }

    var totalCarbs: Double {
        carbsGrams * servings
    }

    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        proteinGrams: Double = 0,
        fatGrams: Double = 0,
        carbsGrams: Double = 0,
        servings: Double = 1.0,
        loggedAt: Date = .now,
        mealType: String = "snack",
        syncedAt: Date? = nil,
        needsSync: Bool = true
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.fatGrams = fatGrams
        self.carbsGrams = carbsGrams
        self.servings = servings
        self.loggedAt = loggedAt
        self.mealType = mealType
        self.syncedAt = syncedAt
        self.needsSync = needsSync
    }

    convenience init(from foodItem: FoodItem, servings: Double = 1.0, mealType: String = "snack") {
        self.init(
            name: foodItem.name,
            calories: foodItem.calories,
            proteinGrams: foodItem.proteinGrams,
            fatGrams: foodItem.fatGrams,
            carbsGrams: foodItem.carbsGrams,
            servings: servings,
            mealType: mealType
        )
    }
}
