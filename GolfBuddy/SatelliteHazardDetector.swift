#if os(iOS)
import Foundation
import MapKit
import CoreLocation
import UIKit

// MARK: - SatelliteHazardDetector

/// Uses MKMapSnapshotter to capture satellite imagery of a golf hole,
/// then applies HSV color segmentation to detect water bodies and bunkers
/// that may be missing from OSM data.
struct SatelliteHazardDetector {

    // MARK: - Public entry points

    /// Detect hazards between tee and pin.
    static func detect(
        tee: CLLocationCoordinate2D,
        pin: CLLocationCoordinate2D,
        existingHazards: [HazardPolygon]
    ) async -> [HazardPolygon] {
        let center = CLLocationCoordinate2D(
            latitude: (tee.latitude + pin.latitude) / 2,
            longitude: (tee.longitude + pin.longitude) / 2
        )
        return await detect(center: center, existingHazards: existingHazards)
    }

    /// Detect hazards around a single center point.
    static func detect(
        center: CLLocationCoordinate2D,
        existingHazards: [HazardPolygon]
    ) async -> [HazardPolygon] {
        // Skip satellite detection if OSM already has coverage of both bunkers and water
        let hasOSMBunkers = existingHazards.contains { $0.kind == .bunker }
        let hasOSMWater = existingHazards.contains { $0.kind == .water || $0.kind == .lateralWater }
        if hasOSMBunkers && hasOSMWater { return [] }

        // Capture satellite snapshot
        let span = MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        let region = MKCoordinateRegion(center: center, span: span)
        let imageSize = CGSize(width: 600, height: 600)

        guard let image = await captureSnapshot(region: region, size: imageSize) else { return [] }
        guard let cgImage = image.cgImage else { return [] }

        var detected: [HazardPolygon] = []

        // Detect water if OSM doesn't have it
        if !hasOSMWater {
            let waterRegions = detectColor(
                in: cgImage,
                hueRange: 190...240,
                saturationMin: 0.3,
                saturationMax: 1.0,
                brightnessMin: 0.2,
                minPixelArea: 100
            )
            for region in waterRegions {
                let coords = pixelsToCoordinates(
                    region, center: center, span: span,
                    imageWidth: CGFloat(cgImage.width), imageHeight: CGFloat(cgImage.height)
                )
                if coords.count >= 3 {
                    detected.append(HazardPolygon(kind: .water, clCoordinates: coords))
                }
            }
        }

        // Detect sand/bunkers if OSM doesn't have them
        if !hasOSMBunkers {
            let sandRegions = detectColor(
                in: cgImage,
                hueRange: 30...50,
                saturationMin: 0.2,
                saturationMax: 0.6,
                brightnessMin: 0.5,
                minPixelArea: 50
            )
            for region in sandRegions {
                let coords = pixelsToCoordinates(
                    region, center: center, span: span,
                    imageWidth: CGFloat(cgImage.width), imageHeight: CGFloat(cgImage.height)
                )
                if coords.count >= 3 {
                    detected.append(HazardPolygon(kind: .bunker, clCoordinates: coords))
                }
            }
        }

        return detected
    }

    // MARK: - Snapshot capture

    private static func captureSnapshot(
        region: MKCoordinateRegion,
        size: CGSize
    ) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.mapType = .satellite

