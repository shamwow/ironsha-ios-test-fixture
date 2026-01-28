import Foundation
import SwiftData

@Model
final class FoodItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var calories: Int
    var proteinGrams: Double
    var fatGrams: Double
    var carbsGrams: Double
    var isUserCreated: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        proteinGrams: Double = 0,
        fatGrams: Double = 0,
        carbsGrams: Double = 0,
        isUserCreated: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.fatGrams = fatGrams
        self.carbsGrams = carbsGrams
        self.isUserCreated = isUserCreated
        self.createdAt = createdAt
    }
}
