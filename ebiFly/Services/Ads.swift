import AppTrackingTransparency
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// AdMob setup and the ads in the game:
/// - rewarded (continue): lets the shrimp keep flying after a crash (once per flight, the player chooses)
/// - rewarded (shop): watched toward an item in the shop instead of paying points (the player chooses)
/// - interstitial: now and then when the player taps "もう一回" on the result screen
/// Each rewarded placement has its own ad unit (separate reporting in AdMob) and its own preloaded ad.
///
/// Start-up order (Google's recommended flow):
/// 1. consent form for EEA/UK users (UMP; shows nothing elsewhere)
/// 2. App Tracking Transparency dialog
/// 3. start the SDK and preload the ads
@MainActor
final class Ads: NSObject, ObservableObject {
    static let shared = Ads()

    /// Real ad units in release builds; Google's sample units while developing, so test plays never count as real traffic.
    #if DEBUG
    private static let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
    #else
    private static let interstitialUnitID = "ca-app-pub-8522231452310619/1132116168"
    #endif

    enum RewardedPlacement: CaseIterable {
        case continueFlight, shop

        var unitID: String {
            #if DEBUG
            return "ca-app-pub-3940256099942544/1712485313"   // Google's sample rewarded unit
            #else
            switch self {
            case .continueFlight: return "ca-app-pub-8522231452310619/8139930531"
            case .shop: return "ca-app-pub-8522231452310619/6480569784"
            }
            #endif
        }
    }

    /// Interstitial pacing: every `interstitialEvery`-th retry, at least `interstitialGap` seconds apart,
    /// and never right after the player has seen another ad or the review dialog.
    #if DEBUG
    /// `-interstitialEvery 1` shows one on every retry while testing.
    static var interstitialEvery: Int {
        let n = UserDefaults.standard.integer(forKey: "interstitialEvery")
        return n > 0 ? n : 3
    }
    #else
    static let interstitialEvery = 3
    #endif
    static let interstitialGap: TimeInterval = 120

    /// The continue-flight ad is loaded (the flight screen offers "continue" only then).
    @Published private(set) var isRewardedReady = false
    /// The shop ad is loaded.
    @Published private(set) var isShopRewardedReady = false

    private var started = false
    private var rewarded: [RewardedPlacement: RewardedAd] = [:]
    private var loadingRewarded: Set<RewardedPlacement> = []
    private var interstitial: InterstitialAd?
    private var loadingInterstitial = false
    private var onDismiss: (() -> Void)?
    private var earned = false
    private var retries = 0
    private var lastFullScreenAd: Date?

    /// Call when the app becomes active; does the work only once.
    func startIfNeeded() {
        guard !started else { return }
        started = true
        #if DEBUG
        // `-skipAds YES`: no consent/ATT dialogs and no ads (for taking store screenshots)
        if UserDefaults.standard.bool(forKey: "skipAds") { return }
        #endif
        Task { [weak self] in
            // errors are ignored on purpose: ads still start (as non-personalised) if consent can't be updated
            try? await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try? await ConsentForm.loadAndPresentIfRequired(from: Self.topViewController())
            self?.requestTrackingThenStart()
        }
    }

    private func requestTrackingThenStart() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            startSDK()
            return
        }
        // a short pause so the dialog isn't dropped while the first screen is still settling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                Task { @MainActor in self.startSDK() }
            }
        }
    }

    private func startSDK() {
        // without consent (EEA/UK users who declined) ads must not be requested
        guard ConsentInformation.shared.canRequestAds else { return }
        MobileAds.shared.start { [weak self] _ in
            Task { @MainActor in
                RewardedPlacement.allCases.forEach { self?.loadRewarded($0) }
                self?.loadInterstitial()
            }
        }
    }

    // MARK: rewarded

    func loadRewarded(_ placement: RewardedPlacement = .continueFlight) {
        guard !loadingRewarded.contains(placement), rewarded[placement] == nil,
              ConsentInformation.shared.canRequestAds else { return }
        loadingRewarded.insert(placement)
        RewardedAd.load(with: placement.unitID, request: Request()) { [weak self] ad, _ in
            Task { @MainActor in
                guard let self else { return }
                self.loadingRewarded.remove(placement)
                self.rewarded[placement] = ad
                ad?.fullScreenContentDelegate = self
                self.updateReady()
            }
        }
    }

    private func updateReady() {
        isRewardedReady = rewarded[.continueFlight] != nil
        isShopRewardedReady = rewarded[.shop] != nil
    }

    /// Shows a rewarded ad. `completion(true)` only if the player watched it to the reward.
    func showRewarded(_ placement: RewardedPlacement = .continueFlight, completion: @escaping (Bool) -> Void) {
        guard let ad = rewarded[placement], let vc = Self.topViewController() else {
            completion(false)
            return
        }
        rewarded[placement] = nil
        updateReady()
        earned = false
        onDismiss = { [weak self] in completion(self?.earned ?? false) }
        lastFullScreenAd = Date()
        ad.present(from: vc) { [weak self] in
            self?.earned = true
        }
    }

    // MARK: interstitial

    func loadInterstitial() {
        guard !loadingInterstitial, interstitial == nil, ConsentInformation.shared.canRequestAds else { return }
        loadingInterstitial = true
        InterstitialAd.load(with: Self.interstitialUnitID, request: Request()) { [weak self] ad, _ in
            Task { @MainActor in
                guard let self else { return }
                self.loadingInterstitial = false
                self.interstitial = ad
                ad?.fullScreenContentDelegate = self
            }
        }
    }

    /// Call when the player taps "もう一回". Shows an interstitial if one is due, then runs `then`
    /// (right away when no ad is shown). `skip` is for results where the review dialog was just shown.
    func retryTapped(skip: Bool = false, then: @escaping () -> Void) {
        retries += 1
        let due = retries % Self.interstitialEvery == 0
        let rested = lastFullScreenAd.map { Date().timeIntervalSince($0) >= Self.interstitialGap } ?? true
        guard due, rested, !skip, let ad = interstitial, let vc = Self.topViewController() else {
            then()
            return
        }
        interstitial = nil
        onDismiss = then
        lastFullScreenAd = Date()
        ad.present(from: vc)
    }

    // MARK: -

    private func finishPresentation() {
        let done = onDismiss
        onDismiss = nil
        done?()
        RewardedPlacement.allCases.forEach { loadRewarded($0) }
        loadInterstitial()
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        var vc = scene?.windows.first { $0.isKeyWindow }?.rootViewController ?? scene?.windows.first?.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        return vc
    }
}

extension Ads: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in self.finishPresentation() }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in self.finishPresentation() }
    }
}
