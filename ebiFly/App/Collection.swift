import UIKit

/// What the points can be exchanged for on the make screen. All of it is cosmetic.
enum ItemCategory: String, CaseIterable, Identifiable {
    case tail, coat, sauce

    var id: String { rawValue }
    var label: String {
        switch self {
        case .tail: return "しっぽ"
        case .coat: return "ころも"
        case .sauce: return "ソース"
        }
    }
    /// UserDefaults key of the item in use ("tail" predates the others).
    var selectionKey: String { rawValue }
    /// UserDefaults key of the owned items.
    var ownedKey: String {
        switch self {
        case .tail: return "ownedTails"
        case .coat: return "ownedCoats"
        case .sauce: return "ownedSauces"
        }
    }
}

/// One kind of exchangeable item. Cases are listed cheapest first; the first case is free and the default.
/// Raw values are persisted and name the image assets (Design/art.py, tails.py, extras.py).
protocol Collectible: RawRepresentable, CaseIterable, Identifiable, Hashable
where RawValue == String, AllCases == [Self] {
    static var category: ItemCategory { get }
    var displayName: String { get }
    var price: Int { get }
    /// Images stacked (bottom first) to show the item in a chip.
    var iconLayers: [String] { get }
}

extension Collectible {
    var id: String { rawValue }
    static var free: Self { allCases[0] }

    /// Rewarded ads that get this item instead of points. One ad, but only for items the points could
    /// already pay for (see ShopView): the ad saves the points, it doesn't skip ahead of them.
    var adsNeeded: Int { price == 0 ? 0 : 1 }
    /// Key for this item's ad progress.
    var adKey: String { "\(Self.category.rawValue).\(rawValue)" }
}

extension TailKind: Collectible {
    static var category: ItemCategory { .tail }
    var iconLayers: [String] { [imageName] }
}

/// Batter coats: an overlay painted on each body ball, over the fry colour.
enum CoatKind: String, Collectible {
    case plain, sesame, nori, cheese, curry, matcha, cornflake, sprinkle, charcoal, gold

    static var category: ItemCategory { .coat }

    var displayName: String {
        switch self {
        case .plain: return "ふつう"
        case .sesame: return "ごま"
        case .nori: return "あおのり"
        case .cheese: return "チーズ"
        case .curry: return "カレー"
        case .matcha: return "まっちゃ"
        case .cornflake: return "コーンフレーク"
        case .sprinkle: return "カラフルスプレー"
        case .charcoal: return "たけすみ"
        case .gold: return "きんぱく"
        }
    }

    var price: Int {
        switch self {
        case .plain: return 0
        case .sesame: return 150
        case .nori: return 200
        case .cheese: return 400
        case .curry: return 500
        case .matcha: return 700
        case .cornflake: return 900
        case .sprinkle: return 1200
        case .charcoal: return 1600
        case .gold: return 2500
        }
    }

    /// What falls in the batter step (sesame seeds, nori flakes, ...); the plain coat uses the panko crumb.
    var crumbName: String { self == .plain ? "crumb" : "crumb-\(rawValue)" }
    /// What the batter step calls the falling bits ("パン粉" for the plain coat).
    var crumbLabel: String { self == .plain ? "パン粉" : displayName }

    /// Image drawn over each ball; nil for the plain coat.
    var overlayName: String? { self == .plain ? nil : "coat-\(rawValue)" }
    var iconLayers: [String] { [SegmentSkin.fry(0.5)] + (overlayName.map { [$0] } ?? []) }
}

enum SauceKind: String, Collectible {
    case sauce, mayo, ketchup, tartar, soy, salt, lemon, curry, choco, honey

    static var category: ItemCategory { .sauce }

    var displayName: String {
        switch self {
        case .sauce: return "ソース"
        case .mayo: return "マヨネーズ"
        case .ketchup: return "ケチャップ"
        case .tartar: return "タルタル"
        case .soy: return "しょうゆ"
        case .salt: return "しお"
        case .lemon: return "レモン"
        case .curry: return "カレー"
        case .choco: return "チョコ"
        case .honey: return "はちみつ"
        }
    }

    /// Short name for the flight HUD ("マヨ ぐんぐん").
    var shortName: String {
        switch self {
        case .mayo: return "マヨ"
        case .ketchup: return "ケチャ"
        default: return displayName
        }
    }

    var price: Int {
        switch self {
        case .sauce: return 0
        case .mayo: return 150
        case .ketchup: return 200
        case .soy: return 300
        case .salt: return 400
        case .lemon: return 500
        case .tartar: return 700
        case .curry: return 900
        case .honey: return 1200
        case .choco: return 1600
        }
    }

    var bottleName: String { self == .sauce ? "sauce" : "bottle-\(rawValue)" }
    var dropName: String { self == .sauce ? "sauce-drop" : "drop-\(rawValue)" }
    var fuelName: String { self == .sauce ? "fuel" : "fuel-\(rawValue)" }
    var iconLayers: [String] { [bottleName] }

    /// Hot, then cooler colour for the jet's particles; nil keeps the default fire colours.
    var jetColors: (UIColor, UIColor)? {
        switch self {
        case .sauce: return nil
        case .mayo: return (UIColor(hex: 0xFFF6D8), UIColor(hex: 0xF2D98A))
        case .ketchup: return (UIColor(hex: 0xFF8A70), UIColor(hex: 0xD9312B))
        case .tartar: return (UIColor(hex: 0xF4F1E0), UIColor(hex: 0x9CCB6A))
        case .soy: return (UIColor(hex: 0xC98A5A), UIColor(hex: 0x5A2A14))
        case .salt: return (UIColor(hex: 0xFFFFFF), UIColor(hex: 0xBFE6FF))
        case .lemon: return (UIColor(hex: 0xFFF6A8), UIColor(hex: 0xFFE14D))
        case .curry: return (UIColor(hex: 0xFFD25A), UIColor(hex: 0xC98A1A))
        case .choco: return (UIColor(hex: 0xC98A5A), UIColor(hex: 0x5B3A29))
        case .honey: return (UIColor(hex: 0xFFE27A), UIColor(hex: 0xF5B82E))
        }
    }
}
