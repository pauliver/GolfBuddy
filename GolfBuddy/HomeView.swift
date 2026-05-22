import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<GolfRound> { !$0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var activeRounds: [GolfRound]
    @Query(sort: \GolfCourse.name) private var courses: [GolfCourse]

    @State private var showCourseSelection = false
    @State private var locationManager = LocationManager()
    @State private var connectivity = ConnectivityManager.shared

    // GPS auto-detect state
    @State private var detectedCourse: GolfCourse?
    @State private var detectionTask: Task<Void, Never>?

    private var activeRound: GolfRound? { activeRounds.first }

    var body: some View {
        NavigationStack {
            Group {
                if let round = activeRound {
                    ActiveRoundView(round: round, locationManager: locationManager)
                } else {
                    noRoundView
                }
            }
            .navigationTitle("GolfBuddy")
            .sheet(isPresented: $showCourseSelection) {
                CourseSelectionSheet { course in
                    startRound(course: course)
                    showCourseSelection = false
                }
            }
            .onAppear {
                locationManager.requestPermission()
            }
            .onChange(of: locationManager.location) { _, loc in
                guard loc != nil, activeRound == nil, detectedCourse == nil else { return }
                detectionTask?.cancel()
                detectionTask = Task { await detectNearbyCourse() }
            }
            .onChange(of: connectivity.pendingStartRound) { _, req in
                guard let req else { return }
                connectivity.pendingStartRound = nil
                handleWatchStartRound(req)
            }
        }
    }

    // MARK: - No-round view

    private var noRoundView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // GPS detection banner
                if let course = detectedCourse {
                    detectionBanner(course: course)
                }

                // Hero area
                VStack(spacing: 12) {
                    Image(systemName: "figure.golf")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.golfMoss)

                    VStack(spacing: 6) {
                        Text("Ready to play?")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.golfInk)
                        Text("Select a course to start tracking your round.")
                            .font(.subheadline)
                            .foregroundStyle(Color.golfInkMute)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                // Start Round button
                Button { showCourseSelection = true } label: {
                    Label("Choose a Course", systemImage: "map")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.golfMoss)
                        .foregroundStyle(Color.golfPaper)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 36)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)
        }
        .background(Color.golfPaper.ignoresSafeArea())
    }

    // MARK: - Detection banner

    private func detectionBanner(course: GolfCourse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundStyle(Color.golfMoss)
                Text("NEARBY")
                    .font(.golfMono(size: 9))
                    .foregroundStyle(Color.golfMoss)
                    .tracking(1.5)
                Spacer()
                Button { detectedCourse = nil } label: {
                    Image(systemName: "xmark").font(.caption2).foregroundStyle(Color.golfInkMute)
                }
            }

            Text(course.name)
                .font(.custom("Georgia", size: 22))
                .foregroundStyle(Color.golfInk)

            if !course.locationString.isEmpty {
                Text(course.locationString)
                    .font(.subheadline)
                    .foregroundStyle(Color.golfInkMute)
            }

            Button { startRound(course: course) } label: {
                Text("Play here")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.golfMoss)
                    .foregroundStyle(Color.golfPaper)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color.golfPaper2, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.golfMoss.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 20)
    }

    // MARK: - Actions

    private func handleWatchStartRound(_ req: ConnectivityManager.StartRoundRequest) {
        let lower = req.courseName.lowercased()
        if let match = courses.first(where: {
            let cn = $0.name.lowercased()
            return cn.contains(lower) || lower.contains(cn) ||
                   cn.split(separator: " ").contains(where: { lower.contains(String($0)) && String($0).count > 3 })
        }) {
            startRound(course: match)
        }
        // If no saved course matches, the watch will show "Check iPhone" and the
        // user can open the app to add the course. Auto-import is a future enhancement.
    }

    private func startRound(course: GolfCourse) {
        let round = GolfRound(course: course)
        modelContext.insert(round)
        detectedCourse = nil
        ConnectivityManager.shared.sendRoundState(round.watchPayload())
    }

    private func detectNearbyCourse() async {
        guard let loc = locationManager.location else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "golf course"
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(center: loc.coordinate,
                                            latitudinalMeters: 1800,
                                            longitudinalMeters: 1800)
        guard let items = try? await MKLocalSearch(request: request).start().mapItems else { return }

        // Keep only courses within 1.2 km
        let nearby = items.filter { item in
            let d = loc.distance(from: CLLocation(latitude: item.placemark.coordinate.latitude,
                                                   longitude: item.placemark.coordinate.longitude))
            return d < 1200
        }

        // Match against saved courses by name
        for item in nearby {
            guard !Task.isCancelled else { return }
            let itemName = (item.name ?? "").lowercased()
            if let match = courses.first(where: { course in
                let cn = course.name.lowercased()
                return cn.contains(itemName) || itemName.contains(cn) ||
                       cn.split(separator: " ").contains(where: { itemName.contains(String($0)) && String($0).count > 3 })
            }) {
                await MainActor.run { detectedCourse = match }
                return
            }
        }
    }
}

// MARK: - Course selection sheet

struct CourseSelectionSheet: View {
    @Query(sort: \GolfCourse.name) private var courses: [GolfCourse]
    let onSelect: (GolfCourse) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(courses) { course in
                Button { onSelect(course) } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(course.name).font(.headline).foregroundStyle(Color.golfInk)
                        HStack(spacing: 6) {
                            if !course.locationString.isEmpty { Text(course.locationString) }
                            Text("\(course.holeCount) holes")
                            if course.totalPar > 0 { Text("· Par \(course.totalPar)") }
                        }
                        .font(.caption).foregroundStyle(Color.golfInkMute)
                    }
                    .padding(.vertical, 3)
                }
                .listRowBackground(Color.golfPaper)
            }
            .scrollContentBackground(.hidden)
            .background(Color.golfPaper.ignoresSafeArea())
            .navigationTitle("Select Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.golfPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.golfMoss)
                }
            }
            .overlay {
                if courses.isEmpty {
                    ContentUnavailableView("No Courses", systemImage: "map",
                        description: Text("Add a course in the Courses tab first."))
                }
            }
        }
    }
}
