import SwiftUI

// Pieces shared by the make screen (put on what you own) and the shop (exchange points for more).

/// An item picked in the shop to try on before exchanging points for it.
struct ItemTrial: Equatable {
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

    func item<T: Collectible>(_: T.Type) -> T? { category == T.category ? T(rawValue: raw) : nil }
}

/// The shrimp on its plate, dressed in the given items. Shrinks to fit the height it gets.
/// `focus` decides what's shown: the tail tab shows it raw, the coat and sauce tabs fried (so the coat
/// shows), the sauce tab adds the bottle and a few drops.
struct ItemPlate: View {
    let tail: TailKind
    let coat: CoatKind
    let sauce: SauceKind
    let bodyCount: Int
    let focus: ItemCategory
    var pop = false
    @Environment(\.uiScale) private var s

    var body: some View {
        GeometryReader { geo in
            art
                .scaleEffect(min(1, geo.size.height / (226 * s)))
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var art: some View {
        let fried = focus != .tail
        return ZStack {
            Circle().fill(Color.white)
                .overlay(Circle().inset(by: 9 * s).stroke(Color(hex: 0xEAF3FB), lineWidth: 14 * s))
                .overlay(Circle().stroke(Palette.ink, lineWidth: 4))
                .frame(width: 210 * s, height: 210 * s)
            ShrimpView(tail: tail, count: bodyCount,
                       skin: fried ? SegmentSkin.fry(0.5) : SegmentSkin.batter(0), unit: 0.62 * s,
                       coat: fried ? coat.overlayName : nil)
                .rotationEffect(.degrees(-20))
                .scaleEffect(pop ? 1.12 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bodyCount)
            if focus == .sauce {
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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focus)
    }
}

/// しっぽ | ころも | ソース
struct CategoryTabs: View {
    @Binding var selection: ItemCategory
    var onChange: () -> Void = {}
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s

    var body: some View {
        HStack(spacing: 4 * s) {
            ForEach(ItemCategory.allCases) { c in
                let on = selection == c
                Button {
                    guard !on else { return }
                    Haptics.light(); Sound.uiTap.play()
                    withAnimation(.easeOut(duration: 0.2)) {
                        selection = c
                        onChange()
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
}

struct PointsBadge: View {
    var size: CGFloat = 14
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(game.points.formatted()).font(AppFont.display(size * s)).monospacedDigit()
                .contentTransition(.numericText())
            Text("pt").font(AppFont.black(size * 0.72 * s))
        }
        .lineLimit(1).fixedSize()
        .padding(.horizontal, 8 * s).padding(.vertical, 1)
        .background(Capsule().fill(Palette.gold))
        .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("もってるポイント \(game.points)")
    }
}

/// One item in a picker. In the shop, items not owned carry their price; owned ones a check mark.
struct ItemChip<T: Collectible>: View {
    let item: T
    let size: CGFloat
    let selected: Bool
    var inShop = false
    var shaking = false
    let action: () -> Void
    @EnvironmentObject private var game: GameModel
    @Environment(\.uiScale) private var s

    var body: some View {
        let owned = game.owns(item)
        let affordable = game.points >= item.price
        Button(action: action) {
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
                if inShop && !owned {
                    Text("\(item.price.formatted())pt")
                        .font(AppFont.black(8.5 * s)).monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(affordable ? Palette.green : Palette.ink))
                        .offset(y: 6)
                }
            }
            .overlay(alignment: .topTrailing) {
                if inShop && owned {
                    Image(systemName: "checkmark")
                        .font(.system(size: 7 * s, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 14 * s, height: 14 * s)
                        .background(Circle().fill(Palette.green))
                        .overlay(Circle().stroke(Palette.ink, lineWidth: 1.2))
                        .offset(x: 4 * s, y: -4 * s)
                }
            }
            .offset(x: shaking ? 4 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.displayName)
        .accessibilityValue(owned ? (game.equipped(T.self) == item ? "つけている" : "もっている") : "\(item.price)ポイント")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
