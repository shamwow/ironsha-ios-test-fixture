import Foundation
import SwiftData

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var dailyCalorieGoal: Int
    var dailyProteinGoal: Double = 150
    var dailyFatGoal: Double = 65
    var dailyCarbsGoal: Double = 250
    var syncEnabled: Bool
    var lastSyncDate: Date?

    init(
        id: UUID = UUID(),
        dailyCalorieGoal: Int = 2000,
        dailyProteinGoal: Double = 150,
        dailyFatGoal: Double = 65,
        dailyCarbsGoal: Double = 250,
        syncEnabled: Bool = false,
        lastSyncDate: Date? = nil
    ) {
        self.id = id
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyFatGoal = dailyFatGoal
        self.dailyCarbsGoal = dailyCarbsGoal
        self.syncEnabled = syncEnabled
        self.lastSyncDate = lastSyncDate
    }
}
