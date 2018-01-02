//
//  MyStructs.swift
//  JLinesV2
//
//  Created by Jozsef Romhanyi on 18.04.15.
//  Copyright (c) 2015 Jozsef Romhanyi. All rights reserved.
//

import UIKit
import GameKit
import RealmSwift
import AVFoundation


//enum Choosed: Int{
//    case Unknown = 0, Right, Left, Settings, Restart
//}
//enum GameControll: Int {
//    case Finger = 0, JoyStick, Accelerometer, PipeLine
//}
//
struct GV {
    static var vBounds = CGRect(x: 0, y: 0, width: 0, height: 0)
    static var notificationCenter = NotificationCenter.default
    static var mainScene: CardGameScene?
    static let freeGameCount = 1000
    static var peerToPeerService: P2PHelper?
//    static let peerToPeerVersion = "1.0" // 2017-06-21
//    static let peerToPeerVersion = "1.1" // 2017-09-01
    static let peerToPeerVersion = "1.2" // 2017-12-11
    static var dX: CGFloat = 0
    static var speed: CGSize = CGSize.zero
    static var touchPoint = CGPoint.zero
    static var gameSize = 5
    static var gameNr = 0
    static var gameSizeMultiplier: CGFloat = 1.0
    static let onIpad = UIDevice.current.model.hasSuffix("iPad")
    static var ipadKorrektur: CGFloat = 0
    static var levelsForPlay = LevelsForPlayWithCards()
    static var mainViewController: UIViewController?
    static let language = Language()
    static var showHelpLines = 0
    static var dummyName = GV.language.getText(.tcGuest)
    static var initName = false
    static let oneGrad:CGFloat = CGFloat(Double.pi) / 180
    static let timeOut = "TimeOut"
    static let IAmBusy = "Busy"
    static let IAmPlaying = "Playing"
    static var appName: String = ""
    static var versionsNumber: String = ""
    static var buildNumber: String = ""
    static var deviceSessionID: String = ""
    static let maxPackageCount = 4
    static var gkPlayers: [String:GKPlayer] = [:]
    static var separator = "°"
    
    


//    static let dataStore = DataStore()
//    static let cloudStore = CloudData()
    
    static let deviceType = UIDevice.current.modelName
    
    
    
//    static let deviceConstants = DeviceConstants(deviceType: UIDevice.current.modelName)

    static var countPlayers: Int = 1

    static var player: PlayerModel?
    static var actGame: GameModel?
    
    static func pointOfCircle(_ radius: CGFloat, center: CGPoint, angle: CGFloat) -> CGPoint {
        let pointOfCircle = CGPoint (x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        return pointOfCircle
    }
    
    enum RealmRecordType: Int {
        case gameModel, playerModel, statisticModel, highScoreModel
    }
    
    static func createNewRecordID(_ recordType: RealmRecordType)->Int {
        var recordID: RecordIDModel
        var ID = 0
        let inWrite = realm.isInWriteTransaction
        if !inWrite {
            realm.beginWrite()
        }
        if realm.objects(RecordIDModel.self).count == 0 {
            recordID = RecordIDModel()
            realm.add(recordID)
        } else  {
            recordID = realm.objects(RecordIDModel.self).first!
        }
//        #if REALM_V2
            switch recordType {
            case .gameModel:
                ID = recordID.gameModelID
                recordID.gameModelID += 1
            case .playerModel:
                ID = recordID.playerModelID
                recordID.playerModelID += 1
            case .statisticModel:
                ID = recordID.statisticModelID
                recordID.statisticModelID += 1
            case RealmRecordType.highScoreModel:
                ID = recordID.highScoreModelID
                recordID.highScoreModelID += 1
           }
//        #else
//            switch recordType {
//            case .gameModel:
//                ID = recordID.gameModelID
//                recordID.gameModelID += 1
//            case .playerModel:
//                ID = recordID.playerModelID
//                recordID.playerModelID += 1
//            case .statisticModel:
//                ID = recordID.statisticModelID
//                recordID.statisticModelID += 1
//            }
//        #endif
        if !inWrite {
            try! realm.commitWrite()
        }
        return ID
    }
    
    static func createNewPlayer(_ isActPlayer: Bool...)->Int {
//        let newID = GV.playerID.getNewID()!
        let newID = GV.createNewRecordID(.playerModel)
//        if newID != 0 {
            let newPlayer = PlayerModel()
            newPlayer.aktLanguageKey = GV.language.getPreferredLanguage()
            newPlayer.name = GV.language.getText(.tcAnonym)
            newPlayer.isActPlayer = isActPlayer.count == 0 ? false : isActPlayer[0]
            newPlayer.ID = newID
            try! realm.write({
                realm.add(newPlayer)
            })
//        }
        return newID
    }
    
    static func createNewHighScore(packageNr: Int, levelID: Int) {
        let allRecords = realm.objects(GameModel.self).filter("levelID = %d and countPackages = %d", levelID, packageNr)
        var myHighScore = 0
        var sent = true
        if allRecords.count > 0 {
            myHighScore = allRecords.max(ofProperty: "playerScore")!
            sent = false  
        }
        let newHighScore = HighScoreModel()
        newHighScore.ID = GV.createNewRecordID(.highScoreModel)
        newHighScore.levelID = levelID
        newHighScore.countPackages = packageNr
        newHighScore.myHighScore = myHighScore
        newHighScore.sentToGameCenter = sent
        newHighScore.bestPlayerName = ""
        newHighScore.bestPlayerHighScore = 0
        newHighScore.created = Date()
        try! realm.write({
            realm.add(newHighScore)
        })
    }
    
    static func randomNumber(_ max: Int)->Int
    {
        let randomNumber = Int(arc4random_uniform(UInt32(max)))
        return randomNumber
    }

}

struct Names {
    var name: String
    var isActPlayer: Bool
    init() {
        name = ""
        isActPlayer = false
    }
    init(name:String, isActPlayer: Bool){
        self.name = name
        self.isActPlayer = isActPlayer
    }
}


struct GameParamStruct {
    var isActPlayer: Bool
    var nameID: Int
    var name: String
    var aktLanguageKey: String
    var levelIndex: Int
    var gameScore: Int
//    var gameModus: Int
    var soundVolume: Float
    var musicVolume: Float
    
