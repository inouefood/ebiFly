import SwiftUI

enum Screen: Hashable {
    case title, make, batter, fry, shake, fly, result, records
}

enum TailKind: String, CaseIterable, Codable, Identifiable {
    case normal, heart, crown

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .normal: return "ノーマル"
        case .heart: return "ハート"
        case .crown: return "おうかん"
        }
    }
    /// Best distance needed to unlock this tail.
    var unlockDistance: Int { self == .crown ? 3000 : 0 }
    var imageName: String { "tail-\(rawValue)" }
}

enum Obstacle: String, Codable, CaseIterable {
    case bird, plane, meteor

    var displayName: String {
        switch self {
        case .bird: return "鳥"
        case .plane: return "飛行機"
        case .meteor: return "いん石"
        }
    }
}

struct RunRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    let distance: Int
    let date: Date
}

struct FlightResult {
    let distance: Int
    let maxDistance: Int
    let hitBy: Obstacle?
    let isNewBest: Bool
    let crumbs: Int
    let fry: Double
    let shakes: Int
}

enum Scoring {
    static let bodyRange = 3...6
    static let batterSeconds: TimeInterval = 10
    static let shakeSeconds: TimeInterval = 3

    /// The furthest the shrimp can fly if it dodges everything.
    static func maxDistance(crumbs: Int, shakes: Int, multiplier: Double, bodyCount: Int) -> Int {
        let base = Double(crumbs * 30 + shakes * 40)
        return Int((base * multiplier * (1 + Double(bodyCount - 3) * 0.12)).rounded())
    }

    static func fryVerdict(_ v: Double) -> (label: String, multiplier: Double) {
        if (0.42...0.58).contains(v) { return ("きつね色！", 1.5) }
        if (0.3...0.7).contains(v) { return ("いい感じ", 1.2) }
        return v < 0.3 ? ("ちょっと生…", 0.8) : ("こげた…", 0.7)
    }

    static let ranks: [(limit: Int, name: String)] = [
        (500, "生えび"), (1200, "見習いフライ"), (2000, "きつね色フライ"),
        (3000, "雲ごえフライ"), (5000, "成層圏フライ"), (.max, "宇宙えびフライ"),
    ]

    static func rank(for distance: Int) -> String {
        ranks.first { distance < $0.limit }?.name ?? ranks[ranks.count - 1].name
    }
}

/// Segment texture names exported from Design/export_assets.py.
enum SegmentSkin {
    static func batter(_ t: Double) -> String { "seg-b\(Int((min(max(t, 0), 1) * 5).rounded()))" }
    static func fry(_ v: Double) -> String { String(format: "seg-f%02d", Int((min(max(v, 0), 1) * 10).rounded())) }
}

@MainActor
final class GameModel: ObservableObject {
    @Published private(set) var screen: Screen = .title
    @Published var tail: TailKind = .normal
    @Published var bodyCount = 4
    @Published private(set) var crumbs = 0
    @Published private(set) var fry = 0.5
    @Published private(set) var shakes = 0
    @Published private(set) var lastResult: FlightResult?
    @Published private(set) var best: Int
    @Published private(set) var history: [RunRecord]

    private let defaults: UserDefaults
    private enum Key {
        static let best = "best"
        static let history = "history"
        static let tail = "tail"
        static let bodyCount = "bodyCount"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        best = defaults.integer(forKey: Key.best)
        if let data = defaults.data(forKey: Key.history),
           let saved = try? JSONDecoder().decode([RunRecord].self, from: data) {
            history = saved
        } else {
            history = []
        }
        if let raw = defaults.string(forKey: Key.tail), let t = TailKind(rawValue: raw), best >= t.unlockDistance {
            tail = t
        }
        let n = defaults.integer(forKey: Key.bodyCount)
        if Scoring.bodyRange.contains(n) { bodyCount = n }
        #if DEBUG
        applyDebugStart()
        #endif
    }

    #if DEBUG
    /// Debug builds only: `-startScreen fly` (launch argument) opens a screen with sample values.
    private func applyDebugStart() {
        guard let name = UserDefaults.standard.string(forKey: "startScreen") else { return }
        let screens: [String: Screen] = ["title": .title, "make": .make, "batter": .batter, "fry": .fry,
                                         "shake": .shake, "fly": .fly, "result": .result, "records": .records]
        guard let s = screens[name] else { return }
        crumbs = 22
        fry = 0.5
        shakes = 20
        if s == .result {
            lastResult = FlightResult(distance: 2300, maxDistance: maxDistance, hitBy: .plane, isNewBest: true,
                                      crumbs: crumbs, fry: fry, shakes: shakes)
        }
        screen = s
    }
    #endif

    var fryMultiplier: Double { Scoring.fryVerdict(fry).multiplier }
    var maxDistance: Int {
        Scoring.maxDistance(crumbs: crumbs, shakes: shakes, multiplier: fryMultiplier, bodyCount: bodyCount)
    }

    func isUnlocked(_ t: TailKind) -> Bool { best >= t.unlockDistance }

    func go(_ s: Screen) {
        withAnimation(.easeInOut(duration: 0.25)) { screen = s }
    }

    func startRun() {
        crumbs = 0
        fry = 0.5
        shakes = 0
        go(.make)
    }

    func select(tail t: TailKind) {
        guard isUnlocked(t) else { return }
        tail = t
        defaults.set(t.rawValue, forKey: Key.tail)
    }

    func changeBody(by delta: Int) {
        let n = bodyCount + delta
        guard Scoring.bodyRange.contains(n) else { return }
        bodyCount = n
        defaults.set(n, forKey: Key.bodyCount)
    }

    func finishBatter(crumbs: Int) {
        self.crumbs = crumbs
        go(.fry)
    }

    func finishFry(_ v: Double) {
        fry = v
        go(.shake)
    }

    func finishShake(_ count: Int) {
        shakes = count
        go(.fly)
    }

    func finishFlight(distance: Int, hitBy: Obstacle?) {
        let isNew = distance > best
        lastResult = FlightResult(distance: distance, maxDistance: maxDistance, hitBy: hitBy, isNewBest: isNew,
                                  crumbs: crumbs, fry: fry, shakes: shakes)
        history.insert(RunRecord(distance: distance, date: Date()), at: 0)
        history = Array(history.prefix(20))
        if isNew { best = distance }
        defaults.set(best, forKey: Key.best)
        if let data = try? JSONEncoder().encode(history) { defaults.set(data, forKey: Key.history) }
        GameCenter.shared.submit(score: distance)
        go(.result)
    }
}
