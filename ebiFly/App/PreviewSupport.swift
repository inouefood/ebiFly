#if DEBUG
import SwiftUI

/// Hosts a game screen in Xcode with its in-app layout and a sample GameModel.
@MainActor
struct PreviewScreen<Content: View>: View {
    @StateObject private var game: GameModel
    private let content: Content
    private let playsFullWidth: Bool

    /// `game`: nil uses `GameModel.preview()`.
    init(_ game: GameModel? = nil, playsFullWidth: Bool = false, @ViewBuilder content: () -> Content) {
        _game = StateObject(wrappedValue: game ?? .preview())
        self.playsFullWidth = playsFullWidth
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let width = GameLayout.columnWidth(in: geo.size)
            ZStack {
                content
                    .frame(width: playsFullWidth ? geo.size.width : width, height: geo.size.height)
                    .environment(\.gameColumnWidth, width)
                    .environment(\.uiScale, min(max(width / 300, 1), 1.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .backdropBackground(unit: width / 300)
        }
        .environmentObject(game)
    }
}
#endif
