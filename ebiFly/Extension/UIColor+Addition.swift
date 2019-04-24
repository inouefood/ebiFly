//
//  SKColor+Addition.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/04/14.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import UIKit

extension UIColor {
    enum AppColor: String {
        case thema
        case white
        case sky
        case night
        var hex: String {
            switch self {
            case .thema:
                return "#248bff"
            case .white:
                return "#ffffff"
            case .sky:
                return "#66CCFF"
            case .night:
                return "#1D3455"
            }
        }
    }
    convenience init(hex: String, alpha: CGFloat) {
        var rgbHex = hex
        if rgbHex.prefix(1) == "#" {
            rgbHex = rgbHex.replacingOccurrences(of: "#", with: "")
        }
        let v = rgbHex.map { String($0) } + Array(repeating: "0", count: max(6 - hex.count, 0))
        let r = CGFloat(Int(v[0] + v[1], radix: 16) ?? 0)
        let g = CGFloat(Int(v[2] + v[3], radix: 16) ?? 0)
        let b = CGFloat(Int(v[4] + v[5], radix: 16) ?? 0)
        self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: alpha)
    }
    
    convenience init(hex: String) {
        self.init(hex: hex, alpha: 1.0)
    }
    
    convenience init(appColor: AppColor) {
        self.init(hex: appColor.hex, alpha: 1.0)
    }
}
