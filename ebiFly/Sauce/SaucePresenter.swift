//
//  SaucePresenter.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/04/27.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation

protocol SaucePresenter {
    func shakeDevice() -> Bool
}

class SaucePresenterImpl: SaucePresenter{
    private var model: SauceModel
    
    init(model: SauceModel) {
        self.model = model
    }
    
    func shakeDevice() -> Bool {
        return model.shakeDevice()
    }
}
