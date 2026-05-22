import Foundation
import CoreLocation

struct HazardLoader {
    static func fetch(
        tee: CLLocationCoordinate2D?,
        pin: CLLocationCoordinate2D?
    ) async throws -> [HazardPolygon] {
        let pts = [tee, pin].compactMap { $0 }
        guard !pts.isEmpty else { return [] }

        let pad = 0.003
        let s = pts.map(\.latitude).min()!  - pad
        let n = pts.map(\.latitude).max()!  + pad
        let w = pts.map(\.longitude).min()! - pad * 1.5
        let e = pts.map(\.longitude).max()! + pad * 1.5

        let bbox = "(\(s),\(w),\(n),\(e))"
        let query = """
        [out:json][timeout:30];
        (
          way["golf"="bunker"]\(bbox);
          way["golf"="water_hazard"]\(bbox);
          way["golf"="lateral_water_hazard"]\(bbox);
          way["natural"="water"]\(bbox);
          way["golf"="green"]\(bbox);
          way["golf"="fairway"]\(bbox);
          way["natural"="tree_row"]\(bbox);
          way["golf"="hole"]\(bbox);
        );
        out body;
        >;
        out skel qt;
        """

        var req = URLRequest(url: URL(string: "https://overpass-api.de/api/interpreter")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var comps = URLComponents()
        comps.queryItems = [URLQueryItem(name: "data", value: query)]
        req.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
        req.timeoutInterval = 35

        let (data, _) = try await URLSession.shared.data(for: req)

        let center = CLLocationCoordinate2D(
            latitude: (s + n) / 2,
            longitude: (w + e) / 2
        )
        return try parse(data, center: center, maxDistFromCenter: pad * 111_320 * 1.2)
    }

    private static func parse(
        _ data: Data,
        center: CLLocationCoordinate2D,
        maxDistFromCenter: Double
    ) throws -> [HazardPolygon] {
        let resp = try JSONDecoder().decode(OverpassResp.self, from: data)

        var nodeLookup: [Int: CLLocationCoordinate2D] = [:]
        for el in resp.elements where el.type == "node" {
            if let lat = el.lat, let lon = el.lon {
                nodeLookup[el.id] = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }

        let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
        var result: [HazardPolygon] = []

        for el in resp.elements where el.type == "way" {
            guard let tags = el.tags, let nodeIds = el.nodes else { continue }
            let coords = nodeIds.compactMap { nodeLookup[$0] }

            let kind: HazardKind
            let minCoords: Int

            switch tags["golf"] {
            case "bunker":               kind = .bunker; minCoords = 3
            case "water_hazard":         kind = .water; minCoords = 3
            case "lateral_water_hazard": kind = .lateralWater; minCoords = 3
            case "green":                kind = .green; minCoords = 3
            case "fairway":              kind = .fairway; minCoords = 3
            case "hole":                 kind = .holeCenterline; minCoords = 2
            default:
                if tags["natural"] == "water" {
                    kind = .water; minCoords = 3
                } else if tags["natural"] == "tree_row" {
                    kind = .treeRow; minCoords = 2
                } else {
                    continue
                }
            }

            guard coords.count >= minCoords else { continue }

            let centroidLat = coords.reduce(0.0) { $0 + $1.latitude } / Double(coords.count)
            let centroidLon = coords.reduce(0.0) { $0 + $1.longitude } / Double(coords.count)
            let centroidLoc = CLLocation(latitude: centroidLat, longitude: centroidLon)
            guard centroidLoc.distance(from: centerLoc) < maxDistFromCenter else { continue }

            let name = tags["name"]
            let hazard = HazardPolygon(kind: kind, clCoordinates: coords, name: name)
            result.append(hazard)
        }

        return result
    }
}

private struct OverpassResp: Decodable { let elements: [OverpassEl] }
private struct OverpassEl: Decodable {
    let type: String; let id: Int
    let lat: Double?; let lon: Double?
    let nodes: [Int]?; let tags: [String: String]?
}
