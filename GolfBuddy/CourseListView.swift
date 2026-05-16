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
                            Text(course.name).font(.headline)
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
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteCourses)
            }
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddCourse = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
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
