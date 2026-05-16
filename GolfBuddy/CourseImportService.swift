import Foundation
import MapKit
import CoreLocation

// MARK: - Parsed OSM hole data

struct OSMHoleData {
    let number: Int
    let par: Int
    let handicap: Int
    let pinLatitude: Double?
    let pinLongitude: Double?
    let teeLatitude: Double?
    let teeLongitude: Double?
}

// MARK: - Service

struct CourseImportService {

    // Step 1 — MapKit local search for golf courses near a query string
    static func searchCourses(query: String, near coordinate: CLLocationCoordinate2D? = nil) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query.lowercased().contains("golf") ? query : "\(query) golf course"
        request.resultTypes = .pointOfInterest
        if let coord = coordinate {
            request.region = MKCoordinateRegion(center: coord,
                                                latitudinalMeters: 80_000,
                                                longitudinalMeters: 80_000)
        }
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.filter {
            let name = ($0.name ?? "").lowercased()
            return name.contains("golf") || name.contains("links") || name.contains("club") ||
                   $0.pointOfInterestCategory == .golf
        }
    }

    // Step 2 — OpenStreetMap Overpass API for hole GPS coordinates
    static func fetchHoleData(coordinate: CLLocationCoordinate2D) async throws -> [OSMHoleData] {
        // 2 km padding each direction — covers any full 18-hole layout
        let pad = 0.018
        let south = coordinate.latitude  - pad
        let north = coordinate.latitude  + pad
        let west  = coordinate.longitude - pad * 1.6
        let east  = coordinate.longitude + pad * 1.6

        let overpassQuery = """
        [out:json][timeout:30];
        (
          node["golf"="pin"](\(south),\(west),\(north),\(east));
          node["golf"="tee"](\(south),\(west),\(north),\(east));
          way["golf"="hole"](\(south),\(west),\(north),\(east));
        );
        out body;
        >;
        out skel qt;
        """

        var request = URLRequest(url: URL(string: "https://overpass-api.de/api/interpreter")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var comps = URLComponents()
        comps.queryItems = [URLQueryItem(name: "data", value: overpassQuery)]
        request.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
        request.timeoutInterval = 35

        let (data, _) = try await URLSession.shared.data(for: request)
        return try parseOverpassResponse(data)
    }

    // MARK: - Parsing

    private static func parseOverpassResponse(_ data: Data) throws -> [OSMHoleData] {
        let response = try JSONDecoder().decode(OverpassResponse.self, from: data)

        var pins:     [Int: (lat: Double, lon: Double)] = [:]
        var tees:     [Int: (lat: Double, lon: Double)] = [:]
        var holeMeta: [Int: (par: Int, handicap: Int)]  = [:]

        for el in response.elements {
            guard let tags = el.tags else { continue }
            let holeNum = tags["ref"].flatMap(Int.init)
            let par     = tags["par"].flatMap(Int.init)      ?? 4
            let hcp     = tags["handicap"].flatMap(Int.init) ?? 0

            switch tags["golf"] {
            case "pin":
                if let n = holeNum, let lat = el.lat, let lon = el.lon {
                    pins[n] = (lat, lon)
                    if holeMeta[n] == nil { holeMeta[n] = (par, hcp) }
                }
            case "tee":
                if let n = holeNum, let lat = el.lat, let lon = el.lon {
                    let use = tags["tee"] ?? tags["golf:use"] ?? ""
                    let preferred = ["regular", "white", "mens", "men"].contains(use)
                    if tees[n] == nil || preferred { tees[n] = (lat, lon) }
                }
            case "hole":
                if let n = holeNum {
                    holeMeta[n] = (par, hcp > 0 ? hcp : holeMeta[n]?.handicap ?? n)
                }
            default:
                break
            }
        }

        let allNums = Set(pins.keys).union(tees.keys).union(holeMeta.keys)
        return allNums.filter { $0 >= 1 && $0 <= 18 }.sorted().map { n in
            OSMHoleData(
                number:       n,
                par:          holeMeta[n]?.par      ?? 4,
                handicap:     holeMeta[n]?.handicap ?? n,
                pinLatitude:  pins[n]?.lat,
                pinLongitude: pins[n]?.lon,
                teeLatitude:  tees[n]?.lat,
                teeLongitude: tees[n]?.lon
            )
        }
    }
}

// MARK: - Overpass response models

private struct OverpassResponse: Decodable {
    let elements: [OverpassElement]
}

private struct OverpassElement: Decodable {
    let type: String
    let id: Int
    let lat: Double?
    let lon: Double?
    let tags: [String: String]?
}
