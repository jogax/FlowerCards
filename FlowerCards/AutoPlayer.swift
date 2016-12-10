//
//  AutoPlayer.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 24/11/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import SpriteKit

class AutoPlayer {
    enum runStatus: Int {
        case getTipp = 0, touchesMoved, touchesEnded
    }
    var scene: CardGameScene
//    @objc let nextStepSelector = "nextStep:"
    var timer: Timer = Timer()
    var bestTipp = CardGameScene.Tipps()
    var autoPlayStatus: runStatus = .getTipp
    

    init(scene: CardGameScene) {
        self.scene = scene
    }
    
    func startPlay() {
        scene.isUserInteractionEnabled = false
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
    }
    
    
    @objc func nextStep(timerX: Timer) {
        if scene.cardCount > 0 /*&& scene.tippArray.count > 0*/ {
            switch autoPlayStatus {
            case .getTipp:
                if scene.tippsButton!.alpha == 1 {  // if tipps are ready
                    bestTipp = CardGameScene.Tipps()
                    for tipp in scene.tippArray {
                        if bestTipp.value < tipp.value {
                            bestTipp = tipp
                        }
                    }
                    scene.myTouchesBegan(touchLocation: bestTipp.points[0])
                    autoPlayStatus = .touchesMoved
//                    timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
               } else {
//                    timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
                }
            case .touchesMoved:
                scene.myTouchesMoved(touchLocation: bestTipp.points[1])
                autoPlayStatus = .touchesEnded
//                timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
            case .touchesEnded:
                scene.myTouchesEnded(touchLocation: bestTipp.points[1])
                autoPlayStatus = .getTipp
//                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
            }
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
        } else {
            scene.isUserInteractionEnabled = true
            timer.invalidate()
        }
    }
    
}
