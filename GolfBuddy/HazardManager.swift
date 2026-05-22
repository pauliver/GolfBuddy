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

    /// Prefetch hazards for all holes on the course in the background.
    func prefetchAllHoles(course: GolfCourse) async {
        prefetchTask?.cancel()
        prefetchTask = Task {
            let courseId = course.id
            for hole in course.sortedHoles {
                guard !Task.isCancelled else { return }
                if await HazardCache.shared.get(courseId: courseId, holeNumber: hole.number) != nil {
                    continue
                }
                var hazards: [HazardPolygon]
                do {
                    hazards = try await HazardLoader.fetch(tee: hole.teeCoordinate, pin: hole.pinCoordinate)
                } catch {
                    hazards = []
                }
                #if os(iOS)
                if let tee = hole.teeCoordinate, let pin = hole.pinCoordinate {
                    hazards += await SatelliteHazardDetector.detect(
                        tee: tee, pin: pin, existingHazards: hazards
                    )
                } else if let coord = hole.pinCoordinate ?? hole.teeCoordinate {
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
