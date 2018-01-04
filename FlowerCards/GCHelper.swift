//
//  GameKitHelper.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 22/11/2017.
//  Copyright © 2017 Jozsef Romhanyi. All rights reserved.
//

// GCHelper.swift (v. 0.5.1)
//
// Copyright (c) 2017 Jack Cook
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
import GameKit
import RealmSwift

/// Custom delegate used to provide information to the application implementing GCHelper.
public protocol GCHelperDelegate: class {
    
    /// Method called when a match has been initiated.
    func matchStarted()
    
    /// Method called when the device received data about the match from another device in the match.
    func match(_ match: GKMatch, didReceive didReceiveData: Data, fromPlayer: String)
    
    /// Method called when the match has ended.
    func matchEnded(error: String)
    func localPlayerAuthenticated()
    func continueTimeCount()
}

/// A GCHelper instance represents a wrapper around a GameKit match.
public class GCHelper: NSObject, GKMatchmakerViewControllerDelegate, GKGameCenterControllerDelegate, GKMatchDelegate, GKLocalPlayerListener, GKInviteEventListener {
    
    /// An array of retrieved achievements. `loadAllAchievements(completion:)` must be called in advance.
    public var achievements = [String: GKAchievement]()
    
    /// The match object provided by GameKit.
    public var match: GKMatch!
    public enum AuthenticatingStatus: Int {
        case notAuthenticated = 0, authenticatingInProgress, authenticated
    }
    public var authenticateStatus: AuthenticatingStatus = .notAuthenticated
    
    fileprivate weak var delegate: GCHelperDelegate?
    fileprivate var invite: GKInvite!
    fileprivate var invitedPlayer: GKPlayer!
    fileprivate var playersDict = [String: GKPlayer]()
    fileprivate var allPlayers = [String:GKPlayer]()
    fileprivate weak var presentingViewController: UIViewController!

    
    fileprivate var authenticated = false {
        didSet {
//            print("Authentication changed: player\(authenticated ? " " : " not ")authenticated")
        }
    }
    
    fileprivate var matchStarted = false
    
    /// The shared instance of GCHelper, allowing you to access the same instance across all uses of the library.
    public class var sharedInstance: GCHelper {
        struct Static {
            static let instance = GCHelper()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(GCHelper.authenticationChanged), name: Notification.Name.GKPlayerAuthenticationDidChangeNotificationName, object: nil)
    }
    
    // MARK: Private functions
    
    @objc fileprivate func authenticationChanged() {
        if GKLocalPlayer.localPlayer().isAuthenticated && !authenticated {
            authenticated = true
        } else {
            authenticated = false
        }
    }
    
    fileprivate func lookupPlayers() {
        print ("\(match.players.count)")
        let playerIDs = match.players.map { $0.playerID } as! [String]
        
        GKPlayer.loadPlayers(forIdentifiers: playerIDs) { (players, error) in
            guard error == nil else {
                print("Error retrieving player info: \(String(describing: error?.localizedDescription))")
                self.matchStarted = false
                let errorText = String(describing: error?.localizedDescription)
                self.delegate?.matchEnded(error: errorText)
                return
            }
            
            guard let players = players else {
                print("Error retrieving players; returned nil")
                return
            }
            
            for player in players {
                print("Found player: \(String(describing: player.alias))")
                self.playersDict[player.playerID!] = player
            }
            
            self.matchStarted = true
            GKMatchmaker.shared().finishMatchmaking(for: self.match)
            self.delegate?.matchStarted()
        }
    }
    
    
    