    init() {
        nameID = GV.countPlayers
        isActPlayer = false
        name = GV.dummyName
        aktLanguageKey = GV.language.getAktLanguageKey()
        levelIndex = 0
        gameScore = 0
//        gameModus = GameModusCards
        soundVolume = 0.1
        musicVolume = 0.1
    }
    
}


enum DeviceTypes: Int {
    case iPadPro12_9 = 0, iPadPro9_7, iPad2, iPadMini, iPhone6Plus, iPhone6, iPhone5, iPhone4, none
}

struct ColumnRow {
    var column: Int
    var row: Int
    init () {
        column = NoValue
        row = NoValue
    }
    init(column: Int, row:Int) {
        self.column = column
        self.row = row
        
    }
}
struct FromToColumnRow {
    var fromColumnRow: ColumnRow
    var toColumnRow: ColumnRow
    
    init() {
        fromColumnRow = ColumnRow()
        toColumnRow = ColumnRow()
    }
    init(fromColumnRow: ColumnRow, toColumnRow: ColumnRow ) {
        self.fromColumnRow = fromColumnRow
        self.toColumnRow = toColumnRow
    }
}
func == (left: ColumnRow, right: ColumnRow)->Bool {
    return left.column == right.column && left.row == right.row
}
func == (left: FromToColumnRow, right: FromToColumnRow)->Bool {
    return left.fromColumnRow == right.fromColumnRow && left.toColumnRow == right.toColumnRow
}

func != (left: FromToColumnRow, right: FromToColumnRow)->Bool {
    return !(left == right)
}


infix operator ~>
private let queue = DispatchQueue(label: "serial-worker", attributes: [])

func ~> (backgroundClosure: @escaping () -> (),
    mainClosure: @escaping () -> ())
    
{
    queue.async {
        backgroundClosure()
        DispatchQueue.main.async(execute: mainClosure)
        
    }
}

func + (left: CGSize, right: CGSize) -> CGSize {
    return CGSize(width: left.width + right.width, height: left.height + right.height)
}

func - (left: CGSize, right: CGSize) -> CGSize {
    return CGSize(width: left.width - right.width, height: left.height - right.height)
}

func * (point: CGSize, scalar: CGFloat) -> CGSize {
    return CGSize(width: point.width * scalar, height: point.height * scalar)
}

func / (point: CGSize, scalar: CGFloat) -> CGSize {
    return CGSize(width: point.width / scalar, height: point.height / scalar)
}



func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif


extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

//struct PhysicsCategory {
//    static let None         : UInt32 = 0
//    static let All          : UInt32 = UInt32.max
//    static let Sprite       : UInt32 = 0b1      // 1
//    static let Container    : UInt32 = 0b10       // 2
//    static let MovingSprite : UInt32 = 0b100     // 4
//    static let WallAround   : UInt32 = 0b1000     // 8
//}
//
struct MyNodeTypes {
    static let none:            UInt32 = 0
    static let MyGameScene:     UInt32 = 0b1        // 1
    static let LabelNode:       UInt32 = 0b10       // 2
    static let CardNode:        UInt32 = 0b100      // 4
    static let ContainerNode:   UInt32 = 0b1000     // 8
    static let ButtonNode:      UInt32 = 0b10000    // 16
}

struct Container {
    let mySKNode: MySKCard
    //    var label: SKLabelNode
    //    var countHits: Int
}

enum CardStatusInStack: Int, CustomStringConvertible {
    case added = 0, addedFromCardStack/*, addedFromShowCard*/, movingStarted, unification, mirrored, firstCardAdded, removed, stopCycle, nothing
    
