import SwiftUI

struct MakeView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    /// A tail the player doesn't own yet, tried on the plate before exchanging points for it.
    @State private var trying: TailKind?
    /// The tail row opened up into a grid of every tail.
    @State private var showAll = false
    @State private var shakeTail: TailKind?
    @State private var popPlate = false
    @State private var note: String?

    private var shownTail: TailKind { trying ?? game.tail }

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

    /// Shrinks to fit when the tail grid is open.
    private var plate: some View {
        GeometryReader { geo in
            plateArt
                .scaleEffect(min(1, geo.size.height / (226 * s)))
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .overlay(alignment: .bottom) {
            if let t = trying {
                Text("ためしにつけ中：\(t.displayName)")
                    .font(AppFont.black(12 * s))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12 * s).padding(.vertical, 3 * s)
                    .background(Capsule().fill(Palette.ink.opacity(0.85)))
                    .padding(.bottom, 6 * s)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var plateArt: some View {
        ZStack {
            Circle().fill(Color.white)
                .overlay(Circle().inset(by: 9 * s).stroke(Color(hex: 0xEAF3FB), lineWidth: 14 * s))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 4))
                .frame(width: 210 * s, height: 210 * s)
            ShrimpView(tail: shownTail, count: game.bodyCount, skin: SegmentSkin.batter(0), unit: 0.62 * s)
                .rotationEffect(.degrees(-20))
                .scaleEffect(popPlate ? 1.12 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: game.bodyCount)
        }
    }

    // MARK: - panel

    private var panel: some View {
        VStack(alignment: .leading, spacing: 10 * s) {
            HStack(spacing: 6 * s) {
                Text("しっぽ").font(AppFont.black(13 * s))
                Text("\(game.ownedTails.count)/\(TailKind.allCases.count)")
                    .font(AppFont.black(11 * s)).foregroundStyle(Palette.muted).monospacedDigit()
                Spacer(minLength: 4)
                pointsBadge
                Button {
                    Haptics.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showAll.toggle() }
                } label: {
                    HStack(spacing: 2) {
                        Text(showAll ? "とじる" : "ぜんぶ")
                        Image(systemName: showAll ? "chevron.up" : "chevron.down")
                    }
                    .font(AppFont.black(11 * s))
                    .padding(.horizontal, 8 * s).padding(.vertical, 3 * s)
                    .background(Capsule().fill(Palette.cream))
                    .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showAll ? "しっぽの一覧をとじる" : "しっぽをぜんぶ見る")
            }
            tailPicker
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

    private var pointsBadge: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(game.points.formatted()).font(AppFont.display(14 * s)).monospacedDigit()
                .contentTransition(.numericText())
            Text("pt").font(AppFont.black(10 * s))
        }
        .padding(.horizontal, 8 * s).padding(.vertical, 1)
        .background(Capsule().fill(Palette.gold))
        .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("もってるポイント \(game.points)")
    }

    /// Every tail, cheapest first: a sideways row normally, a grid when opened up.
    @ViewBuilder private var tailPicker: some View {
        if showAll {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6 * s), count: 5), spacing: 8 * s) {
                    ForEach(TailKind.allCases) { tailChip($0, size: 46 * s) }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
            }
            .frame(maxHeight: 196 * s)
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8 * s) {
                        ForEach(TailKind.allCases) { tailChip($0, size: 50 * s).id($0) }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)
                }
                .frame(height: 50 * s + 12)
                .onAppear { proxy.scrollTo(shownTail, anchor: .center) }
            }
        }
    }

    private func tailChip(_ t: TailKind, size: CGFloat) -> some View {
        let owned = game.isUnlocked(t)
        let selected = shownTail == t
        let affordable = game.points >= t.price
        return Button { tap(t) } label: {
            Image(t.imageName).resizable().frame(width: size * 0.68, height: size * 0.68)
                .grayscale(owned ? 0 : 0.7)
                .opacity(owned || selected ? 1 : affordable ? 0.75 : 0.4)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: 14).fill(selected ? Color(hex: 0xFFE7DF) : Palette.paper))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                    selected ? Palette.accent : Palette.line,
                    style: StrokeStyle(lineWidth: selected ? 3.5 : 2.5, dash: selected && !owned ? [6, 4] : [])))
                .overlay(alignment: .bottom) {
                    if !owned {
                        Text("\(t.price.formatted())pt")
                            .font(AppFont.black(8.5 * s)).monospacedDigit()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(affordable ? Palette.green : Palette.ink))
                            .offset(y: 6)
                    }
                }
                .offset(x: shakeTail == t ? 4 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t.displayName)
        .accessibilityValue(owned ? (game.tail == t ? "つけている" : "もっている") : "\(t.price)ポイント")
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
                .buttonStyle(GameButtonStyle(kind: .ghost, size: 16))
                Button(short > 0 ? "あと \(short.formatted())pt" : "\(t.price.formatted())pt でこうかん") { exchange(t) }
                    .buttonStyle(GameButtonStyle(wide: true, size: 16))
                    .disabled(short > 0)
            }
        } else {
            Button("衣をつける") { game.go(.batter) }
                .buttonStyle(GameButtonStyle(wide: true))
        }
    }

    private func tap(_ t: TailKind) {
        Haptics.light()
        withAnimation(.easeOut(duration: 0.2)) {
            if game.isUnlocked(t) {
                trying = nil
                game.select(tail: t)
            } else {
                trying = t
            }
        }
        if !game.isUnlocked(t), game.points < t.price {
            withAnimation(.default) { shakeTail = t }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shakeTail = nil }
        }
    }

    private func exchange(_ t: TailKind) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            guard game.exchange(t) else { return }
            trying = nil
            popPlate = true
        }
        Haptics.success()
        show("「\(t.displayName)」をゲット！")
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
        Button(action: { Haptics.light(); action() }) {
            Text(text).font(AppFont.black(18 * s))
                .frame(width: 34 * s, height: 34 * s)
                .background(Circle().fill(Palette.cream))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 2.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
