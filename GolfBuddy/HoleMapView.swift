import SwiftUI
import MapKit
import CoreLocation

struct HoleMapView: View {
    let hole: GolfHole
    let userLocation: CLLocation?

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position) {
            UserAnnotation()

            if let pin = hole.pinCoordinate {
                Annotation("Pin", coordinate: pin, anchor: .bottom) {
                    Image(systemName: "flag.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.red, in: Circle())
                }
            }

            if let tee = hole.teeCoordinate {
                Annotation("Tee", coordinate: tee, anchor: .center) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }

            if let tee = hole.teeCoordinate, let pin = hole.pinCoordinate {
                MapPolyline(coordinates: [tee, pin])
                    .stroke(.white.opacity(0.6), lineWidth: 2)
            }
        }
        .mapStyle(.hybrid(elevation: .flat))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onAppear { setCamera() }
        .onChange(of: hole.number) { _, _ in setCamera() }
    }

    private func setCamera() {
        let coords = [hole.pinCoordinate, hole.teeCoordinate].compactMap { $0 }
        guard !coords.isEmpty else {
            position = .userLocation(fallback: .automatic)
            return
        }
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 2.5, 0.003),
            longitudeDelta: max((lons.max()! - lons.min()!) * 2.5, 0.003)
        )
        position = .region(MKCoordinateRegion(center: center, span: span))
    }
}
