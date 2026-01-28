import SwiftUI
import SwiftData

@main
struct ZenithApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FoodItem.self, FoodEntry.self, UserSettings.self])
    }
}
