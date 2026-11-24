import CoreMotion
import Foundation
import UIKit

/// Device motion for the sauce shake and the tilt steering. Accelerometer access needs no permission prompt.
final class MotionService {
    private let manager = CMMotionManager()
    private var lastShake: TimeInterval = 0

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    /// Calls `onShake` once per distinct shake (user acceleration above ~1.1g, debounced).
    func startShakeDetection(_ onShake: @escaping () -> Void) {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let a = motion?.userAcceleration else { return }
            let magnitude = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            let now = ProcessInfo.processInfo.systemUptime
            if magnitude > 1.1, now - self.lastShake > 0.12 {
                self.lastShake = now
                onShake()
            }
        }
    }

    func startTilt() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60
        manager.startDeviceMotionUpdates()
    }

    /// Left/right gravity component in the interface's coordinate system.
    func tiltX(in orientation: UIInterfaceOrientation) -> Double {
        guard let gravity = manager.deviceMotion?.gravity else { return 0 }
        switch orientation {
        case .landscapeLeft: return -gravity.y
        case .landscapeRight: return gravity.y
        case .portraitUpsideDown: return -gravity.x
        default: return gravity.x
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
