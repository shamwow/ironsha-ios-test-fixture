import SwiftData
import SwiftUI

@main
struct ZenithApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FoodEntry.self, UserSettings.self])
    }
}
