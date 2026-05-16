import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct AddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var selectedItem: MKMapItem?
    @State private var osmHoles: [OSMHoleData] = []
    @State private var isFetchingOSM = false
    @State private var osmError: String?
    @State private var holeCount = 18
    @State private var showManual = false

    var body: some View {
        NavigationStack {
            Group {
                if let item = selectedItem {
                    confirmView(item: item)
                } else {
                    searchView
                }
            }
            .navigationTitle("Add Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selectedItem != nil {
                        Button("Back") { selectedItem = nil; osmHoles = [] }
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
                List(searchResults, id: \.self) { item in
                    Button { Task { await selectItem(item) } } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name ?? "Unknown")
                                .font(.headline).foregroundStyle(Color.golfInk)
                            if let addr = item.placemark.title, addr != item.name {
                                Text(addr)
                                    .font(.caption).foregroundStyle(Color.golfInkMute)
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
    private func confirmView(item: MKMapItem) -> some View {
        List {
            Section {
                LabeledContent("Course", value: item.name ?? "")
                if let city = item.placemark.locality { LabeledContent("City", value: city) }
                if let state = item.placemark.administrativeArea { LabeledContent("State", value: state) }
            }

            Section("Holes") {
                Picker("Number of Holes", selection: $holeCount) {
                    Text("9 holes").tag(9)
                    Text("18 holes").tag(18)
                }
                .pickerStyle(.segmented)
            }

            Section {
                if isFetchingOSM {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Fetching hole coordinates from OpenStreetMap…")
                            .font(.subheadline).foregroundStyle(Color.golfInkMute)
                    }
                } else if let err = osmError {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.orange)
                } else if osmHoles.isEmpty {
                    Text("No GPS coordinates found in OSM. Tee and pin locations can be recorded on-course as you play.")
                        .font(.caption).foregroundStyle(Color.golfInkMute)
                } else {
                    let pins = osmHoles.filter { $0.pinLatitude != nil }.count
                    let tees = osmHoles.filter { $0.teeLatitude != nil }.count
                    Label("\(pins) of \(holeCount) pin locations found", systemImage: "flag.fill")
                        .foregroundStyle(Color.golfMoss)
                    Label("\(tees) of \(holeCount) tee locations found", systemImage: "circle.fill")
                        .foregroundStyle(Color.golfFairway)
                    if pins < holeCount {
                        Text("Missing holes will be recorded automatically the first time you play them.")
                            .font(.caption).foregroundStyle(Color.golfInkMute)
                    }
                }
            } header: {
                Text("GPS Data (OpenStreetMap)")
            }

            Section {
                Button(action: importCourse) {
                    Text("Import Course")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .disabled(isFetchingOSM)
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

    private func selectItem(_ item: MKMapItem) async {
        selectedItem = item
        isFetchingOSM = true
        osmError = nil
        do {
            let data = try await CourseImportService.fetchHoleData(coordinate: item.placemark.coordinate)
            osmHoles = data
        } catch {
            osmError = "Couldn't fetch OSM data. Locations can be set on-course."
        }
        isFetchingOSM = false
    }

    private func importCourse() {
        guard let item = selectedItem else { return }
        let course = GolfCourse(
            name:  item.name ?? "Unknown Course",
            city:  item.placemark.locality ?? "",
            state: item.placemark.administrativeArea ?? ""
        )
        modelContext.insert(course)

        for i in 1...holeCount {
            let osm = osmHoles.first { $0.number == i }
            let hole = GolfHole(number: i, par: osm?.par ?? 4, handicap: osm?.handicap ?? i, yardage: 0)
            if let lat = osm?.pinLatitude, let lon = osm?.pinLongitude {
                hole.pinLatitude = lat; hole.pinLongitude = lon; hole.hasPinCoordinates = true
            }
            if let lat = osm?.teeLatitude, let lon = osm?.teeLongitude {
                hole.teeLatitude = lat; hole.teeLongitude = lon; hole.hasTeeCoordinates = true
            }
            hole.course = course
            course.holes.append(hole)
            modelContext.insert(hole)
        }
        dismiss()
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
