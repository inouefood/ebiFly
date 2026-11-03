import SwiftUI

enum Screen: Hashable {
    case title, make, batter, fry, shake, fly, result, records
}

/// Tails, in the order the make screen lists them (cheapest first). Purely cosmetic.
/// Raw values are persisted and match the `tail-<rawValue>` image assets (Design/art.py, Design/tails.py).
enum TailKind: String, CaseIterable, Codable, Identifiable {
    case normal, heart, blue, purple, stripe, dots, leaf, clover, sakura, ribbon
    case fish, star, maple, ginkgo, shell, butterfly, moon, bolt, flame, snow
    case sun, wings, peacock, rainbow, silver, rocket, crown, gold, gem, galaxy

    var id: String { rawValue }
    var imageName: String { "tail-\(rawValue)" }

    var displayName: String {
        switch self {
        case .normal: return "ノーマル"
        case .heart: return "ハート"
        case .blue: return "あお"
        case .purple: return "むらさき"
        case .stripe: return "しましま"
        case .dots: return "みずたま"
        case .leaf: return "はっぱ"
        case .clover: return "よつば"
        case .sakura: return "さくら"
        case .ribbon: return "リボン"
        case .fish: return "さかな"
        case .star: return "ほし"
        case .maple: return "もみじ"
        case .ginkgo: return "いちょう"
        case .shell: return "かいがら"
        case .butterfly: return "ちょうちょ"
        case .moon: return "みかづき"
        case .bolt: return "いなずま"
        case .flame: return "ほのお"
        case .snow: return "ゆき"
        case .sun: return "たいよう"
        case .wings: return "つばさ"
        case .peacock: return "くじゃく"
        case .rainbow: return "にじいろ"
        case .silver: return "ぎん"
        case .rocket: return "ロケット"
        case .crown: return "おうかん"
        case .gold: return "きん"
        case .gem: return "ほうせき"
        case .galaxy: return "ぎんが"
        }
    }

    /// Points needed to exchange for this tail. 0 = owned from the start.
    var price: Int {
        switch self {
        case .normal: return 0
        case .heart, .blue, .purple: return 100
        case .stripe, .dots: return 150
        case .leaf, .clover: return 200
        case .sakura, .ribbon: return 300
        case .fish, .star: return 400
        case .maple, .ginkgo: return 500
        case .shell: return 600
        case .butterfly: return 700
        case .moon: return 800
        case .bolt: return 900
        case .flame, .snow: return 1000
        case .sun: return 1200
        case .wings: return 1400
        case .peacock: return 1600
        case .rainbow: return 1800
        case .silver: return 2000
        case .rocket: return 2200
        case .crown: return 2500
        case .gold: return 2800
        case .gem, .galaxy: return 3000
        }
    }
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
    let refuels: Int
    /// Exchange points this flight earned.
    let points: Int
}

enum Scoring {
    static let bodyRange = 3...6
    static let batterSeconds: TimeInterval = 10
    static let shakeSeconds: TimeInterval = 3

    /// Fuel the prep steps put in the tank, in meters of climbing (before any refuel in the air).
    static func maxDistance(crumbs: Int, shakes: Int, multiplier: Double, bodyCount: Int) -> Int {
        // crumbs come in by the hundred, so each one is worth little
        let base = Double(crumbs) * 10 / 3 + Double(shakes * 40)
        return Int((base * multiplier * (1 + Double(bodyCount - 3) * 0.12)).rounded())
    }

    /// Exchange points for a flight: 1 point per 10 m.
    static func points(forDistance d: Int) -> Int { max(0, d) / 10 }

    /// Climb speed in m/s: the more sauce, the faster the shrimp rises.
    static func climbSpeed(shakes: Int) -> Double {
        min(640, 220 + Double(max(shakes, 0)) * 12)
    }

    static func sauceLabel(shakes: Int) -> String {
        switch shakes {
        case ..<10: return "ちょろちょろ"
        case ..<20: return "ぐんぐん"
        case ..<30: return "びゅーん"
        default: return "ロケット"
        }
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
    /// Exchange points to spend on tails.
    @Published private(set) var points: Int
    @Published private(set) var ownedTails: Set<TailKind>
    /// Set after a run when the review dialog should be shown on the result screen.
    @Published var wantsReview = false
    private var reviewPrompt: ReviewPrompt

    private let defaults: UserDefaults
    private enum Key {
        static let best = "best"
        static let history = "history"
        static let tail = "tail"
        static let bodyCount = "bodyCount"
        static let points = "points"
        static let ownedTails = "ownedTails"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        reviewPrompt = ReviewPrompt(defaults: defaults)
        let best = defaults.integer(forKey: Key.best)
        self.best = best
        if let data = defaults.data(forKey: Key.history),
           let saved = try? JSONDecoder().decode([RunRecord].self, from: data) {
            history = saved
        } else {
            history = []
        }
        points = defaults.integer(forKey: Key.points)
        if let saved = defaults.stringArray(forKey: Key.ownedTails) {
            ownedTails = Set(saved.compactMap(TailKind.init(rawValue:)))
        } else {
            // Before the exchange, the heart was free and the crown came with a 3000 m best.
            // Players who already played keep what they had; new players start with only the normal tail.
            var kept: Set<TailKind> = []
            if best > 0 { kept.insert(.heart) }
            if best >= 3000 { kept.insert(.crown) }
            ownedTails = kept
        }
        ownedTails.formUnion(TailKind.allCases.filter { $0.price == 0 })
        if let raw = defaults.string(forKey: Key.tail), let t = TailKind(rawValue: raw), ownedTails.contains(t) {
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
                                      crumbs: crumbs, fry: fry, shakes: shakes, refuels: 3, points: 230)
        }
        screen = s
    }
    #endif

    var fryMultiplier: Double { Scoring.fryVerdict(fry).multiplier }
    var maxDistance: Int {
        Scoring.maxDistance(crumbs: crumbs, shakes: shakes, multiplier: fryMultiplier, bodyCount: bodyCount)
    }

    func isUnlocked(_ t: TailKind) -> Bool { ownedTails.contains(t) }

    /// Spend points on a tail and put it on. Returns false if it is not affordable.
    @discardableResult
    func exchange(_ t: TailKind) -> Bool {
        guard !ownedTails.contains(t), points >= t.price else { return false }
        points -= t.price
        ownedTails.insert(t)
        defaults.set(points, forKey: Key.points)
        defaults.set(ownedTails.map(\.rawValue).sorted(), forKey: Key.ownedTails)
        select(tail: t)
        return true
    }

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

    func finishFlight(distance: Int, hitBy: Obstacle?, refuels: Int) {
        let isNew = distance > best
        let earned = Scoring.points(forDistance: distance)
        lastResult = FlightResult(distance: distance, maxDistance: maxDistance, hitBy: hitBy, isNewBest: isNew,
                                  crumbs: crumbs, fry: fry, shakes: shakes, refuels: refuels, points: earned)
        points += earned
        defaults.set(points, forKey: Key.points)
        history.insert(RunRecord(distance: distance, date: Date()), at: 0)
        history = Array(history.prefix(20))
        if isNew { best = distance }
        defaults.set(best, forKey: Key.best)
        if let data = try? JSONEncoder().encode(history) { defaults.set(data, forKey: Key.history) }
        GameCenter.shared.submit(score: distance)
        wantsReview = reviewPrompt.runFinished(isNewBest: isNew)
        go(.result)
    }
}
