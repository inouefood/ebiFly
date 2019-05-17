//
//  SaucePresenter.swift
//  ebiFly
//
//  Created by 佐川晴海 on 2019/04/27.
//  Copyright © 2019 佐川晴海. All rights reserved.
//

import Foundation

protocol SaucePresenter:class {
    func shakeDevice(shake:@escaping(Bool) -> Void)
    func fallEbifly()
    func fallBackgroundItem()
    func vibrate()
}
protocol SaucePresenterOutput:class {
    func showUpdateEbiflyPos()
    func showUpdateBackgroundItem()
}

class SaucePresenterImpl: SaucePresenter{
    private var model: SauceModel
    private weak var output: SaucePresenterOutput?
    
    init(model: SauceModel, output: SaucePresenterOutput) {
        self.model = model
        self.output = output
    }

    func shakeDevice(shake: @escaping (Bool) -> ()) {
        model.shakeDevice(shaked: {shake($0)})
    }
    func vibrate() {
        model.vibrate()
    }
    func fallEbifly() {
        output?.showUpdateEbiflyPos()
    }
    func fallBackgroundItem() {
        output?.showUpdateBackgroundItem()
    }
}
