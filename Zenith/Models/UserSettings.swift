import Foundation
import SwiftData

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var dailyCalorieGoal: Int
    var syncEnabled: Bool
    var lastSyncDate: Date?

    init(
        id: UUID = UUID(),
        dailyCalorieGoal: Int = 2000,
        syncEnabled: Bool = false,
        lastSyncDate: Date? = nil
    ) {
        self.id = id
        self.dailyCalorieGoal = dailyCalorieGoal
        self.syncEnabled = syncEnabled
        self.lastSyncDate = lastSyncDate
    }
}