    // MARK: User functions
    
    
    /// Authenticates the user with their Game Center account if possible
    public func authenticateLocalUser(theDelegate: GCHelperDelegate) {
        delegate = theDelegate
//        if let _ = delegate{
//            print ("delegate OK")
//        }else{
//            print("The delegate is nil")
//        }
//        print("Authenticating local user...")
        authenticateStatus = .authenticatingInProgress
        if GKLocalPlayer.localPlayer().isAuthenticated == false {
            GKLocalPlayer.localPlayer().authenticateHandler = { (view, error) in
                guard error == nil else {
                    print("Authentication error: \(String(describing: error?.localizedDescription))")
                    return
                }
                self.delegate?.localPlayerAuthenticated()
                self.authenticateStatus = .authenticated
                self.authenticated = true
                self.getAllPlayers()
                self.startGameCenterSync()
                GKLocalPlayer.localPlayer().unregisterAllListeners()
                GKLocalPlayer.localPlayer().register(self)
            }
        } else {
//            print("Already authenticated")
        }
    }
    
    /**
     Attempts to pair up the user with other users who are also looking for a match.
     
     :param: minPlayers The minimum number of players required to create a match.
     :param: maxPlayers The maximum number of players allowed to create a match.
     :param: viewController The view controller to present required GameKit view controllers from.
     :param: delegate The delegate receiving data from GCHelper.
     */
    public func findMatchWithMinPlayers(_ minPlayers: Int, maxPlayers: Int, viewController: UIViewController, delegate theDelegate: GCHelperDelegate) {
        matchStarted = false
        match = nil
        presentingViewController = viewController
        delegate = theDelegate
        presentingViewController.dismiss(animated: false, completion: nil)
        
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        
        let mmvc = GKMatchmakerViewController(matchRequest: request)!
        mmvc.matchmakerDelegate = self
        
        presentingViewController.present(mmvc, animated: true, completion: nil)
    }
    
    public func customFindMatchWithMinPlayers(_ minPlayers: Int, maxPlayers: Int, viewController: UIViewController, delegate theDelegate: GCHelperDelegate) {
        matchStarted = false
        match = nil
        presentingViewController = viewController
        delegate = theDelegate
        presentingViewController.dismiss(animated: false, completion: nil)
        
        let waitAlert = UIAlertController(title: GV.language.getText(.tcWaitForOpponent),
                                          message: "",
                                          preferredStyle: .alert)
        let noMoreWaitAction = UIAlertAction(title: GV.language.getText(.tcNoWait), style: .default,
                                             handler: {(paramAction:UIAlertAction!) in
                                                GV.mainViewController!.stopAlert()
                                                if self.match != nil {
                                                    self.match.disconnect()
                                                }
                                                self.delegate?.continueTimeCount()
        })
        waitAlert.addAction(noMoreWaitAction)
        GV.mainViewController!.showAlert(waitAlert)
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        let matchMaker = GKMatchmaker()
        matchMaker.findMatch(for: request, withCompletionHandler: {
            
            (match, error) in
            if ((error) != nil) {
                // Process the error.
            } else if (match != nil) {
                self.match = match
                self.match.delegate = self
                if !self.matchStarted && match?.expectedPlayerCount == 0 {
//                    print("Ready to start match: count Players: \(String(describing: match!.players.count))")
                    self.lookupPlayers()
                }
            }
        })
    }

