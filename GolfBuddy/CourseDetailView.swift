import SwiftUI
import SwiftData
import CoreLocation

struct CourseDetailView: View {
    @Bindable var course: GolfCourse
    @Environment(\.modelContext) private var modelContext
    @State private var locationManager = LocationManager()
    @State private var editingHole: GolfHole?

    var body: some View {
        List {
            Section("Course Info") {
                LabeledContent("Name") {
                    TextField("Name", text: $course.name)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("City") {
                    TextField("City", text: $course.city)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("State") {
                    TextField("State", text: $course.state)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Holes") {
                ForEach(course.sortedHoles) { hole in
                    Button { editingHole = hole } label: {
                        HoleRowView(hole: hole)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle(course.name.isEmpty ? "Course" : course.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { locationManager.requestPermission() }
        .sheet(item: $editingHole) { hole in
            HoleEditView(hole: hole, locationManager: locationManager)
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
                    .foregroundStyle(.secondary)
                if hole.yardage > 0 {
                    Text("\(hole.yardage) yds")
                        .foregroundStyle(.secondary)
                }
                if hole.hasPinCoordinates {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .font(.subheadline)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
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
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Yardage") {
                        TextField("0", value: $hole.yardage, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Tee Location") {
                    if hole.hasTeeCoordinates {
                        LabeledContent("Latitude", value: String(format: "%.5f", hole.teeLatitude))
                        LabeledContent("Longitude", value: String(format: "%.5f", hole.teeLongitude))
                        Button("Clear Tee Location", role: .destructive) {
                            hole.hasTeeCoordinates = false
                        }
                    } else {
                        Button("Set Tee to My Location") { setTeeLocation() }
                            .disabled(locationManager.location == nil)
                    }
                }

                Section("Pin Location") {
                    if hole.hasPinCoordinates {
                        LabeledContent("Latitude", value: String(format: "%.5f", hole.pinLatitude))
                        LabeledContent("Longitude", value: String(format: "%.5f", hole.pinLongitude))
                        Button("Clear Pin Location", role: .destructive) {
                            hole.hasPinCoordinates = false
                        }
                    } else {
                        Button("Set Pin to My Location") { setPinLocation() }
                            .disabled(locationManager.location == nil)
                    }
                }
            }
            .navigationTitle("Hole \(hole.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
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
