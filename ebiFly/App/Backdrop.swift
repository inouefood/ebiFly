import SwiftUI

/// What fills the space beside the game column on wide screens (iPad, an unfolded iPhone Duo).
/// Each screen publishes its own background with `.backdrop(_:)`, so the column's edges blend into the sides
/// instead of ending at dark bars.
enum Backdrop: Equatable {
    case solid(Color)
    /// vertical gradient, `top` at the top
    case gradient(top: Color, bottom: Color)
    /// the sauce kitchen: wall gradient (`wall` to `wallLow`) down to a counter that starts `edge` (0...1) from the top
    case counter(wall: Color, wallLow: Color, counter: Color, edge: CGFloat)
    /// the panko bowl: flat colour with a dot grid
    case dots(Color, dot: Color)
    /// the kitchen wall behind the pot: flat colour with a tile grid
    case tiles(Color)
}

private struct BackdropKey: PreferenceKey {
    static let defaultValue = Backdrop.solid(Palette.letterbox)
    static func reduce(value: inout Backdrop, nextValue: () -> Backdrop) { value = nextValue() }
}

extension View {
    /// Declares the background to extend beside the game column.
    func backdrop(_ backdrop: Backdrop) -> some View {
        preference(key: BackdropKey.self, value: backdrop)
    }

    /// Draws the backdrop published by the current screen behind this view.
    /// `unit` is the column's design scale (column width / 300) so patterns match the scene's.
    func backdropBackground(unit: CGFloat) -> some View {
        backgroundPreferenceValue(BackdropKey.self) { backdrop in
            BackdropView(backdrop: backdrop, unit: unit).ignoresSafeArea()
        }
    }
}

private struct BackdropView: View {
    let backdrop: Backdrop
    let unit: CGFloat

    var body: some View {
        switch backdrop {
        case .solid(let color):
            color
        case .gradient(let top, let bottom):
            LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
        case .counter(let wall, let wallLow, let counter, let edge):
            GeometryReader { geo in
                VStack(spacing: 0) {
                    LinearGradient(colors: [wall, wallLow], startPoint: .top, endPoint: .bottom)
                        .frame(height: geo.size.height * edge)
                    Palette.ink.frame(height: 4)
                    counter
                }
            }
        case .dots(let color, let dot):
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color))
                let spacing = 14 * unit, r = 1.8 * unit
                var path = Path()
                for y in stride(from: spacing / 2, to: size.height, by: spacing) {
                    for x in stride(from: spacing / 2, to: size.width, by: spacing) {
                        path.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    }
                }
                ctx.fill(path, with: .color(dot))
            }
        case .tiles(let color):
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color))
                let spacing = 36 * unit
                var path = Path()
                for p in stride(from: 0, to: max(size.width, size.height), by: spacing) {
                    path.addRect(CGRect(x: p, y: 0, width: 2, height: size.height))
                    path.addRect(CGRect(x: 0, y: p, width: size.width, height: 2))
                }
                ctx.fill(path, with: .color(.white.opacity(0.07)))
            }
        }
    }
}
