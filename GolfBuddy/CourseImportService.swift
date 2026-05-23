import Foundation
import CoreLocation
import MapKit

// MARK: - Public types

struct CourseSearchResult: Identifiable {
    let id: Int
    let name: String
    let city: String
    let state: String
    let coordinate: CLLocationCoordinate2D
    let holes: [HoleImportData]

    var holeCount: Int { holes.count }
    var totalPar: Int { holes.reduce(0) { $0 + $1.par } }
    var locationString: String { [city, state].filter { !$0.isEmpty }.joined(separator: ", ") }
}

struct HoleImportData {
    var number: Int
    var par: Int
    var handicap: Int
    var yardage: Int
    var pinLatitude:  Double? = nil
    var pinLongitude: Double? = nil
    var teeLatitude:  Double? = nil
    var teeLongitude: Double? = nil
}

// MARK: - Service

struct CourseImportService {
    private static let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "GOLF_COURSE_API_KEY") as? String ?? ""
    }()
    private static let baseURL = "https://api.golfcourseapi.com/v1"

    // Step 1 — Search courses; returns full scorecard (par, yardage, handicap) immediately.
    // Falls back to bundled offline DB when the API is unreachable or returns empty.
    static func searchCourses(query: String) async throws -> [CourseSearchResult] {
        if !apiKey.isEmpty {
            do {
                var comps = URLComponents(string: "\(baseURL)/search")!
                comps.queryItems = [URLQueryItem(name: "search_query", value: query)]
                var req = URLRequest(url: comps.url!)
                req.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 15
                let (data, _) = try await URLSession.shared.data(for: req)
                let results = try parseSearchResponse(data)
                if !results.isEmpty { return results }
            } catch { }
        }
        return await OfflineCourseStore.shared.search(query: query)
    }

    // Step 2 — Supplement with GPS.
    // Resolution order: bundled offline DB → live OSM Overpass query.
    // If coordinate is (0,0) a MapKit lookup is attempted first.
    static func supplementWithGPS(
        holes: [HoleImportData],
        at coordinate: CLLocationCoordinate2D,
        courseName: String? = nil
    ) async throws -> [HoleImportData] {
        var effectiveCoord = coordinate
        if coordinate.latitude == 0 && coordinate.longitude == 0, let name = courseName {
            effectiveCoord = (try? await mapKitCoordinate(for: name)) ?? coordinate
        }

        // 1. Offline bundled database
        let offline = await OfflineCourseStore.shared.lookupGPS(near: effectiveCoord)
        if !offline.isEmpty {
            return holes.map { hole in
                var h = hole
                if let gps = offline.first(where: { $0.number == hole.number }) {
                    if let lat = gps.pinLat, let lon = gps.pinLon {
                        h.pinLatitude = lat; h.pinLongitude = lon
                    }
                    if let lat = gps.teeLat, let lon = gps.teeLon {
                        h.teeLatitude = lat; h.teeLongitude = lon
                    }
                }
                return h
            }
        }

        // 2. Live OSM Overpass query
        let points = try await fetchOSMPoints(near: effectiveCoord)
        return holes.map { hole in
            var h = hole
            if let pin = points.first(where: { $0.kind == .pin && $0.number == hole.number }) {
                h.pinLatitude = pin.lat; h.pinLongitude = pin.lon
            }
            if let tee = points.first(where: { $0.kind == .tee && $0.number == hole.number }) {
                h.teeLatitude = tee.lat; h.teeLongitude = tee.lon
            }
            return h
        }
    }

    // MARK: - GolfCourseAPI parsing

    private static func parseSearchResponse(_ data: Data) throws -> [CourseSearchResult] {
        let response = try JSONDecoder().decode(GolfAPIResponse.self, from: data)
        return response.courses.compactMap { course in
            guard let tee = pickTee(from: course.tees), !tee.holes.isEmpty else { return nil }
            let holes = tee.holes.enumerated().map { i, h in
                HoleImportData(number: i + 1, par: h.par, handicap: h.handicap, yardage: h.yardage)
            }
            return CourseSearchResult(
                id: course.id,
                name: course.courseName,
                city: course.location.city ?? "",
                state: course.location.state ?? "",
                coordinate: CLLocationCoordinate2D(
                    latitude: course.location.latitude,
                    longitude: course.location.longitude
                ),
                holes: holes
            )
        }
    }

    private static func pickTee(from tees: GolfAPITees) -> GolfAPITee? {
        let preferred = ["white", "regular", "silver", "blue"]
        let male = (tees.male ?? []).filter { $0.numberOfHoles >= 9 }
        for name in preferred {
            if let t = male.first(where: { $0.teeName.lowercased().contains(name) }) { return t }
        }
        if !male.isEmpty { return male[male.count / 2] }
        let female = (tees.female ?? []).filter { $0.numberOfHoles >= 9 }
        for name in preferred {
            if let t = female.first(where: { $0.teeName.lowercased().contains(name) }) { return t }
        }
        return female.first
    }

    // MARK: - MapKit coordinate fallback

    static func mapKitCoordinate(for courseName: String) async throws -> CLLocationCoordinate2D? {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = courseName
        req.resultTypes = .pointOfInterest
        let items = (try? await MKLocalSearch(request: req).start().mapItems) ?? []
        return items.first.map { $0.placemark.coordinate }
    }

    // MARK: - OSM GPS fetch

    private struct OSMPoint {
        enum Kind { case pin, tee }
        let kind: Kind; let number: Int; let lat: Double; let lon: Double
    }

    private static func fetchOSMPoints(near coordinate: CLLocationCoordinate2D) async throws -> [OSMPoint] {
        let pad = 0.018
        let s = coordinate.latitude  - pad,  n = coordinate.latitude  + pad
        let w = coordinate.longitude - pad * 1.6, e = coordinate.longitude + pad * 1.6

        let query = """
        [out:json][timeout:30];
        (
          node["golf"="pin"](\(s),\(w),\(n),\(e));
          node["golf"="tee"](\(s),\(w),\(n),\(e));
        );
        out body;
        """
        var req = URLRequest(url: URL(string: "https://overpass-api.de/api/interpreter")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var comps = URLComponents()
        comps.queryItems = [URLQueryItem(name: "data", value: query)]
        req.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
        req.timeoutInterval = 35

        let (data, _) = try await URLSession.shared.data(for: req)
        let response = try JSONDecoder().decode(OverpassResponse.self, from: data)

        var pins: [Int: (Double, Double)] = [:]
        var tees: [Int: (Double, Double)] = [:]

        for el in response.elements {
            guard let tags = el.tags, let lat = el.lat, let lon = el.lon,
                  let n = tags["ref"].flatMap(Int.init) else { continue }
            switch tags["golf"] {
            case "pin":
                pins[n] = (lat, lon)
            case "tee":
                let use = tags["tee"] ?? tags["golf:use"] ?? ""
                let preferred = ["regular", "white", "mens", "men"].contains(use)
                if tees[n] == nil || preferred { tees[n] = (lat, lon) }
            default: break
            }
        }

        var result: [OSMPoint] = []
        for (n, p) in pins where n >= 1 && n <= 18 { result.append(OSMPoint(kind: .pin, number: n, lat: p.0, lon: p.1)) }
        for (n, p) in tees where n >= 1 && n <= 18 { result.append(OSMPoint(kind: .tee, number: n, lat: p.0, lon: p.1)) }
        return result
    }
}

// MARK: - GolfCourseAPI Decodable models

private struct GolfAPIResponse: Decodable { let courses: [GolfAPICourse] }

private struct GolfAPICourse: Decodable {
    let id: Int
    let courseName: String
    let location: GolfAPILocation
    let tees: GolfAPITees
    enum CodingKeys: String, CodingKey {
        case id; case courseName = "course_name"; case location; case tees
    }
}

private struct GolfAPILocation: Decodable {
    let city: String?; let state: String?
    let latitude: Double; let longitude: Double
}

private struct GolfAPITees: Decodable {
    let female: [GolfAPITee]?; let male: [GolfAPITee]?
}

private struct GolfAPITee: Decodable {
    let teeName: String; let numberOfHoles: Int; let holes: [GolfAPIHole]
    enum CodingKeys: String, CodingKey {
        case teeName = "tee_name"; case numberOfHoles = "number_of_holes"; case holes
    }
}

private struct GolfAPIHole: Decodable { let par: Int; let yardage: Int; let handicap: Int }

// MARK: - Overpass Decodable models

private struct OverpassResponse: Decodable { let elements: [OverpassElement] }
private struct OverpassElement: Decodable {
    let lat: Double?; let lon: Double?; let tags: [String: String]?
}