    var statusName: String {
        let statusNames = [
            "Added",
            "AddedFromCardStack",
            "AddedFromShowCard",
            "MovingStarted",
            "Unification",
            "Mirrored",
            "Removed",
            "Exchanged",
            "Nothing"
        ]
        
        return statusNames[rawValue]
    }
    
    var description: String {
        return statusName
    }
    
}

public enum CommunicationCommands: Int {
    case errorValue = 0,
    myNameIs,
            //
            //      parameters: 1 - myName
    myNameIsChanged,
    //
    //      parameters: 1 - myName
    //                  2 - oldName
    //                  2 - deviceName
    iWantToPlayWithYou, //sendMessage
            //
            //      parameters: 1 - myName
            //                  2 - PeerToPeerVersion
            //                  3 - levelID
            //                  4 - countPackages
            //                  5 - gameNumber to play
            //                  6 - Device Type
            //      answer: "OK" - play starts
            //              "LevelTooHigh" - for opponent is this level vorbidden
            //              "Cancel" - opponent will not play
    myScoreHasChanged, // sendInfo
            //
            //      parameters: 1 - Score
            //                  2 - Count Cards
    gameIsFinished, //sendInfo
            //
            //      parameters: 1: Score
            //                  2: TimeBonus
            //                  3: Total Score
    didEnterBackGround, // sendInfo
            //
            //      parameter:
    stopCompetition, // sendInfo
            //
            //      parameter:
    myStatusIsFree,
    //
    //      parameters: -
    
    myStatusIsPlaying,
    //
    //      parameters: 1 - opponentName
    startGame,
    //
    //      parameters: 1 - myName
    //                  2 - countPackages
    //                  3 - levelIndex
    //                  4 - gameNumber
    

    maxValue
    
    var commandName: String {
        return String(self.rawValue)
    }
    
    static func decodeCommand(_ commandName: String)->CommunicationCommands {
        if let command = Int(commandName) {
            if command < CommunicationCommands.maxValue.rawValue && command > CommunicationCommands.errorValue.rawValue {
                return CommunicationCommands(rawValue: command)!
            } else {
                return errorValue
            }
        } else {
            return errorValue
        }
    }
    
    
}



struct SavedCard {
    var card: MySKCard? = nil
    var status: CardStatusInStack = .added
    var type: MySKCardType = .cardType
    var name: String = ""
    //    var type: MySKNodeType
    var startPosition: CGPoint = CGPoint(x: 0, y: 0)
    var endPosition: CGPoint = CGPoint(x: 0, y: 0)
    var colorIndex: Int = 0
    var size: CGSize = CGSize(width: 0, height: 0)
    var countScore: Int = 0 // Score of Game 
    var minValue: Int = NoValue
    var maxValue: Int = NoValue
    var BGPictureAdded = false
    var countTransitions = 0
    var column: Int = 0
    var row: Int = 0
}


enum LinePosition: Int, CustomStringConvertible {
    case upperHorizontal = 0, rightVertical, bottomHorizontal, leftVertical
    var linePositionName: String {
        let linePositionNames = [
            "UH",
            "RV",
            "BH",
            "LV"
        ]
        return linePositionNames[rawValue]
    }
    
    var description: String {
        return linePositionName
    }
    
}

func sleep(_ sleepTime: Double) {
    var count = 0
    let actTime = Date()
    while Date().timeIntervalSince(actTime) < sleepTime {
        count += 1
    }
}

func stringArrayToNSData(_ array: [String]) -> Data {
    let data = NSMutableData()
    let terminator = [0]
    for string in array {
        if let encodedString = string.data(using: String.Encoding.utf8) {
            data.append(encodedString)
            data.append(terminator, length: 1)
        }
        else {
            NSLog("Cannot encode string \"\(string)\"")
        }
    }
    return data as Data
}



let atlas = SKTextureAtlas(named: "sprites")

@objc protocol SettingsDelegate {
    func settingsDelegateFunc()
}

//protocol JGXLineDelegate {
//    func findColumnRowDelegateFunc(fromPoint:CGPoint, toPoint:CGPoint)->FromToColumnRow
//}