    public func autoFindMatchWithMinPlayers(_ minPlayers: Int, maxPlayers: Int, viewController: UIViewController, delegate theDelegate: GCHelperDelegate) {
        matchStarted = false
        match = nil
        presentingViewController = viewController
        delegate = theDelegate
        presentingViewController.dismiss(animated: false, completion: nil)
        let searchAlert = UIAlertController(title: GV.language.getText(.tcSearchOpponent),
                                          message: "",
                                          preferredStyle: .alert)
        let OKAction = UIAlertAction(title: GV.language.getText(.tcok), style: .default,
                                             handler: {(paramAction:UIAlertAction!) in
                                                GV.mainViewController!.stopAlert()
                                                if self.match != nil {
                                                    self.match.disconnect()
                                                }
                                                self.delegate?.continueTimeCount()
        })
        searchAlert.addAction(OKAction)
        GV.mainViewController!.showAlert(searchAlert, delay: 10)

        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        let matchMaker = GKMatchmaker()
        matchMaker.findMatch(for: request, withCompletionHandler: {
            
            (match, error) in
            if ((error) != nil) {
                // Process the error.
            } else if (match != nil) {
                self.match = match
                self.match.delegate = self
                if !self.matchStarted && match?.expectedPlayerCount == 0 {
                    self.lookupPlayers()
                }
            }
        })
    }


//    private func createAction (playerName: String, minPlayers: Int, maxPlayers: Int, foundedPlayerID: String) ->UIAlertAction {
//        let playerAction = UIAlertAction(title: playerName, style: .default,
//                                         handler: {(paramAction:UIAlertAction!) in
//                                            let waitAlert = UIAlertController(title: GV.language.getText(.tcWaitForOpponent),
//                                                                              message: "",
//                                                                              preferredStyle: .alert)
//                                            let noMoreWaitAction = UIAlertAction(title: GV.language.getText(.tcNoWait), style: .default,
//                                                                                 handler: {(paramAction:UIAlertAction!) in
//                                                                                    GV.mainViewController!.stopAlert()
//                                                                                    if self.match != nil {
//                                                                                        self.match.disconnect()
//                                                                                    }
//                                            })
//                                            waitAlert.addAction(noMoreWaitAction)
//                                            GV.mainViewController!.showAlert(waitAlert)
//                                            let request = GKMatchRequest()
//                                            request.minPlayers = minPlayers
//                                            request.maxPlayers = maxPlayers
//                                            request.recipients = [self.allPlayers[foundedPlayerID]!]
//                                            request.inviteMessage = "Your Custom Invitation Message Here"
//                                            request.recipientResponseHandler = {(player, response) in
//                                                print("\(player) -> \(response)")
//                                            }
//                                            let matchMaker = GKMatchmaker()
//                                            matchMaker.findMatch(for: request, withCompletionHandler: {
//
//                                                (match, error) in
//                                                if ((error) != nil) {
//                                                    // Process the error.
//                                                } else if (match != nil) {
//                                                    self.match = match
//                                                    self.match.delegate = self
//                                                    if !self.matchStarted && match?.expectedPlayerCount == 0 {
//                                                        print("Ready to start match: count Players: \(String(describing: match!.players.count))")
//                                                        self.lookupPlayers()
//                                                    }
//
//                                                    //                                                            self.match = match; // Use a retaining property to retain the match.
//                                                    //                                                            self.match.delegate = self;
//                                                    //                                                            if (!self.matchStarted && match?.expectedPlayerCount == 0) {
//                                                    //                                                                self.matchStarted = true;
//                                                    //                                                            }
//                                                }
//                                            })
//
//
//
//        })
//        return playerAction
//    }
//
//    private func createAllPlayersAction(minPlayers: Int, maxPlayers: Int)->UIAlertAction {
//        let playerAction = UIAlertAction(title: GV.language.getText(.tcAllPlayers), style: .default,
//                                         handler: {(paramAction:UIAlertAction!) in
//                                            let waitAlert = UIAlertController(title: GV.language.getText(.tcWaitForOpponent),
//                                                                              message: "",
//                                                                              preferredStyle: .alert)
//                                            let noMoreWaitAction = UIAlertAction(title: GV.language.getText(.tcNoWait), style: .default,
//                                                                                 handler: {(paramAction:UIAlertAction!) in
//                                                                                    GV.mainViewController!.stopAlert()
//                                                                                    if self.match != nil {
//                                                                                        self.match.disconnect()
//                                                                                    }
//                                            })
//                                            waitAlert.addAction(noMoreWaitAction)
//                                            GV.mainViewController!.showAlert(waitAlert)
//                                            let request = GKMatchRequest()
//                                            request.minPlayers = minPlayers
//                                            request.maxPlayers = maxPlayers
//                                            let matchMaker = GKMatchmaker()
//                                            matchMaker.findMatch(for: request, withCompletionHandler: {
//
//                                                (match, error) in
//                                                if ((error) != nil) {
//                                                    // Process the error.
//                                                } else if (match != nil) {
//                                                    self.match = match
//                                                    self.match.delegate = self
//                                                    if !self.matchStarted && match?.expectedPlayerCount == 0 {
//                                                        print("Ready to start match")
//                                                        self.lookupPlayers()
//                                                    }
//
//                                                }
//                                            })
//
//
//
//        })
//        return playerAction
//    }
//
    
