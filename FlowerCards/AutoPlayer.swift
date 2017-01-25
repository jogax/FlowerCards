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
    enum TestType: Int {
        case newTest = 1, fromTable, fromDB, runOnce
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
    var bestTipp = Tipps()
    var autoPlayStatus: runStatus = .getTipp
    var replay: Bool
    var indexForReplay: Int = 0
    var stopTimer = false
    var testType: TestType = .runOnce //.test
    var testerType: TesterType = .expert
    var gamesToPlay: [GameToPlay] = [        
        GameToPlay(level: 18, gameNumber: 25), //You have lost ===> now too!!!

        GameToPlay(level: 18, gameNumber: 45), //OK
//        GameToPlay(level: 6, gameNumber: 97), //OK

//        GameToPlay(level: 10, gameNumber: 37),  //OK --> crash!!!
//        GameToPlay(level: 10, gameNumber: 42), //, stopAt: 101),
//        GameToPlay(level: 10, gameNumber: 78), // OK --> crash!!!
//        GameToPlay(level: 10, gameNumber: 86), //OK --> You have Lost
//        GameToPlay(level: 10, gameNumber: 95), //OK --> endlos at 58
//        GameToPlay(level: 14, gameNumber: 5), //OK
//        GameToPlay(level: 14, gameNumber: 8), //OK
//        GameToPlay(level: 14, gameNumber: 11), //OK
//        GameToPlay(level: 14, gameNumber: 12), //OK
//        GameToPlay(level: 14, gameNumber: 13), //OK
//        GameToPlay(level: 14, gameNumber: 14), //OK
//        GameToPlay(level: 14, gameNumber: 15), //OK
//        GameToPlay(level: 14, gameNumber: 17), //OK
//        GameToPlay(level: 14, gameNumber: 18), //OK
//        GameToPlay(level: 14, gameNumber: 19), //OK
//        GameToPlay(level: 14, gameNumber: 22), //OK
//        GameToPlay(level: 14, gameNumber: 24), //OK
//        GameToPlay(level: 14, gameNumber: 26), //OK
//        GameToPlay(level: 14, gameNumber: 27), //OK
//        GameToPlay(level: 14, gameNumber: 30), //OK
//        GameToPlay(level: 14, gameNumber: 31), //OK
//        GameToPlay(level: 14, gameNumber: 35), //OK
//        GameToPlay(level: 14, gameNumber: 38), //OK
//        GameToPlay(level: 14, gameNumber: 40, stopAt: 47), // crash at 48
////        GameToPlay(level: 14, gameNumber: 42),
//        GameToPlay(level: 14, gameNumber: 50),
//        GameToPlay(level: 14, gameNumber: 52),
//        GameToPlay(level: 14, gameNumber: 55),
//        GameToPlay(level: 14, gameNumber: 57),
//        GameToPlay(level: 14, gameNumber: 59),
//        GameToPlay(level: 14, gameNumber: 61),
//        GameToPlay(level: 14, gameNumber: 63),
//        GameToPlay(level: 14, gameNumber: 64),
//        GameToPlay(level: 14, gameNumber: 65),
//        GameToPlay(level: 14, gameNumber: 67),
//        GameToPlay(level: 14, gameNumber: 70),
//        GameToPlay(level: 14, gameNumber: 71),
//        GameToPlay(level: 14, gameNumber: 77),
//        GameToPlay(level: 14, gameNumber: 78),
//        GameToPlay(level: 14, gameNumber: 84),
//        GameToPlay(level: 14, gameNumber: 86),
//        GameToPlay(level: 14, gameNumber: 87),
//        GameToPlay(level: 14, gameNumber: 90),
//        GameToPlay(level: 14, gameNumber: 91),
//        GameToPlay(level: 14, gameNumber: 92),
//        GameToPlay(level: 14, gameNumber: 96),
//        GameToPlay(level: 18, gameNumber: 3),
//        GameToPlay(level: 18, gameNumber: 6),
//        GameToPlay(level: 18, gameNumber: 12),
//        GameToPlay(level: 18, gameNumber: 22),
//        GameToPlay(level: 18, gameNumber: 24),
//        GameToPlay(level: 18, gameNumber: 27),
//        GameToPlay(level: 18, gameNumber: 36),
//        GameToPlay(level: 18, gameNumber: 37),
//        GameToPlay(level: 18, gameNumber: 38),
//        GameToPlay(level: 18, gameNumber: 39),
//        GameToPlay(level: 18, gameNumber: 40),
//        GameToPlay(level: 18, gameNumber: 42),
//        GameToPlay(level: 18, gameNumber: 43),
//        GameToPlay(level: 18, gameNumber: 45),
//        GameToPlay(level: 18, gameNumber: 48),
//        GameToPlay(level: 18, gameNumber: 50),
//        GameToPlay(level: 18, gameNumber: 52),
//        GameToPlay(level: 18, gameNumber: 53),
//        GameToPlay(level: 18, gameNumber: 54),
//        GameToPlay(level: 18, gameNumber: 60),
//        GameToPlay(level: 18, gameNumber: 65),
//        GameToPlay(level: 18, gameNumber: 66),
//        GameToPlay(level: 18, gameNumber: 67),
//        GameToPlay(level: 18, gameNumber: 69),
//        GameToPlay(level: 18, gameNumber: 73),
//        GameToPlay(level: 18, gameNumber: 74),
//        GameToPlay(level: 18, gameNumber: 75),
//        GameToPlay(level: 18, gameNumber: 77),
//        GameToPlay(level: 18, gameNumber: 78),
//        GameToPlay(level: 18, gameNumber: 79),
//        GameToPlay(level: 18, gameNumber: 86),
//        GameToPlay(level: 18, gameNumber: 92),
//        GameToPlay(level: 18, gameNumber: 96),
//        GameToPlay(level: 18, gameNumber: 100),
        ]
    var gameIndex = 0
    
    init(scene: CardGameScene) {
        self.scene = scene
        self.replay = false
        self.stopTimer = false
        printOldGames()
    }
    
    func printOldGames () {
        var oldLevelID: Int = -1
        let errorGames = realm.objects(GameModel.self).filter("playerID = %d and gameFinished = false", GV.player!.ID).sorted(byProperty: "levelID")
        for game in errorGames {
            let countHistoryRecords = realm.objects(HistoryModel.self).filter("gameID = %d", game.ID).count
            if countHistoryRecords > 0 && countHistoryRecords < 105 {
                if game.levelID != oldLevelID {
                    oldLevelID = game.levelID
                }
                let lineGameToPlay = "GameToPlay(level: \(game.levelID + 1), gameNumber: \(game.gameNumber + 1)),"
                print (lineGameToPlay)
            }
        }
    }
    
    func startPlay(replay: Bool, testType: TestType = .runOnce) {
        self.replay = replay
        scene.replaying = replay
        stopTimer = false
        self.testType = testType
        if self.replay {
            scene.startNewGame(false)
            scene.durationMultiplier = scene.durationMultiplierForAutoplayer
            indexForReplay = 0
        } else {
            switch testType {
            case .newTest:
                gamesToPlay.removeAll()
                var levelIndex = 2
                for _ in 0...21 {
                    for gameNumber in 1...100 {
                        gamesToPlay.append(GameToPlay(level: levelIndex, gameNumber: gameNumber))
                    }
                    levelIndex += 4
                }
            case .runOnce:
                gamesToPlay.removeAll()
            case .fromTable:
                break
            case .fromDB:
                gamesToPlay.removeAll()
                let errorGames = realm.objects(GameModel.self).filter("playerID = %d and gameFinished = false", GV.player!.ID)
                for game in errorGames {
                    let countHistoryRecords = realm.objects(HistoryModel.self).filter("gameID = %d", game.ID).count
                    if countHistoryRecords >= 0 && countHistoryRecords < 105 {
                        gamesToPlay.append(GameToPlay(level: game.levelID + 1 , gameNumber: game.gameNumber + 1))
                    }
                }
            }
            if self.testType != .runOnce {
                startNextGame()
                scene.durationMultiplier = scene.durationMultiplierForAutoplayer
            }
        }
        scene.isUserInteractionEnabled = false
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
    }
    
    func startNextGame() {
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
            scene.startNewGame(false)
            scene.durationMultiplier = scene.durationMultiplierForAutoplayer
        }
    }
    
    
    @objc func nextStep(timerX: Timer) {
        if scene.cardCount > 0 /*&& scene.tippArray.count > 0*/ {
            switch autoPlayStatus {
            case .getTipp:
                if scene.tippsButton!.alpha == 1 && scene.countMovingCards == 0 {  // if tipps are ready
                    bestTipp = Tipps()
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
                        switch testerType {
                        case .beginner:
                            for tipp in scene.tippArray {
                                if bestTipp.value < tipp.value {
                                    bestTipp = tipp
                                }
                            }
                        case .medium:
                            for tipp in scene.tippArray {
                                if bestTipp.value < tipp.value {
                                    bestTipp = tipp
                                }
                            }
                        case .expert:
                            for tipp in scene.tippArray {
                                if tipp.toRow != NoValue  { // first check only Cards
                                    if bestTipp.value < tipp.value {
                                        bestTipp = tipp
                                    }
                                }
                            }
                            if bestTipp.points.count == 0 {
                                for tipp in scene.tippArray {
                                    if tipp.toRow == NoValue  { // first check only Cards
                                        if bestTipp.value < tipp.value {
                                            bestTipp = tipp
                                        }
                                    }
                                }
                            }

                        }
                    }
                    if bestTipp.points.count > 0 {
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
                scene.myTouchesBegan(touchLocation: bestTipp.points[0])
                autoPlayStatus = .touchesMoved
            case .touchesMoved:
                scene.myTouchesMoved(touchLocation: bestTipp.points[1])
                autoPlayStatus = .touchesEnded
            case .touchesEnded:
                scene.myTouchesEnded(touchLocation: bestTipp.points[1])
                if self.testType != .runOnce && MySKCard.cardCount == gamesToPlay[gameIndex].stopAt {
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
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
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