        let snapshotter = MKMapSnapshotter(options: options)
        do {
            let snapshot = try await snapshotter.start()
            return snapshot.image
        } catch {
            print("SatelliteHazardDetector: snapshot failed: \(error)")
            return nil
        }
    }

    // MARK: - Color detection

    /// Pixel region represented as an array of (x, y) boundary points (convex hull).
    typealias PixelRegion = [(x: Int, y: Int)]

    /// Detect contiguous regions of pixels matching HSV criteria.
    private static func detectColor(
        in image: CGImage,
        hueRange: ClosedRange<Double>,
        saturationMin: Double,
        saturationMax: Double,
        brightnessMin: Double,
        minPixelArea: Int
    ) -> [PixelRegion] {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return [] }

        // Get raw pixel data (RGBA, 8 bits per component)
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data,
              let ptr = CFDataGetBytePtr(data) else { return [] }

        let bytesPerPixel = image.bitsPerPixel / 8
        let bytesPerRow = image.bytesPerRow
        let alphaInfo = CGImageAlphaInfo(rawValue: image.bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        let byteOrder = CGBitmapInfo(rawValue: image.bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue)
        let isBGRA = (byteOrder == .byteOrder32Little) ||
                     (alphaInfo == .premultipliedFirst || alphaInfo == .noneSkipFirst)

        var mask = [Bool](repeating: false, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r: Double
                let g: Double
                let b: Double
                if isBGRA {
                    b = Double(ptr[offset]) / 255.0
                    g = Double(ptr[offset + 1]) / 255.0
                    r = Double(ptr[offset + 2]) / 255.0
                } else {
                    r = Double(ptr[offset]) / 255.0
                    g = Double(ptr[offset + 1]) / 255.0
                    b = Double(ptr[offset + 2]) / 255.0
                }

                let (h, s, v) = rgbToHSV(r: r, g: g, b: b)

                if hueRange.contains(h) && s >= saturationMin && s <= saturationMax && v >= brightnessMin {
                    mask[y * width + x] = true
                }
            }
        }

        // Connected component analysis via flood fill
        var visited = [Bool](repeating: false, count: width * height)
        var regions: [PixelRegion] = []

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                guard mask[idx] && !visited[idx] else { continue }

                // Flood fill to find the connected region
                var regionPixels: [(x: Int, y: Int)] = []
                var stack: [(x: Int, y: Int)] = [(x, y)]
                visited[idx] = true

                while let current = stack.popLast() {
                    regionPixels.append(current)

                    // Check 4-connected neighbors
                    let neighbors = [
                        (current.x - 1, current.y),
                        (current.x + 1, current.y),
                        (current.x, current.y - 1),
                        (current.x, current.y + 1)
                    ]
                    for (nx, ny) in neighbors {
                        guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                        let nIdx = ny * width + nx
                        guard mask[nIdx] && !visited[nIdx] else { continue }
                        visited[nIdx] = true
                        stack.append((nx, ny))
                    }
                }

                // Only keep regions above the minimum area threshold
                guard regionPixels.count >= minPixelArea else { continue }

                // Extract convex hull of the region's boundary
                let hull = convexHull(of: regionPixels)
                if hull.count >= 3 {
                    // Simplify to a manageable number of points
                    let simplified = simplifyPolygon(hull, maxPoints: 20)
                    regions.append(simplified)
                }
            }
        }

        return regions
    }

    // MARK: - RGB to HSV

    private static func rgbToHSV(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        // Value
        let v = maxC

        // Saturation
        let s: Double = maxC == 0 ? 0 : delta / maxC

        // Hue
        var h: Double = 0
        if delta > 0.0001 {
            if maxC == r {
                h = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
            } else if maxC == g {
                h = 60 * ((b - r) / delta + 2)
            } else {
                h = 60 * ((r - g) / delta + 4)
            }
            if h < 0 { h += 360 }
        }

        return (h, s, v)
    }

    // MARK: - Convex hull (Andrew's monotone chain, O(n log n))

    private static func convexHull(of points: [(x: Int, y: Int)]) -> PixelRegion {
        guard points.count >= 3 else { return points }

        // Extract boundary pixels only: for each row, keep min-x and max-x.
        // Reduces input from O(area) to O(2*height), massive speedup for large regions.
        var rowBounds: [Int: (minX: Int, maxX: Int)] = [:]
        for p in points {
            if let existing = rowBounds[p.y] {
                rowBounds[p.y] = (min(existing.minX, p.x), max(existing.maxX, p.x))
            } else {
                rowBounds[p.y] = (p.x, p.x)
            }
        }
        var boundary: PixelRegion = []
        for (y, bounds) in rowBounds {
            boundary.append((x: bounds.minX, y: y))
            if bounds.maxX != bounds.minX {
                boundary.append((x: bounds.maxX, y: y))
            }
        }

        let sorted = boundary.sorted { a, b in a.x < b.x || (a.x == b.x && a.y < b.y) }
        guard sorted.count >= 3 else { return sorted }

        var lower: PixelRegion = []
        for p in sorted {
            while lower.count >= 2 && crossProduct(o: lower[lower.count - 2], a: lower[lower.count - 1], b: p) <= 0 {
                lower.removeLast()
            }
            lower.append(p)
        }
        var upper: PixelRegion = []
        for p in sorted.reversed() {
            while upper.count >= 2 && crossProduct(o: upper[upper.count - 2], a: upper[upper.count - 1], b: p) <= 0 {
                upper.removeLast()
            }
            upper.append(p)
        }
        lower.removeLast()
        upper.removeLast()
        return lower + upper
    }

    private static func crossProduct(
        o: (x: Int, y: Int), a: (x: Int, y: Int), b: (x: Int, y: Int)
    ) -> Int {
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    }

    // MARK: - Polygon simplification

    /// Reduce a polygon to at most `maxPoints` by keeping every Nth point.
    private static func simplifyPolygon(_ points: PixelRegion, maxPoints: Int) -> PixelRegion {
        guard points.count > maxPoints else { return points }
        let step = Double(points.count) / Double(maxPoints)
        var result: PixelRegion = []
        for i in 0..<maxPoints {
            let idx = Int(Double(i) * step) % points.count
            result.append(points[idx])
        }
        return result
    }

    // MARK: - Pixel-to-coordinate mapping

    /// Convert pixel boundary points to geographic coordinates using the known region.
    /// This is an approximation that works well at golf-course zoom levels.
    private static func pixelsToCoordinates(
        _ pixels: PixelRegion,
        center: CLLocationCoordinate2D,
        span: MKCoordinateSpan,
        imageWidth: CGFloat,
        imageHeight: CGFloat
    ) -> [CLLocationCoordinate2D] {
        pixels.map { point in
            let longitude = center.longitude + (Double(point.x) / Double(imageWidth) - 0.5) * span.longitudeDelta
            let latitude = center.latitude - (Double(point.y) / Double(imageHeight) - 0.5) * span.latitudeDelta
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}
#endif