    /**
     Reports progress on an achievement to GameKit if the achievement has not been completed already
     
     :param: identifier A string that matches the identifier string used to create an achievement in iTunes Connect.
     :param: percent A percentage value (0 - 100) stating how far the user has progressed on the achievement.
     */
    public func reportAchievementIdentifier(_ identifier: String, percent: Double, showsCompletionBanner banner: Bool = true) {
        let achievement = GKAchievement(identifier: identifier)
        
        if !achievementIsCompleted(identifier) {
            achievement.percentComplete = percent
            achievement.showsCompletionBanner = banner
            
            GKAchievement.report([achievement]) { (error) in
                guard error == nil else {
                    print("Error in reporting achievements: \(String(describing: error))")
                    return
                }
            }
        }
    }
    
    /**
     Loads all achievements into memory
     
     :param: completion An optional completion block that fires after all achievements have been retrieved
     */
    public func loadAllAchievements(_ completion: (() -> Void)? = nil) {
        GKAchievement.loadAchievements { (achievements, error) in
            guard error == nil, let achievements = achievements else {
                print("Error in loading achievements: \(String(describing: error))")
                return
            }
            
            for achievement in achievements {
                if let id = achievement.identifier {
                    self.achievements[id] = achievement
                }
            }
            
            completion?()
        }
    }
    
    /**
     Checks if an achievement in allPossibleAchievements is already 100% completed
     
     :param: identifier A string that matches the identifier string used to create an achievement in iTunes Connect.
     */
    public func achievementIsCompleted(_ identifier: String) -> Bool {
        if let achievement = achievements[identifier] {
            return achievement.percentComplete == 100
        }
        
        return false
    }
    
    /**
     Resets all achievements that have been reported to GameKit.
     */
    public func resetAllAchievements() {
        GKAchievement.resetAchievements { (error) in
            guard error == nil else {
                print("Error resetting achievements: \(String(describing: error))")
                return
            }
        }
    }
    
    /**
     Reports a high score eligible for placement on a leaderboard to GameKit.
     
     :param: identifier A string that matches the identifier string used to create a leaderboard in iTunes Connect.
     :param: score The score earned by the user.
     */
    public func reportLeaderboardIdentifier(_ identifier: String, score: Int) {
        let scoreObject = GKScore(leaderboardIdentifier: identifier)
        scoreObject.value = Int64(score)
        GKScore.report([scoreObject]) { (error) in
            guard error == nil else {
                print("Error in reporting leaderboard scores: \(String(describing: error))")
                return
            }
        }
    }
    
    /**
     Presents the game center view controller provided by GameKit.
     
     :param: viewController The view controller to present GameKit's view controller from.
     :param: viewState The state in which to present the new view controller.
     */
    public func showGameCenter(_ viewController: UIViewController, viewState: GKGameCenterViewControllerState) {
        presentingViewController = viewController
        
        let gcvc = GKGameCenterViewController()
        gcvc.viewState = viewState
        gcvc.gameCenterDelegate = self
        presentingViewController.present(gcvc, animated: true, completion: nil)
    }
    
    // MARK: GKGameCenterControllerDelegate
    
    public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: GKMatchmakerViewControllerDelegate
    
    public func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
    
