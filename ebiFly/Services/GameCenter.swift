import GameKit
import UIKit

/// Game Center sign-in and the distance leaderboard.
/// The leaderboard `leaderboardID` must exist in App Store Connect (Features > Game Center).
@MainActor
final class GameCenter: ObservableObject {
    static let shared = GameCenter()
    // v2: the original "ebifly.distance" was released with the wrong sort order (Low to High); this one is High to Low.
    static let leaderboardID = "ebifly.distance.v2"

    @Published private(set) var isAuthenticated = false
    private var pendingLogin: UIViewController?

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, _ in
            Task { @MainActor in
                guard let self else { return }
                // Don't interrupt the title screen; the sign-in sheet is shown when the player opens the ranking.
                self.pendingLogin = viewController
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
        }
    }

    func submit(score: Int) {
        guard isAuthenticated, score > 0 else { return }
        Task {
            try? await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                                 leaderboardIDs: [Self.leaderboardID])
        }
    }

    func showLeaderboard() {
        if isAuthenticated {
            GKAccessPoint.shared.trigger(state: .leaderboards) {}
        } else if let login = pendingLogin, let root = Self.topViewController() {
            root.present(login, animated: true)
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
