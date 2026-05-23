import Foundation
import CoreLocation

enum HazardKind: String, Codable, CaseIterable {
    case bunker
    case water
    case lateralWater
    case green
    case fairway
    case treeRow
    case holeCenterline
}

struct SerializableCoordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(_ coord: CLLocationCoordinate2D) {
        self.latitude = coord.latitude
        self.longitude = coord.longitude
    }

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct HazardPolygon: Identifiable, Codable {
    let id: UUID
    let kind: HazardKind
    let coordinates: [SerializableCoordinate]
    let name: String?

    init(id: UUID = UUID(), kind: HazardKind, coordinates: [SerializableCoordinate],
         name: String? = nil) {
        self.id = id
        self.kind = kind
        self.coordinates = coordinates
        self.name = name
    }

    init(kind: HazardKind, clCoordinates: [CLLocationCoordinate2D],
         name: String? = nil) {
        self.id = UUID()
        self.kind = kind
        self.coordinates = clCoordinates.map { SerializableCoordinate($0) }
        self.name = name
    }

    var clCoordinates: [CLLocationCoordinate2D] {
        coordinates.map { $0.clCoordinate }
    }

    var isPolyline: Bool {
        kind == .treeRow || kind == .holeCenterline
    }

    var centroid: CLLocationCoordinate2D {
        guard !coordinates.isEmpty else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        let sumLat = coordinates.reduce(0.0) { $0 + $1.latitude }
        let sumLon = coordinates.reduce(0.0) { $0 + $1.longitude }
        let n = Double(coordinates.count)
        return CLLocationCoordinate2D(latitude: sumLat / n, longitude: sumLon / n)
    }

    func nearestPoint(from location: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard coordinates.count >= 2 else {
            return coordinates.first?.clCoordinate ?? location
        }

        var best = coordinates[0].clCoordinate
        var bestDist = Double.greatestFiniteMagnitude
        let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)

        for i in 0..<(coordinates.count - 1) {
            let a = coordinates[i]
            let b = coordinates[i + 1]
            let projected = projectOntoSegment(point: location, a: a.clCoordinate, b: b.clCoordinate)
            let dist = loc.distance(from: CLLocation(latitude: projected.latitude, longitude: projected.longitude))
            if dist < bestDist {
                bestDist = dist
                best = projected
            }
        }

        if !isPolyline, coordinates.count >= 3 {
            let a = coordinates[coordinates.count - 1]
            let b = coordinates[0]
            let projected = projectOntoSegment(point: location, a: a.clCoordinate, b: b.clCoordinate)
            let dist = loc.distance(from: CLLocation(latitude: projected.latitude, longitude: projected.longitude))
            if dist < bestDist {
                best = projected
            }
        }

        return best
    }

    func distanceInYards(from location: CLLocation) -> Double {
        let nearest = nearestPoint(from: location.coordinate)
        let meters = location.distance(from: CLLocation(latitude: nearest.latitude, longitude: nearest.longitude))
        return meters * 1.09361
    }

    func simplified(maxPoints: Int = 60) -> HazardPolygon {
        guard coordinates.count > maxPoints else { return self }
        let simplified = rdpSimplify(coordinates, epsilon: 0.000005, maxPoints: maxPoints)
        return HazardPolygon(id: id, kind: kind, coordinates: simplified, name: name)
    }

    var displayName: String {
        if let name, !name.isEmpty { return name }
        switch kind {
        case .bunker: return "Bunker"
        case .water: return "Water Hazard"
        case .lateralWater: return "Lateral Water"
        case .green: return "Green"
        case .fairway: return "Fairway"
        case .treeRow: return "Tree Line"
        case .holeCenterline: return "Line of Play"
        }
    }

    var abbreviation: String {
        switch kind {
        case .bunker: return "BKR"
        case .water: return "WTR"
        case .lateralWater: return "LAT"
        case .green: return "GRN"
        case .fairway: return "FWY"
        case .treeRow: return "TRE"
        case .holeCenterline: return "LINE"
        }
    }

    var iconName: String {
        switch kind {
        case .bunker: return "sun.dust.fill"
        case .water: return "drop.fill"
        case .lateralWater: return "water.waves"
        case .green: return "flag.fill"
        case .fairway: return "arrow.up.right.and.arrow.down.left"
        case .treeRow: return "tree.fill"
        case .holeCenterline: return "point.topleft.down.to.point.bottomright.curvepath"
        }
    }
}

// MARK: - Geometry utilities

private func projectOntoSegment(
    point: CLLocationCoordinate2D,
    a: CLLocationCoordinate2D,
    b: CLLocationCoordinate2D
) -> CLLocationCoordinate2D {
    let dx = b.longitude - a.longitude
    let dy = b.latitude - a.latitude
    let lenSq = dx * dx + dy * dy
    guard lenSq > 0 else { return a }

    let t = max(0, min(1,
        ((point.longitude - a.longitude) * dx + (point.latitude - a.latitude) * dy) / lenSq
    ))
    return CLLocationCoordinate2D(
        latitude: a.latitude + t * dy,
        longitude: a.longitude + t * dx
    )
}

private func rdpSimplify(_ points: [SerializableCoordinate], epsilon: Double, maxPoints: Int) -> [SerializableCoordinate] {
    var eps = epsilon
    var result = rdpPass(points, epsilon: eps)
    while result.count > maxPoints {
        eps *= 2
        result = rdpPass(points, epsilon: eps)
    }
    return result
}

private func rdpPass(_ points: [SerializableCoordinate], epsilon: Double) -> [SerializableCoordinate] {
    guard points.count > 2 else { return points }

    var maxDist = 0.0
    var maxIdx = 0
    let first = points.first!
    let last = points.last!

    for i in 1..<(points.count - 1) {
        let d = perpendicularDistance(points[i], lineStart: first, lineEnd: last)
        if d > maxDist {
            maxDist = d
            maxIdx = i
        }
    }

    if maxDist > epsilon {
        let left = rdpPass(Array(points[...maxIdx]), epsilon: epsilon)
        let right = rdpPass(Array(points[maxIdx...]), epsilon: epsilon)
        return Array(left.dropLast()) + right
    } else {
        return [first, last]
    }
}

private func perpendicularDistance(
    _ point: SerializableCoordinate,
    lineStart: SerializableCoordinate,
    lineEnd: SerializableCoordinate
) -> Double {
    let dx = lineEnd.longitude - lineStart.longitude
    let dy = lineEnd.latitude - lineStart.latitude
    let lenSq = dx * dx + dy * dy
    guard lenSq > 0 else {
        let ddx = point.longitude - lineStart.longitude
        let ddy = point.latitude - lineStart.latitude
        return sqrt(ddx * ddx + ddy * ddy)
    }
    let num = abs(dy * point.longitude - dx * point.latitude + lineEnd.longitude * lineStart.latitude - lineEnd.latitude * lineStart.longitude)
    return num / sqrt(lenSq)
}

func bearingBetween(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    let lat1 = from.latitude * .pi / 180
    let lat2 = to.latitude * .pi / 180
    let dLon = (to.longitude - from.longitude) * .pi / 180
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let bearing = atan2(y, x) * 180 / .pi
    return (bearing + 360).truncatingRemainder(dividingBy: 360)
}
