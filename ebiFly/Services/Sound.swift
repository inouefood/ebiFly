import AVFoundation

/// Short sound effects bundled in Resources/Sounds.
/// Uses the ambient session: mixes with the player's music and stays quiet with the silent switch on.
enum Sound: String {
    case collision = "ebi_collision_one_shot"

    /// Call once at launch.
    static func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    /// A few players per sound so hits close together overlap instead of cutting each other off.
    private static var pools: [Sound: [AVAudioPlayer]] = [:]
    private static let poolSize = 3

    func play(volume: Float = 1) {
        let players = Self.pools[self] ?? load()
        guard let player = players.first(where: { !$0.isPlaying }) ?? players.first else { return }
        player.currentTime = 0
        player.volume = volume
        player.play()
    }

    /// Loads (and prepares) the players ahead of time so the first play has no delay.
    func preload() { _ = Self.pools[self] ?? load() }

    private func load() -> [AVAudioPlayer] {
        guard let url = Bundle.main.url(forResource: rawValue, withExtension: "wav") else { return [] }
        let players = (0..<Self.poolSize).compactMap { _ -> AVAudioPlayer? in
            let p = try? AVAudioPlayer(contentsOf: url)
            p?.prepareToPlay()
            return p
        }
        Self.pools[self] = players
        return players
    }
}
