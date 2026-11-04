import SwiftUI

/// Put the shrimp together: choose from the tails, coats and sauces you own and set the body length.
/// New items are exchanged for points in the shop (ShopView), reached from the end of the item row.
struct MakeView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    @State private var tab: ItemCategory = .tail
    /// The item row opened up into a grid.
    @State private var showAll = false

    var body: some View {
        ZStack {
            Palette.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                StepsBar(current: 0)
                Text("えびをつくる").font(AppFont.display(24 * s)).foregroundStyle(Palette.ink).padding(.top, 4)
                ItemPlate(tail: game.tail, coat: game.coat, sauce: game.sauce, bodyCount: game.bodyCount, focus: tab)
                    // points in the free corner beside the round plate (the top-right is where the sauce bottle goes)
                    .overlay(alignment: .topLeading) { PointsBadge().padding(.top, 6 * s) }
                    .frame(maxHeight: .infinity)
                panel.padding(.bottom, 14 * s)
                Button("衣をつける") { game.go(.batter) }
                    .buttonStyle(GameButtonStyle(wide: true))
            }
            .padding(.horizontal, 18 * s)
            .padding(.top, 8)
            .padding(.bottom, 20 * s)
        }
        .backdrop(.solid(Palette.cream))
    }

    // MARK: - panel

    private var panel: some View {
        VStack(alignment: .leading, spacing: 10 * s) {
            HStack(spacing: 6 * s) {
                CategoryTabs(selection: $tab)
                Spacer(minLength: 4)
                Button {
                    Haptics.light(); Sound.uiTap.play()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showAll.toggle() }
                } label: {
                    Image(systemName: showAll ? "chevron.up" : "square.grid.3x3.fill")
                        .font(.system(size: 11 * s, weight: .bold))
                        .frame(width: 26 * s, height: 22 * s)
                        .background(Capsule().fill(Palette.cream))
                        .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showAll ? "一覧をとじる" : "ぜんぶ見る")
            }
            switch tab {
            case .tail: picker(TailKind.self)
            case .coat: picker(CoatKind.self)
            case .sauce: picker(SauceKind.self)
            }
            HStack(spacing: 10) {
                Text("からだ").font(AppFont.black(13 * s)).frame(width: 52 * s, alignment: .leading)
                HStack(spacing: 14 * s) {
                    stepButton("−", label: "短くする") { game.changeBody(by: -1) }
                        .disabled(game.bodyCount <= Scoring.bodyRange.lowerBound)
                    Text("\(game.bodyCount)").font(AppFont.display(22 * s)).frame(minWidth: 26 * s)
                    stepButton("＋", label: "長くする") { game.changeBody(by: 1) }
                        .disabled(game.bodyCount >= Scoring.bodyRange.upperBound)
                }
            }
            Text("長いほどパン粉がつきやすく距離ものびる。でも空では当たり判定が大きくなる。")
                .font(AppFont.body(11.5 * s))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 14 * s)
        .padding(.vertical, 12 * s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.ink, lineWidth: 3))
    }

    /// The items of a kind the player owns, then the way to the shop: a sideways row, or a grid when opened up.
    @ViewBuilder private func picker<T: Collectible>(_: T.Type) -> some View {
        let owned = T.allCases.filter { game.owns($0) }
        if showAll {
            ScrollView {
                // 5 chips of 40 + 4 gaps of 8 fit the panel's ~236 pt inside width
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(40 * s), spacing: 8 * s), count: 5), spacing: 10 * s) {
                    ForEach(owned) { chip($0, size: 40 * s) }
                    shopChip(size: 40 * s)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
            }
            .frame(maxHeight: 196 * s)
            .id(T.category)
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8 * s) {
                        ForEach(owned) { chip($0, size: 50 * s).id($0.id) }
                        shopChip(size: 50 * s)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)
                }
                .frame(height: 50 * s + 12)
                .onAppear { proxy.scrollTo(game.equipped(T.self).id, anchor: .center) }
            }
            .id(T.category)
        }
    }

    private func chip<T: Collectible>(_ item: T, size: CGFloat) -> some View {
        ItemChip(item: item, size: size, selected: game.equipped(T.self) == item) {
            Haptics.light(); Sound.uiTap.play()
            withAnimation(.easeOut(duration: 0.2)) { game.equip(item) }
        }
    }

    /// The end of the row: opens the shop, lit up when something there is affordable.
    private func shopChip(size: CGFloat) -> some View {
        Button {
            Haptics.light(); Sound.uiTap.play()
            game.openShop(from: .make, tab: tab)
        } label: {
            VStack(spacing: 1) {
                Image(systemName: "bag.fill").font(.system(size: size * 0.3, weight: .bold))
                Text("ショップ").font(AppFont.black(size * 0.18)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: 14).fill(Palette.accent))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink, lineWidth: 2.5))
            .overlay(alignment: .topTrailing) {
                if game.hasAffordableItem {
                    // something can be exchanged right now
                    Circle().fill(Palette.gold).overlay(Circle().stroke(Palette.ink, lineWidth: 1.5))
                        .frame(width: 12 * s, height: 12 * s)
                        .offset(x: 3 * s, y: -3 * s)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("ショップ")
        .accessibilityHint("ポイントでアイテムをこうかんできます")
    }

    private func stepButton(_ text: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.light(); Sound.uiTap.play(); action() }) {
            Text(text).font(AppFont.black(18 * s))
                .frame(width: 34 * s, height: 34 * s)
                .background(Circle().fill(Palette.cream))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 2.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#if DEBUG
#Preview("つくる") { PreviewScreen { MakeView() } }

#Preview("つくる・はじめて") { PreviewScreen(.preview(points: 0, owned: 1)) { MakeView() } }
#endif
