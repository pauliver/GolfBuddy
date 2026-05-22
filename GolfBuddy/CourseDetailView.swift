import SwiftUI
import SwiftData
import CoreLocation
import MapKit

struct CourseDetailView: View {
    @Bindable var course: GolfCourse
    @Environment(\.modelContext) private var modelContext
    @State private var locationManager = LocationManager()
    @State private var editingHole: GolfHole?
    @State private var lookAroundScene: MKLookAroundScene?

    private var lookAroundCoordinate: CLLocationCoordinate2D? {
        course.sortedHoles.first(where: \.hasPinCoordinates)?.pinCoordinate ??
        course.sortedHoles.first(where: \.hasTeeCoordinates)?.teeCoordinate
    }

    var body: some View {
        List {
            Section("Course Info") {
                LabeledContent("Name") {
                    TextField("Name", text: $course.name)
                        .foregroundStyle(Color.golfInkSoft)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("City") {
                    TextField("City", text: $course.city)
                        .foregroundStyle(Color.golfInkSoft)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("State") {
                    TextField("State", text: $course.state)
                        .foregroundStyle(Color.golfInkSoft)
                        .multilineTextAlignment(.trailing)
                }
            }
            .foregroundStyle(Color.golfInk)
            .listRowBackground(Color.golfPaper)

            if lookAroundScene != nil {
                Section("Look Around") {
                    LookAroundPreview(scene: $lookAroundScene)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }
                .listRowBackground(Color.golfPaper)
            }

            Section("Holes") {
                ForEach(course.sortedHoles) { hole in
                    Button { editingHole = hole } label: {
                        HoleRowView(hole: hole)
                    }
                    .foregroundStyle(Color.golfInk)
                    .listRowBackground(Color.golfPaper)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.golfPaper.ignoresSafeArea())
        .navigationTitle(course.name.isEmpty ? "Course" : course.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { locationManager.requestPermission() }
        .sheet(item: $editingHole) { hole in
            HoleEditView(hole: hole, locationManager: locationManager)
        }
        .task {
            guard let coord = lookAroundCoordinate else { return }
            lookAroundScene = try? await MKLookAroundSceneRequest(coordinate: coord).scene
        }
    }
}

struct HoleRowView: View {
    let hole: GolfHole

    var body: some View {
        HStack {
            Text("Hole \(hole.number)")
                .fontWeight(.medium)
            Spacer()
            HStack(spacing: 12) {
                Text("Par \(hole.par)")
                    .foregroundStyle(Color.golfInkMute)
                if hole.yardage > 0 {
                    Text("\(hole.yardage) yds")
                        .foregroundStyle(Color.golfInkMute)
                }
                if hole.hasPinCoordinates {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundStyle(Color.golfMoss)
                }
            }
            .font(.subheadline)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.golfInkMute.opacity(0.5))
        }
        .padding(.vertical, 2)
    }
}

struct HoleEditView: View {
    @Bindable var hole: GolfHole
    let locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Hole \(hole.number)") {
                    Picker("Par", selection: $hole.par) {
                        Text("Par 3").tag(3)
                        Text("Par 4").tag(4)
                        Text("Par 5").tag(5)
                    }
                    .pickerStyle(.segmented)

                    LabeledContent("Handicap") {
                        TextField("1–18", value: $hole.handicap, format: .number)
                            .foregroundStyle(Color.golfInkSoft)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Yardage") {
                        TextField("0", value: $hole.yardage, format: .number)
                            .foregroundStyle(Color.golfInkSoft)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .foregroundStyle(Color.golfInk)
                .listRowBackground(Color.golfPaper)

                Section("Tee Location") {
                    if hole.hasTeeCoordinates {
                        LabeledContent("Latitude", value: String(format: "%.5f", hole.teeLatitude))
                        LabeledContent("Longitude", value: String(format: "%.5f", hole.teeLongitude))
                        Button { hole.hasTeeCoordinates = false } label: {
                            Text("Clear Tee Location").foregroundStyle(Color.golfPin)
                        }
                    } else {
                        Button("Set Tee to My Location") { setTeeLocation() }
                            .foregroundStyle(Color.golfMoss)
                            .disabled(locationManager.location == nil)
                    }
                }
                .foregroundStyle(Color.golfInk)
                .listRowBackground(Color.golfPaper)

                Section("Pin Location") {
                    if hole.hasPinCoordinates {
                        LabeledContent("Latitude", value: String(format: "%.5f", hole.pinLatitude))
                        LabeledContent("Longitude", value: String(format: "%.5f", hole.pinLongitude))
                        Button { hole.hasPinCoordinates = false } label: {
                            Text("Clear Pin Location").foregroundStyle(Color.golfPin)
                        }
                    } else {
                        Button("Set Pin to My Location") { setPinLocation() }
                            .foregroundStyle(Color.golfMoss)
                            .disabled(locationManager.location == nil)
                    }
                }
                .foregroundStyle(Color.golfInk)
                .listRowBackground(Color.golfPaper)
            }
            .scrollContentBackground(.hidden)
            .background(Color.golfPaper.ignoresSafeArea())
            .navigationTitle("Hole \(hole.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.golfPaper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.golfMoss)
                }
            }
        }
    }

    private func setTeeLocation() {
        guard let loc = locationManager.location else { return }
        hole.teeLatitude = loc.coordinate.latitude
        hole.teeLongitude = loc.coordinate.longitude
        hole.hasTeeCoordinates = true
    }

    private func setPinLocation() {
        guard let loc = locationManager.location else { return }
        hole.pinLatitude = loc.coordinate.latitude
        hole.pinLongitude = loc.coordinate.longitude
        hole.hasPinCoordinates = true
    }
}
