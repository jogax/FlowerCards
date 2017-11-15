//
//  GameCenterSync.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 11/10/2017.
//  Copyright © 2017 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import GameKit
import RealmSwift

class GameCenterSync {
    var timer: Timer?
    init() {
    }
    
    
    
    @objc private func waitForLocalPlayer() {
        if GKLocalPlayer.localPlayer().isAuthenticated == false {
            timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(waitForLocalPlayer), userInfo: nil, repeats: false)
        } else {
            startSyncWithGameCenter()
        }
    }
    
    func startGameCenterSync() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(waitForLocalPlayer), userInfo: nil, repeats: false)
    }
    
    private func startSyncWithGameCenter() {
        DispatchQueue.global(qos: .background).async {
            let myBackgroundRealm = try! Realm()
            let GCEnabled = myBackgroundRealm.objects(PlayerModel.self).filter("isActPlayer = true").first!.GCEnabled
            if GCEnabled == GCEnabledType.GameCenterEnabled.rawValue {
                let sortProperties = [SortDescriptor(keyPath: "countPackages", ascending: true), SortDescriptor(keyPath: "levelID", ascending: true)]
                let myHighScores = myBackgroundRealm.objects(HighScoreModel.self).sorted(by: sortProperties)

                for actHighScore in myHighScores {
                    let countPackages = actHighScore.countPackages
                    let levelID = actHighScore.levelID
                    let score = actHighScore.myHighScore
                    if !actHighScore.sentToGameCenter {
                        self.sendScoreToGameCenter(score: score, countPackages: countPackages, levelID: levelID)
                        myBackgroundRealm.beginWrite()
                        actHighScore.sentToGameCenter = true
                        try! myBackgroundRealm.commitWrite()
                    }
                    self.importBestScoreFromGameCenter(countPackages: countPackages, levelID: levelID)
                }
            }
//            print("This is run on the background queue")
            
            DispatchQueue.main.async {
                // every hour import the best players for each countPackage and levelID
                self.timer = Timer.scheduledTimer(timeInterval: 3600.0, target: self, selector: #selector(self.waitForLocalPlayer), userInfo: nil, repeats: false)
//                print("This is run on the main queue, after the previous code in outer block")
            }
        }
    }
    func sendScoreToGameCenter(score: Int, countPackages: Int, levelID: Int) {
        // Submit score to GC leaderboard
        let bestScore = GKScore(leaderboardIdentifier: "P\(countPackages)L\(levelID + 1)", player: GKLocalPlayer.localPlayer())
        bestScore.value = Int64(score)
        let scoreArray = [bestScore]
        GKScore.report(scoreArray) { (error) in
            if error != nil {
                print("Error by send score to GameCenter: \(error!.localizedDescription)")
            } else {
//                print("Best Score: \(score) of \(String(describing: GKLocalPlayer.localPlayer().alias))! sent to Leaderboard: \("P\(countPackages)L\(levelID + 1)")")
            }
        }
    }
    private func importBestScoreFromGameCenter(countPackages: Int, levelID: Int) {
//        if GKLocalPlayer.localPlayer().isAuthenticated == false {return}
        let leaderboardID = "P\(countPackages)L\(levelID + 1)"
//        print("Downloading Score for leaderboardID: \(leaderboardID) started")
        // first downloading my Rank
        let myLeaderBoard = GKLeaderboard(players: [GKLocalPlayer.localPlayer()])
        myLeaderBoard.identifier = leaderboardID
        myLeaderBoard.loadScores(completionHandler: {
            (scores, error) in
            if error != nil {
                print("Error by downloading scores for \(leaderboardID): \(error!.localizedDescription)")
            } else {
                if scores != nil {
                    let myRealm = try! Realm()
                    let actResult = myRealm.objects(HighScoreModel.self).filter("countPackages = %d and levelID = %d", countPackages, levelID).first!
                    realm.beginWrite()
                    actResult.myRank = (scores?.first!.rank)!
                    if let intValue = scores?.first!.value {
                        if actResult.myHighScore < scores!.first!.value {
                            actResult.myHighScore = Int(intValue)
                        }
                    } 
                    //                    print("Bestplayer: \(actResult.bestPlayerName) with score: \(actResult.bestPlayerHighScore) saved to \(leaderboardID)")
                    try! realm.commitWrite()
                }
            }
        })
        let leaderBoard = GKLeaderboard()
        leaderBoard.identifier = leaderboardID
        leaderBoard.playerScope = .global
        leaderBoard.range = NSMakeRange(1,1)
        leaderBoard.loadScores(completionHandler: {
            (scores, error) in
            if error != nil {
                print("Error by downloading scores for \(leaderboardID): \(error!.localizedDescription)")
            } else {
                if scores != nil {
                    let myRealm = try! Realm()
                    let actResult = myRealm.objects(HighScoreModel.self).filter("countPackages = %d and levelID = %d", countPackages, levelID).first!
                    realm.beginWrite()
                    actResult.bestPlayerName = (scores?.first!.player?.alias)!
                    if let intValue = scores?.first!.value {
                        actResult.bestPlayerHighScore = Int(intValue)
                    } else {
                        actResult.bestPlayerHighScore = 0
                    }
//                    print("Bestplayer: \(actResult.bestPlayerName) with score: \(actResult.bestPlayerHighScore) saved to \(leaderboardID)")
                    try! realm.commitWrite()
                }
            }
        })
    }
    
    func printAllGamers() {
        var players: [String] = []
        var countLevels = 0
        for countPackages in 1...4 {
            for levelID in 1...26 {
                let leaderboardID = "P\(countPackages)L\(levelID)"
                let leaderBoard = GKLeaderboard()
                leaderBoard.identifier = leaderboardID
                leaderBoard.playerScope = .global
//                leaderBoard.range = NSMakeRange(1,1000)
                leaderBoard.loadScores(completionHandler: {
                    (scores, error) in
                    if error != nil {
                        countLevels += 1
                        print("Error by downloading scores for \(leaderboardID): \(error!.localizedDescription)")
                    } else {
                        if scores != nil {
                            print("PackageNr: \(countPackages), levelID: \(levelID), countPlayers: \(String(describing: scores!.count))")
                            for score in scores! {
                                if let alias = score.player!.alias {
                                    if !players.contains(alias) {
                                        players.append(alias)
                                    }
                                    print("rank: \(score.rank), player: \(String(describing: alias)), Score: \(score.value)")
                                }
                            }
                        }
                        countLevels += 1
                        if countLevels > 103 {
                            print("-------------------------------------")
                            print ("List of Players: (\(players.count))")
                            for player in players {
                                print(player)
                            }
                        }
                    }
                })
            }
        }
    }
}
