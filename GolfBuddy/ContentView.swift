import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Play", systemImage: "flag.fill") }

            CourseListView()
                .tabItem { Label("Courses", systemImage: "map") }

            RoundHistoryView()
                .tabItem { Label("History", systemImage: "chart.bar.fill") }
        }
        .tint(Color.golfMoss)
    }
}

#Preview {
    ContentView()
}

