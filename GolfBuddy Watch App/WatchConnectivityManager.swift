import WatchConnectivity
import Foundation

@Observable
class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    var hasActiveRound: Bool = false
    var courseName: String = ""
    var currentHole: Int = 1
    var totalHoles: Int = 18
    var par: Int = 4
    var yardage: Int = 0
    var hasPinCoordinates: Bool = false
    var pinLat: Double = 0
    var pinLon: Double = 0
    var scores:   [Int: Int]  = [:]
    var putts:    [Int: Int]  = [:]
    var fairways: [Int: Bool] = [:]
    var totalStrokes: Int = 0

    var currentHoleScore:   Int  { scores[currentHole]   ?? 0 }
    var currentHolePutts:   Int  { putts[currentHole]    ?? 0 }
    var currentHoleFairway: Bool? { fairways[currentHole] }

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendScoreUpdate(hole: Int, strokes: Int, putts p: Int, fairwayHit: Bool? = nil) {
        scores[hole]  = strokes
        putts[hole]   = p
        if let fw = fairwayHit { fairways[hole] = fw }
        var msg: [String: Any] = ["action": "setScore", "hole": hole, "strokes": strokes, "putts": p]
        if let fw = fairwayHit { msg["fairwayHit"] = fw }
        sendToPhone(msg)
    }

    func sendNextHole() { sendToPhone(["action": "nextHole"]) }
    func sendEndRound() { sendToPhone(["action": "endRound"]) }

    private func sendToPhone(_ message: [String: Any]) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(message, replyHandler: nil) { err in
            print("Watch→Phone send error: \(err)")
        }
    }

    private func applyPayload(_ payload: [String: Any]) {
        hasActiveRound    = payload["hasActiveRound"] as? Bool ?? false
        guard hasActiveRound else { return }
        courseName        = payload["courseName"] as? String ?? ""
        currentHole       = payload["currentHole"] as? Int ?? 1
        totalHoles        = payload["totalHoles"] as? Int ?? 18
        par               = payload["par"] as? Int ?? 4
        yardage           = payload["yardage"] as? Int ?? 0
        hasPinCoordinates = payload["hasPinCoordinates"] as? Bool ?? false
        pinLat            = payload["pinLat"] as? Double ?? 0
        pinLon            = payload["pinLon"] as? Double ?? 0
        totalStrokes      = payload["totalStrokes"] as? Int ?? 0

        if let raw = payload["scores"] as? [String: Int] {
            scores = Dictionary(uniqueKeysWithValues: raw.compactMap { k, v in Int(k).map { ($0, v) } })
        }
        if let raw = payload["putts"] as? [String: Int] {
            putts = Dictionary(uniqueKeysWithValues: raw.compactMap { k, v in Int(k).map { ($0, v) } })
        }
        if let raw = payload["fairways"] as? [String: Bool] {
            fairways = Dictionary(uniqueKeysWithValues: raw.compactMap { k, v in Int(k).map { ($0, v) } })
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.applyPayload(applicationContext) }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.applyPayload(message) }
    }
}
