//
//  CharactorMakeModel.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/05/11.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation

protocol CharactorMakeModel {
    func changeEbiTale(count: Int) -> Int
}

class CharactorMakeModelImpl:CharactorMakeModel {
    private var taleImageCount = 1
    func changeEbiTale(count: Int) -> Int{
        taleImageCount += count
        if taleImageCount == 4 {
            taleImageCount = 1
        }
        if taleImageCount == 0 {
            taleImageCount = 3
        }
        return taleImageCount
    }
}
