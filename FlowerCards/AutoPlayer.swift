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
        case getTipp = 0, touchesBegan, touchesMoved, touchesEnded
    }
    var scene: CardGameScene
//    @objc let nextStepSelector = "nextStep:"
    var timer: Timer = Timer()
    var bestTipp = CardGameScene.Tipps()
    var autoPlayStatus: runStatus = .getTipp
    var replay: Bool
    var indexForReplay: Int = 0
    var stopTimer = false

    init(scene: CardGameScene) {
        self.scene = scene
        self.replay = false
        self.stopTimer = false
    }
    
    func startPlay(replay: Bool) {
        self.replay = replay
        scene.replaying = replay
        stopTimer = false
        if self.replay {
            scene.startNewGame(false)
            scene.durationMultiplier = scene.durationMultiplierForAutoplayer
            indexForReplay = 0
        }
        scene.isUserInteractionEnabled = false
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
    }
    
    
    @objc func nextStep(timerX: Timer) {
        if scene.cardCount > 0 /*&& scene.tippArray.count > 0*/ {
            switch autoPlayStatus {
            case .getTipp:
                if scene.tippsButton!.alpha == 1 && scene.countMovingCards == 0 {  // if tipps are ready
                    bestTipp = CardGameScene.Tipps()
                    if replay {
                        if indexForReplay < realm.objects(HistoryModel.self).filter("gameID = %d", scene.actGame!.ID).count {
                            let historyRecord = realm.objects(HistoryModel.self).filter("gameID = %d", scene.actGame!.ID)[indexForReplay]
                            indexForReplay += 1
                            bestTipp.points.append(CGPoint(x: historyRecord.points[0].x, y: historyRecord.points[0].y))
                            bestTipp.points.append(CGPoint(x: historyRecord.points[1].x, y: historyRecord.points[1].y))
                        } else {
                            stopAutoplay()
                        }
                    } else {
                        for tipp in scene.tippArray {
                            if bestTipp.value < tipp.value {
                                bestTipp = tipp
                            }
                        }
                    }
                    if bestTipp.points.count > 0 {
                        autoPlayStatus = .touchesBegan
                    } else {
                        stopAutoplay()
                    }
                    
                }
            case .touchesBegan:
                scene.myTouchesBegan(touchLocation: bestTipp.points[0])
                autoPlayStatus = .touchesMoved
            case .touchesMoved:
                scene.myTouchesMoved(touchLocation: bestTipp.points[1])
                autoPlayStatus = .touchesEnded
            case .touchesEnded:
                scene.myTouchesEnded(touchLocation: bestTipp.points[1])
                if MySKCard.cardCount == 126 {
                    stopAutoplay()
                }
                autoPlayStatus = .getTipp
            }
            if stopTimer {
                timer.invalidate()
            } else {
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
            }
        } else {
            stopAutoplay()
        }
    }
    
    func stopAutoplay() {
        scene.isUserInteractionEnabled = true
        scene.autoPlayerActive = false
        scene.replaying = false
        stopTimer = true
        print("timer stopped at indexForReplay: \(indexForReplay)")
    }
    
}
