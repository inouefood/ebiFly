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
    private var taleCollectionCount = 1
    func changeEbiTale(count: Int) -> Int{
        taleCollectionCount += count
        if taleCollectionCount == 4 {
            taleCollectionCount = 1
        }
        if taleCollectionCount == 0 {
            taleCollectionCount = 3
        }
        return taleCollectionCount
    }
}
