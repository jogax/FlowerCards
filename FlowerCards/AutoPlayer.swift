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
    // game to Play saves Games, Levels and CountPackages as they are displayed
    let gamesToPlayTable: [GameToPlay] = [
        GameToPlay(level: 18, countPackages: 2, gameNumber: 1454), // at Step: 199
    ]
    enum runStatus: Int {
        case getTipp = 0, touchesBegan, touchesMoved, touchesEnded, waitingForNextStep
    }
    enum TestType: Int {
        case newTest = 1, fromTable, fromDB, runOnce, stepByStep
    }
    enum TesterType: Int {
        case beginner = 0, longPacks, medium, expert, tester
    }
    struct GameToPlay {
        var level: Int
        var countPackages: Int
        var gameNumber: Int
        var stopAt: Int
        init(level: Int, countPackages: Int, gameNumber: Int, stopAt: Int = 0) {
            self.level = level
            self.countPackages = countPackages
            self.gameNumber = gameNumber
            self.stopAt = stopAt
        }
    }
    var scene: CardGameScene
//    @objc let nextStepSelector = "nextStep:"
    private var timer: Timer = Timer()
    private var bestTipp = Tipp()
    private var choosedTipp: Tipp.InnerTipp = Tipp.InnerTipp()
    private var autoPlayStatus: runStatus = .getTipp
    private var indexForReplay: Int = 0
    private var stopTimer = false
    private var testType: TestType = .runOnce //.test
    private var testerType: TesterType = .expert
    private var gamesToPlay: [GameToPlay] = []
    private var gameIndex = 0
    private let playerColors: [[Int]] = [[0, 1], [2, 3]]
    private var actPlayer = 0
    
    
    init(scene: CardGameScene) {
        self.scene = scene
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
            let errorGames = realm.objects(GameModel.self).filter("playerID = %d and gameFinished = false and levelID = %d and ID != %d", GV.player!.ID, levelID, GV.actGame!.ID).sorted(byProperty: "gameNumber")
            for game in errorGames  {
                if game.countSteps == 0 {
                    realm.beginWrite()
                    realm.delete(game)
                    try! realm.commitWrite()                    
                } else {
                    if game.levelID != oldLevelID {
                        oldLevelID = game.levelID
                    }
                    let lineGameToPlay = "GameToPlay(level: \(game.levelID + 1), countPackages: \(game.countPackages), gameNumber: \(game.gameNumber + 1)), // at Step: \(game.countSteps)"
                    print (lineGameToPlay)
                }
            }
            levelID += 1
        }
        let allGamesCount = realm.objects(GameModel.self).filter("playerID = %d", GV.player!.ID).count
        let errorGamesCount = realm.objects(GameModel.self).filter("playerID = %d and gameFinished = false and ID != %d", GV.player!.ID, GV.actGame!.ID).count
        if allGamesCount > 0 {
            print ("AllGames: \(allGamesCount), Errorgames: \(errorGamesCount), Procent errorgames: \((Double(errorGamesCount) * 100.0 / Double(allGamesCount)).twoDecimals)%")
            for countPkgs in 1...4 {
                let gameCount = realm.objects(GameModel.self).filter("playerID = %d and countPackages = %d", GV.player!.ID, countPkgs).count
                let errorCount = realm.objects(GameModel.self).filter("playerID = %d and countPackages = %d and gameFinished = false and (ID != %d or levelID != %d)", GV.player!.ID, countPkgs, GV.actGame!.ID, GV.actGame!.levelID).count
                if gameCount > 0 {
                    print ("Pack \(countPkgs): \(gameCount), Errorgames: \(errorCount), Procent errorgames: \((Double(errorCount) * 100.0 / Double(gameCount)).twoDecimals)%")
                } else {
                    print ("Pack \(countPkgs): \(gameCount), Errorgames: \(errorCount), Procent errorgames: 0%")
                }
            }
        } else {
            print ("AllGames: \(allGamesCount), Errorgames: \(errorGamesCount), Procent errorgames: 0%")
        }
    }
    #endif
    func startPlay(testType: TestType = .runOnce) {
        stopTimer = false
        gameIndex = 0
        self.testType = testType
        let playerName = GV.player!.name
        switch playerName {
        case "NewPlayer": testerType = .tester
        case "Beginner": testerType = .beginner
        case "LongPacks": testerType = .longPacks
        case "Medium": testerType = .medium
        case "Expert": testerType = .expert
        default: testerType = .expert
        }
        switch testType {
        case .newTest:
            gamesToPlay.removeAll()
            switch testerType {
            case .tester:
                generateTestForTester()
            default:
                generateTestForAllOthers()
            }

        case .runOnce:
            gamesToPlay.removeAll()
        case .fromTable:
            gamesToPlay = gamesToPlayTable
        case .stepByStep:
            scene.prepareHelpButtonForStepByStep(callBack: makeStep)
        case .fromDB:
            gamesToPlay.removeAll()
            let searchString = "" //"and ((countSteps < 190 and countPackages = 4) or (countSteps < 146 and countPackages = 3))"
            let errorGames = realm.objects(GameModel.self).filter("playerID = %d and gameFinished = false \(searchString)", GV.player!.ID).sorted(byProperty: "created", ascending: true)
            for game in errorGames {
                let countSteps = game.countSteps
                if countSteps > 0 {
                    gamesToPlay.append(GameToPlay(level: game.levelID + 1, countPackages: game.countPackages, gameNumber: game.gameNumber + 1))
                }
            }
        }
        if self.testType != .runOnce {
            startNextGame()
            scene.durationMultiplier = scene.durationMultiplierForAutoplayer
            scene.waitForStartConst = scene.waitForStartForAutoplayer
        }
        scene.isUserInteractionEnabled = false
        timer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
    }
    
    func makeStep() {
        
        testType = .stepByStep
        autoPlayStatus = .getTipp
        stopTimer = false
        timer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
    }
    
    private func generateTestForTester() {
        var gameCounts: [[Int]] = Array(repeating: Array(repeating: 0, count: 26), count: 4)
        var maxCount = 0
        var countMaxValues = 0
        for countPkgs in 0...3 {
            for levelId in 0...25 {
                let count = realm.objects(GameModel.self).filter("playerID = %d and countPackages = %d and levelID = %d and countSteps > 3", GV.player!.ID, countPkgs + 1, levelId).count
                gameCounts[countPkgs][levelId] = count
                if maxCount < count {
                    maxCount = count
                    countMaxValues = 1
                } else if maxCount == count {
                    countMaxValues += 1
                }
            }
        }
        
        if countMaxValues != 4 * 26 {
            for countPkgs in 0...3 {
                for levelId in 0...25 {
                    let count = maxCount - gameCounts[3 - countPkgs][levelId]
                    for _ in 0..<count {
                        let gameToPlay = GameToPlay(level: levelId + 1, countPackages: 4 - countPkgs, gameNumber: 1 + Int(arc4random()) % MaxGameNumber)
                        gamesToPlay.append(gameToPlay)
                    }
                }
            }
        }
        var go = true
        while go {
            for countPkgs in 0...3 {
                for levelId in 0...25 {
                    for _ in 0..<1 {
                        let gameToPlay = GameToPlay(level: levelId + 1, countPackages: 4 - countPkgs, gameNumber: 1 + Int(arc4random()) % MaxGameNumber)
                        gamesToPlay.append(gameToPlay)
                        if gamesToPlay.count > 1000 {
                            go = false
                        }
                    }
                }
            }
        }
    }
    
    private func generateTestForAllOthers() {
        let origID = realm.objects(PlayerModel.self).filter("name = %@", "NewPlayer").first!.ID
        let games = realm.objects(GameModel.self).filter("playerID = %d", origID).sorted(byProperty: "gameNumber", ascending: true)
        for game in games {
            let levelID = game.levelID
            let countPackages = game.countPackages
            let gameNumber = game.gameNumber
            if realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and countPackages = %d and gameNumber = %d", GV.player!.ID, levelID, countPackages, gameNumber).count == 0 {
                let gameToPlay = GameToPlay(level: game.levelID + 1, countPackages: game.countPackages, gameNumber: game.gameNumber + 1)
                gamesToPlay.append(gameToPlay)
            }
            if gamesToPlay.count == 1000 {
                break
            }
        }
    }
    
    func startNextGame() {
        if gameIndex < gamesToPlay.count {
            var go = true
            while true {
                let levelIndex = gamesToPlay[gameIndex].level - 1
                let countPackages = gamesToPlay[gameIndex].countPackages
                let gameNumber = gamesToPlay[gameIndex].gameNumber - 1
                if self.testType == .newTest {
                    if realm.objects(GameModel.self).filter("gameNumber = %d and levelID = %d and playerID = %d and countPackages = %d",
                        gameNumber, levelIndex, GV.player!.ID, countPackages).count > 0 {
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
                GV.player!.countPackages = gamesToPlay[gameIndex].countPackages
                try! realm.commitWrite()
                scene.gameNumber = gamesToPlay[gameIndex].gameNumber - 1
                scene.startNewGame(next: false)
                scene.durationMultiplier = scene.durationMultiplierForAutoplayer
                scene.waitForStartConst = scene.waitForStartForAutoplayer
            }
        }
    }
    
    
    @objc func nextStep(timerX: Timer) {
        if scene.cardCount > 0 {
            switch autoPlayStatus {
            case .getTipp:
                choosedTipp = Tipp.InnerTipp()
                if scene.tippsButton!.alpha == 1 && scene.countMovingCards == 0 {  // if tipps are ready
                    bestTipp = Tipp()
                    if tippArray.count > 0 {
                        switch testerType {
                        case .beginner:
                            for tipp in tippArray {
                                if !tipp.supressed && (bestTipp.innerTipps.count == 0 || bestTipp.innerTipps.first!.value < tipp.innerTipps.first!.value) {
                                    bestTipp = tipp
                                    choosedTipp = tipp.innerTipps.first!
                                }
                            }
                        case .longPacks:
                            for tipp in tippArray {
                                let AWithK = (tipp.connectedValues.upper == FirstCardValue && tipp.connectedValues.lower == LastCardValue ) || tipp.card1.countTransitions + tipp.card2.countTransitions > 0
                                if tipp.card2.type != .containerType && !AWithK { // first check only Cards without transitions
                                    if bestTipp.innerTipps.count == 0 || bestTipp.innerTipps.last!.value < tipp.innerTipps.last!.value {
                                        bestTipp = tipp
                                        choosedTipp = tipp.innerTipps.last!
                                    }
                                }
                            }
                            if bestTipp.innerTipps.count == 0 {
                                for tipp in tippArray {
                                    if !tipp.supressed && tipp.card2.type == .containerType  { // first check only Cards
                                        if bestTipp.innerTipps.count == 0 || bestTipp.innerTipps.last!.value < tipp.innerTipps.last!.value {
                                            bestTipp = tipp
                                            choosedTipp = tipp.innerTipps.last!
                                            
                                        }
                                    }
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
                                    if !tipp.supressed && tipp.card2.type == .containerType  { // first check only Cards
                                        if bestTipp.innerTipps.count == 0 || bestTipp.innerTipps.last!.value < tipp.innerTipps.last!.value {
                                            bestTipp = tipp
                                            choosedTipp = tipp.innerTipps.last!

                                        }
                                    }
                                }
                            }
                            
                        case .expert, .tester:
                            for tipp in tippArray {
//                                if tipp.supressed {
//                                    print("supressed: \(tipp.printValue())")
//                                    stopAutoplay()
//                                    break
//                                } else 
                                if !tipp.supressed && tipp.card2.type != .containerType  { // first check only Cards an not supressed tipps
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
                    if choosedTipp.points.count > 0 && tippArray.count > 0 {
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
                scene.autoTouchesEnded(touchLocation: choosedTipp.points[1])
                switch testType {
                case .runOnce:
                    break
                case .stepByStep:
                    autoPlayStatus = .waitingForNextStep
                    stopTimer = true
                    timer.invalidate()
                default:
                    if gamesToPlay.count > 0 && MySKCard.cardCount == gamesToPlay[gameIndex].stopAt {
                        self.stopAutoplay()
                    }
                }
                autoPlayStatus = .getTipp
            case .waitingForNextStep:
                break
            }
            if stopTimer {
                timer.invalidate()
            } else {
                let interval = autoPlayStatus == .getTipp || autoPlayStatus == .touchesBegan ? 0.001 : 0.0001
                timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
            }
        } else {
            scene.updateGameCountLabels()
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
                timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(nextStep(timerX:)), userInfo: nil, repeats: false)
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
