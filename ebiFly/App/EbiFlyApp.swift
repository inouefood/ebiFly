import SwiftUI

@main
struct EbiFlyApp: App {
    @StateObject private var game = GameModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AppFont.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(game)
                .onAppear { GameCenter.shared.authenticate() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { Ads.shared.startIfNeeded() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var game: GameModel

    var body: some View {
        GeometryReader { geo in
            // iPhone: full width. iPad: a phone-shaped column in the middle so the game keeps its proportions.
            let width = min(geo.size.width, geo.size.height * 0.56)
            ZStack {
                Palette.letterbox.ignoresSafeArea()
                screen
                    .id(game.screen)
                    .transition(.opacity)
                    .frame(width: width, height: geo.size.height)
                    .environment(\.uiScale, min(max(width / 300, 1), 1.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    @ViewBuilder private var screen: some View {
        switch game.screen {
        case .title: TitleView()
        case .make: MakeView()
        case .batter: BatterView(tail: game.tail, bodyCount: game.bodyCount)
        case .fry: FryView(tail: game.tail, bodyCount: game.bodyCount)
        case .shake: ShakeView(tail: game.tail, bodyCount: game.bodyCount, fry: game.fry)
        case .fly: FlyView(tail: game.tail, bodyCount: game.bodyCount, fry: game.fry, shakes: game.shakes, maxDistance: game.maxDistance)
        case .result: ResultView()
        case .records: RecordsView()
        }
    }
}
