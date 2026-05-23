import Foundation
import CoreLocation

@Observable
class HazardManager {
    var currentHazards: [HazardPolygon] = []
    private var prefetchTask: Task<Void, Never>?

    /// Load hazards for a specific hole, using cache, OSM, and satellite detection.
    func loadHazards(for hole: GolfHole, courseId: UUID) async {
        // 1. Check cache
        if let cached = await HazardCache.shared.get(courseId: courseId, holeNumber: hole.number) {
            currentHazards = cached
            return
        }

        // 2. Fetch from OSM
        let osmHazards: [HazardPolygon]
        do {
            osmHazards = try await HazardLoader.fetch(tee: hole.teeCoordinate, pin: hole.pinCoordinate)
        } catch {
            osmHazards = []
        }

        // 3. Run satellite detection to supplement
        var allHazards = osmHazards
        #if os(iOS)
        if let tee = hole.teeCoordinate, let pin = hole.pinCoordinate {
            let satelliteHazards = await SatelliteHazardDetector.detect(
                tee: tee, pin: pin, existingHazards: osmHazards
            )
            allHazards += satelliteHazards
        } else if let coord = hole.pinCoordinate ?? hole.teeCoordinate {
            let satelliteHazards = await SatelliteHazardDetector.detect(
                center: coord, existingHazards: osmHazards
            )
            allHazards += satelliteHazards
        }
        #endif

        // 4. Cache the combined result
        await HazardCache.shared.set(courseId: courseId, holeNumber: hole.number, hazards: allHazards)

        currentHazards = allHazards
    }

    private struct HoleCoords: Sendable {
        let number: Int
        let tee: CLLocationCoordinate2D?
        let pin: CLLocationCoordinate2D?
    }

    func prefetchAllHoles(course: GolfCourse) async {
        prefetchTask?.cancel()
        let courseId = course.id
        let holeData = course.sortedHoles.map {
            HoleCoords(number: $0.number, tee: $0.teeCoordinate, pin: $0.pinCoordinate)
        }
        prefetchTask = Task.detached { [holeData] in
            for hole in holeData {
                guard !Task.isCancelled else { return }
                if await HazardCache.shared.get(courseId: courseId, holeNumber: hole.number) != nil {
                    continue
                }
                var hazards: [HazardPolygon]
                do {
                    hazards = try await HazardLoader.fetch(tee: hole.tee, pin: hole.pin)
                } catch {
                    hazards = []
                }
                #if os(iOS)
                if let tee = hole.tee, let pin = hole.pin {
                    hazards += await SatelliteHazardDetector.detect(
                        tee: tee, pin: pin, existingHazards: hazards
                    )
                } else if let coord = hole.pin ?? hole.tee {
                    hazards += await SatelliteHazardDetector.detect(
                        center: coord, existingHazards: hazards
                    )
                }
                #endif
                await HazardCache.shared.set(courseId: courseId, holeNumber: hole.number, hazards: hazards)
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
        }
    }

    /// Cancel any in-progress prefetch.
    func cancelPrefetch() {
        prefetchTask?.cancel()
    }
}
