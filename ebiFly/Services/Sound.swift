import AVFoundation

/// Sound effects bundled in Resources/Sounds (cleaned up by Design/tools/prepare_sounds.py).
/// Uses the playback session so effects are heard even with the silent switch on,
/// mixed with whatever the player is listening to (their music keeps playing).
enum Sound: String, CaseIterable {
    case uiTap = "ui_tap"
    case stepClear = "step_clear"
    case titleCollision = "ebi_collision_one_shot"
    // batter
    case pankoA = "catch_panko_a", pankoB = "catch_panko_b", pankoC = "catch_panko_c"
    case gold = "catch_gold"
    case waterHit = "water_hit"
    // fry
    case fryDip = "fry_dip"
    case frySizzle = "fry_sizzle_loop"
    case fryPerfect = "fry_perfect"
    case fryUnder = "fry_under"
    case fryBurnt = "fry_burnt"
    // sauce
    case sauceShake = "sauce_shake"
    case sauceDrop = "sauce_drop"
    // fly
    case launchReady = "launch_ready"
    case launch
    case fuel = "fuel_pickup"
    case collision = "collision_pon"
    case gameOver = "gameover"

    /// Playback volume, to even out the files (measured RMS) and keep the frequent ones quiet.
    private var volume: Float {
        switch self {
        case .uiTap: return 0.35            // loudest file, and the most frequent sound
        case .pankoA, .pankoB, .pankoC: return 0.4
        case .sauceDrop: return 0.35
        case .sauceShake: return 0.55
        case .frySizzle: return 0.6
        case .waterHit, .gameOver: return 0.75
        default: return 0.85
        }
    }

    /// A random one of the three crumb catches, so a quick run of them doesn't sound mechanical.
    static var panko: Sound { [.pankoA, .pankoB, .pankoC].randomElement()! }

    // All audio work (session setup, loading, playing) runs on one serial queue, never the main thread:
    // activating the session can block, and AVAudioPlayer.prepareToPlay()/play() activate it implicitly
    // when it isn't active yet, which is what made AVAudioSession warn about main-thread activation.
    // Being serial also orders things: the session is set up before any player is created or played.
    // `pools` and `lastPlayed` are only touched on this queue.
    private static let queue = DispatchQueue(label: "ebiFly.sound", qos: .userInitiated)

    /// Call once at launch.
    static func configure() {
        queue.async {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, options: [.mixWithOthers])
            try? session.setActive(true)
        }
    }

    /// Loads every sound ahead of time so nothing has a delay the first time it plays.
    static func preloadAll() {
        queue.async { allCases.forEach { _ = $0.players } }
    }

    /// A few players per sound so plays close together overlap instead of cutting each other off.
    private static var pools: [Sound: [AVAudioPlayer]] = [:]
    private static var lastPlayed: [Sound: TimeInterval] = [:]

    /// Call on `queue` only.
    private var players: [AVAudioPlayer] {
        if let p = Self.pools[self] { return p }
        guard let url = Bundle.main.url(forResource: rawValue, withExtension: "wav") else { return [] }
        let count = self == .frySizzle ? 1 : 3
        let players = (0..<count).compactMap { _ -> AVAudioPlayer? in
            let p = try? AVAudioPlayer(contentsOf: url)
            p?.prepareToPlay()
            return p
        }
        Self.pools[self] = players
        return players
    }

    /// - Parameters:
    ///   - gain: extra scale on top of the sound's own volume.
    ///   - minInterval: skip the play if this sound started less than this many seconds ago
    ///     (for things that can happen many times a second, like catching crumbs).
    func play(gain: Float = 1, minInterval: TimeInterval = 0) {
        let now = ProcessInfo.processInfo.systemUptime
        Self.queue.async {
            if minInterval > 0, let last = Self.lastPlayed[self], now - last < minInterval { return }
            Self.lastPlayed[self] = now
            let pool = players
            guard let player = pool.first(where: { !$0.isPlaying }) ?? pool.first else { return }
            player.currentTime = 0
            player.volume = volume * gain
            player.numberOfLoops = 0
            player.play()
        }
    }

    /// Plays over and over until `stop()`, fading in.
    func loop(fadeIn: TimeInterval = 0.3) {
        Self.queue.async {
            guard let player = players.first, !player.isPlaying else { return }
            player.numberOfLoops = -1
            player.currentTime = 0
            player.volume = 0
            player.play()
            player.setVolume(volume, fadeDuration: fadeIn)
        }
    }

    /// Stops a looping (or any) play of this sound, fading out.
    func stop(fadeOut: TimeInterval = 0.2) {
        Self.queue.async {
            for player in players where player.isPlaying {
                player.setVolume(0, fadeDuration: fadeOut)
                Self.queue.asyncAfter(deadline: .now() + fadeOut) { player.stop() }
            }
        }
    }
}
