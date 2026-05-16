import WatchConnectivity
import Foundation
import CoreLocation

@Observable
class ConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = ConnectivityManager()
    var isWatchReachable: Bool = false
    var isWatchAppInstalled: Bool = false

    var onWatchMessage: (([String: Any]) -> Void)?

    struct StartRoundRequest: Equatable {
        let courseName: String
        let lat: Double
        let lon: Double
    }
    var pendingStartRound: StartRoundRequest?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendRoundState(_ state: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        do { try WCSession.default.updateApplicationContext(state) }
        catch { print("ConnectivityManager: context update failed: \(error)") }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(state, replyHandler: nil, errorHandler: nil)
        }
    }

    func sendNoActiveRound() { sendRoundState(["hasActiveRound": false]) }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isWatchReachable = session.isReachable }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String, action == "startRound",
               let name = message["courseName"] as? String,
               let lat  = message["courseLat"]  as? Double,
               let lon  = message["courseLon"]  as? Double {
                self.pendingStartRound = StartRoundRequest(courseName: name, lat: lat, lon: lon)
            } else {
                self.onWatchMessage?(message)
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}

// MARK: - Round → Watch payload

extension GolfRound {
    func watchPayload() -> [String: Any] {
        var scoresDict: [String: Int] = [:]
        var puttsDict:  [String: Int] = [:]
        var fairwayDict: [String: Bool] = [:]
        for score in scores {
            scoresDict["\(score.holeNumber)"] = score.strokes
            puttsDict["\(score.holeNumber)"]  = score.putts
            if let fw = score.fairwayHit { fairwayDict["\(score.holeNumber)"] = fw }
        }
        let hole = course?.sortedHoles.first { $0.number == currentHoleNumber }
        var payload: [String: Any] = [
            "hasActiveRound":    true,
            "courseName":        course?.name ?? "",
            "currentHole":       currentHoleNumber,
            "totalHoles":        course?.holeCount ?? 18,
            "par":               hole?.par ?? 4,
            "yardage":           hole?.yardage ?? 0,
            "hasPinCoordinates": hole?.hasPinCoordinates ?? false,
            "scores":            scoresDict,
            "putts":             puttsDict,
            "fairways":          fairwayDict,
            "totalStrokes":      totalStrokes,
            "roundDate":         ISO8601DateFormatter().string(from: date)
        ]
        if let pin = hole?.pinCoordinate {
            payload["pinLat"] = pin.latitude
            payload["pinLon"] = pin.longitude
        }
        return payload
    }
}
