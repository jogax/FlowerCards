//
//  MySKGameStatistic.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 05/08/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import SpriteKit
import RealmSwift

class MySKGameStatistic: MySKTable {
    
    var callBack: (Bool , Int, Int) -> ()
    let myGameColumnWidths: [CGFloat] = [12, 15, 15, 20, 15, 13, 10] // in %
    let myName = "MySKStatistic"
    let countLines = 0
    let playerID: Int
    let levelID: Int
    let gamesOfThisLevel: Results<GameModel>
    var lastLocation = CGPoint.zero
    var gameNumbers = [Int: Int]() // column : gameNumber
    
    
    
    
    
    init(playerID: Int, levelID: Int, parent: SKSpriteNode, callBack: @escaping (Bool, Int, Int)->()) {
        self.playerID = playerID
        self.levelID = levelID
        let playerName = realm.objects(PlayerModel.self).filter("ID = %d", playerID).first!.name
        self.callBack = callBack
        let headLines = GV.language.getText(.tcPlayerStatisticLevel, values: playerName, String(levelID + 1))
        gamesOfThisLevel = realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true and playerScore > 0", playerID, levelID).sorted(byProperty: "gameNumber")
        super.init(columnWidths: myGameColumnWidths, rows:gamesOfThisLevel.count + 1, headLines: [headLines], parent: parent, width: parent.parent!.frame.width * 0.9)
        self.showVerticalLines = true
        self.name = myName
        
        showMe(showStatistic)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showStatistic() {
        let elements: [MultiVar] = [MultiVar(string: GV.language.getText(.tcGame)),
                                    MultiVar(string: GV.language.getText(.tcGameArt)),
                                    MultiVar(string: GV.language.getText(.tcOpponent)),
                                    MultiVar(string: GV.language.getText(.tcScore)),
                                    MultiVar(string: GV.language.getText(.tcAllTime)),
                                    MultiVar(string: GV.language.getText(.tcVictory)),
                                    MultiVar(string: GV.language.getText(.tcStart)),
                                    ]
        showRowOfTable(elements, row: 0, selected: true)
        var row = 1
        for game in gamesOfThisLevel {
            var gameArt = GV.language.getText(.tcGame) // simple Game
            var opponent = ""
            var score = String(game.playerScore)
            var victory = DrawImages.getOKImage(CGSize(width: 20, height: 20))
            let startImage = DrawImages.getStartImage(CGSize(width: 20, height: 20))
            if game.multiPlay {
                gameArt = GV.language.getText(.tcCompetitionShort)
                opponent = game.opponentName
                score += " / " + String(game.opponentScore)
                if game.playerScore < game.opponentScore {
                    victory = DrawImages.getNOKImage(CGSize(width: 20, height: 20))
                }
            }
            let elements: [MultiVar] = [MultiVar(string: "#\(game.gameNumber + 1)"),
                                        MultiVar(string: gameArt),
                                        MultiVar(string: opponent),
                                        MultiVar(string: score),
                                        MultiVar(string: game.time.dayHourMinSec),
                                        MultiVar(image: victory),
                                        MultiVar(image: startImage),
                                        ]
            showRowOfTable(elements, row: row, selected: true)
            gameNumbers[row] = game.gameNumber
            row += 1
        }
        
    }
    
    func convertNameWhenRequired(_ name: String)->String {
        if name == GV.language.getText(.tcAnonym) {
            return GV.language.getText(.tcGuest)
        }
        return name
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first!.location(in: self)
        touchesBeganAtNode = atPoint(touchLocation)
        lastLocation = touches.first!.location(in: GV.mainViewController!.view)
        if !(touchesBeganAtNode is SKLabelNode || (touchesBeganAtNode is SKSpriteNode && touchesBeganAtNode!.name != myName)) {
            touchesBeganAtNode = nil
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//p         let adder:CGFloat = 100
        
        let actLocation = touches.first!.location(in: GV.mainViewController!.view)
        let delta:CGFloat = lastLocation.y - actLocation.y
        lastLocation = actLocation
        scrollView(delta)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let (_, row) = checkTouches(touches, withEvent: event)
        switch row {
        case 0:
            let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
            myParent.run(fadeInAction)
            removeFromParent()
            callBack(false, 0, 0)
        case 2..<10000:
            callBack(true, gameNumbers[row - 1]!, levelID)
        default:
            break
        }
        
    }
    
    func showDetailedPlayerStatistic(_ row: Int) {
        //        let countLevelLines = Int(LevelsForPlayWithCards().count() + 1)
        
    }
    
    override func setMyDeviceSpecialConstants() {
        switch GV.deviceConstants.type {
        case .iPadPro12_9:
            fontSize = CGFloat(20)
        case .iPadPro9_7:
            fontSize = CGFloat(20)
        case .iPad2:
            fontSize = CGFloat(20)
        case .iPadMini:
            fontSize = CGFloat(20)
        case .iPhone6Plus:
            fontSize = CGFloat(15)
        case .iPhone6:
            fontSize = CGFloat(15)
        case .iPhone5:
            fontSize = CGFloat(13)
        case .iPhone4:
            fontSize = CGFloat(12)
        default:
            break
        }
    }
    
    
}

