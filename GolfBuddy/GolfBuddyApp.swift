import SwiftUI
import SwiftData

@main
struct GolfBuddyApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: GolfCourse.self, GolfHole.self, GolfRound.self, HoleScore.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
        _ = ConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