    public func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        presentingViewController.dismiss(animated: true, completion: nil)
        print("Error finding match: \(error.localizedDescription)")
    }
    
    public func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind theMatch: GKMatch) {
        presentingViewController.dismiss(animated: true, completion: nil)
        match = theMatch
        match.delegate = self
        if !matchStarted && match.expectedPlayerCount == 0 {
            print("Ready to start match!")
            self.lookupPlayers()
        }
    }
    
    // MARK: GKMatchDelegate
    
    public func match(_ theMatch: GKMatch, didReceive data: Data, fromPlayer playerID: String) {
        if match != theMatch {
            return
        }
        
        delegate?.match(theMatch, didReceive: data, fromPlayer: playerID)
    }
    
    
    public func match(_ theMatch: GKMatch, player playerID: String, didChange state: GKPlayerConnectionState) {
        if match != theMatch {
            return
        }
        
        switch state {
        case .stateConnected where !matchStarted && theMatch.expectedPlayerCount == 0:
            lookupPlayers()
        case .stateDisconnected:
            matchStarted = false
            guard let playerName = playersDict[playerID]?.alias! else {
                print("playerName is empty!")
                break
            }
            
            delegate?.matchEnded(error: GV.language.getText(.tcMatchDisconnected, values: playerName))
            match = nil
        default:
            break
        }
    }
    
    public func match(_ theMatch: GKMatch, didFailWithError error: Error?) {
        if match != theMatch {
            return
        }
        
        print("Match failed with error: \(String(describing: error?.localizedDescription))")
        matchStarted = false
        let errorText = String(describing: error?.localizedDescription)
        delegate?.matchEnded(error: errorText)
    }
    
    // MARK: GKLocalPlayerListener
    
    public func player(_ player: GKPlayer, didAccept inviteToAccept: GKInvite) {
        let mmvc = GKMatchmakerViewController(invite: inviteToAccept)!
        mmvc.matchmakerDelegate = self
        presentingViewController.present(mmvc, animated: true, completion: nil)
    }
    
    public func getAllPlayers() {
        if GV.gkPlayers.count == 0 {
            let myBackgroundRealm = try! Realm()
            for countPackages in 1...4 {
                for levelID in 1...26 {
                    let leaderboardID = "P\(countPackages)L\(levelID)"
                    let leaderBoard = GKLeaderboard()
                    leaderBoard.identifier = leaderboardID
                    leaderBoard.playerScope = .global
                    leaderBoard.timeScope = .allTime
                    //                leaderBoard.range = NSMakeRange(1,1000)
                    leaderBoard.loadScores(completionHandler: {
                        (scores, error) in
                        if scores != nil {
                            for score in scores! {
                                if let playerID = score.player!.playerID {
                                    if GV.gkPlayers[playerID] == nil {
                                        GV.gkPlayers[playerID] = score.player!
                                    }
                                    let foundedPlayers = myBackgroundRealm.objects(GCPlayerModel.self).filter("playerID = %d", playerID)
                                    myBackgroundRealm.beginWrite()
                                    if foundedPlayers.count == 0 {
                                        let playerObject = GCPlayerModel()
                                        playerObject.playerID = playerID
                                        playerObject.name = score.player!.alias!
                                        playerObject.isMyFriend = false
                                        myBackgroundRealm.add(playerObject)
                                    } else {
                                        if foundedPlayers.first!.name != score.player!.alias! {
                                            foundedPlayers.first!.name = score.player!.alias!
                                        }
                                    }
                                    try! myBackgroundRealm.commitWrite()
                                    if self.allPlayers[playerID] == nil {
                                        self.allPlayers[playerID] = score.player!
                                    }
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    var timer: Timer?
    
    @objc private func waitForLocalPlayer() {
        if GKLocalPlayer.localPlayer().isAuthenticated == false {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(waitForLocalPlayer), userInfo: nil, repeats: false)
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
    public func sendScoreToGameCenter(score: Int, countPackages: Int, levelID: Int) {
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
    
    public func sendGameCountToGameCenter(gameCount: Int) {
        let bestGameCount = GKScore(leaderboardIdentifier: "GC", player: GKLocalPlayer.localPlayer())
        bestGameCount.value = Int64(gameCount)
        let countArray = [bestGameCount]
        GKScore.report(countArray) { (error) in
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

}
