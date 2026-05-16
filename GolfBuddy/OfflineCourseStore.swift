import Foundation
import CoreLocation
import SQLite3

// Read-only access to the bundled golf_courses.db produced by scripts/export_golf_courses.py.
// All methods return empty collections when the database isn't present in the bundle.
final class OfflineCourseStore {
    static let shared = OfflineCourseStore()

    private var db: OpaquePointer?

    private init() {
        guard let path = Bundle.main.path(forResource: "golf_courses", ofType: "db") else { return }
        sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil)
    }

    deinit { sqlite3_close(db) }

    // MARK: - Course search (text)

    func search(query: String, limit: Int = 30) -> [CourseSearchResult] {
        guard let db else { return [] }
        let pattern = "%\(query.trimmingCharacters(in: .whitespacesAndNewlines))%"
        let sql = """
            SELECT id, name, city, country, lat, lon, hole_count
            FROM courses
            WHERE name LIKE ?
            ORDER BY name
            LIMIT ?
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, pattern, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_int(stmt, 2, Int32(limit))

        var results: [CourseSearchResult] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let rowId      = Int(sqlite3_column_int(stmt, 0))
            let name       = String(cString: sqlite3_column_text(stmt, 1))
            let city       = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
            let country    = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
            let lat        = sqlite3_column_double(stmt, 4)
            let lon        = sqlite3_column_double(stmt, 5)
            let holeCount  = max(1, Int(sqlite3_column_int(stmt, 6)))

            let holeData = (1...holeCount).map { n in
                HoleImportData(number: n, par: 4, handicap: n, yardage: 0)
            }
            results.append(CourseSearchResult(
                id:         rowId,
                name:       name,
                city:       city,
                state:      country,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                holes:      holeData
            ))
        }
        return results
    }

    // MARK: - Hole GPS lookup

    struct HoleGPS {
        let number: Int
        let pinLat:  Double?
        let pinLon:  Double?
        let teeLat:  Double?
        let teeLon:  Double?
    }

    /// Returns pre-seeded pin/tee coordinates for holes belonging to any course
    /// whose centroid falls within ~2 km of `coordinate`.
    func lookupGPS(near coordinate: CLLocationCoordinate2D) -> [HoleGPS] {
        guard let db else { return [] }
        let pad  = 0.018   // ~2 km
        let padL = pad * 1.6
        let sql = """
            SELECT h.number, h.tee_lat, h.tee_lon, h.pin_lat, h.pin_lon
            FROM holes h
            JOIN courses c ON h.course_id = c.id
            WHERE c.lat BETWEEN ? AND ?
              AND c.lon BETWEEN ? AND ?
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_double(stmt, 1, coordinate.latitude  - pad)
        sqlite3_bind_double(stmt, 2, coordinate.latitude  + pad)
        sqlite3_bind_double(stmt, 3, coordinate.longitude - padL)
        sqlite3_bind_double(stmt, 4, coordinate.longitude + padL)

        var result: [HoleGPS] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let n      = Int(sqlite3_column_int(stmt, 0))
            let teeLat = sqlite3_column_type(stmt, 1) != SQLITE_NULL ? sqlite3_column_double(stmt, 1) : nil as Double?
            let teeLon = sqlite3_column_type(stmt, 2) != SQLITE_NULL ? sqlite3_column_double(stmt, 2) : nil as Double?
            let pinLat = sqlite3_column_type(stmt, 3) != SQLITE_NULL ? sqlite3_column_double(stmt, 3) : nil as Double?
            let pinLon = sqlite3_column_type(stmt, 4) != SQLITE_NULL ? sqlite3_column_double(stmt, 4) : nil as Double?
            result.append(HoleGPS(number: n, pinLat: pinLat, pinLon: pinLon, teeLat: teeLat, teeLon: teeLon))
        }
        return result
    }
}
