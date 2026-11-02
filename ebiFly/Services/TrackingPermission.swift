import AppTrackingTransparency

/// Shows the App Tracking Transparency dialog once, the first time the app becomes active.
/// The request has to be made while the app is active, or iOS ignores it without showing anything.
enum TrackingPermission {
    @MainActor
    static func requestIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // a short pause lets the first screen settle so the dialog is not dropped during launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
