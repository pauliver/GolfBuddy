import Foundation
import SwiftData
import CoreLocation

// MARK: - Hole Features

enum FeatureType: String, Codable {
    case bunker
    case water
    case green
}

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct HoleFeature: Codable {
    let type: FeatureType
    let coordinates: [Coordinate]
}


@Model
final class GolfCourse {
    var id: UUID = UUID()
    var name: String = ""
    var city: String = ""
    var state: String = ""
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade) var holes: [GolfHole] = []
    @Relationship(deleteRule: .cascade) var rounds: [GolfRound] = []

    init(name: String, city: String = "", state: String = "") {
        self.id = UUID()
        self.name = name
        self.city = city
        self.state = state
        self.createdAt = Date()
        self.holes = []
        self.rounds = []
    }

    var sortedHoles: [GolfHole] { holes.sorted { $0.number < $1.number } }
    var totalPar: Int { holes.reduce(0) { $0 + $1.par } }
    var holeCount: Int { holes.count }
    var locationString: String { [city, state].filter { !$0.isEmpty }.joined(separator: ", ") }
}

@Model
final class GolfHole {
    var number: Int = 1
    var par: Int = 4
    var handicap: Int = 1
    var yardage: Int = 0
    var teeLatitude: Double = 0.0
    var teeLongitude: Double = 0.0
    var pinLatitude: Double = 0.0
    var pinLongitude: Double = 0.0
    var hasTeeCoordinates: Bool = false
    var hasPinCoordinates: Bool = false
    var featuresData: Data? = nil
    var course: GolfCourse?


    init(number: Int, par: Int = 4, handicap: Int = 1, yardage: Int = 0) {
        self.number = number
        self.par = par
        self.handicap = handicap
        self.yardage = yardage
    }

    var pinCoordinate: CLLocationCoordinate2D? {
        guard hasPinCoordinates else { return nil }
        return CLLocationCoordinate2D(latitude: pinLatitude, longitude: pinLongitude)
    }

    var teeCoordinate: CLLocationCoordinate2D? {
        guard hasTeeCoordinates else { return nil }
        return CLLocationCoordinate2D(latitude: teeLatitude, longitude: teeLongitude)
    }

    var features: [HoleFeature] {
        guard let data = featuresData else { return [] }
        return (try? JSONDecoder().decode([HoleFeature].self, from: data)) ?? []
    }
}


@Model
final class GolfRound {
    var id: UUID = UUID()
    var date: Date = Date()
    var currentHoleNumber: Int = 1
    var isComplete: Bool = false
    var course: GolfCourse?
    @Relationship(deleteRule: .cascade) var scores: [HoleScore] = []

    init(course: GolfCourse) {
        self.id = UUID()
        self.date = Date()
        self.currentHoleNumber = 1
        self.isComplete = false
        self.course = course
        self.scores = []
    }

    var totalStrokes: Int { scores.reduce(0) { $0 + $1.strokes } }
    var totalPutts:   Int { scores.reduce(0) { $0 + $1.putts } }

    var scoreVsPar: Int {
        guard let par = course?.totalPar, par > 0 else { return 0 }
        return totalStrokes - par
    }

    var completedHoles: Int { scores.filter { $0.strokes > 0 }.count }

    // Fairway stats — only holes where fairwayHit was recorded (par 4/5)
    var fairwaysHit:      Int { scores.compactMap(\.fairwayHit).filter { $0 }.count }
    var fairwaysEligible: Int { scores.compactMap(\.fairwayHit).count }

    // GIR — derived from strokes, putts, and hole par
    func greensInRegulation() -> Int {
        scores.filter { score in
            guard score.strokes > 0,
                  let hole = course?.sortedHoles.first(where: { $0.number == score.holeNumber })
            else { return false }
            return score.strokes - score.putts <= hole.par - 2
        }.count
    }

    func holesEligibleForGIR() -> Int {
        scores.filter { $0.strokes > 0 }.count
    }

    func scoreForHole(_ number: Int) -> HoleScore? {
        scores.first { $0.holeNumber == number }
    }

    func setScore(holeNumber: Int, strokes: Int, putts: Int, fairwayHit: Bool? = nil) {
        if let existing = scoreForHole(holeNumber) {
            existing.strokes    = strokes
            existing.putts      = putts
            if let fw = fairwayHit { existing.fairwayHit = fw }
        } else {
            let s = HoleScore(holeNumber: holeNumber, strokes: strokes, putts: putts, fairwayHit: fairwayHit)
            s.round = self
            scores.append(s)
        }
    }
}

@Model
final class HoleScore {
    var holeNumber: Int = 1
    var strokes: Int = 0
    var putts: Int = 0
    var fairwayHit: Bool? = nil   // nil = N/A (par 3); true/false for par 4/5
    var round: GolfRound?

    init(holeNumber: Int, strokes: Int = 0, putts: Int = 0, fairwayHit: Bool? = nil) {
        self.holeNumber = holeNumber
        self.strokes    = strokes
        self.putts      = putts
        self.fairwayHit = fairwayHit
    }
}
