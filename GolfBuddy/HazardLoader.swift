import Foundation
import CoreLocation

struct HazardPolygon: Identifiable {
    enum Kind { case bunker, water }
    let id = UUID()
    let kind: Kind
    let coordinates: [CLLocationCoordinate2D]
}

struct HazardLoader {
    // Fetches bunker and water hazard polygons from OSM for the area around a hole.
    static func fetch(
        tee: CLLocationCoordinate2D?,
        pin: CLLocationCoordinate2D?
    ) async throws -> [HazardPolygon] {
        let pts = [tee, pin].compactMap { $0 }
        guard !pts.isEmpty else { return [] }

        let pad = 0.0022   // ~240m — enough to cover any hole
        let s = pts.map(\.latitude).min()!  - pad
        let n = pts.map(\.latitude).max()!  + pad
        let w = pts.map(\.longitude).min()! - pad * 1.5
        let e = pts.map(\.longitude).max()! + pad * 1.5

        let query = """
        [out:json][timeout:25];
        (
          way["golf"="bunker"](\(s),\(w),\(n),\(e));
          way["golf"="water_hazard"](\(s),\(w),\(n),\(e));
          way["natural"="water"](\(s),\(w),\(n),\(e));
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
        req.timeoutInterval = 30

        let (data, _) = try await URLSession.shared.data(for: req)
        return try parse(data)
    }

    private static func parse(_ data: Data) throws -> [HazardPolygon] {
        let resp = try JSONDecoder().decode(OverpassResp.self, from: data)

        // Build node-id → coordinate lookup
        var nodeLookup: [Int: CLLocationCoordinate2D] = [:]
        for el in resp.elements where el.type == "node" {
            if let lat = el.lat, let lon = el.lon {
                nodeLookup[el.id] = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }

        var result: [HazardPolygon] = []
        for el in resp.elements where el.type == "way" {
            guard let tags = el.tags, let nodeIds = el.nodes else { continue }
            let coords = nodeIds.compactMap { nodeLookup[$0] }
            guard coords.count >= 3 else { continue }

            let kind: HazardPolygon.Kind
            switch tags["golf"] {
            case "water_hazard": kind = .water
            case "bunker":       kind = .bunker
            default:
                if tags["natural"] == "water" { kind = .water } else { continue }
            }
            result.append(HazardPolygon(kind: kind, coordinates: coords))
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
