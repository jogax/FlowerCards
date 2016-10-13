//
//  MySKDetailedStatistic.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 11/05/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import SpriteKit
import RealmSwift

class MySKDetailedStatistic: MySKTable {
    
    var callBack: (Bool, Int, Int)->()
    let myDetailedColumnWidths: [CGFloat] = [15, 13, 20, 30, 12, 10] // in %
    let myName = "MySKStatistic"
    let countLines = GV.levelsForPlay.count()
    let playerID: Int
    let parentNode: SKSpriteNode

    
    
    
    
    init(playerID: Int, parent: SKSpriteNode, callBack: @escaping (Bool, Int, Int)->()) {
        self.playerID = playerID
        let playerName = realm.objects(PlayerModel.self).filter("ID = %d", playerID).first!.name
        self.parentNode = parent
        self.callBack = callBack
        let headLines = GV.language.getText(.tcPlayerStatisticHeader, values: playerName)
        super.init(columnWidths: myDetailedColumnWidths, rows:countLines + 1, headLines: [headLines], parent: parent, width: parent.parent!.frame.width * 0.9)
        self.showVerticalLines = true
        self.name = myName
        
        showMe(showStatistic)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showStatistic() {
        let elements: [MultiVar] = [MultiVar(string: GV.language.getText(.tcLevel)),
                                    MultiVar(string: GV.language.getText(.tcCountPlays)),
                                    MultiVar(string: GV.language.getText(.tcCountCompetitions)),
                                    MultiVar(string: GV.language.getText(.tcCountVictorys)),
                                    MultiVar(string: GV.language.getText(.tcAllTime)),
                                    ]
        showRowOfTable(elements, row: 0, selected: true)
        for levelID in 0..<countLines {
            var statistic: StatisticModel?
            statistic = realm.objects(StatisticModel.self).filter("playerID = %d and levelID = %d", playerID, levelID).first
            if statistic == nil {
                statistic = StatisticModel()
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = NumberFormatter.Style.none // .DecimalStyle
//            let bestScoreString = formatter.stringFromNumber(statistic!.bestScore)
            let elements: [MultiVar] = [MultiVar(string: String(levelID + 1)),
                                        MultiVar(string: "\(statistic!.countPlays)"),
                                        MultiVar(string: "\(statistic!.countMultiPlays)"),
                                        MultiVar(string: "\(statistic!.victorys) / \(statistic!.defeats)"),
                                        MultiVar(string: "\(statistic!.allTime.dayHourMinSec)"),
                                        MultiVar(image: DrawImages.getGoForwardImage(CGSize(width: 20, height: 20))),
            ]
            showRowOfTable(elements, row: levelID + 1, selected: true)
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
        if !(touchesBeganAtNode is SKLabelNode || (touchesBeganAtNode is SKSpriteNode && touchesBeganAtNode!.name != myName)) {
            touchesBeganAtNode = nil
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        _ = touches.first!.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let (_, row, column) = checkTouches(touches, withEvent: event)
        switch row {
        case 0:
            let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
            myParent.run(fadeInAction)
            removeFromParent()
            callBack(false, 0, 0)
        case 2..<10000:
            showDetailedPlayerStatistic(row - 2)
        default:
            break
        }
        
    }
    
    
    func showDetailedPlayerStatistic(_ row: Int) {
        _ = MySKGameStatistic(playerID: playerID, levelID: row, parent: self, callBack: callBackFromGameStatistic)
    }
 
    func callBackFromGameStatistic(_ startGame: Bool = false, gameNumber: Int = 0, levelIndex: Int = 0) {
        if startGame {
            callBack(startGame, gameNumber, levelIndex)
        }
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

