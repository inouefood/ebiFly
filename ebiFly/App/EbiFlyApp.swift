import SwiftUI

@main
struct EbiFlyApp: App {
    @StateObject private var game = GameModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AppFont.register()
        Sound.configure()
        Sound.preloadAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(game)
                .onAppear { GameCenter.shared.authenticate() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Ads.shared.startIfNeeded() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var game: GameModel

    var body: some View {
        GeometryReader { geo in
            // Keep the HUD readable while the action can use the whole screen.
            let width = GameLayout.columnWidth(in: geo.size)
            let playsFullWidth = game.screen == .title || game.screen == .batter || game.screen == .fly
            ZStack {
                screen
                    .id(game.screen)
                    .transition(.opacity)
                    .frame(width: playsFullWidth ? geo.size.width : width, height: geo.size.height)
                    .environment(\.gameColumnWidth, width)
                    .environment(\.uiScale, min(max(width / 300, 1), 1.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // wide screens: each screen's own background continues beside the column (no dark bars)
            .backdropBackground(unit: width / 300)
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    @ViewBuilder private var screen: some View {
        switch game.screen {
        case .title: TitleView()
        case .make: MakeView()
        case .batter: BatterView(tail: game.tail, bodyCount: game.bodyCount, coat: game.coat)
        case .fry: FryView(tail: game.tail, bodyCount: game.bodyCount, coat: game.coat)
        case .shake: ShakeView(tail: game.tail, bodyCount: game.bodyCount, fry: game.fry, coat: game.coat, sauce: game.sauce)
        case .fly: FlyView(tail: game.tail, bodyCount: game.bodyCount, fry: game.fry, shakes: game.shakes,
                           maxDistance: game.maxDistance, coat: game.coat, sauce: game.sauce)
        case .result: ResultView()
        case .records: RecordsView()
        case .shop: ShopView()
        }
    }
}
