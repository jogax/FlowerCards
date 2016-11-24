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
    static var mainScene: SKScene?
    static let freeGameCount = 1000
    static var peerToPeerService: PeerToPeerServiceManager?

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
    static let oneGrad:CGFloat = CGFloat(M_PI) / 180
    static let timeOut = "TimeOut"
    static let IAmBusy = "Busy"

//    static let dataStore = DataStore()
//    static let cloudStore = CloudData()
    
    static let deviceType = UIDevice.current.modelName
    
    
    
//    static let deviceConstants = DeviceConstants(deviceType: UIDevice.current.modelName)

    static var countPlayers: Int = 1

    static var player: PlayerModel?
    
    static func pointOfCircle(_ radius: CGFloat, center: CGPoint, angle: CGFloat) -> CGPoint {
        let pointOfCircle = CGPoint (x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        return pointOfCircle
    }
    
    enum RealmRecordType: Int {
        case gameModel, playerModel, statisticModel
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
        }
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

/*
struct DeviceConstants {
//    var sizeMultiplier: CGFloat
//    var buttonSizeMultiplier: CGFloat
//    var cardPositionMultiplier: CGFloat
//    var fontSizeMultiplier: CGFloat
//    var imageSizeMultiplier: CGFloat
//    var type: DeviceTypes
    
    init(deviceType: String) {
        switch deviceType {
            case "iPad Pro":
//                sizeMultiplier = 2.2
//                buttonSizeMultiplier = 1.0
//                cardPositionMultiplier = 1.0
//                fontSizeMultiplier = 0.10
//                imageSizeMultiplier = 1.0
//                type = .iPadPro12_9
            case "iPad6,3":
//                sizeMultiplier = 1.6
//                buttonSizeMultiplier = 1.2
//                cardPositionMultiplier = 1.0
//                fontSizeMultiplier = 0.20
//                imageSizeMultiplier = 1.3
                type = .iPadPro9_7
            case "iPad 2", "iPad 3", "iPad 4", "iPad Air", "iPad Air 2":
//                sizeMultiplier = 1.6
//                buttonSizeMultiplier = 1.2
//                cardPositionMultiplier = 1.0
//                fontSizeMultiplier = 0.20
//                imageSizeMultiplier = 1.3
                type = .iPad2
            case "iPad Mini", "iPad Mini 2", "iPad Mini 3", "iPad Mini 4":
//                sizeMultiplier = 1.6
//                buttonSizeMultiplier = 1.2
//                cardPositionMultiplier = 1.0
//                fontSizeMultiplier = 0.20
//                imageSizeMultiplier = 1.3
                type = .iPadMini
            case "iPhone 6 Plus", "iPhone 6s Plus":
//                sizeMultiplier = 1.0
//                buttonSizeMultiplier = 1.8
//                cardPositionMultiplier = 1.4
//                fontSizeMultiplier = 0.20
//                imageSizeMultiplier = 1.0
                type = .iPhone6Plus
            case "iPhone 6", "iPhone 6s":
//                sizeMultiplier = 1.0
//                buttonSizeMultiplier = 2.0
//                cardPositionMultiplier = 1.4
//                fontSizeMultiplier = 0.20
//                imageSizeMultiplier = 0.8
                type = .iPhone6
            case "iPhone 5s", "iPhone 5", "iPhone 5c":
//                sizeMultiplier = 0.8
//                buttonSizeMultiplier = 2.1
//                cardPositionMultiplier = 1.3
//                fontSizeMultiplier = 0.20
//                imageSizeMultiplier = 0.7
                type = .iPhone5
            case "iPhone 4s", "iPhone 4":
//                sizeMultiplier = 0.8
//                buttonSizeMultiplier = 2.0
//                cardPositionMultiplier = 1.1
//                fontSizeMultiplier = 0.10
//                imageSizeMultiplier = 0.7
                type = .iPhone4
           default:
//                sizeMultiplier = 1.0
//                buttonSizeMultiplier = 1.0
//                cardPositionMultiplier = 1.0
//                fontSizeMultiplier = 1.0
//                imageSizeMultiplier = 1.0
                type = .none
        }
        
    }
    
}
*/
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

enum CardStatus: Int, CustomStringConvertible {
    case added = 0, addedFromCardStack, addedFromShowCard, movingStarted, unification, mirrored, fallingMovingCard, fallingCard, hitcounterChanged, firstCardAdded, removed, stopCycle, nothing
    
    var statusName: String {
        let statusNames = [
            "Added",
            "AddedFromCardStack",
            "AddedFromShowCard",
            "MovingStarted",
            "Unification",
            "Mirrored",
            "FallingMovingCard",
            "FallingCard",
            "HitcounterChanged",
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

enum PeerToPeerCommands: Int {
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
            //                  2 - levelID
            //                  3 - gameNumber to play
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
    didEnterBackGround, // sendInfo
            //
            //      parameter:  
    stopCompetition, // sendInfo
            //
            //      parameter:
    maxValue
    
    var commandName: String {
        return String(self.rawValue)
    }
    
    static func decodeCommand(_ commandName: String)->PeerToPeerCommands {
        if let command = Int(commandName) {
            if command < PeerToPeerCommands.maxValue.rawValue && command > PeerToPeerCommands.errorValue.rawValue {
                return PeerToPeerCommands(rawValue: command)!
            } else {
                return errorValue
            }
        } else {
            return errorValue
        }
    }
    
    
}



struct SavedCard {
    var status: CardStatus = .added
    var type: MySKCardType = .cardType
    var name: String = ""
    //    var type: MySKNodeType
    var startPosition: CGPoint = CGPoint(x: 0, y: 0)
    var endPosition: CGPoint = CGPoint(x: 0, y: 0)
    var colorIndex: Int = 0
    var size: CGSize = CGSize(width: 0, height: 0)
    var hitCounter: Int = 0
    var countScore: Int = 0 // Score of Game 
    var belongsToPackage: Int = 0
    var minValue: Int = NoValue
    var maxValue: Int = NoValue
    var BGPictureAdded = false
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
