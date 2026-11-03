import SwiftUI

struct RecordsView: View {
    @EnvironmentObject private var game: GameModel
    @ObservedObject private var gameCenter = GameCenter.shared
    @Environment(\.uiScale) private var s

    var body: some View {
        ZStack {
            Palette.cream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12 * s) {
                    Text("きろく").font(AppFont.display(24 * s))
                    card("ベスト") {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            OutlinedText(text: game.best.formatted(), font: AppFont.display(40 * s), fill: Palette.accent, width: 2.5)
                            OutlinedText(text: "m", font: AppFont.display(20 * s), fill: Palette.accent, width: 2)
                        }
                        Text(Scoring.rank(for: game.best))
                            .font(AppFont.display(14 * s)).foregroundStyle(Palette.gold)
                            .padding(.horizontal, 12).padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Palette.ink))
                    }
                    card("さいきん") {
                        if game.history.isEmpty {
                            Text("まだきろくがありません。あそんでみよう。")
                                .font(AppFont.body(13 * s)).foregroundStyle(Palette.muted)
                        } else {
                            ForEach(Array(game.history.prefix(5).enumerated()), id: \.element.id) { i, r in
                                HStack {
                                    Text("\(i + 1)").font(AppFont.black(13 * s)).frame(width: 20, alignment: .leading)
                                    Text(Scoring.rank(for: r.distance)).font(AppFont.body(13 * s))
                                    Text(r.date.formatted(.dateTime.month().day())).font(AppFont.body(11 * s)).foregroundStyle(Palette.muted)
                                    Spacer()
                                    Text("\(r.distance.formatted())m").font(AppFont.display(14 * s)).monospacedDigit()
                                }
                                if i < min(game.history.count, 5) - 1 {
                                    Divider().overlay(Palette.line)
                                }
                            }
                        }
                    }
                    card("コレクション") {
                        collection(TailKind.self)
                        collection(CoatKind.self)
                        collection(SauceKind.self)
                        Text("ショップでポイントとこうかんできます（「つくる」画面や結果画面から）。")
                            .font(AppFont.body(11 * s)).foregroundStyle(Palette.muted)
                            .padding(.top, 4)
                    }
                    Button("ランキングを見る") { gameCenter.showLeaderboard() }
                        .buttonStyle(GameButtonStyle(kind: .ghost, wide: true, size: 16))
                        .padding(.top, 4)
                }
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 18 * s)
                .padding(.top, 12 * s)
                .padding(.bottom, 12)
            }
            .safeAreaInset(edge: .bottom) {
                Button("もどる") { game.go(.title) }
                    .buttonStyle(GameButtonStyle(wide: true))
                    .padding(.horizontal, 18 * s)
                    .padding(.vertical, 12 * s)
                    .background(Palette.cream)
            }
        }
        .backdrop(.solid(Palette.cream))
    }

    private func collection<T: Collectible>(_: T.Type) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(T.category.label)  \(game.ownedCount(T.category))/\(T.allCases.count)")
                .font(AppFont.black(11 * s)).foregroundStyle(Palette.muted)
                .padding(.top, 4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6 * s), count: 5), spacing: 6 * s) {
                ForEach(T.allCases) { item in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Palette.paper)
                        RoundedRectangle(cornerRadius: 10).stroke(Palette.line, lineWidth: 2)
                        if game.owns(item) {
                            ZStack {
                                ForEach(item.iconLayers, id: \.self) { Image($0).resizable().scaledToFit() }
                            }
                            .padding(6 * s)
                        } else {
                            Text("?").font(AppFont.display(16 * s)).foregroundStyle(Palette.line)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .accessibilityLabel(game.owns(item) ? item.displayName : "まだもっていない")
                }
            }
        }
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(AppFont.black(12 * s)).tracking(1.2).foregroundStyle(Palette.muted)
            content()
        }
        .padding(.horizontal, 14 * s)
        .padding(.vertical, 10 * s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.ink, lineWidth: 3))
    }
}
