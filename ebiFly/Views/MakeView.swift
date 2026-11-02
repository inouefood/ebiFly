import SwiftUI

struct MakeView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s
    @State private var shakeTail: TailKind?

    var body: some View {
        ZStack {
            Palette.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                StepsBar(current: 0)
                Text("えびをつくる").font(AppFont.display(24 * s)).foregroundStyle(Palette.ink).padding(.top, 4)
                plate.frame(maxHeight: .infinity)
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

    private var plate: some View {
        ZStack {
            Circle().fill(Color.white)
                .overlay(Circle().inset(by: 9 * s).stroke(Color(hex: 0xEAF3FB), lineWidth: 14 * s))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 4))
                .frame(width: 210 * s, height: 210 * s)
            ShrimpView(tail: game.tail, count: game.bodyCount, skin: SegmentSkin.batter(0), unit: 0.62 * s)
                .rotationEffect(.degrees(-20))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: game.bodyCount)
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 12 * s) {
            HStack(spacing: 10) {
                Text("しっぽ").font(AppFont.black(13 * s)).frame(width: 52 * s, alignment: .leading)
                HStack(spacing: 8 * s) {
                    ForEach(TailKind.allCases) { t in tailChip(t) }
                }
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

    private func tailChip(_ t: TailKind) -> some View {
        let locked = !game.isUnlocked(t)
        let selected = game.tail == t
        return Button {
            if locked {
                Haptics.light()
                withAnimation(.default) { shakeTail = t }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shakeTail = nil }
            } else {
                Haptics.light()
                game.select(tail: t)
            }
        } label: {
            ZStack(alignment: .bottom) {
                Image(t.imageName).resizable().frame(width: 34 * s, height: 34 * s)
                    .grayscale(locked ? 1 : 0)
                    .opacity(locked ? 0.3 : 1)
                    .frame(width: 50 * s, height: 50 * s)
                if locked {
                    Text("\(t.unlockDistance.formatted())m")
                        .font(AppFont.black(9 * s)).foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Palette.ink))
                        .offset(y: 7)
                }
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(selected ? Color(hex: 0xFFE7DF) : Palette.paper))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Palette.accent : Palette.line, lineWidth: selected ? 3.5 : 2.5))
            .offset(x: shakeTail == t ? 4 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t.displayName + (locked ? "（\(t.unlockDistance.formatted())mで解放）" : ""))
        .accessibilityAddTraits(selected ? .isSelected : [])
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
