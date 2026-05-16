import SwiftUI

@main
struct GolfBuddy_Watch_AppApp: App {
    init() {
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
