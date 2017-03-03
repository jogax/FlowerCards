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
        case getTipp = 0, touchesBegan, touchesMoved, touchesEnded, waitingForNextStep
    }
    enum TestType: Int {
        case newTest = 1, fromTable, fromDB, runOnce, stepByStep
    }
    enum TesterType: Int {
        case beginner = 0, medium, expert
    }
    struct GameToPlay {
        var level: Int
        var gameNumber: Int
        var stopAt: Int
        init(level: Int, gameNumber: Int, stopAt: Int = 0) {
            self.level = level
            self.gameNumber = gameNumber
            self.stopAt = stopAt
        }
    }
    var scene: CardGameScene
//    @objc let nextStepSelector = "nextStep:"
    var timer: Timer = Timer()
    var bestTipp = Tipp()
    var choosedTipp: Tipp.InnerTipp = Tipp.InnerTipp()
    var autoPlayStatus: runStatus = .getTipp
    var replay: Bool
    var indexForReplay: Int = 0
    var stopTimer = false
    var testType: TestType = .runOnce //.test
    var testerType: TesterType = .expert
    var gamesToPlay: [GameToPlay] = [
        GameToPlay(level: 7, gameNumber: 285, stopAt: 72),
//        GameToPlay(level: 40, gameNumber: 5414, stopAt:40),
    ]
    var gameIndex = 0
    
    init(scene: CardGameScene) {
        self.scene = scene
        self.replay = false
        self.stopTimer = false
        #if TEST
            printOldGames()
        #endif
    }
    #if TEST
    func printOldGames () {
        var oldLevelID: Int = -1
        let maxLevelID = GV.levelsForPlay.count()
        var levelID = 0
//        var lostGames: [String] = []
//        var couldNotEndGames: [String] = []
        while levelID < maxLevelID {
            let errorGames = realm.objects(GameModel.self).filter("playerID = %d and gameFinished = false and levelID = %d and ID != %d", GV.player!.ID, levelID, actGame!.ID).sorted(byProperty: "gameNumber")
            for game in errorGames  {
                let countHistoryRecords = realm.objects(HistoryModel.self).filter("gameID = %d", game.ID).count
                if countHistoryRecords == 0 {
                    realm.beginWrite()
                    realm.delete(realm.objects(HistoryModel.self).filter("gameID = %d", game.ID))
                    realm.delete(game)
                    try! realm.commitWrite()                    
                } else {
                    if game.levelID != oldLevelID {
                        oldLevelID = game.levelID
                    }
                    let lineGameToPlay = "GameToPlay(level: \(game.levelID + 1), gameNumber: \(game.gameNumber + 1)), // at Step: \(countHistoryRecords)"
                    print (lineGameToPlay)
                }
            }
            levelID += 1
        }
        let allGamesCount = realm.objects(GameModel.self).filter("playerID = %d", GV.player!.ID).count
        let errorGamesCount = realm.objects(GameModel.self).filter("playerID = %d and gameFinished = false", GV.player!.ID).count
        if allGamesCount > 0 {
            print ("Allgames: \(allGamesCount), Errorgames: \(errorGamesCount), Procent errorgames: \(errorGamesCount * 100 / allGamesCount)")
        }
    }
    #endif
    func startPlay(replay: Bool, testType: TestType = .runOnce) {
        self.replay = replay
        scene.replaying = replay
        stopTimer = false
        self.testType = testType
        if self.replay {
            scene.startNewGame(next: false)
            scene.durationMultiplier = scene.durationMultiplierForAutoplayer
            scene.waitForStartConst = scene.waitForStartForAutoplayer
            indexForReplay = 0
        } else {
            switch testType {
            case .newTest:
                gamesToPlay.removeAll()
                let levelIndex = GV.player!.levelID + 1
                for gameNumber in 1...1000 {
                    gamesToPlay.append(GameToPlay(level: levelIndex, gameNumber: gameNumber))
                }
            case .runOnce:
                gamesToPlay.removeAll()
            case .fromTable:
                break
            case .stepByStep:
                scene.prepareHelpButtonForStepByStep(callBack: makeStep)
            case .fromDB:
                gamesToPlay.removeAll()
                let errorGames = realm.objects(GameModel.self).filter("playerID = %d and gameFinished = false", GV.player!.ID).sorted(byProperty: "levelID")
                for game in errorGames {
                    let countHistoryRecords = realm.objects(HistoryModel.self).filter("gameID = %d", game.ID).count
                    if countHistoryRecords >= 0 {
                        gamesToPlay.append(GameToPlay(level: game.levelID + 1 , gameNumber: game.gameNumber + 1))
                    }
                }
            }
            if self.testType != .runOnce {
                startNextGame()
                scene.durationMultiplier = scene.durationMultiplierForAutoplayer
                scene.waitForStartConst = scene.waitForStartForAutoplayer
            }
        }
        scene.isUserInteractionEnabled = false
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
    }
    
    func makeStep() {
        
        testType = .stepByStep
        autoPlayStatus = .getTipp
        stopTimer = false
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
    }
    
    func startNextGame() {
        if gameIndex < gamesToPlay.count {
            var go = true
            while true {
                let levelIndex = gamesToPlay[gameIndex].level - 1
                let gameNumber = gamesToPlay[gameIndex].gameNumber - 1
                if self.testType == .newTest {
                    if realm.objects(GameModel.self).filter("gameNumber = %d and levelID = %d and playerID = %d", gameNumber, levelIndex, GV.player!.ID).count > 0 {
                        gameIndex += 1
                        if gameIndex == gamesToPlay.count {
                            go = false
                            break
                        }
                    } else {
                        break
                    }
                } else {
                    break
                }
            }
            if go {
                realm.beginWrite()
                GV.player!.levelID = gamesToPlay[gameIndex].level - 1
                try! realm.commitWrite()
                scene.gameNumber = gamesToPlay[gameIndex].gameNumber - 1
                scene.startNewGame(next: false)
                scene.durationMultiplier = scene.durationMultiplierForAutoplayer
                scene.waitForStartConst = scene.waitForStartForAutoplayer
            }
        }
    }
    
    
    @objc func nextStep(timerX: Timer) {
        if scene.cardCount > 0 /*&& scene.tippArray.count > 0*/ {
            switch autoPlayStatus {
            case .getTipp:
                if scene.tippsButton!.alpha == 1 && scene.countMovingCards <= 0 {  // if tipps are ready
                    bestTipp = Tipp()
                    if replay {
//                        if indexForReplay < realm.objects(HistoryModel.self).filter("gameID = %d", actGame!.ID).count {
//                            let historyRecord = realm.objects(HistoryModel.self).filter("gameID = %d", actGame!.ID)[indexForReplay]
//                            indexForReplay += 1
//                            bestTipp.points.append(CGPoint(x: historyRecord.points[0].x, y: historyRecord.points[0].y))
//                            bestTipp.points.append(CGPoint(x: historyRecord.points[1].x, y: historyRecord.points[1].y))
//                        } else {
//                            stopAutoplay()
//                        }
                    } else {
                        switch testerType {
                        case .beginner:
                            for tipp in tippArray {
                                if bestTipp.innerTipps.count == 0 || bestTipp.innerTipps.first!.value < tipp.innerTipps.first!.value {
                                    bestTipp = tipp
                                    choosedTipp = tipp.innerTipps.first!
                                }
                            }
                        case .medium:
                            for tipp in tippArray {
                                
                                if tipp.card2.type != .containerType  { // first check only Cards
                                    if bestTipp.innerTipps.count == 0 || bestTipp.innerTipps.last!.value < tipp.innerTipps.last!.value {
                                        bestTipp = tipp
                                        choosedTipp = tipp.innerTipps.last!
                                    }
                                }
                            }
                            if bestTipp.innerTipps.count == 0 {
                                for tipp in tippArray {
                                    if tipp.card2.type == .containerType  { // first check only Cards
                                        if bestTipp.innerTipps.count == 0 || bestTipp.innerTipps.last!.value < tipp.innerTipps.last!.value {
                                            bestTipp = tipp
                                            choosedTipp = tipp.innerTipps.last!

                                        }
                                    }
                                }
                            }
                            
                        case .expert:
                            for tipp in tippArray {
                                if tipp.card2.type != .containerType  { // first check only Cards
                                    if bestTipp.innerTipps.count == 0 || bestTipp.innerTipps.last!.value < tipp.innerTipps.last!.value {
                                        bestTipp = tipp
                                        choosedTipp = tipp.innerTipps.last!
                                    }
                                }
                            }
                            if bestTipp.innerTipps.count == 0 {
                                for tipp in tippArray {
                                    if tipp.card2.type == .containerType  { // first check only Cards
                                        if bestTipp.innerTipps.count == 0 || bestTipp.innerTipps.last!.value < tipp.innerTipps.last!.value {
                                            bestTipp = tipp
                                            choosedTipp = tipp.innerTipps.last!
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                    if choosedTipp.points.count > 0 {
                        autoPlayStatus = .touchesBegan
                    } else {
                        if gamesToPlay.count == 0 {
                            stopAutoplay()
                        } else {
                            gameIndex += 1
                            if gameIndex < gamesToPlay.count {
                               startNextGame()
                            }
                        }
                    }
                    
                }
            case .touchesBegan:
                scene.myTouchesBegan(touchLocation: choosedTipp.points[0])
                autoPlayStatus = .touchesMoved
            case .touchesMoved:
                scene.myTouchesMoved(touchLocation: choosedTipp.points[1])
                autoPlayStatus = .touchesEnded
            case .touchesEnded:
                scene.myTouchesEnded(touchLocation: choosedTipp.points[1])
                switch testType {
                case .runOnce:
                    break
                case .stepByStep:
                    autoPlayStatus = .waitingForNextStep
                    stopTimer = true
                    timer.invalidate()
                default:
                    if MySKCard.cardCount == gamesToPlay[gameIndex].stopAt {
                        stopAutoplay()
                    }
                }
                autoPlayStatus = .getTipp
            case .waitingForNextStep:
                break
            }
            if stopTimer {
                timer.invalidate()
            } else {
                let interval = autoPlayStatus == .getTipp || autoPlayStatus == .touchesBegan ? 0.01 : 0.0001
                timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
            }
        } else {
                if gamesToPlay.count == 0 {
                    stopAutoplay()
                } else {
                    gameIndex += 1
                    if gameIndex < gamesToPlay.count {
                        startNextGame()
                    } else {
                        stopAutoplay()
                    }
                }
            if !stopTimer {
                timer = Timer.scheduledTimer(timeInterval: 0.15, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
            }
        }
    }
    
    func stopAutoplay() {
        scene.isUserInteractionEnabled = true
        scene.autoPlayerActive = false
        scene.replaying = false
        stopTimer = true
        timer.invalidate()
        print("timer stopped at indexForReplay: \(indexForReplay)")
    }
    
}
