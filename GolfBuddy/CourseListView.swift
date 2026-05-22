import SwiftUI
import SwiftData

struct CourseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GolfCourse.name) private var courses: [GolfCourse]
    @State private var showAddCourse = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(courses) { course in
                    NavigationLink(destination: CourseDetailView(course: course)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(course.name).font(.headline).foregroundStyle(Color.golfInk)
                            HStack(spacing: 6) {
                                if !course.locationString.isEmpty {
                                    Text(course.locationString)
                                }
                                Text("\(course.holeCount) holes")
                                if course.totalPar > 0 {
                                    Text("• Par \(course.totalPar)")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(Color.golfInkMute)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.golfPaper)
                }
                .onDelete(perform: deleteCourses)
            }
            .scrollContentBackground(.hidden)
            .background(Color.golfPaper.ignoresSafeArea())
            .navigationTitle("Courses")
            .toolbarBackground(Color.golfPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddCourse = true } label: {
                        Image(systemName: "plus").foregroundStyle(Color.golfMoss)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton().foregroundStyle(Color.golfMoss)
                }
            }
            .sheet(isPresented: $showAddCourse) {
                AddCourseView()
            }
            .overlay {
                if courses.isEmpty {
                    ContentUnavailableView("No Courses", systemImage: "map",
                        description: Text("Tap + to add your first course."))
                }
            }
        }
    }

    private func deleteCourses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(courses[index])
        }
    }
}
