import SwiftUI
import MapKit
import CoreLocation

struct HoleMapView: View {
    let hole: GolfHole
    let hazards: [HazardPolygon]
    let locationManager: LocationManager
    var fallbackCoordinate: CLLocationCoordinate2D? = nil

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedHazard: HazardPolygon?

    // Yardage rings: 100 / 150 / 200 yards (1 yard = 0.9144 m)
    private static let rings: [(yards: Int, meters: Double)] = [
        (100, 91.44), (150, 137.16), (200, 182.88)
    ]

    /// Hazards that should NOT show a tappable centroid annotation
    private var nonTappableKinds: Set<HazardKind> {
        [.holeCenterline, .fairway, .rough, .path]
    }

    /// Whether a holeCenterline hazard exists in the array
    private var centerlineHazard: HazardPolygon? {
        hazards.first { $0.kind == .holeCenterline }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mapContent
            if let selected = selectedHazard {
                hazardDistanceCapsule(selected)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear { setCamera() }
        .onChange(of: hole.number) { _, _ in
            selectedHazard = nil
            setCamera()
        }
    }

    // MARK: - Map

    private var mapContent: some View {
        Map(position: $position) {
            UserAnnotation()

            // Hazard overlays
            ForEach(hazards) { hazard in
                if hazard.isPolyline {
                    polylineContent(for: hazard)
                } else {
                    polygonContent(for: hazard)
                }
            }

            // Centroid annotations for tappable hazards
            ForEach(hazards.filter { !nonTappableKinds.contains($0.kind) }) { hazard in
                Annotation("", coordinate: hazard.centroid, anchor: .center) {
                    hazardDot(for: hazard)
                }
            }

            // Yardage rings
            if let pin = hole.pinCoordinate {
                ForEach(Self.rings, id: \.yards) { ring in
                    MapCircle(center: pin, radius: ring.meters)
                        .foregroundStyle(Color.clear)
                        .stroke(.white.opacity(0.55), lineWidth: 1)

                    Annotation("\(ring.yards)", coordinate: northOf(pin, meters: ring.meters), anchor: .center) {
                        Text("\(ring.yards)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(.black.opacity(0.45), in: Capsule())
                    }
                }

                // Pin annotation
                Annotation("Pin", coordinate: pin, anchor: .bottom) {
                    Image(systemName: "flag.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.golfPin, in: Circle())
                }
            }

            // Tee annotation
            if let tee = hole.teeCoordinate {
                Annotation("Tee", coordinate: tee, anchor: .center) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }

            // Tee-to-pin line: use holeCenterline if available, otherwise straight line
            if centerlineHazard == nil,
               let tee = hole.teeCoordinate,
               let pin = hole.pinCoordinate {
                MapPolyline(coordinates: [tee, pin])
                    .stroke(.white.opacity(0.6), lineWidth: 2)
            }
        }
        .mapStyle(.hybrid(elevation: .flat))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    // MARK: - Hazard rendering helpers

    @MapContentBuilder
    private func polygonContent(for hazard: HazardPolygon) -> some MapContent {
        let isSelected = selectedHazard?.id == hazard.id
        let lw: CGFloat = isSelected ? 3 : 1
        let fill = fillColor(for: hazard).opacity(isSelected ? 0.85 : fillOpacity(for: hazard))

        MapPolygon(coordinates: hazard.clCoordinates)
            .foregroundStyle(fill)
            .stroke(strokeColor(for: hazard), lineWidth: lw)
    }

    @MapContentBuilder
    private func polylineContent(for hazard: HazardPolygon) -> some MapContent {
        let isSelected = selectedHazard?.id == hazard.id
        let lw: CGFloat = isSelected ? 3 : 2

        if hazard.kind == .holeCenterline {
            MapPolyline(coordinates: hazard.clCoordinates)
                .stroke(.white.opacity(0.40), style: StrokeStyle(lineWidth: lw, dash: [6, 4]))
        } else if hazard.kind == .path {
            MapPolyline(coordinates: hazard.clCoordinates)
                .stroke(Color.gray.opacity(0.8), style: StrokeStyle(lineWidth: lw, dash: [4, 4]))
        } else {
            // treeRow
            MapPolyline(coordinates: hazard.clCoordinates)
                .stroke(Color.golfTreeStroke.opacity(0.60), lineWidth: lw)
        }
    }

    private func fillColor(for hazard: HazardPolygon) -> Color {
        switch hazard.kind {
        case .bunker, .sand:return .golfBunkerFill
        case .water:        return .golfWaterFill
        case .lateralWater: return .golfLatWaterFill
        case .green:        return .golfGreenFill
        case .fairway:      return .golfFairwayFill
        case .rough:        return Color.golfFairwayFill
        default:            return .clear
        }
    }

    private func fillOpacity(for hazard: HazardPolygon) -> Double {
        switch hazard.kind {
        case .bunker, .sand:return 0.55
        case .water:        return 0.50
        case .lateralWater: return 0.50
        case .green:        return 0.40
        case .fairway:      return 0.25
        case .rough:        return 0.15
        default:            return 0
        }
    }

    private func strokeColor(for hazard: HazardPolygon) -> Color {
        switch hazard.kind {
        case .bunker, .sand:return .golfBunkerStroke
        case .water:        return .golfWaterStroke
        case .lateralWater: return .golfLatWaterStroke
        case .green:        return .golfGreenStroke
        case .fairway:      return .golfFairwayStroke
        case .treeRow:      return .golfTreeStroke
        case .rough:        return .golfFairwayStroke
        case .path:         return .gray
        case .holeCenterline: return .white
        }
    }

    // MARK: - Centroid dot

    private func hazardDot(for hazard: HazardPolygon) -> some View {
        let isSelected = selectedHazard?.id == hazard.id
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedHazard?.id == hazard.id {
                    selectedHazard = nil
                } else {
                    selectedHazard = hazard
                }
            }
        } label: {
            Image(systemName: hazard.iconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: isSelected ? 26 : 22, height: isSelected ? 26 : 22)
                .background(
                    strokeColor(for: hazard).opacity(isSelected ? 1 : 0.8),
                    in: Circle()
                )
                .overlay(
                    Circle().stroke(.white, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Distance overlay capsule

    private func hazardDistanceCapsule(_ hazard: HazardPolygon) -> some View {
        HStack(spacing: 10) {
            Image(systemName: hazard.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(strokeColor(for: hazard))

            VStack(alignment: .leading, spacing: 1) {
                Text(hazard.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.golfInk)

                if let loc = locationManager.location {
                    let yards = Int(hazard.distanceInYards(from: loc).rounded())
                    Text("\(yards) yds")
                        .font(.golfMono(size: 13, weight: .medium))
                        .foregroundStyle(Color.golfInk)
                }
            }

            Spacer()

            compassArrow(for: hazard)
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.golfPaper2.opacity(0.95), in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .padding(.horizontal, 16)
    }

    // MARK: - Compass arrow

    private func compassArrow(for hazard: HazardPolygon) -> some View {
        Group {
            if let loc = locationManager.location {
                let nearestPt = hazard.nearestPoint(from: loc.coordinate)
                let bearing = bearingBetween(from: loc.coordinate, to: nearestPt)
                let deviceHeading = locationManager.heading?.trueHeading ?? 0
                let relative = bearing - deviceHeading

                Image(systemName: "location.north.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.golfMoss)
                    .rotationEffect(.degrees(relative))
            } else {
                Image(systemName: "location.slash")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.golfInkMute)
            }
        }
    }

    // MARK: - Geometry helpers

    private func northOf(_ center: CLLocationCoordinate2D, meters: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude:  center.latitude + meters / 111_320,
            longitude: center.longitude
        )
    }

    private func setCamera() {
        let coords = [hole.pinCoordinate, hole.teeCoordinate].compactMap { $0 }
        guard !coords.isEmpty else {
            if let fb = fallbackCoordinate {
                position = .region(MKCoordinateRegion(
                    center: fb,
                    span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                ))
            } else {
                position = .userLocation(fallback: .automatic)
            }
            return
        }
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude:  (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta:  max((lats.max()! - lats.min()!) * 2.5, 0.003),
            longitudeDelta: max((lons.max()! - lons.min()!) * 2.5, 0.003)
        )
        position = .region(MKCoordinateRegion(center: center, span: span))
    }
}

