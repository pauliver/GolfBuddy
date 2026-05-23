import CoreLocation
import Foundation

@MainActor
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var location: CLLocation?
    var heading: CLHeading?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 3
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func distanceInYards(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let location else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: target) * 1.09361
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
