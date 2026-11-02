import SwiftUI

struct ResultView: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s

    var body: some View {
        ZStack {
            Palette.resultBg.ignoresSafeArea()
            RadialGradient(colors: [Color(hex: 0xFFF7D6), Color(hex: 0xFFF7D6, alpha: 0)], center: UnitPoint(x: 0.5, y: 0.28),
                           startRadius: 100 * s, endRadius: 125 * s)
                .ignoresSafeArea()
            if let r = game.lastResult {
                content(r)
            }
        }
    }

    private func content(_ r: FlightResult) -> some View {
        VStack(spacing: 0) {
            Text("とんだきょり").font(AppFont.black(12 * s)).tracking(1.5).foregroundStyle(Palette.muted)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                OutlinedText(text: r.distance.formatted(), font: AppFont.display(56 * s), fill: Palette.accent, width: 2.5)
                OutlinedText(text: "m", font: AppFont.display(24 * s), fill: Palette.accent, width: 2)
            }
            Text(Scoring.rank(for: r.distance))
                .font(AppFont.display(17 * s))
                .foregroundStyle(Palette.gold)
                .padding(.horizontal, 14).padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 10).fill(Palette.ink))
                .padding(.top, 6)
            if r.isNewBest {
                Text("ベスト更新")
                    .font(AppFont.black(11 * s)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 1)
                    .background(Capsule().fill(Palette.green))
                    .padding(.top, 6)
            }
            Text(r.hitBy.map { "\($0.displayName)にぶつかった" } ?? "さいごまで とびきった！")
                .font(AppFont.black(13 * s)).foregroundStyle(Palette.ink)
                .padding(.top, 6)

            bento(r).padding(.vertical, 12 * s)

            breakdown(r)

            HStack(spacing: 10 * s) {
                Button("もう一回") { game.startRun() }
                    .buttonStyle(GameButtonStyle(wide: true, size: 15))
                Button("きろく") { game.go(.records) }
                    .buttonStyle(GameButtonStyle(kind: .ghost, wide: true, size: 15))
            }
            .padding(.top, 14 * s)
        }
        .padding(.horizontal, 18 * s)
        .padding(.top, 16 * s)
        .padding(.bottom, 20 * s)
    }

    /// The lunch box with the player's own shrimp in it.
    private func bento(_ r: FlightResult) -> some View {
        let w = 236 * s
        let px = w / 300   // bento artwork is 300 x 210 design units
        return ZStack(alignment: .topLeading) {
            Image("bento").resizable().frame(width: w, height: w * 210 / 300)
            ShrimpView(tail: game.tail, count: game.bodyCount, skin: SegmentSkin.fry(r.fry), unit: 54 / ShrimpGeometry.width * px)
                .rotationEffect(.degrees(-62))
                .position(x: 208 * px, y: 104 * px)
        }
        .frame(width: w, height: w * 210 / 300)
        .accessibilityHidden(true)
    }

    private func breakdown(_ r: FlightResult) -> some View {
        let (label, mult) = Scoring.fryVerdict(r.fry)
        let rows: [(String, String)] = [
            ("パン粉", "\(r.crumbs)こ"),
            ("揚げ加減", "\(label) ×\(mult.formatted())"),
            ("シェイク", "\(r.shakes)回"),
            ("最大距離", "\(r.maxDistance.formatted())m"),
        ]
        return VStack(spacing: 2) {
            ForEach(rows, id: \.0) { row in
                HStack {
                    Text(row.0).font(AppFont.body(12.5 * s))
                    Spacer()
                    Text(row.1).font(AppFont.black(12.5 * s)).monospacedDigit()
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink, lineWidth: 2.5))
    }
}
