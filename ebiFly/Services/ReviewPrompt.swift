import Foundation

/// Decides when to ask for an App Store review, so the dialog shows up rarely and at a good moment.
///
/// Rules (on top of iOS's own limit of 3 times a year):
/// - only after the player has finished at least `minPlays` runs
/// - only right after a good run (a new best)
/// - at most once per app version
/// - at least `minDaysBetween` days since the last time
/// - at most `maxRequests` times in total
struct ReviewPrompt {
    static let minPlays = 3
    static let minDaysBetween = 60.0
    static let maxRequests = 3

    private let defaults: UserDefaults
    private enum Key {
        static let plays = "review.plays"
        static let count = "review.count"
        static let lastDate = "review.lastDate"
        static let lastVersion = "review.lastVersion"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Call once per finished run. Returns true when the review dialog should be shown now,
    /// and records that it was asked.
    mutating func runFinished(isNewBest: Bool, now: Date = Date(),
                              version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "") -> Bool {
        let plays = defaults.integer(forKey: Key.plays) + 1
        defaults.set(plays, forKey: Key.plays)

        guard plays >= Self.minPlays, isNewBest else { return false }
        let count = defaults.integer(forKey: Key.count)
        guard count < Self.maxRequests else { return false }
        guard defaults.string(forKey: Key.lastVersion) != version else { return false }
        if let last = defaults.object(forKey: Key.lastDate) as? Date,
           now.timeIntervalSince(last) < Self.minDaysBetween * 86_400 {
            return false
        }

        defaults.set(count + 1, forKey: Key.count)
        defaults.set(now, forKey: Key.lastDate)
        defaults.set(version, forKey: Key.lastVersion)
        return true
    }
}
