import SwiftUI
import SwiftData

struct AddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [CourseSearchResult] = []
    @State private var isSearching = false
    @State private var selected: CourseSearchResult?
    @State private var mergedHoles: [HoleImportData] = []
    @State private var isFetchingGPS = false
    @State private var gpsStatus: GPSStatus = .idle
    @State private var showManual = false

    enum GPSStatus { case idle, fetching, found(Int), none }

    var body: some View {
        NavigationStack {
            Group {
                if let course = selected {
                    confirmView(course: course)
                } else {
                    searchView
                }
            }
            .navigationTitle("Add Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selected != nil {
                        Button("Back") { selected = nil; mergedHoles = []; gpsStatus = .idle }
                    } else {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }

    // MARK: - Search view

    private var searchView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Course name or location…", text: $searchText)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { Task { await performSearch() } }
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color.golfPaper2, in: RoundedRectangle(cornerRadius: 10))
            .padding()

            if isSearching {
                Spacer()
                ProgressView("Searching…")
                Spacer()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                Spacer()
                ContentUnavailableView("No Results", systemImage: "magnifyingglass",
                    description: Text("Try a different name or city."))
                Spacer()
            } else {
                List(searchResults) { result in
                    Button { Task { await selectResult(result) } } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(result.name)
                                .font(.headline).foregroundStyle(Color.golfInk)
                            HStack(spacing: 8) {
                                if !result.locationString.isEmpty {
                                    Text(result.locationString)
                                        .font(.caption).foregroundStyle(Color.golfInkMute)
                                }
                                Text("Par \(result.totalPar) · \(result.holeCount) holes")
                                    .font(.caption).foregroundStyle(Color.golfFairway)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.golfPaper)
            }

            Divider()
            Button("Enter Manually Instead") { showManual = true }
                .font(.subheadline)
                .foregroundStyle(Color.golfMoss)
                .padding()
        }
        .background(Color.golfPaper.ignoresSafeArea())
        .onChange(of: searchText) { _, text in
            if text.count > 2 { Task { await performSearch() } }
        }
        .sheet(isPresented: $showManual) { ManualCourseEntryView() }
    }

    // MARK: - Confirm / import view

    @ViewBuilder
    private func confirmView(course: CourseSearchResult) -> some View {
        List {
            Section("Course") {
                LabeledContent("Name", value: course.name)
                if !course.city.isEmpty { LabeledContent("City", value: course.city) }
                if !course.state.isEmpty { LabeledContent("State", value: course.state) }
                LabeledContent("Par", value: "\(course.totalPar)")
                LabeledContent("Holes", value: "\(course.holeCount)")
            }

            Section("Scorecard") {
                ForEach(mergedHoles.isEmpty ? course.holes : mergedHoles, id: \.number) { hole in
                    HStack {
                        Text("Hole \(hole.number)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(Color.golfInkSoft)
                            .frame(width: 70, alignment: .leading)
                        Text("Par \(hole.par)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color.golfInkMute)
                        Spacer()
                        if hole.yardage > 0 {
                            Text("\(hole.yardage) yd")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.golfInk)
                        }
                        if hole.pinLatitude != nil {
                            Image(systemName: "flag.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.golfPin)
                        }
                    }
                }
            }

            Section {
                switch gpsStatus {
                case .idle:
                    EmptyView()
                case .fetching:
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Fetching GPS coordinates…")
                            .font(.subheadline).foregroundStyle(Color.golfInkMute)
                    }
                case .found(let count):
                    Label("\(count) of \(course.holeCount) pin locations found", systemImage: "flag.fill")
                        .foregroundStyle(Color.golfMoss)
                    if count < course.holeCount {
                        Text("Remaining holes will be mapped automatically the first time you play them.")
                            .font(.caption).foregroundStyle(Color.golfInkMute)
                    }
                case .none:
                    Label("No GPS data found in OpenStreetMap", systemImage: "location.slash")
                        .font(.caption).foregroundStyle(.orange)
                    Text("Pin locations can be recorded on-course as you play.")
                        .font(.caption).foregroundStyle(Color.golfInkMute)
                }
            } header: {
                Text("GPS Coordinates")
            }

            Section {
                Button(action: importCourse) {
                    Text("Import Course")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .disabled(gpsStatus == .fetching)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.golfPaper.ignoresSafeArea())
    }

    // MARK: - Actions

    private func performSearch() async {
        isSearching = true
        defer { isSearching = false }
        do { searchResults = try await CourseImportService.searchCourses(query: searchText) }
        catch { searchResults = [] }
    }

    private func selectResult(_ result: CourseSearchResult) async {
        selected = result
        mergedHoles = result.holes
        gpsStatus = .fetching
        do {
            let enriched = try await CourseImportService.supplementWithGPS(
                holes: result.holes, at: result.coordinate)
            mergedHoles = enriched
            let pinCount = enriched.filter { $0.pinLatitude != nil }.count
            gpsStatus = pinCount > 0 ? .found(pinCount) : .none
        } catch {
            gpsStatus = .none
        }
    }

    private func importCourse() {
        guard let result = selected else { return }
        let course = GolfCourse(name: result.name, city: result.city, state: result.state)
        modelContext.insert(course)

        let holes = mergedHoles.isEmpty ? result.holes : mergedHoles
        for data in holes {
            let hole = GolfHole(
                number: data.number,
                par: data.par,
                handicap: data.handicap,
                yardage: data.yardage
            )
            if let lat = data.pinLatitude, let lon = data.pinLongitude {
                hole.pinLatitude = lat; hole.pinLongitude = lon; hole.hasPinCoordinates = true
            }
            if let lat = data.teeLatitude, let lon = data.teeLongitude {
                hole.teeLatitude = lat; hole.teeLongitude = lon; hole.hasTeeCoordinates = true
            }
            hole.course = course
            course.holes.append(hole)
            modelContext.insert(hole)
        }
        dismiss()
    }
}

// MARK: - Equatable for GPSStatus switch in disabled
extension AddCourseView.GPSStatus: Equatable {
    static func == (lhs: AddCourseView.GPSStatus, rhs: AddCourseView.GPSStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.fetching, .fetching), (.none, .none): return true
        case (.found(let a), .found(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Manual fallback

struct ManualCourseEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var city = ""
    @State private var state = ""
    @State private var holeCount = 18

    var body: some View {
        NavigationStack {
            Form {
                Section("Course Info") {
                    TextField("Course Name", text: $name)
                    TextField("City", text: $city)
                    TextField("State / Region", text: $state)
                }
                Section("Holes") {
                    Picker("Number of Holes", selection: $holeCount) {
                        Text("9 holes").tag(9)
                        Text("18 holes").tag(18)
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Text("Par, yardage, and GPS coordinates can be set per-hole after creating the course.")
                        .font(.caption).foregroundStyle(Color.golfInkMute)
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let course = GolfCourse(
            name:  name.trimmingCharacters(in: .whitespaces),
            city:  city.trimmingCharacters(in: .whitespaces),
            state: state.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(course)
        for i in 1...holeCount {
            let hole = GolfHole(number: i, par: 4, handicap: i, yardage: 0)
            hole.course = course; course.holes.append(hole); modelContext.insert(hole)
        }
        dismiss()
    }
}
