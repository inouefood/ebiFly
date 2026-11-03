import SwiftUI

struct MakeView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    @State private var tab: ItemCategory = .tail
    /// Something the player doesn't own yet, tried on before exchanging points for it.
    @State private var trying: Trial?
    /// The item row opened up into a grid of every item.
    @State private var showAll = false
    @State private var shaking: String?
    @State private var popPlate = false
    @State private var note: String?

    private struct Trial: Equatable {
        let category: ItemCategory
        let raw: String
        let name: String
        let price: Int

        init<T: Collectible>(_ item: T) {
            category = T.category
            raw = item.rawValue
            name = item.displayName
            price = item.price
        }
    }

    /// What the plate shows: the item being tried on, otherwise what the player has on.
    private func shown<T: Collectible>(_: T.Type) -> T {
        if let trying, trying.category == T.category, let item = T(rawValue: trying.raw) { return item }
        return game.equipped()
    }

    var body: some View {
        ZStack {
            Palette.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                StepsBar(current: 0)
                Text("えびをつくる").font(AppFont.display(24 * s)).foregroundStyle(Palette.ink).padding(.top, 4)
                plate.frame(maxHeight: .infinity)
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
    }

    // MARK: - plate

    /// Shrinks to fit when the item grid is open.
    private var plate: some View {
        GeometryReader { geo in
            plateArt
                .scaleEffect(min(1, geo.size.height / (226 * s)))
                .frame(width: geo.size.width, height: geo.size.height)
        }
        // points in the free corner beside the round plate (the panel's tab row has no room for them;
        // the top-right is where the sauce bottle goes)
        .overlay(alignment: .topLeading) { pointsBadge.padding(.top, 6 * s) }
        .overlay(alignment: .bottom) {
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
    }

    private var plateArt: some View {
        // the tail tab shows the shrimp as it is now (raw); coats and sauces show it fried, so they can be seen
        let fried = tab != .tail
        let sauce = shown(SauceKind.self)
        return ZStack {
            Circle().fill(Color.white)
                .overlay(Circle().inset(by: 9 * s).stroke(Color(hex: 0xEAF3FB), lineWidth: 14 * s))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 4))
                .frame(width: 210 * s, height: 210 * s)
            ShrimpView(tail: shown(TailKind.self), count: game.bodyCount,
                       skin: fried ? SegmentSkin.fry(0.5) : SegmentSkin.batter(0), unit: 0.62 * s,
                       coat: fried ? shown(CoatKind.self).overlayName : nil)
                .rotationEffect(.degrees(-20))
                .scaleEffect(popPlate ? 1.12 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: game.bodyCount)
            if tab == .sauce {
                // a few drops on the shrimp and the bottle tipped over it
                ForEach(0..<3, id: \.self) { i in
                    Image(sauce.dropName).resizable().scaledToFit()
                        .frame(width: 16 * s)
                        .offset(x: [-14, 6, 20][i] * s, y: [-30, -4, 22][i] * s)
                }
                Image(sauce.bottleName).resizable().scaledToFit()
                    .frame(height: 104 * s)
                    .rotationEffect(.degrees(150))
                    .offset(x: 78 * s, y: -66 * s)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tab)
    }

    // MARK: - panel

    private var panel: some View {
        VStack(alignment: .leading, spacing: 10 * s) {
            HStack(spacing: 6 * s) {
                tabs
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

    private var tabs: some View {
        HStack(spacing: 4 * s) {
            ForEach(ItemCategory.allCases) { c in
                let on = tab == c
                Button {
                    guard !on else { return }
                    Haptics.light(); Sound.uiTap.play()
                    withAnimation(.easeOut(duration: 0.2)) {
                        tab = c
                        trying = nil
                    }
                } label: {
                    Text(c.label)
                        .font(AppFont.black(12 * s))
                        .lineLimit(1).fixedSize()
                        .foregroundStyle(on ? .white : Palette.ink)
                        .padding(.horizontal, 8 * s).padding(.vertical, 3 * s)
                        .background(Capsule().fill(on ? Palette.ink : Palette.cream))
                        .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(c.label) \(game.ownedCount(c))しゅるい もっている")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    private var pointsBadge: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(game.points.formatted()).font(AppFont.display(14 * s)).monospacedDigit()
                .contentTransition(.numericText())
            Text("pt").font(AppFont.black(10 * s))
        }
        .lineLimit(1).fixedSize()
        .padding(.horizontal, 8 * s).padding(.vertical, 1)
        .background(Capsule().fill(Palette.gold))
        .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("もってるポイント \(game.points)")
    }

    /// Every item of a kind, cheapest first: a sideways row normally, a grid when opened up.
    @ViewBuilder private func picker<T: Collectible>(_: T.Type) -> some View {
        if showAll {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6 * s), count: 5), spacing: 8 * s) {
                    ForEach(T.allCases) { chip($0, size: 46 * s) }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
            }
            .frame(maxHeight: 196 * s)
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8 * s) {
                        ForEach(T.allCases) { chip($0, size: 50 * s).id($0.rawValue) }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)
                }
                .frame(height: 50 * s + 12)
                .onAppear { proxy.scrollTo(shown(T.self).rawValue, anchor: .center) }
            }
        }
    }

    private func chip<T: Collectible>(_ item: T, size: CGFloat) -> some View {
        let owned = game.owns(item)
        let selected = shown(T.self) == item
        let affordable = game.points >= item.price
        let key = "\(T.category.rawValue).\(item.rawValue)"
        return Button { tap(item) } label: {
            ZStack {
                ForEach(item.iconLayers, id: \.self) { Image($0).resizable().scaledToFit() }
            }
            .frame(width: size * 0.68, height: size * 0.68)
            .grayscale(owned ? 0 : 0.7)
            .opacity(owned || selected ? 1 : affordable ? 0.75 : 0.4)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: 14).fill(selected ? Color(hex: 0xFFE7DF) : Palette.paper))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                selected ? Palette.accent : Palette.line,
                style: StrokeStyle(lineWidth: selected ? 3.5 : 2.5, dash: selected && !owned ? [6, 4] : [])))
            .overlay(alignment: .bottom) {
                if !owned {
                    Text("\(item.price.formatted())pt")
                        .font(AppFont.black(8.5 * s)).monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(affordable ? Palette.green : Palette.ink))
                        .offset(y: 6)
                }
            }
            .offset(x: shaking == key ? 4 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.displayName)
        .accessibilityValue(owned ? (game.equipped(T.self) == item ? "つけている" : "もっている") : "\(item.price)ポイント")
        .accessibilityAddTraits(selected ? .isSelected : [])
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
                // than backing out (the price is shown on the plate, which keeps this label short enough to fit)
                Button { exchange(t) } label: {
                    Text(short > 0 ? "あと\(short.formatted())pt" : "こうかん")
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                .buttonStyle(GameButtonStyle(wide: true, size: 16))
                    .disabled(short > 0)
            }
        } else {
            Button("衣をつける") { game.go(.batter) }
                .buttonStyle(GameButtonStyle(wide: true))
        }
    }

    private func tap<T: Collectible>(_ item: T) {
        Haptics.light(); Sound.uiTap.play()
        let owned = game.owns(item)
        withAnimation(.easeOut(duration: 0.2)) {
            if owned {
                trying = nil
                game.equip(item)
            } else {
                trying = Trial(item)
            }
        }
        if !owned, game.points < item.price {
            let key = "\(T.category.rawValue).\(item.rawValue)"
            withAnimation(.default) { shaking = key }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shaking = nil }
        }
    }

    private func exchange(_ t: Trial) {
        func buy<T: Collectible>(_: T.Type) -> Bool { T(rawValue: t.raw).map { game.exchange($0) } ?? false }
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
