import SwiftUI

/// ショップ: every tail, coat and sauce; try one on, then exchange points for it.
/// Opened from the make screen and the result screen; "もどる" goes back to where it was opened from.
/// What's bought is put on right away and can be switched on the make screen.
struct ShopView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    @State private var tab: ItemCategory = .tail
    @State private var trying: ItemTrial?
    @State private var shaking: String?
    @State private var popPlate = false
    @State private var note: String?

    /// What the plate shows: the item being tried on, otherwise what the player has on.
    private func shown<T: Collectible>(_: T.Type) -> T { trying?.item(T.self) ?? game.equipped() }

    var body: some View {
        ZStack {
            Palette.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("ショップ").font(AppFont.display(24 * s))
                    Spacer()
                    PointsBadge(size: 18)
                }
                .foregroundStyle(Palette.ink)
                .padding(.top, 4)
                ItemPlate(tail: shown(TailKind.self), coat: shown(CoatKind.self), sauce: shown(SauceKind.self),
                          bodyCount: game.bodyCount, focus: tab, pop: popPlate)
                    .frame(minHeight: 100 * s, maxHeight: .infinity)
                    .overlay(alignment: .bottom) { tryingLabel }
                panel.padding(.bottom, 14 * s)
                bottomButtons
            }
            .padding(.horizontal, 18 * s)
            .padding(.top, 8)
            .padding(.bottom, 20 * s)

            if let note {
                Toast(text: note)
                    .padding(.horizontal, 40 * s)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .allowsHitTesting(false)
            }
        }
        .backdrop(.solid(Palette.cream))
        .onAppear { tab = game.shopTab }
    }

    @ViewBuilder private var tryingLabel: some View {
        if let t = trying {
            Text("ためしにつけ中：\(t.name)（\(t.price.formatted())pt）")
                .font(AppFont.black(12 * s))
                .lineLimit(1).minimumScaleFactor(0.75)
                .foregroundStyle(.white)
                .padding(.horizontal, 12 * s).padding(.vertical, 3 * s)
                .background(Capsule().fill(Palette.ink.opacity(0.85)))
                .padding(.bottom, 6 * s)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 8 * s) {
            HStack {
                CategoryTabs(selection: $tab) { trying = nil }
                Spacer(minLength: 4)
                Text("\(game.ownedCount(tab))/\(count(tab))")
                    .font(AppFont.black(11 * s)).foregroundStyle(Palette.muted).monospacedDigit()
            }
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6 * s), count: 5), spacing: 10 * s) {
                    switch tab {
                    case .tail: chips(TailKind.self)
                    case .coat: chips(CoatKind.self)
                    case .sauce: chips(SauceKind.self)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            .frame(height: 186 * s)   // three rows, the rest scrolls (fits an iPhone SE)
            Text("とんだきょり10mごとに1pt。こうかんしたアイテムは「つくる」画面でつけかえられます。")
                .font(AppFont.body(11 * s))
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

    private func count(_ c: ItemCategory) -> Int {
        switch c {
        case .tail: return TailKind.allCases.count
        case .coat: return CoatKind.allCases.count
        case .sauce: return SauceKind.allCases.count
        }
    }

    private func chips<T: Collectible>(_: T.Type) -> some View {
        ForEach(T.allCases) { item in
            let key = "\(T.category.rawValue).\(item.rawValue)"
            ItemChip(item: item, size: 46 * s, selected: shown(T.self) == item, inShop: true, shaking: shaking == key) {
                tap(item, key: key)
            }
        }
    }

    // MARK: - buttons

    @ViewBuilder private var bottomButtons: some View {
        if let t = trying {
            let short = t.price - game.points
            HStack(spacing: 10 * s) {
                Button("やめる") {
                    Haptics.light()
                    withAnimation(.easeOut(duration: 0.2)) { trying = nil }
                }
                .buttonStyle(GameButtonStyle(kind: .ghost, wide: true, size: 16))
                // same width as "やめる" on purpose: spending points can't be undone, so it isn't pushed harder
                // than backing out (the price is on the plate, which keeps this label short enough to fit)
                Button { exchange(t) } label: {
                    Text(short > 0 ? "あと\(short.formatted())pt" : "こうかん")
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                .buttonStyle(GameButtonStyle(wide: true, size: 16))
                .disabled(short > 0)
            }
        } else {
            Button("もどる") { game.go(game.shopReturn) }
                .buttonStyle(GameButtonStyle(wide: true))
        }
    }

    private func tap<T: Collectible>(_ item: T, key: String) {
        Haptics.light(); Sound.uiTap.play()
        let owned = game.owns(item)
        withAnimation(.easeOut(duration: 0.2)) {
            if owned {
                // already owned: just put it on
                trying = nil
                game.equip(item)
            } else {
                trying = ItemTrial(item)
            }
        }
        if !owned, game.points < item.price {
            withAnimation(.default) { shaking = key }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shaking = nil }
        }
    }

    private func exchange(_ t: ItemTrial) {
        func buy<T: Collectible>(_: T.Type) -> Bool { t.item(T.self).map { game.exchange($0) } ?? false }
        var done = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            switch t.category {
            case .tail: done = buy(TailKind.self)
            case .coat: done = buy(CoatKind.self)
            case .sauce: done = buy(SauceKind.self)
            }
            guard done else { return }
            trying = nil
            popPlate = true
        }
        guard done else { return }
        Haptics.success()
        Sound.stepClear.play()
        show("「\(t.name)」をゲット！")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { popPlate = false }
        }
    }

    private func show(_ text: String) {
        withAnimation(.easeOut(duration: 0.15)) { note = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            if note == text { withAnimation(.easeIn(duration: 0.2)) { note = nil } }
        }
    }
}

#if DEBUG
#Preview("ショップ") { PreviewScreen { ShopView() } }
#endif
