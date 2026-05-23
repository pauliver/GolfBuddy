import Foundation

actor HazardCache {
    static let shared = HazardCache()

    private var cache: [String: CacheEntry] = [:]
    private let ttl: TimeInterval = 86400

    private struct CacheEntry {
        let hazards: [HazardPolygon]
        let fetchedAt: Date
    }

    func get(courseId: UUID, holeNumber: Int) -> [HazardPolygon]? {
        let key = "\(courseId)-\(holeNumber)"
        guard let entry = cache[key],
              Date().timeIntervalSince(entry.fetchedAt) < ttl
        else { return nil }
        return entry.hazards
    }

    func set(courseId: UUID, holeNumber: Int, hazards: [HazardPolygon]) {
        let key = "\(courseId)-\(holeNumber)"
        cache[key] = CacheEntry(hazards: hazards, fetchedAt: Date())
    }
}
