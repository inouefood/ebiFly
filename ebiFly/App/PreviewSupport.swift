#if DEBUG
import SwiftUI

/// Hosts a screen in an Xcode Preview the way RootView does in the app: a phone-shaped column with the
/// screen's own `uiScale`, its backdrop behind it, and a sample GameModel.
@MainActor
struct PreviewScreen<Content: View>: View {
    @StateObject private var game: GameModel
    private let content: Content

    /// `game`: nil uses `GameModel.preview()`.
    init(_ game: GameModel? = nil, @ViewBuilder content: () -> Content) {
        _game = StateObject(wrappedValue: game ?? .preview())
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, geo.size.height * 0.56)
            ZStack {
                content
                    .frame(width: width, height: geo.size.height)
                    .environment(\.uiScale, min(max(width / 300, 1), 1.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .backdropBackground(unit: width / 300)
        }
        .environmentObject(game)
    }
}
#endif
