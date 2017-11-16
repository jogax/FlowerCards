
//  CardGameScene.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 2015. 11. 26..
//  Copyright © 2015. Jozsef Romhanyi. All rights reserved.
//


import SpriteKit
import AVFoundation
import Foundation
import MultipeerConnectivity
import GameKit
import RealmSwift

struct GameArrayPositions {
    var used: Bool
    var position: CGPoint
    var card: MySKCard
    init() {
        self.used = false
        self.position = CGPoint(x: 0, y: 0)
        self.card = MySKCard()
    }
    init(colorIndex: Int, minValue: Int, maxValue: Int, origValue: Int, card: MySKCard) {
        self.used = false
        self.position = CGPoint(x: 0, y: 0)
        self.card = card
    }
}

struct PairStatus {
    var color: MyColors
    var pair: FromToColumnRow
    var startTime: Date
    var changeTime: Date
    var founded: Founded
    var fixed: Bool
    var points: [CGPoint]
    init() {
        self.color = .none
        self.pair = FromToColumnRow()
        self.startTime = Date()
        self.changeTime = Date()
        self.founded = Founded()
        self.fixed = false
        self.points = [CGPoint]()
    }
    init(color: MyColors, pair: FromToColumnRow, founded: Founded, startTime: Date, points: [CGPoint]) {
        self.color = color
        self.pair = pair
        self.founded = founded
        self.startTime = startTime
        self.changeTime = startTime
        self.fixed = false
        self.points = points
    }
    mutating func setValue(_ color: MyColors, pair: FromToColumnRow, founded: Founded, startTime: Date , points: [CGPoint]) {
        self.color = color
        self.pair = pair
        self.founded = founded
        self.startTime = startTime
        self.changeTime = startTime
        self.fixed = false
        self.points = points
    }
    mutating func setValue(_ color: MyColors) {
        self.color = color
    }
    
    
}
struct ColorTabLine {
    var colorIndex: Int
    var cardName: String
    var cardValue: Int
    init(colorIndex: Int, cardName: String){
        self.colorIndex = colorIndex
        self.cardName = cardName
        self.cardValue = 0
    }
    init(colorIndex: Int, cardName: String, cardValue: Int){
        self.colorIndex = colorIndex
        self.cardName = cardName
        self.cardValue = cardValue
    }
}


enum Colors: Int {
    case purple = 0, blue, green, red
}

enum MyColors: Int {
    case none = 0, red, green, yellow
}



struct DrawHelpLinesParameters {
    var points: [CGPoint]
    var lineWidth: CGFloat
    var twoArrows: Bool
    var color: MyColors
    var scores: Int
    
    init() {
        points = [CGPoint]()
        lineWidth = 0
        twoArrows = false
        color = .red
        scores = 0
    }
}


enum ShowHelpLine: Int {
    case green = 0, cyan, hidden
}


// Global Variable and Constants
let countContainers = 4
var countColumns = 0
var countRows = 0
var gameArray = [[GameArrayPositions]]()
var containers = [MySKCard]()
var cardStack:Stack<MySKCard> = Stack()
var stack:Stack<SavedCard> = Stack()
var lastChange = (color: NoColor, toContainer: false)
var countPackages = 1
var random: MyRandom?
//var actGame: GameModel?
let MaxGameNumber = 10000
var lastUsedTipp: Tipp?
let myBuildVersion = GV.buildNumber + "/" + GV.versionsNumber
var cardTabRect = CGRect.zero

enum GCEnabledType: Int {
    case AskForGameCenter = 0, GameCenterEnabled, GameCenterSupressed
}




var lastPair = PairStatus() {
    didSet {
        if oldValue.color != lastPair.color {
            lastPair.startTime = Date()
            lastPair.changeTime = lastPair.startTime
        }
    }
}

class CardGameScene: SKScene, SKPhysicsContactDelegate, AVAudioPlayerDelegate, PeerToPeerServiceManagerDelegate, GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate, GKMatchDelegate {
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    
    struct Opponent {
        enum FinishType: Int {
            case none = 0, finished, interrupted
        }
        var peerID: MCPeerID?
        var ID = 0
        var name: String = ""
        var score: Int = 0
        var cardCount: Int = 0
        var finish: FinishType = .none
    }
    
    
    enum CongratulationsType: Int {
        case No = 0, Won, Lost
    }
    enum PlayerType: Int {
        case singlePlayer = 0, multiPlayer, bestPlayer
    }
    
    enum CardGeneratingType: Int {
        case first = 0, normal
    }
    
    enum ButtonPos: Int {
        case NoValue = 0, SettingsButtonPos, StartButtonPos, CardCountPos, HelpButtonPos, TippButtonPos, UndoButtonPos
    }
    
    struct GenerateCard {
        var cardValue: Int
        var packageNr: Int
        var used: Bool
        init() {
            cardValue = 0
            packageNr = 0
            used      = false
        }
    }
    
    func calculateLen(points: [CGPoint]) -> CGFloat{
        var len: CGFloat = 0
        if points.count > 1 {
            for index in 0..<points.count - 1 {
                len += (points[index] - points[index + 1]).length()
            }
        }
        return len
    }
    

    
    let answerYes = "YES"
    let answerNo = "NO"
    let peerToPeerVersionOfOpponentIsLower = "LOWER"
    let peerToPeerVersionOfOpponentIsHigher = "HIGHER"
    
    let showTippSleepTime = 30.0
    let doCountUpSleepTime = 1.0
    let showTippsFreeCount = 3
    let freeAmount = 3
    let penalty = 25
    
    var scoreFactor: Double = 0
    var scoreTime: Double = 0 // Minutes
    
//    let showTippSelector = "showTipp"
    let doCountUpSelector = "showTime"
    let checkGreenLineSelector = "setGreenLineSize"
    let fingerName = "finger"
    let settingsButtonName = "settings"
    let restartButtonName = "restart"
    let undoButtonName = "undo"
    let helpButtonName = "help"

    
    let emptyCardTxt = "emptycard"
    var movingCards: [MySKCard] = []
    
//    var cardStack:Stack<MySKCard> = Stack()
//    var showCardStack:Stack<MySKCard> = Stack()
    var tippCountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    var cardPackage: MySKButton?
    var cardPlaceButton: MySKButton?
    var tippsButton: MySKButton?
    
    var cardPlaceButtonAddedToParent = false
    var cardToChange: MySKCard?
    
    var showCard: MySKCard?
    var showCardFromStack: MySKCard?
    var showCardFromStackAddedToParent = false
    var backGroundOperation = Operation()


    var lastCollisionsTime = Date()
    var cardArray: [[GenerateCard]] = []
//    var valueTab = [Int]()
    let nextLevel = true
    let previousLevel = false
//    let maxLevelForiPhone = GV.levelsForPlay.getLastLevelWithColumnCount(maxColumnCount: 7)

    var lastUpdateSec = 0
//    var lastNextPoint: Founded?
    var generatingTipps = false
//    var tippArray = [Tipps]()
//    var tippIndex = 0
    
//    var showTippAtTimer: NSTimer?
    var dummy = 0
    
    var labelFontSize = CGFloat(0)
    
//    var tremblingCards: [MySKCard] = []
    // Values from json File
    var params = ""
    var countCardsProContainer: Int?
//    var showHelpLines: ShowHelpLine = .green
    let maxColumnForiPhone = 6
    var targetScoreKorr: Int = 0
    var tableCellSize: CGFloat = 0
    var cardSizeMultiplier: CGSize = CGSize(width: 1, height: 1)
    var containerSize:CGSize = CGSize(width: 0, height: 0)
//    var cardSize:CGSize = CGSize(width: 0, height: 0)
    var minUsedCells = 0
    var maxUsedCells = 0
    var gameNumber = 0
    
    var scoreModifyer = 0
    var showTippCounter = 0
//    var mirroredScore = 0
    
    var touchesBeganAt: Date?
    
    let containerSizeOrig: CGFloat = 40
    
    var showFingerNode = false
//    var countMovingCards = 0
    var countCheckCounts = 0
    var freeUndoCounter = 0
    var freeTippCounter = 0

    var countUpTimer: Timer?
    var greenLineTimer: Timer?
    var waitForSKActionEndedTimer: Timer?
    var waitWhileInGeneratingCardsTimer: Timer?
    var lastMirrored = ""
    var musicPlayer: AVAudioPlayer?
    var soundPlayer: AVAudioPlayer?
    var soundPlayerArray = [AVAudioPlayer?](repeating: nil, count: 5)
    var myView = SKView()
    var levelIndex = GV.player!.levelID
    var maxLevelIndex = 0
    //var gameArray = [[Bool]]() // true if Cell used
    var colorTab = [ColorTabLine]()
    var countColorsProContainer = [Int]()
    var labelBackground = SKSpriteNode()
    let labelRowCorr = CGFloat(0.1)
    let countLabelRows = CGFloat(4.0)
//    var MaxCountGamesToPlayInARound = 1
//    var countGamesToPlay = 0
    var inTouches = false
    
    var gameNumberLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var sizeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var packageLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    var whoIsHeaderLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var playerHeaderLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var timeHeaderLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var scoreHeaderLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var cardCountHeaderLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    var whoIsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var playerNameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var playerTimeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var playerScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var playerCardCountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    var opponentTypeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var opponentNameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var opponentTimeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var opponentScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var opponentCardCountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    var allGamesLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var onePkgLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var twoPkgLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var threePkgLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var fourPkgLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    var cardCountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var settingsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var startLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var helpLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var tippLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var undoLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    var bestPlaceLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var myPlaceLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    

    
    
//    var showScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
//    var opponentScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    
//    var gameScore = GV.player!.gameScore
    var levelScore: Int = 0 {
        didSet {
            showLevelScore()
            if playerType == .multiPlayer {
                GV.peerToPeerService!.sendInfo(.myScoreHasChanged, message: [String(levelScore), String(cardCount)], toPeer: opponent.peerID!)
            }
        }
    }
    
    var highScore: Int = 0
    var timeBonus: Int = 0
    
    var timeCount: Int = 0  { // seconds
        didSet {
            showLevelScore()
        }
    }
    var movedFromNode: MySKCard!
    var settingsButton: MySKButton?
    var undoButton: MySKButton?
    var helpButton: MySKButton?
    var restartButton: MySKButton?
    var exchangeButton: MySKButton?
    var nextLevelButton: MySKButton?
    var targetScore = 0
    var maxCardCount = 0
    var gameCenterSync = GameCenter()

    var cardCount = 0 {
        didSet {
            if playerType == .multiPlayer {
                GV.peerToPeerService!.sendInfo(.myScoreHasChanged, message: [String(levelScore), String(cardCount)], new: false, toPeer: opponent.peerID!)
            }
        }
    }


    //var restartCount = 0
    var stopped = true
//    var collisionActive = false
    var bgImage: SKSpriteNode?
    var bgAdder: CGFloat = 0
    let maxHelpLinesCount = 4
    //    var undoCount = 0
    var inFirstGeneratecards = false
    var lastShownNode: MySKCard?
//    var parentViewController: UIViewController?
    var settingsSceneStarted = false
    var settingsDelegate: SettingsDelegate?
    //var settingsNode = SettingsNode()
    var gameDifficulty: Int = 0
    
    var buttonField: SKSpriteNode?
    //var levelArray = [Level]()
    var countLostGames = 0
    var lineUH: JGXLine?
    var lineLV: JGXLine?
    var lineRV: JGXLine?
    var lineBH: JGXLine?
    
//    var lastGreenPair: PairStatus?
//    var lastRedPair: PairStatus?
//    var lastPair = PairStatus() {
//        didSet {
//            if oldValue.color != lastPair.color {
//                lastPair.startTime = Date()
//                lastPair.changeTime = lastPair.startTime
//            }
//        }
//    }
    
//    var lastDrawHelpLinesParameters = DrawHelpLinesParameters()

    
    var actPair: PairStatus?
    var oldFromToColumnRow: FromToColumnRow?
    
    var buttonSize = CGFloat(0)
    var buttonYPos = CGFloat(0)
    var buttonXPosNormalized = CGFloat(0)
    let images = DrawImages()
    
//    var panel: MySKPanel?
//    var countUpAdder = 0
    
    var doTimeCount: Bool = false
    
    
    var playerType: PlayerType = .singlePlayer
    var opponent = Opponent()
    var startGetNextPlayArt = false
    var restartGame: Bool = false
    var inSettings: Bool = false
    var inGeneratingCards: Bool = false
    var receivedMessage: [String] = []

    
    var gameArrayChanged = false {
        didSet {
//            startCreateTippsInBackground()
        }
    }
    
    var tapLocation: CGPoint?
    let qualityOfServiceClass = DispatchQoS.QoSClass.background
    let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
    let playMusicForever = -1
    
    var whoIsPos = 0
    var scorePos = 0
    
    var autoPlayerActive = false
    var autoPlayer: AutoPlayer?
    var replaying = false
    var durationMultiplier = 0.001
    let durationMultiplierForPlayer = 0.001
    let durationMultiplierForAutoplayer = 0.001 //0.000001
    var waitForStartConst = 0.1
    let waitForStartForPlayer = 0.1
    let waitForStartForAutoplayer = 0.001
    var cardManager: CardManager?
    
    override func didMove(to view: SKView) {
        
        if !settingsSceneStarted {
            if realm.objects(HighScoreModel.self).count < GV.maxPackageCount * GV.levelsForPlay.count() {
                for packageNr in 1...GV.maxPackageCount {
                    for levelID in 0..<GV.levelsForPlay.count() {
                        if realm.objects(HighScoreModel.self).filter("levelID = %d and countPackages = %d", levelID, packageNr).count == 0 {
                            GV.createNewHighScore(packageNr: packageNr, levelID: levelID)
                        }
                    }
                }
            }

//            startSyncWithGameCenter() --
            myView = view
            GV.mainScene = self
            
            GV.peerToPeerService!.delegate = self
            let width:CGFloat = 64.0
            let height: CGFloat = 89.0
            let sizeMultiplierConstant = CGFloat(0.0020)
            levelIndex = GV.player!.levelID
            

            cardSizeMultiplier = CGSize(width: self.size.width * sizeMultiplierConstant,
                                    height: self.size.width * sizeMultiplierConstant * height / width)

            

            GV.levelsForPlay.setAktLevel(levelIndex)
            
            let buttonSizeMultiplierConstant = CGFloat(GV.onIpad ? 10 : 8)
            buttonSize = self.size.width / buttonSizeMultiplierConstant
            buttonYPos = self.size.height * 0.09
            buttonXPosNormalized = self.size.width / 10
            self.name = "CardGameScene"
            prepareNextGame(newGame: true)
            generateCards(generatingType: .first)
            autoPlayer = AutoPlayer(scene: self)
            let copyRight = "Copyright \u{00A9} 2017 " + GV.appName + "(Ver:" + GV.versionsNumber + " / Build:" + GV.buildNumber + ")"
            let copyrightLabel = SKLabelNode(fontNamed: "ArialMT")
            copyrightLabel.color = UIColor.white
            copyrightLabel.text = copyRight
            copyrightLabel.fontSize = self.frame.size.height * 0.01
            let yPosCorrection: CGFloat = GV.deviceType == iPhone_X ? 15 : 0
            copyrightLabel.position = CGPoint(x: self.frame.minX + (copyrightLabel.frame.size.width / 2) * 1.15, y: self.frame.minY + (copyrightLabel.frame.size.height / 2) * 1.03 + yPosCorrection)
           
            self.addChild(copyrightLabel)
            switch GV.player!.GCEnabled {
                case GCEnabledType.GameCenterEnabled.rawValue:
                    if !GKLocalPlayer.localPlayer().isAuthenticated {
                        authenticateLocalPlayer()
                    }
//                    if GKLocalPlayer.localPlayer().isAuthenticated {
//                        gameCenterSync.startGameCenterSync()
//                    } else {
//                        // when not authenticated, set to GC Not enabled
//                        realm.beginWrite()
//                        GV.player!.GCEnabled = GCEnabledType.AskForGameCenter.rawValue
//                        try! realm.commitWrite()
//                    }
                case GCEnabledType.AskForGameCenter.rawValue:
                    let alert = UIAlertController(title: GV.language.getText(.tcAskForGameCenter),
                                                  message: "",
                                                  preferredStyle: .alert)
                    let connectAction = UIAlertAction(title: GV.language.getText(.tcConnectGC), style: .default,
                                                       handler: {(paramAction:UIAlertAction!) in
                                                        self.connectToGameCenter()
                        })
                    
                    alert.addAction(connectAction)
                    
                    let askLaterAction = UIAlertAction(title: GV.language.getText(.tcAskLater), style: .default,
                                                      handler: {(paramAction:UIAlertAction!) in
                    })
                    
                    alert.addAction(askLaterAction)
                    let askNoMoreAction = UIAlertAction(title: GV.language.getText(.tcAskNoMore), style: .default,
                                                       handler: {(paramAction:UIAlertAction!) in
                                                        try! realm.write({
                                                                GV.player!.GCEnabled = GCEnabledType.GameCenterSupressed.rawValue
                                                        })
                    })
                    
                    alert.addAction(askNoMoreAction)
                    myAlert = alert
                    waitForShow()
                default:
                    break
                
            }
        } else {
            playMusic("MyMusic", volume: GV.player!.musicVolume, loops: playMusicForever)
            
        }
//        //printFunc(function: "didMove", start: false)
    }
    
    var myAlert: UIAlertController?
    @objc func waitForShow() {
        if movingCards.count > 0 {
            _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(waitForShow), userInfo: nil, repeats: false)
        } else {
            GV.mainViewController!.showAlert(myAlert!)
        }
    }
    
    
    func printHighScoreModel() {
        let sortProperties = [SortDescriptor(keyPath: "countPackages", ascending: true), SortDescriptor(keyPath: "levelID", ascending: true)]
        let myHighScores = realm.objects(HighScoreModel.self).sorted(by: sortProperties)
        print ("countPkgs: levelID: myHighScore: bestPlayer:      highScore:")
        print ("---------- -------- ------------ ---------------- ----------")
        for highScoreRecord in myHighScores {
            let actPkg = "    \(highScoreRecord.countPackages)     "
            let actLevelInt = (highScoreRecord.levelID < 9 ? "0" : "") + "\(highScoreRecord.levelID + 1)"
            let actLevel = "    \(actLevelInt)  "
            var myScoreString = String(highScoreRecord.myHighScore)
            while myScoreString.length < 8 {
                myScoreString = " " + myScoreString
            }
            var bestPlayerString = "  " + String(highScoreRecord.bestPlayerName)
            while bestPlayerString.length < 16 {
                bestPlayerString += " "
            }
            var bestScoreString = String(highScoreRecord.bestPlayerHighScore) + "  "
            while bestScoreString.length < 10 {
                bestScoreString = " " + bestScoreString
            }
            let printString = actPkg + " " + actLevel + " " + myScoreString + " " + bestPlayerString + " " + bestScoreString
            print(printString)
        }
    }
    
    func prepareNextGame(newGame: Bool) {
        labelFontSize = GV.onIpad ? self.size.height / 50 : self.size.height / 70
        lastChange.color = NoColor
        lastChange.toContainer = false
        durationMultiplier = durationMultiplierForPlayer
        waitForStartConst = waitForStartForPlayer
        supressedTipps.removeAll()
        levelIndex = GV.player!.levelID
        if GV.player!.countPackages > GV.maxPackageCount {
            realm.beginWrite()
            GV.player!.countPackages = GV.maxPackageCount
            try! realm.commitWrite()
        }
        countPackages = GV.player!.countPackages
        GV.levelsForPlay.setAktLevel(levelIndex)
        specialPrepareFuncFirst()
        if newGame {
            gameNumber = randomGameNumber()
            createGameRecord(gameNumber: gameNumber)
        } else {
            getGameRecord(gameNumber: gameNumber)
        }

        cardManager = CardManager()
        freeUndoCounter = freeAmount
        freeTippCounter = freeAmount
        scoreModifyer = 0
        levelScore = 0
//        countMovingCards = 0
        showTippCounter = showTippsFreeCount

//        GV.statistic = GV.realm.objects(StatisticModel).filter("playerID = %d and levelID = %d", GV.player!.ID, GV.player!.levelID).first
        self.removeAllChildren()
        

        playMusic("MyMusic", volume: GV.player!.musicVolume, loops: playMusicForever)
        stack = Stack()
        timeCount = 0
//        if newGame {
//            gameNumber = randomGameNumber()
//        }
//        createGameRecord(gameNumber)

        if levelIndex < 0 {
            levelIndex = 0
        }
        random = MyRandom(level: levelIndex, gameNumber: gameNumber)
        
        stopTimer(&countUpTimer)
        
        tippArray.removeAll()
        gameArray.removeAll()
        containers.removeAll()
        //undoCount = 3
        
        // fill gameArray

        for _ in 0..<countColumns {
            gameArray.append(Array(repeating: GameArrayPositions(), count: countRows))
        }
        
        // calvulate card Positions
        
        labelBackground.color = UIColor.white
        labelBackground.alpha = 0.7
        let labelBGHeight = CGFloat(countLabelRows) * labelFontSize + labelRowCorr * 100
        if GV.deviceType == iPhone_X {
            labelBackground.position = CGPoint(x: self.size.width / 2, y: self.size.height - labelBGHeight / 2 - 50)
        } else {
            labelBackground.position = CGPoint(x: self.size.width / 2, y: self.size.height - labelBGHeight / 2 - 30)
        }
        labelBackground.size = CGSize(width: self.size.width * 0.95, height: labelBGHeight)
        
      self.addChild(labelBackground)
        
        let tippsTexture = SKTexture(image: images.getTipp())
        tippsButton = MySKButton(texture: tippsTexture, frame: CGRect(x: buttonXPosNormalized * 7.5, y: buttonYPos, width: buttonSize, height: buttonSize))
        tippsButton!.name = "tipps"
        addChild(tippsButton!)
        
        let cardSize = CGSize(width: buttonSize, height: buttonSize * cardSizeMultiplier.height / cardSizeMultiplier.width)
        let cardPackageButtonTexture = SKTexture(image: images.getCardPackage())
        cardPackage = MySKButton(texture: cardPackageButtonTexture, frame: CGRect(x: buttonXPosNormalized * 4.0, y: buttonYPos, width: cardSize.width, height: cardSize.height), makePicture: false)
        cardPackage!.name = "cardPackege"
        addChild(cardPackage!)

        prepareContainers()
        
        prepareCardArray()
        

        for column in 0..<countColumns {
            for row in 0..<countRows {
                gameArray[column][row].position = calculateCardPosition(column, row: row)
            }
        }
        
        if !GV.onIpad {
            calculateCardSizeForIPhone()
        }
        

        showCardFromStack = nil
        
        
        bgImage = setBGImageNode()
        bgAdder = 0.1
        
        bgImage!.position.y = GV.deviceType == iPhone_X ? -592 : 10
        bgImage!.anchorPoint = CGPoint.zero
        bgImage!.zPosition = -15
        self.addChild(bgImage!)
        
        let settingsTexture = SKTexture(image: images.getSettings())
        settingsButton = MySKButton(texture: settingsTexture, frame: CGRect(x: buttonXPosNormalized * 1, y: buttonYPos, width: buttonSize, height: buttonSize))
        settingsButton!.name = settingsButtonName
        addChild(settingsButton!)
        
        let restartTexture = SKTexture(image: images.getRestart())
        restartButton = MySKButton(texture: restartTexture, frame: CGRect(x: buttonXPosNormalized * 2.5, y: buttonYPos, width: buttonSize, height: buttonSize))
        restartButton!.name = restartButtonName
        addChild(restartButton!)
        
        let undoTexture = SKTexture(image: images.getUndo())
        undoButton = MySKButton(texture: undoTexture, frame: CGRect(x: buttonXPosNormalized * 9.0, y: buttonYPos, width: buttonSize, height: buttonSize))
        undoButton!.name = undoButtonName
        addChild(undoButton!)
        
        let helpTexture = atlas.textureNamed("help")
        helpButton = MySKButton(texture: helpTexture, frame: CGRect(x: buttonXPosNormalized * 6.0, y: buttonYPos, width: buttonSize, height: buttonSize))
        helpButton!.name = helpButtonName
        addChild(helpButton!)
        
        
        backgroundColor = UIColor.white //SKColor.whiteColor()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
//        makeLineAroundGameboard(.upperHorizontal)
//        makeLineAroundGameboard(.rightVertical)
//        makeLineAroundGameboard(.bottomHorizontal)
//        makeLineAroundGameboard(.leftVertical)
        makeLinesAroundGameboard(color: GV.deviceType == iPhone_X ? UIColor.white : UIColor.green)
        //        self.inFirstGenerateCards = false
        cardCount = Int(CGFloat(countContainers * countCardsProContainer! * countPackages))
        let cardCountText: String = String(cardStack.count(type: .MySKCardType))
        let tippCountText: String = "\(tippArray.count)"
//        let showScoreText: String = GV.language.getText(.TCGameScore, values: "\(levelScore)")
        let gameNumberText = GV.language.getText(.tcGameNumber) + "\(gameNumber + 1)"
        let size = " \(GV.levelsForPlay.aktLevel.countColumns) x \(GV.levelsForPlay.aktLevel.countRows)"
        let sizeText = GV.language.getText(.tcSize) + size
        let packageText = GV.language.getText(.tcPackage, values: String(countPackages))
        
        let whoIsText = GV.language.getText(.tcWhoIs)
        let whoIsTypeText1 = GV.language.getText(.tcPlayerType)
        let whoIsTypeText2 = GV.language.getText(.tcOpponentType)
        let whoIsLenght = max(whoIsText.length, whoIsTypeText1.length, whoIsTypeText2.length) * 2
        
        let playerHeaderText = GV.language.getText(.tcName)
        let opponentNameText = opponent.name
//        let playerNameLength = max(playerHeaderText.length + 4, playerNameText.length, opponentNameText.length) * 2
        let playerNameLength = (playerHeaderText.length + 4) * 2
        
        let timeHeaderText = GV.language.getText(.tcTime)
        let timeLength = (timeHeaderText.length + 5) * 2
        
        let scoreHeaderText = GV.language.getText(.tcScoreHead)
        let scoreLength = (scoreHeaderText.length + 5) * 2
        
        let gameNumberPos = 10
        let sizePos = gameNumberPos + gameNumberText.length * 2
        let packagePos = sizePos + sizeText.length * 2
        let levelPos = packagePos + packageText.length * 2
        
        whoIsPos = 10
        let playerNamePos = whoIsPos + whoIsLenght
        let timePos = playerNamePos + playerNameLength
        scorePos = timePos + timeLength
        
        
        let cardCountPos = scorePos + scoreLength
        
        let settingsLabelText = GV.language.getText(.tcSettings)
        let startLabelText = GV.language.getText(.tcStart)
        let helpLabelText = GV.language.getText(.tcHelp)
        let tippLabelText = GV.language.getText(.tcTipps)
        let undoLabelText = GV.language.getText(.tcUndo)
        
        
        createLabels(label: gameNumberLabel, text: gameNumberText, row: 1, xPosProzent: gameNumberPos)
        createLabels(label: sizeLabel, text: sizeText, row: 1, xPosProzent: sizePos)
        createLabels(label: packageLabel, text: packageText, row: 1, xPosProzent: packagePos)
        createLabels(label: levelLabel, text: GV.language.getText(.tcLevel) + ": \(levelIndex + 1)", row: 1, xPosProzent: levelPos)
        
        createLabels(label: whoIsHeaderLabel, text: whoIsText, row: 2, xPosProzent: whoIsPos)
        createLabels(label: playerHeaderLabel, text: playerHeaderText, row: 2, xPosProzent: playerNamePos)
        createLabels(label: timeHeaderLabel, text: timeHeaderText, row: 2, xPosProzent: timePos)
        createLabels(label: scoreHeaderLabel, text: scoreHeaderText, row: 2, xPosProzent: scorePos)
        createLabels(label: cardCountHeaderLabel, text: GV.language.getText(.tcCardHead), row: 2, xPosProzent: cardCountPos)

        createLabels(label: whoIsLabel, text: whoIsTypeText1, row: 3, xPosProzent: whoIsPos)
        createLabels(label: playerNameLabel, text: getName(), row: 3, xPosProzent: playerNamePos)
        createLabels(label: playerTimeLabel, text: "0", row: 3, xPosProzent: timePos)
        createLabels(label: playerScoreLabel, text: String(levelScore), row: 3, xPosProzent: scorePos)
        createLabels(label: playerCardCountLabel, text: String(cardCount), row: 3, xPosProzent: cardCountPos)
        
        createLabels(label: settingsLabel, text: settingsLabelText, row: 6, buttonLabel: .SettingsButtonPos)
        createLabels(label: startLabel, text: startLabelText, row: 6, buttonLabel: .StartButtonPos)
        createLabels(label: helpLabel, text: helpLabelText, row: 6, buttonLabel: .HelpButtonPos)
        createLabels(label: tippLabel, text: tippLabelText, row: 6, buttonLabel: .TippButtonPos)
        createLabels(label: undoLabel, text: undoLabelText, row: 6, buttonLabel: .UndoButtonPos)
        
        createLabels(label: cardCountLabel, text: cardCountText, row: 5, buttonLabel: .CardCountPos)
        createLabels(label: tippCountLabel, text: tippCountText, row: 5, buttonLabel: .TippButtonPos)

        if playerType == .multiPlayer {
            createLabels(label: opponentTypeLabel, text: whoIsTypeText2, row: 4, xPosProzent: whoIsPos)
            createLabels(label: opponentNameLabel, text: opponentNameText, row: 4, xPosProzent: playerNamePos)
            createLabels(label: opponentTimeLabel, text: "0", row: 4, xPosProzent: timePos)
            createLabels(label: opponentScoreLabel, text: String(opponent.score), row: 4, xPosProzent: scorePos)
            createLabels(label: opponentCardCountLabel, text: String(opponent.cardCount), row: 4, xPosProzent: cardCountPos)
            
        } else {
            playerType = .singlePlayer
            opponentTypeLabel.isHidden = true
            opponentNameLabel.isHidden = true
            opponentTimeLabel.isHidden = true
            opponentScoreLabel.isHidden = true
            opponentCardCountLabel.isHidden = true
            createLabelsForBestPlace()
// This Code is running if connect to Game Center - therefore is not required here
//            if GV.player!.GCEnabled == GCEnabledType.GameCenterEnabled.rawValue {
//                let (bestPlaceLabelText, myPlaceLabelText) = setRankingLabels()
//                createLabels(label: bestPlaceLabel, text:bestPlaceLabelText, row: 4, xPosProzent: whoIsPos)
//                createLabels(label: myPlaceLabel, text:myPlaceLabelText, row: 4, xPosProzent: scorePos)
//            }

        }

//        #if TEST
//            let pkgSize = 15
//            let allGamesLabelSize = 25
//            let allGamesLabelPos = 10
//            let onePkgLabelPos = allGamesLabelPos + allGamesLabelSize
//            let twoPkgLabelPos = onePkgLabelPos + pkgSize
//            let threePkgLabelPos = twoPkgLabelPos + pkgSize
//            let fourPkgLabelPos = threePkgLabelPos + pkgSize
//            createLabels(label: allGamesLabel, text: GV.language.getText(.tcAllGamesCount,values: "0"), row: 4, xPosProzent: allGamesLabelPos, fontSizeModifier: 0.7)
//            createLabels(label: onePkgLabel, text: GV.language.getText(.tcPkgTxt,values: "1", "0", "0"), row: 4, xPosProzent: onePkgLabelPos, fontSizeModifier: 0.7)
//            createLabels(label: twoPkgLabel, text: GV.language.getText(.tcPkgTxt,values: "2", "0", "0"), row: 4, xPosProzent: twoPkgLabelPos, fontSizeModifier: 0.7)
//            createLabels(label: threePkgLabel, text: GV.language.getText(.tcPkgTxt,values: "3", "0"), row: 4, xPosProzent: threePkgLabelPos, fontSizeModifier: 0.7)
//            createLabels(label: fourPkgLabel, text: GV.language.getText(.tcPkgTxt,values: "4", "0"), row: 4, xPosProzent: fourPkgLabelPos, fontSizeModifier: 0.7)
//            updateGameCountLabels()
//        #endif
        let mySortedPlays = realm.objects(GameModel.self).filter("playerID = %d and played = true", GV.player!.ID).sorted(byKeyPath: "levelID")
        if mySortedPlays.count > 0 {
            maxLevelIndex = mySortedPlays.last!.levelID
        } else {
            maxLevelIndex = 0
        }
        prepareCards()
//        //printFunc(function: "prepareNextGame", start: false)


    }
    
    
    func createGameRecord(gameNumber: Int) {
//        //printFunc(function: "createGameRecord", start: true)

        let gameNew = GameModel()
        gameNew.ID = GV.createNewRecordID(.gameModel)
        gameNew.gameNumber = gameNumber
        gameNew.levelID = levelIndex
        gameNew.playerID = GV.player!.ID
        gameNew.played = false
        gameNew.countPackages = GV.player!.countPackages
        gameNew.countSteps = 0
        try! realm.write() {
            realm.add(gameNew)
        }
        GV.actGame = gameNew
//        //printFunc(function: "createGameRecord", start: false)
    }
    
    func getGameRecord(gameNumber: Int) {
        GV.actGame = realm.objects(GameModel.self).filter("gameNumber = %d and levelID = %d and playerID = %d and countPackages = %d", gameNumber, levelIndex, GV.player!.ID, GV.player!.countPackages).first
        if GV.actGame == nil {
            createGameRecord(gameNumber: gameNumber)
        }
    }
    
    
    
    func createLabels(label: SKLabelNode, text: String, row: Int, xPosProzent: Int = 0, fontSizeModifier: CGFloat = 1, buttonLabel: ButtonPos = .NoValue) {
//        //printFunc(function: "createLabels", start: true)
        
        // values for buttonLabel: NoValue - No Button, 1 - cardPackage, 2 tippsButton
        label.text = text
        label.fontName = "ArialMT"
        let xPos = self.size.width * CGFloat(xPosProzent) * 0.01
        
        if buttonLabel == .NoValue {
            let posAdder = CGFloat(row - 1) * labelFontSize * (1 + labelRowCorr)
            var yPos = CGFloat(labelBackground.position.y - 120 * labelRowCorr)
            yPos += labelBackground.size.height / 2
            yPos -= labelFontSize / 2 + posAdder
            label.position = CGPoint(x: xPos, y: yPos)
            label.fontSize = labelFontSize * fontSizeModifier;
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .baseline
            label.fontColor = SKColor.black
        } else {
            label.fontSize = labelFontSize * (row == 5 ? 1.5 : 1) * fontSizeModifier
            label.fontColor = row == 5 ? UIColor.black : UIColor.white
            switch buttonLabel {
            case .SettingsButtonPos:
                label.position.x = (self.settingsButton?.position.x)!
                label.position.y = (self.settingsButton?.position.y)! - (self.settingsButton?.size.height)! * 0.8
            case .StartButtonPos:
                label.position.x = (self.restartButton?.position.x)!
                label.position.y = (self.restartButton?.position.y)! - (self.restartButton?.size.height)! * 0.8
            case .CardCountPos:
                label.position = self.cardPackage!.position
            case .HelpButtonPos:
                label.position.x = (self.helpButton?.position.x)!
                label.position.y = (self.helpButton?.position.y)! - (self.helpButton?.size.height)! * 0.8
            case .TippButtonPos:
                if row == 5 {
                    label.position = self.tippsButton!.position
                } else {
                    label.position.x = (self.tippsButton?.position.x)!
                    label.position.y = (self.tippsButton?.position.y)! - (self.tippsButton?.size.height)! * 0.8
                }
            case .UndoButtonPos:
                label.position.x = (self.undoButton?.position.x)!
                label.position.y = (self.undoButton?.position.y)! - (self.undoButton?.size.height)! * 0.8
            default: break
            }
//            label.position = (buttonLabel == 1 ? self.cardPackage!.position : self.tippsButton!.position)
            label.zPosition = 5
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
        }
        label.color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.addChild(label)
        //printFunc(function: "createLabels", start: false)
    }
    
    
    
    func showLevelScore() {
        playerScoreLabel.text = String(levelScore)
        playerCardCountLabel.text = String(cardCount)
        if playerType == .multiPlayer {
            opponentScoreLabel.text = String(opponent.score)
            opponentCardCountLabel.text = String(opponent.cardCount)
        }
    }
    


    func getTexture(_ index: Int)->SKTexture {
        //printFunc(function: "getTexture", start: true)
        if index == NoColor {
            //printFunc(function: "getTexture", start: false)
            return atlas.textureNamed("emptycard")
        } else {
            //printFunc(function: "getTexture", start: false)
            return atlas.textureNamed ("card\(index)")
        }
    }
    
    func updateGameCountLabels() {
        let allGameCount = realm.objects(GameModel.self).filter("playerID = %d", GV.player!.ID).count
        var referencePlayerID = NoValue
        var referenceGameCount = 0
        if realm.objects(PlayerModel.self).filter("name = %@", "NewPlayer").count > 0 {
            referencePlayerID = realm.objects(PlayerModel.self).filter("name = %@", "NewPlayer").first!.ID
            referenceGameCount = realm.objects(GameModel.self).filter("playerID = %d", referencePlayerID).count
            let procent = String(Double(100.0 * Double(allGameCount) / Double(referenceGameCount)).twoDecimals) + "%"
            allGamesLabel.text = GV.language.getText(.tcAllGamesCount, values: "\(allGameCount)", "\(referenceGameCount)", "\(procent)")
        } else {
            allGamesLabel.text = GV.language.getText(.tcAllGamesCount, values: "\(allGameCount)", "0", "0")
        }
        let pkgLabels = [onePkgLabel, twoPkgLabel, threePkgLabel, fourPkgLabel]
        for pkgNr in 1...4 {
            let pkgCount = realm.objects(GameModel.self).filter("playerID = %d and countPackages = %d", GV.player!.ID, pkgNr).count
            let pkgErrorCount = realm.objects(GameModel.self).filter("playerID = %d and countPackages = %d and gameFinished = false and ID != %d", GV.player!.ID, pkgNr, GV.actGame!.ID).count
            pkgLabels[pkgNr - 1].text = GV.language.getText(.tcPkgTxt, values: "\(pkgNr)", "\(pkgErrorCount)", "\(pkgCount)")
        }
    }
    
    func specialPrepareFuncFirst() {
        //printFunc(function: "specialPrepareFuncFirst", start: true)
        stopCreateTippsInBackground = true
//        countPackages = GV.levelsForPlay.aktLevel.countPackages
//        countPackages = GV.player!.countPackages
        maxCardCount = countPackages * countContainers * CountCardsInPackage
        countCardsProContainer = CountCardsInPackage //levelsForPlay.aktLevel.countCardsProContainer
        countColumns = GV.levelsForPlay.aktLevel.countColumns
        countRows = GV.levelsForPlay.aktLevel.countRows
        minUsedCells = GV.levelsForPlay.aktLevel.minProzent * countColumns * countRows / 100
        maxUsedCells = GV.levelsForPlay.aktLevel.maxProzent * countColumns * countRows / 100
//        showHelpLines = .green
        containerSize = CGSize(width: CGFloat(containerSizeOrig) * cardSizeMultiplier.width, height: CGFloat(containerSizeOrig) * cardSizeMultiplier.height)
        cardSize = CGSize(width: CGFloat(GV.levelsForPlay.aktLevel.cardSize) * cardSizeMultiplier.width, height: CGFloat(GV.levelsForPlay.aktLevel.cardSize) * cardSizeMultiplier.height)
        
        #if TEST
            let line = "GameNr: \(gameNumber + 1), Packages: \(countPackages), Level: \(levelIndex + 1), Format: \(countColumns) * \(countRows)"
            print(line)
        #endif
        MySKCard.cleanForNewGame(countPackages: countPackages)

        for _ in 0..<countContainers {
            var hilfsArray: [GenerateCard] = []
            for cardIndex in 0..<countCardsProContainer! * countPackages {
                var card = GenerateCard()
                card.cardValue = cardIndex % countCardsProContainer!
                card.packageNr = cardIndex / countCardsProContainer!
                
                hilfsArray.append(card)
            }
            cardArray.append(hilfsArray)
        }
        //printFunc(function: "specialPrepareFuncFirst", start: false)
    }
    
    func updateCardCount(_ adder: Int) {
        //printFunc(function: "updateCardCount", start: true)
        cardCount += adder
        showCardCount()
        //printFunc(function: "updateCardCount", start: false)
    }
    
    func showCardCount() {
        cardCountLabel.text = String(cardStack.count(type: .MySKCardType))
    }

    
    func changeLanguage()->Bool {
        //printFunc(function: "changeLanguage", start: true)
        
        whoIsHeaderLabel.text = GV.language.getText(.tcWhoIs)
        playerHeaderLabel.text = GV.language.getText(.tcName)
        timeHeaderLabel.text = GV.language.getText(.tcTime)
        scoreHeaderLabel.text = GV.language.getText(.tcScoreHead)
        cardCountHeaderLabel.text = GV.language.getText(.tcCardHead)
        
        playerNameLabel.text = getName()
        whoIsLabel.text = GV.language.getText(.tcPlayerType)

        levelLabel.text = GV.language.getText(.tcLevel) + ": \(levelIndex + 1)"
        gameNumberLabel.text = GV.language.getText(.tcGameNumber) + "\(gameNumber + 1)"
        sizeLabel.text = GV.language.getText(.tcSize) + "\(GV.levelsForPlay.aktLevel.countColumns) x \(GV.levelsForPlay.aktLevel.countRows)"
        packageLabel.text = GV.language.getText(.tcPackage, values: String(countPackages))
        
        settingsLabel.text = GV.language.getText(.tcSettings)
        startLabel.text = GV.language.getText(.tcStart)
        helpLabel.text = GV.language.getText(.tcHelp)
        tippLabel.text = GV.language.getText(.tcTipps)
        undoLabel.text = GV.language.getText(.tcUndo)

        if GV.player!.GCEnabled == GCEnabledType.GameCenterEnabled.rawValue {
            let (bestPlaceLabelText, myPlaceLabelText) = setRankingLabels()
            bestPlaceLabel.text = bestPlaceLabelText
            myPlaceLabel.text = myPlaceLabelText
        }
        showCardCount()
        showTippCount()
        showLevelScore()
        //printFunc(function: "changeLanguage", start: false)
        return true
    }
    
    func getName() -> String {
        var name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        if GV.player!.GCEnabled == GCEnabledType.GameCenterEnabled.rawValue {
            if GKLocalPlayer.localPlayer().alias != nil {
                name = GKLocalPlayer.localPlayer().alias!
            }
        }
        return name
    }
    
    func setRankingLabels() -> (String, String) {
        let actResult = realm.objects(HighScoreModel.self).filter("countPackages = %d and levelID = %d", countPackages, levelIndex).first!
        if actResult.myHighScore > actResult.bestPlayerHighScore {
            gameCenterSync.sendScoreToGameCenter(score: actResult.myHighScore, countPackages: countPackages, levelID: levelIndex)
            realm.beginWrite()
            actResult.bestPlayerName = getName()
            actResult.bestPlayerHighScore = actResult.myHighScore
            try! realm.commitWrite()
        }
        let bestPlayer = actResult.bestPlayerName
        let bestPlayerScore = actResult.bestPlayerHighScore
        let myPlace = actResult.myRank
        let myBestScore = actResult.myHighScore
        
        let bestPlaceLabelText = GV.language.getText(.tcBestPlace, values: bestPlayer, String(bestPlayerScore))
        let myPlaceLabelText = GV.language.getText(.tcMyPlace, values: String(myPlace), String(myBestScore))
        return (bestPlaceLabelText, myPlaceLabelText)
    }
    
    func showTippCount() {
        //printFunc(function: "showTippCount", start: true)
        tippCountLabel.text = String(tippArray.count)
        if tippArray.count > 9 {
            tippCountLabel.fontSize = labelFontSize
        } else {
            tippCountLabel.fontSize = labelFontSize * 1.5
        }
        //printFunc(function: "showTippCount", start: false)
    }

    func setBGImageNode()->SKSpriteNode {
//        return SKSpriteNode()
        return SKSpriteNode(imageNamed: "cardBackground.png")
    }

    
    func spezialPrepareFunc() {
//        valueTab.removeAll()
    }

    func getValueForContainer()->Int {
        return countCardsProContainer!// + 1
    }
 
    func createCardStack() {
        cardStack = Stack()
        var newCard: MySKCard
        var go = true
        while go {
            (newCard, go) = MySKCard.getRandomCard(random: random)
            cardStack.push(card: newCard)
        }
    }
    
    func fillEmptyCards() {
        //printFunc(function: "fillEmptyCards", start: true)
        for column in 0..<countColumns {
            for row in 0..<countRows {
                makeEmptyCard(column, row: row)
            }
        }
        //printFunc(function: "fillEmptyCards", start: false)
    }

    func generateCards(generatingType: CardGeneratingType) {
        if inGeneratingCards {
            return
        }
        inGeneratingCards = true
        var waitForStart: TimeInterval = 0.0
        let cardArray = cardManager!.findNewCardsForGameArray()
        showCardCount()
        showTippCount()
        for card in cardArray {
            let zielPosition = gameArray[card.column][card.row].position
            card.position = cardPackage!.position
            card.startPosition = zielPosition
            
            if GV.deviceType == iPhone_X {
                card.size = CGSize(width: cardSize.width * 0.8, height: cardSize.height * 0.8)
            } else {
                card.size = CGSize(width: cardSize.width, height: cardSize.height)
            }
            
            push(card, status: .addedFromCardStack)
            
//            cardManager!.check(color: card.colorIndex)
            addChild(card)
            card.alpha = 0
            let duration:Double = Double((zielPosition - cardPackage!.position).length()) * durationMultiplier
            let actionMove = SKAction.move(to: zielPosition, duration: duration)
            
            let waitingAction = SKAction.wait(forDuration: waitForStart)
            waitForStart += waitForStartConst
            
            let zPositionPlus = SKAction.run({
                card.zPosition += 100
            })

            let zPositionMinus = SKAction.run({
                card.zPosition -= 100
            })

            let actionHideEmptyCard = SKAction.run({
                self.deleteEmptyCard(column: card.column, row: card.row)
            })
            
            let actionFadeAlpha = SKAction.fadeAlpha(to: 1, duration: 0.2)
            let actionMoveAndFadeIn = SKAction.group([actionMove, actionFadeAlpha])
            self.movingCards.append(card)
            let actionAddCardToMovingCards = SKAction.run {
//                self.movingCards.append(card)
            }
            let actionRemoveCardFromMovingCards = SKAction.run {
                self.movingCards.remove(at: self.movingCards.index(where: { $0 === card })!)
            }
            card.run(SKAction.sequence([actionAddCardToMovingCards, waitingAction, zPositionPlus, actionMoveAndFadeIn, zPositionMinus, actionHideEmptyCard, /*actionCountMovingCards,*/ actionRemoveCardFromMovingCards]), withKey: "index")
            if cardStack.count(type: .MySKCardType) == 0 {
                cardPackage!.changeButtonPicture(SKTexture(imageNamed: "emptycard"))
                cardPackage!.alpha = 0.3
            }
        }
        
        waitForMovingCards()
//        self.waitForSKActionEndedTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.waitForMovingCards), userInfo: nil, repeats: false) // start timer for check

        if generatingType == .first {
            countUpTimer = Timer.scheduledTimer(timeInterval: doCountUpSleepTime, target: self, selector: #selector(showTime), userInfo: nil, repeats: true)
            doTimeCount = true
        }
        stopped = false
        inGeneratingCards = false
    }
    
    func startAutoplay(testType: AutoPlayer.TestType) {
        autoPlayerActive = true
        durationMultiplier = durationMultiplierForAutoplayer
        waitForStartConst = waitForStartForAutoplayer
        autoPlayer?.startPlay(testType: testType)
    }
        
    
    
    func deleteEmptyCard(column: Int, row: Int) {
        //printFunc(function: "deleteEmptyCard", start: true)
        let searchName = "\(emptyCardTxt)-\(column)-\(row)"
        if self.childNode(withName: searchName) != nil {
            self.childNode(withName: searchName)!.removeFromParent()
        }
//        if gameArray[column][row].card.name == searchName {
//            gameArray[column][row].card.removeFromParent()
//        }
        //printFunc(function: "deleteEmptyCard", start: false)

    
    }
    
    func makeEmptyCard(_ column:Int, row: Int) {
        //printFunc(function: "makeEmptyCard", start: true)
        let searchName = "\(emptyCardTxt)-\(column)-\(row)"
        if self.childNode(withName: searchName) == nil {
            let emptyCard = MySKCard()
            emptyCard.position = gameArray[column][row].position
            emptyCard.size = CGSize(width: cardSize.width, height: cardSize.height)
            emptyCard.name = "\(emptyCardTxt)-\(column)-\(row)"
            emptyCard.column = column
            emptyCard.row = row
            gameArray[column][row].card = emptyCard
            gameArray[column][row].used = false
//            gameArray[column][row].card.colorIndex = NoColor
//            gameArray[column][row].name = searchName
            addChild(emptyCard)
        }
        //printFunc(function: "makeEmptyCard", start: false)
    }

    func specialButtonPressed(_ buttonName: String) {
        if buttonName == "tipps" {
            if !generatingTipps {
                if let manager = cardManager {
                    manager.getTipps()
                }
            }
        }
    }
    
//    func startTippTimer(){
//    }
    
    
    func findPairForCard (_ colorIndex: Int, minValue: Int, maxValue: Int)->Bool {
        var founded = false
        for column in 0..<countColumns {
            for row in 0..<countRows {
                if gameArray[column][row].card.colorIndex == colorIndex &&
                    (gameArray[column][row].card.minValue == maxValue + 1 ||
                    gameArray[column][row].card.maxValue == minValue - 1) {
                        founded = true
                        break
                }
            }
        }
        if !founded {
            for index in 0..<containers.count {
                if (containers[index].minValue == NoColor && maxValue == LastCardValue) ||
                    (containers[index].colorIndex == colorIndex && containers[index].minValue == maxValue + 1){
                        founded = true
                        break
                }
            }
        }
        return founded
    }
    
    override func update(_ currentTime: TimeInterval) {
        let sec10: Int = Int(currentTime * 10) % 3
        if sec10 != lastUpdateSec && sec10 == 0 {
            let adder:CGFloat = 5
            for index in 0..<cardManager!.tremblingCards.count {
                let aktCard = cardManager!.tremblingCards[index]
                switch aktCard.trembling {
                    case 0: aktCard.trembling = adder
                    case adder: aktCard.trembling = -adder
                    case -adder: aktCard.trembling = adder
                    default: aktCard.trembling = adder
                }
                switch aktCard.tremblingType {
                    case .noTrembling: break
                    case .changeSize:  aktCard.size = CGSize(width: aktCard.origSize.width + aktCard.trembling, height: aktCard.origSize.height +  aktCard.trembling)
                    case .changePos: break
                    case .changeDirection: aktCard.zRotation = CGFloat(CGFloat(Double.pi)/CGFloat(aktCard.trembling == 0 ? 16 : aktCard.trembling * CGFloat(8)))
                    case .changeSizeOnce:
                        if aktCard.size == aktCard.origSize {
                            aktCard.size.width += adder
                            aktCard.size.height += adder
                        }
                }
            }
            

        }
        lastUpdateSec = sec10
        if restartGame {
            restartGame = false
            startNewGame(next: false)
        }
        checkMultiplayer()
        cardManager!.checkColoredLines()
        
    }
    
    func checkMultiplayer() {
        if playerType == .multiPlayer {
            opponentNameLabel.text = opponent.name
            opponentTypeLabel.isHidden = false
            opponentNameLabel.isHidden = false
            opponentScoreLabel.isHidden = false
            opponentTimeLabel.isHidden = false
            opponentCardCountLabel.isHidden = false
            showLevelScore()
        }
        
        if startGetNextPlayArt {
            startGetNextPlayArt = false
            let alert = getNextPlayArt(congratulations: .No)
            GV.mainViewController!.showAlert(alert)
        }
        
        if opponent.finish == .finished || opponent.finish == .interrupted {
            animateFinishGame()
            if opponent.finish == .finished {
                saveStatisticAndGame()
            }
            opponent.finish = .none
            playerType = .singlePlayer
            GV.peerToPeerService!.changeStatusToFree()
            doTimeCount = false
            opponentTypeLabel.isHidden = true
            opponentNameLabel.isHidden = true
            opponentTimeLabel.isHidden = true
            opponentScoreLabel.isHidden = true
            opponentCardCountLabel.isHidden = true
            createLabelsForBestPlace()
            showLevelScore()
        }
    }
    
    func animateFinishGame() {
        for gameRow in gameArray {
            for game in gameRow {
                if game.used {
                    let cardToMove = game.card
                    makeEmptyCard(cardToMove.column, row: cardToMove.row)
                    animateMovingCard(cardToMove)
                }
            }
            repeat {
                if let cardToMove: MySKCard = cardStack.pull() {
                    cardToMove.position = cardPackage!.position
                    animateMovingCard(cardToMove)
                } else {
                    break
                }
            } while true
        }
    }
    
    func animateMovingCard(_ card: MySKCard) {
        var endPosition = CGPoint.zero
        let minValue = card.minValue
        let maxValue = card.maxValue
        let color = card.colorIndex
        for container in containers {
            if container.colorIndex == color {
                endPosition = container.position
                container.minValue = container.minValue > card.minValue ? card.minValue : container.minValue
                container.maxValue = container.maxValue > card.maxValue ? container.maxValue : card.maxValue
                container.reload()
                break
            }
        }
        if endPosition == CGPoint.zero {
            for container in containers {
                if container.colorIndex == NoColor {
                    endPosition = container.position
                    container.colorIndex = color
                    container.maxValue = maxValue
                    container.minValue = minValue
                    container.texture = getTexture(color)
                    container.reload()
                    break
                }
            }
        }
        let moveToContainerAction = SKAction.move(to: endPosition, duration: 4)
        let rotateAction =  SKAction.rotate(byAngle: 360 * GV.oneGrad, duration: 4)
        let hideAction = SKAction.sequence([SKAction.removeFromParent()])
        let countAction = SKAction.run { 
            self.showCardCount()
        }
        let actionAddCardToMovingCards = SKAction.run {
            self.movingCards.append(card)
        }
        let actionRemoveCardFromMovingCards = SKAction.run {
            self.movingCards.remove(at: self.movingCards.index(where: { $0 === card })!)
        }
        let allActions = SKAction.group([moveToContainerAction, rotateAction])
        let action = SKAction.sequence([actionAddCardToMovingCards, allActions, hideAction, countAction, actionRemoveCardFromMovingCards])
        card.run(action)
    }
    
    
    func cardDidCollideWithContainer(node1:MySKCard, node2:MySKCard, points: [CGPoint]) {
        let movingCard = node1
        let container = node2
        if container.minValue == container.maxValue && container.maxValue == NoColor && movingCard.maxValue == LastCardValue {
            var containerNotFound = true
            for index in 0..<countContainers {
                if containers[index].colorIndex == movingCard.colorIndex {
                    containerNotFound = false
                }
            }
            if containerNotFound {
                container.colorIndex = movingCard.colorIndex
                container.colorIndex = movingCard.colorIndex
                container.texture = getTexture(movingCard.colorIndex)
                push(container, status: .firstCardAdded)
            }
        }
        
        let connectable = cardManager!.areConnectable(first: movingCard, second: container)
        
        let OK = movingCard.colorIndex == container.colorIndex && (container.minValue == NoColor || connectable.OK)

        
        
        if OK  {
            lastUsedTipp = Tipp()
            push(container, status: .unification)
            push(movingCard, status: .removed)
            lastChange.color = movingCard.colorIndex
            lastChange.toContainer = true
            container.connectWith(otherCard: movingCard)
            //            saveHistoryRecord(colorIndex: movingCard.colorIndex, points:  points,
            //                              fromColumn: movingCard.column, fromRow: movingCard.row, fromMinValue: movingCard.minValue, fromMaxValue: movingCard.maxValue,
            //                              toColumn: container.column,   toRow: container.row,   toMinValue: container.minValue,   toMaxValue: container.maxValue)
            //
//            self.addChild(showCountScore("+\(movingCard.countScore)", position: movingCard.position))
            
            levelScore += movingCard.countScore
            levelScore += movingCard.getMirroredScore()
            
            container.reload()
            cardManager!.resetGameArrayCell(movingCard)
            movingCard.removeFromParent()
            playSound("Container", volume: GV.player!.soundVolume)
//            countMovingCards = 0
            
            updateCardCount(-1)
            
        } else {
            updateCardCount(-1)
            movingCard.removeFromParent()
//            countMovingCards = 0
            push(movingCard, status: .removed)
            pull(createTipps: false) // no createTipps
//            startTippTimer()
            
        }
        tippsButton!.activateButton(true)
    }
    
    func cardDidCollideWithMovingCard(node1:MySKCard, node2:MySKCard, points: [CGPoint]) {
        let movingCard = node1
        let card = node2
//        collisionActive = false
        
        let connectable = cardManager!.areConnectable(first: movingCard, second: card)
        
        //        let OK = connectable //MySKCard.areConnectable(first: movingCard, second: card)
        if connectable.OK {
            lastUsedTipp = Tipp()
            for tipp in tippArray {
                if tipp.card1 == movingCard && tipp.card2 == card || tipp.card2 == movingCard && tipp.card1 == card {
                    lastUsedTipp = Tipp()
                    lastUsedTipp?.card1 = tipp.card1.copy() as! MySKCard
                    lastUsedTipp?.card2 = tipp.card2.copy() as! MySKCard
                    break
                }
            }
//            if lastUsedTipp?.card1.colorIndex == NoColor {
//                print("lastUsedTipp Not Filled!!! at \(movingCard.printValue)")
//            }
            push(card, status: .unification)
            push(movingCard, status: .removed)
            lastChange.color = movingCard.colorIndex
            lastChange.toContainer = false
            
            card.connectWith(otherCard: movingCard)
            //            cardManager!.check(color: card.colorIndex)
            //            saveHistoryRecord(colorIndex: movingCard.colorIndex, points: points,
            //                              fromColumn: movingCard.column, fromRow: movingCard.row, fromMinValue: movingCard.minValue, fromMaxValue: movingCard.maxValue,
            //                              toColumn: card.column,   toRow: card.row,   toMinValue: card.minValue,   toMaxValue: card.maxValue)
            //
            //
//            self.addChild(showCountScore("+\(movingCard.countScore)", position: movingCard.position))
            levelScore += movingCard.countScore
            levelScore += movingCard.getMirroredScore()
            
            card.reload()
            
            playSound("OK", volume: GV.player!.soundVolume)
            
            cardManager!.updateGameArrayCell(card: card)
            cardManager!.resetGameArrayCell(movingCard)
            
            movingCard.removeFromParent()
//            countMovingCards = 0
            updateCardCount(-1)
            //            checkGameFinished()
            saveStatisticAndGame()
        } else {
            
            updateCardCount(-1)
            movingCard.removeFromParent()
//            countMovingCards = 0
            push(movingCard, status: .removed)
            pull(createTipps: false) // no createTipps
//            startTippTimer()
            
        }
        tippsButton!.activateButton(true)
    }

    func cardDidCollideWithCardOrContainer(movingCard:MySKCard, cardOrContainer:MySKCard, connectable: Bool) {
        
//        if cardOrContainer.minValue == cardOrContainer.maxValue && cardOrContainer.maxValue == NoColor && movingCard.maxValue == LastCardValue {
//            var containerNotFound = true
//            for index in 0..<countContainers {
//                if containers[index].colorIndex == movingCard.colorIndex {
//                    containerNotFound = false
//                }
//            }
//            if containerNotFound {
//                cardOrContainer.colorIndex = movingCard.colorIndex
//                cardOrContainer.colorIndex = movingCard.colorIndex
//                cardOrContainer.texture = getTexture(movingCard.colorIndex)
//                push(cardOrContainer, status: .firstCardAdded)
//            }
//        }
        if cardOrContainer.type == .containerType {
            push(cardOrContainer, status: .firstCardAdded)
        }
        
        //        let connectable = cardManager?.areConnectable(first: movingCard, second: container)
        
        let OK = connectable || cardOrContainer.minValue == NoColor
        
        
        
        if OK  {
            levelScore += movingCard.countScore
            levelScore += movingCard.getMirroredScore()
            cardOrContainer.reload()
            movingCard.removeFromParent()
            
        } else {
            updateCardCount(-1)
            movingCard.removeFromParent()
//            countMovingCards = 0
            push(movingCard, status: .removed)
            pull(createTipps: false) // no createTipps
            //            startTippTimer()
            
        }
        tippsButton!.activateButton(true)
    }
    
//    func showCountScore(_ text: String, position: CGPoint)->SKLabelNode {
//        let score = SKLabelNode()
//        score.position = position
//        score.text = text
//        score.fontColor = UIColor.red
//        score.fontName = "ArialMT"
//        score.fontSize = 30
//        score.zPosition = 1000
//        let showAction = SKAction.moveTo(y: position.y + 1000, duration: 3.0)
//        let hideAction = SKAction.sequence([SKAction.fadeOut(withDuration: 3.0), SKAction.removeFromParent()])
//        let scoreActions = SKAction.group([showAction, hideAction])
//        score.run(scoreActions)
//        return score
//    }
    
    func checkGameFinished() {
        func checkNoMoreSteps() {
            if cardManager!.noMoreSteps && lastUsedTipp?.card1.colorIndex != NoColor
            {
                self.pull(createTipps: true)
                for (index, tipp) in tippArray.enumerated() {
                    if  tipp.card1 == lastUsedTipp!.card1 &&
                        tipp.card2 == lastUsedTipp!.card2
                    {
                        tippArray[index].supressed = true
                        if !supressedTipps.contains(where: {$0.card1 == lastUsedTipp!.card1 && $0.card2 == lastUsedTipp!.card2}) {
                            supressedTipps.append(lastUsedTipp!)
                        }
                        break
                    }
                }
                let alert = UIAlertController(title: GV.language.getText(.tcNoMoreSteps),
                                              message: "",
                                              preferredStyle: .alert)
                
                let OKAction = UIAlertAction(title: GV.language.getText(.tcok), style: .default,
                                             handler: {(paramAction:UIAlertAction!) in
                                                
                })
                alert.addAction(OKAction)
                GV.mainViewController!.showAlert(alert)
            }
        }
    
//        let usedCellCount = cardManager!.countGameArrayItems
//        let containersOK = checkContainers()
        
//        let finishGame = cardCount == 0
        
        if cardCount == 0 { // Level completed, start a new game
            let countPlayedCards = countCardsProContainer! * countContainers * countPackages
            let optimalValue = 45000 // milliseconds / Card -> 45 sec / Card
            let milliSecondsProCard = (1000 * timeCount) / countPlayedCards
            let milliSecondsProCardCorrected = milliSecondsProCard + 0 < optimalValue ? milliSecondsProCard : optimalValue + (milliSecondsProCard - optimalValue) / 32
            let bonusProcent: Double = Double(optimalValue - milliSecondsProCardCorrected) / 30000.0
            timeBonus = Int(Double(levelScore) * bonusProcent)
            timeBonus = timeBonus > 0 ? timeBonus : 0
            highScore = levelScore + timeBonus
            
            stopTimer(&countUpTimer)
            playMusic("Winner", volume: GV.player!.musicVolume, loops: 0)
            playerCardCountLabel.text = "0"
//            if playerType == .multiPlayer {
//                GV.peerToPeerService?.sendInfo(.gameIsFinished, message: [String(levelScore)], toPeerIndex: opponent.peerIndex)
//            }
            
            // get && modify the statistic record
            
            var sentToGameCenter = false
            if GV.player!.GCEnabled == GCEnabledType.GameCenterEnabled.rawValue {
                gameCenterSync.sendScoreToGameCenter(score: highScore, countPackages: countPackages, levelID: levelIndex)
                sentToGameCenter = true
            }
            let levelOldHighScore = realm.objects(HighScoreModel.self).filter("countPackages = %d and levelID = %d", countPackages, levelIndex).first!
            if levelOldHighScore.myHighScore < highScore {
                realm.beginWrite()
                levelOldHighScore.myHighScore = highScore
                levelOldHighScore.sentToGameCenter = sentToGameCenter
                try! realm.commitWrite()
            }
            if levelOldHighScore.bestPlayerHighScore < highScore {
                realm.beginWrite()
                levelOldHighScore.bestPlayerHighScore = highScore
                levelOldHighScore.bestPlayerName = GKLocalPlayer.localPlayer().alias!
                try! realm.commitWrite()
            }

            saveStatisticAndGame()
            if playerType == .multiPlayer {
                GV.peerToPeerService?.sendInfo(.gameIsFinished, message: [String(levelScore)], new: false, toPeer: opponent.peerID!)
                alertIHaveGameFinished()
            } else {
                let alert = getNextPlayArt(congratulations: .Won)
                GV.mainViewController!.showAlert(alert)
            }
        } else { // usedCellCount <= minUsedCells && usedCellCount > 1 {
//            if touchType == .manual {
//                DispatchQueue.global().async {
//                    self.generateCards(generatingType: .normal)  // Nachgenerierung
//                    DispatchQueue.main.async {
//                        checkNoMoreSteps()
//                    }
//                }
//            } else {
                self.generateCards(generatingType: .normal)  // Nachgenerierung
                checkNoMoreSteps()
//            }
        }
    }
    
    func saveStatisticAndGame () {
        realm.beginWrite()
//        if realm.objects(StatisticModel.self).filter("playerID = %d and levelID = %d and countPackages = %d",
//            GV.player!.ID, GV.player!.levelID, GV.player!.countPackages).count == 0 {
//            // create a new Statistic record if required
//            let statistic = StatisticModel()
//            statistic.ID = GV.createNewRecordID(.statisticModel)
//            statistic.playerID = GV.player!.ID
//            statistic.levelID = GV.player!.levelID
//            statistic.countPackages = GV.player!.countPackages
//            try! realm.write({
//                realm.add(statistic)
//            })
//        }
//
//        let statistic = realm.objects(StatisticModel.self).filter("playerID = %d and levelID = %d and countPackages = %d",
//            GV.player!.ID, GV.player!.levelID, GV.player!.countPackages).first!        
//        statistic.actTime = timeCount
//        statistic.allTime += timeCount
//        
//        if statistic.bestTime == 0 || timeCount < statistic.bestTime {
//            statistic.bestTime = timeCount
//        }
//        
//        
//        statistic.actScore = levelScore
//        if cardCount == 0 {
//            statistic.levelScore += levelScore
//            if statistic.bestScore < levelScore {
//                statistic.bestScore = levelScore
//            }
//            if statistic.bestScore < levelScore {
//                statistic.bestScore = levelScore
//            }
//        }
        GV.actGame!.countSteps = maxCardCount - cardCount
        GV.actGame!.time = timeCount
        GV.actGame!.playerScore = levelScore
        GV.actGame!.played = true
        GV.actGame!.created = Date()
//        #if REALM_V2
        if cardCount > 0 {
            GV.actGame!.gameFinished = false
        } else {
            GV.actGame!.gameFinished = true
        }
//        #endif
        if playerType == .multiPlayer {
            GV.actGame!.multiPlay = true
            GV.actGame!.opponentName = opponent.name
            GV.actGame!.opponentScore = opponent.score
//            statistic.countMultiPlays += 1
//            if opponent.score > levelScore {
//                statistic.defeats += 1
//            } else {
//                statistic.victorys += 1
//            }
        } else if cardCount == 0 {  // countPlays only when game is finished
//            statistic.countPlays += 1
        }
        try! realm.commitWrite()

    }
    
    func restartButtonPressed() {
        let alert = getNextPlayArt(congratulations: .No)
        GV.mainViewController!.showAlert(alert)
    }
    
    func choosePartner() {
        var playingPartners: [String] = []
        let partners = GV.peerToPeerService!.getPartners()
        let alert = UIAlertController(title: GV.language.getText(partners.count == 0 ?.tcThereIsNoPartner : .tcChoosePartner),
                                      message: "",
                                      preferredStyle: .alert)
        if partners.count > 0 {
            for index in 0..<partners.count {
                var identity: String = ""
                if partners[index].name != nil && !playingPartners.contains(partners[index].name!) {
                    identity = partners[index].name!
                    var isEnabled = true
                    if partners[index].playingWith != nil && partners[index].playingWith != "" {
                        identity = identity + GV.language.getText(.tcIsPlayingWith, values: partners[index].playingWith!)
                        playingPartners.append(partners[index].playingWith!)
                        isEnabled = false
                    }
                    let peerID = partners[index]
                    let nameAction = UIAlertAction(title: identity, style: .default,
                                                    handler: {(paramAction:UIAlertAction!) in
                                                        self.opponent.name = identity
                                                        self.opponent.score = 0
                                                        self.callPartner(peerID: peerID, identity: identity)
                    })
                    alert.addAction(nameAction)
                    alert.actions.last?.isEnabled = isEnabled
                }
            }
        }
        let returnAction = UIAlertAction(title: GV.language.getText(.tcReturn), style: .cancel,
                                         handler: {(paramAction:UIAlertAction!) in
                                            
        })
        alert.addAction(returnAction)
        GV.mainViewController!.showAlert(alert)
}
    
    func callPartner(peerID: MCPeerID, identity: String) {
        let gameNumber = randomGameNumber()
        opponent.peerID = peerID
        let myName = getName()
        var answer = GV.peerToPeerService!.sendMessage(command: .iWantToPlayWithYou, message: [myName, GV.peerToPeerVersion, String(levelIndex), String(countPackages), String(gameNumber)], toPeer: peerID)
        switch answer[0] {
        case answerYes:
            self.playerType = .multiPlayer
            self.gameNumber = gameNumber
            self.opponent.name = identity
            self.opponent.score = 0
            self.restartGame = true
            GV.peerToPeerService!.changeStatusToIsPlaying(isPlayingWith: opponent.name)
        case answerNo, GV.IAmBusy, GV.timeOut:
            alertOpponentDoesNotWantPlay(alert: .tcOpponentNotPlay)
            self.opponent = Opponent()
            self.playerType = .singlePlayer
            GV.peerToPeerService!.changeStatusToFree()
        case peerToPeerVersionOfOpponentIsHigher:
            alertOpponentDoesNotWantPlay(alert: .tcPeerToPeerVersionIsHigher, opponentName: identity)
            self.opponent = Opponent()
            self.playerType = .singlePlayer
            GV.peerToPeerService!.changeStatusToFree()
        case peerToPeerVersionOfOpponentIsLower:
            alertOpponentDoesNotWantPlay(alert: .tcPeerToPeerVersionIsLower, opponentName: identity)
            self.opponent = Opponent()
            self.playerType = .singlePlayer
            GV.peerToPeerService!.changeStatusToFree()
       default:
            break
        }
    }
    
    func alertOpponentDoesNotWantPlay(alert: TextConstants, opponentName: String = "") {
        let alert = UIAlertController(title: GV.language.getText(alert, values: opponentName),
            message: "",
            preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: GV.language.getText(.tcok), style: .default,
                                        handler: {(paramAction:UIAlertAction!) in
                                            
        })
        alert.addAction(OKAction)

        
        GV.mainViewController!.showAlert(alert, delay: 10)
        
    }
    
    func chooseLevelAndOptions() {
        _ = ChooseLevelAndOptions(callBackFromChooseLevelAndOptions)
    }
    
    func callBackFromChooseLevelAndOptions() {
        startNewGame(next: true)
    }

    
    func randomGameNumber()->Int {
        for _ in 0...MaxGameNumber {
            let gameNumber = Int(arc4random_uniform(UInt32(MaxGameNumber)))
            if realm.objects(GameModel.self).filter("playerID = %d and gameNumber = %d and levelID = %d and played = true", GV.player!.ID, gameNumber, levelIndex).count == 0
            {
                return gameNumber
            }
        }
        return 0
    }
    
    func callBackFromMySKTextField(_ gameNumber: Int) {
        self.gameNumber = gameNumber
        self.isUserInteractionEnabled = true
        startNewGame(next: false)
    }
    
    func startNewGame(next: Bool) {
        stopped = true
        if next {
            cardManager!.lastNextPoint = nil
        }
        
        realm.beginWrite()
        realm.delete(realm.objects(GameModel.self).filter("played = false"))
        try! realm.commitWrite()
        
        stopCreateTippsInBackground = true
        for _ in 0..<self.children.count {
            let childNode = children[self.children.count - 1]
            childNode.removeFromParent()
        }
        
        stopTimer(&countUpTimer)
        prepareNextGame(newGame: next)
        generateCards(generatingType: .first)
    }

    func getNextPlayArt(congratulations: CongratulationsType, firstStart: Bool = false)->UIAlertController {
//        let playerName = GV.player!.name
        let statisticsTxt = ""
        var congratulationsTxt = GV.language.getText(.tcChooseGame)
        
        switch congratulations {
        case .Won, .Lost:
//            let actGames = realm.objects(GameModel.self).filter("levelID = %d and gameNumber = %d and countPackages = %d",
//                levelIndex, GV.actGame!.gameNumber, GV.actGame!.countPackages)
//            if actGames.count > 0 {
//                bestGameScore = actGames.max(ofProperty: "playerScore")!
//                let bestScorePlayerID = actGames.filter("playerScore = %d", bestGameScore).first!.playerID
//                bestScorePlayerName = realm.objects(PlayerModel.self).filter("ID = %d",bestScorePlayerID).first!.name
//            }
//
            var bestGameScore = 0
            var bestScorePlayerName = ""
            
            let myName = getName()

            let highScoreRecord = realm.objects(HighScoreModel.self).filter("countPackages = %d and levelID = %d", countPackages, levelIndex)
            if highScoreRecord.count > 0 {
                bestGameScore = highScoreRecord.first!.bestPlayerHighScore
                bestScorePlayerName = highScoreRecord.first!.bestPlayerName
            }
            
            
            tippCountLabel.text = String(0)
//            let statistic = realm.objects(StatisticModel.self).filter("playerID = %d and levelID = %d and countPackages = %d",
//                            GV.player!.ID, GV.player!.levelID, GV.player!.countPackages).first!

            congratulationsTxt = GV.language.getText(.tcLevelAndPackage, values: String(countPackages), String(levelIndex + 1), "\(countColumns)x\(countRows)")
            congratulationsTxt += "\r\n" + GV.language.getText(.tcGameComplete, values: String(gameNumber + 1))
            congratulationsTxt += "\r\n" + GV.language.getText(TextConstants.tcCongratulations) + myName + "!"
            congratulationsTxt += "\r\n ============== \r\n"
            
            if highScoreRecord.count > 0 {
//                if bestScorePlayerName != myName {
                    congratulationsTxt += "\r\n" + GV.language.getText(.tcReachedScore, values: String(levelScore))
                    congratulationsTxt += "\r\n" + GV.language.getText(.tcTimeBonus, values: String(timeBonus))
                    congratulationsTxt += "\r\n" + GV.language.getText(.tcYourScore, values: String(highScore))
                    congratulationsTxt += "\r\n" + GV.language.getText(.tcBestScoreOfGame, values: String(bestGameScore), bestScorePlayerName)
//                } else {
//                    congratulationsTxt += "\r\n" + GV.language.getText(.tcYouAreTheBest, values: String(bestGameScore))
//                }
            } else {
                congratulationsTxt += "\r\n" + GV.language.getText(.tcLevelScore, values: " \(highScore)")
            }
            congratulationsTxt += "\r\n" + GV.language.getText(.tcActTime) + String(timeCount.HourMin)
        case .No:
            break
        }
        let alert = UIAlertController(title: congratulationsTxt,
            message: statisticsTxt,
            preferredStyle: .alert)
        
        if playerType == .multiPlayer {
            let stopAction = UIAlertAction(title: GV.language.getText(.tcStopCompetition), style: .default,
                                            handler: {(paramAction:UIAlertAction!) in
                                                self.stopCompetition()
            })
            alert.addAction(stopAction)
            
        } else {
            switch GV.player!.GCEnabled {
                case GCEnabledType.AskForGameCenter.rawValue, GCEnabledType.GameCenterSupressed.rawValue:
                    let connectToGamecenter = UIAlertAction(title: GV.language.getText(.tcConnectGC), style: .default,
                                                            handler: {(paramAction:UIAlertAction!) in
                                                                
                                                                self.connectToGameCenter()
                                                                try! realm.write({
                                                                    if GKLocalPlayer.localPlayer().isAuthenticated {
                                                                        GV.player!.GCEnabled = GCEnabledType.GameCenterEnabled.rawValue
                                                                    }
                                                                })
                                                                
                    })
                    alert.addAction(connectToGamecenter)
//                case GCEnabledType.GameCenterEnabled.rawValue:
//                    let connectToGamecenter = UIAlertAction(title: GV.language.getText(.tcDisconnectGC), style: .default,
//                                                            handler: {(paramAction:UIAlertAction!) in
//                                                                //                                                self.GCEnabled = !self.GCEnabled
//                                                                try! realm.write({
//                                                                    GV.player!.GCEnabled = GCEnabledType.AskForGameCenter.rawValue
//                                                                })
//
//                    })
//                    alert.addAction(connectToGamecenter)
                default:
                    break
            }

            if GV.player!.GCEnabled == GCEnabledType.GameCenterEnabled.rawValue {
                let gameCenterAction = UIAlertAction(title: GV.language.getText(.tcShowGameCenter), style: .default,
                                                handler: {(paramAction:UIAlertAction!) in
                                                    self.goToGameCenter(countPackages: GV.actGame!.countPackages, level: self.levelIndex + 1)
                })
                alert.addAction(gameCenterAction)
            }
            if !firstStart {
                let againAction = UIAlertAction(title: GV.language.getText(.tcGameAgain), style: .default,
                    handler: {(paramAction:UIAlertAction!) in
                        self.startNewGame(next: false)
                })
                alert.addAction(againAction)
            }
            let newGameAction = UIAlertAction(title: GV.language.getText(TextConstants.tcNewGame), style: .default,
                handler: {(paramAction:UIAlertAction!) in
//                    realm.beginWrite()
//                    GV.player!.levelID += 1
//                    GV.player!.levelID %= GV.levelsForPlay.count()
//                    if GV.player!.levelID == 0 {
//                        GV.player!.countPackages += 1
//                        if GV.player!.countPackages > GV.maxPackageCount {
//                            GV.player!.countPackages = 1
//                        }
//                    }
//                    try! realm.commitWrite()
                    self.startNewGame(next: true)
                    //self.gameArrayChanged = true

            })
            alert.addAction(newGameAction)
            
            let nextLevelAction = UIAlertAction(title: GV.language.getText(TextConstants.tcNextLevel), style: .default,
                                                handler: {(paramAction:UIAlertAction!) in
                                                    realm.beginWrite()
                                                    GV.player!.levelID += 1
                                                    GV.player!.levelID %= GV.levelsForPlay.count()
                                                    if GV.player!.levelID == 0 {
                                                        GV.player!.countPackages += 1
                                                        if GV.player!.countPackages > GV.maxPackageCount {
                                                            GV.player!.countPackages = GV.maxPackageCount
                                                            GV.player!.levelID = GV.levelsForPlay.count() - 1
                                                        }
                                                    }
                                                    try! realm.commitWrite()
                                                    self.startNewGame(next: true)
                                                    //self.gameArrayChanged = true
                                                    
            })
            alert.addAction(nextLevelAction)
            
            let previousLevelAction = UIAlertAction(title: GV.language.getText(TextConstants.tcPreviousLevel), style: .default,
                                                handler: {(paramAction:UIAlertAction!) in
                                                    realm.beginWrite()
                                                    GV.player!.levelID -= 1
//                                                    GV.player!.levelID %= GV.levelsForPlay.count()
                                                    if GV.player!.levelID < 0 {
                                                        GV.player!.levelID = GV.levelsForPlay.count() - 1
                                                        GV.player!.countPackages -= 1
                                                        if GV.player!.countPackages < 1 {
                                                            GV.player!.countPackages = 1
                                                            GV.player!.levelID = 1
                                                        }
                                                    }
                                                    try! realm.commitWrite()
                                                    self.startNewGame(next: true)
                                                    //self.gameArrayChanged = true
                                                    
            })
            alert.addAction(previousLevelAction)
            
            let chooseLevelAction = UIAlertAction(title: GV.language.getText(.tcChooseLevel), style: .default,
                                           handler: {(paramAction:UIAlertAction!) in
                                            self.chooseLevelAndOptions()
            })
            alert.addAction(chooseLevelAction)
            
            #if TEST
                
                let autoPlayActionNormal = UIAlertAction(title: GV.language.getText(.tcAutoPlayNormal), style: .default,
                                                         handler: {(paramAction:UIAlertAction!) in
                                                            self.startAutoplay(testType: .runOnce)
                })
                alert.addAction(autoPlayActionNormal)
            
//                let autoPlayActionNewTest = UIAlertAction(title: GV.language.getText(.tcAutoPlayNewTest), style: .default,
//                                                   handler: {(paramAction:UIAlertAction!) in
//                                                    self.startAutoplay(testType: .newTest)
//                })
//                alert.addAction(autoPlayActionNewTest)
//
//                let autoPlayActionErrors = UIAlertAction(title: GV.language.getText(.tcAutoPlayErrors), style: .default,
//                                                   handler: {(paramAction:UIAlertAction!) in
//                                                    self.startAutoplay(testType: .fromDB)
//                })
//                alert.addAction(autoPlayActionErrors)
//
//                let autoPlayActionTable = UIAlertAction(title: GV.language.getText(.tcAutoPlayTable), style: .default,
//                                                         handler: {(paramAction:UIAlertAction!) in
//                                                            self.startAutoplay(testType: .fromTable)
//                })
//                alert.addAction(autoPlayActionTable)
//
//                let autoStepActionTable = UIAlertAction(title: GV.language.getText(.tcActivateAutoPlay), style: .default,
//                                                        handler: {(paramAction:UIAlertAction!) in
//                                                            self.autoPlayerActive = true
//                })
//                alert.addAction(autoStepActionTable)
//
//
            #endif


            let competitionAction = UIAlertAction(title: GV.language.getText(.tcCompetition), style: .default,
                                                  handler: {(paramAction:UIAlertAction!) in
                                                    self.choosePartner()
                                                    //self.gameArrayChanged = true
                                                    
            })
            alert.addAction(competitionAction)
            if GV.player!.GCEnabled == GCEnabledType.GameCenterEnabled.rawValue {
                let onlineGameAction = UIAlertAction(title: GV.language.getText(.tcOnlineGame), style: .default,
                                                      handler: {(paramAction:UIAlertAction!) in
                                                        self.makeMatch()
                                                        //self.gameArrayChanged = true
                                                        
                })
                alert.addAction(onlineGameAction)
            }
                
        }
        let cancelAction = UIAlertAction(title: GV.language.getText(TextConstants.tcCancel), style: .default,
            handler: {(paramAction:UIAlertAction!) in
        })
        alert.addAction(cancelAction)
        return alert
    }
    
    var matchRequest: GKMatchRequest?
    var matchMakerViewController: GKMatchmakerViewController?
    var match: GKMatch?
    var matchStarted = false
    func makeMatch() {
        matchRequest = GKMatchRequest()
        matchRequest!.minPlayers = 2
        matchRequest!.maxPlayers = 2
        matchRequest!.defaultNumberOfPlayers = 2
        matchRequest!.playerGroup = 0
        
        let matchMaker = GKMatchmaker.shared()
        matchMaker.findMatch(for: matchRequest!, withCompletionHandler: { (match: GKMatch!, error: NSError!) -> Void in
            
            if error != nil {
                print("matchmaking canceled")
                return
            }
            
            self.match = match
            self.match!.delegate = self
            if self.matchStarted == false && match.expectedPlayerCount == 0 {
                print("in here")
                //self.lookupPlayers()
                matchMaker.finishMatchmaking(for: self.match!)
            }
        } as? (GKMatch?, Error?) -> Void )

//        matchMakerViewController = GKMatchmakerViewController()
//        matchMakerViewController!.matchmakerDelegate = self
//        GV.mainViewController?.present(matchMakerViewController!, animated: true, completion: nil)
        
    }
    
    func stopCompetition() {
        GV.peerToPeerService!.sendInfo(.stopCompetition, message: [], toPeer: opponent.peerID!)
        opponent.finish = .interrupted
        playerType = .singlePlayer
        GV.peerToPeerService!.changeStatusToFree()
        checkMultiplayer()
//        showBestPlaceLineIfNeaded()
    }

    func showBestPlaceLineIfNeaded() {
        let realm = try! Realm()
        let GCEnabled = realm.objects(PlayerModel.self).filter("isActPlayer = true").first!.GCEnabled
        if GCEnabled == GCEnabledType.GameCenterEnabled.rawValue {
            bestPlaceLabel.isHidden = false
            myPlaceLabel.isHidden = false
        }
    }

    func setLevel(_ next: Bool) {
        if next {
            levelIndex = GV.levelsForPlay.getNextLevel()
        } else {
            levelIndex = GV.levelsForPlay.getPrevLevel()
        }
        try! realm.write({
            GV.player!.levelID = levelIndex
            realm.add(GV.player!, update: true)
        })
        
    }
    

    func checkContainers()->Bool {
        for index in 0..<containers.count {
            if containers[index].minValue != FirstCardValue || containers[index].maxValue % CountCardsInPackage != LastCardValue {
                return false
            }
            
        }
        return true

    }
    
    func prepareCards() {
       
        colorTab.removeAll(keepingCapacity: false)
        var cardName = 10000
        
        for cardIndex in 0..<countCardsProContainer! * countPackages {
            for containerIndex in 0..<countContainers {
                let colorTabLine = ColorTabLine(colorIndex: containerIndex, cardName: "\(cardName)",
                    cardValue: cardArray[containerIndex][cardIndex % CountCardsInPackage].cardValue) //generateValue(containerIndex) - 1)
                colorTab.append(colorTabLine)
                cardName += 1
            }
        }
        
        createCardStack()
        fillEmptyCards()
    }

    func prepareContainers() {
        let xDelta = size.width / CGFloat(countContainers)
        for index in 0..<countContainers {
            let centerX = (size.width / CGFloat(countContainers)) * CGFloat(index) + xDelta / 2
            var centerY = labelBackground.position.y
                centerY -= labelBackground.size.height / 2
                centerY -= containerSize.height // / 2
//                centerY -= containerSize.height / 4
            containers.append(MySKCard(colorIndex: NoColor, type: .containerType, value: NoColor))
            containers[index].name = "\(index)"
            containers[index].position = CGPoint(x: centerX, y: centerY)
            containers[index].size = CGSize(width: containerSize.width, height: containerSize.height)
            containers[index].column = index
            containers[index].row = NoValue
            
            containers[index].colorIndex = NoColor
            countColorsProContainer.append(countCardsProContainer!)
            addChild(containers[index])
            containers[index].reload()
        }
    }
    
    func prepareCardArray() {
        let maxY = containers[0].frame.minY
        let minY = cardPackage!.frame.maxY
//        let midY = minY + (maxY - minY) / 2
        let minX = self.frame.minX
        let maxX = self.frame.maxX
//        let midX = self.frame.midX
        
        cardTabRect.origin = CGPoint(x: minX, y: minY)
        cardTabRect.size = CGSize(width: maxX - minX, height: maxY - minY)
        
        tableCellSize = cardTabRect.width / CGFloat(countColumns)
    }
    
    func calculateCardPosition(_ column: Int, row: Int) -> CGPoint {
        let gapX = (cardTabRect.maxX - cardTabRect.minX) / ((2 * CGFloat(countColumns)) + 1)
        let gapY = (cardTabRect.maxY - cardTabRect.minY) / ((2 * CGFloat(countRows)) + 1)
        
        var x = cardTabRect.origin.x
            x += (2 * CGFloat(column) + 1.5) * gapX
        var y = cardTabRect.origin.y
            y += (2 * CGFloat(row) + 1.5) * gapY

        let point = CGPoint(
            x: x,
            y: y
        )
        return point
    }
    
    func calculateCardSizeForIPhone() {
        // 3 * 3 = 9,  3 * 4 = 12, 3 * 5 = 15, 3 * 6 = 18
        // 4 * 4 = 16, 4 * 5 = 20, 4 * 6 = 24, 4 * 7 = 28
        // 5 * 5 = 25, 5 * 6 = 30, 5 * 7 = 35, 5 * 8 = 40
        // 6 * 6 = 36, 6 * 7 = 42, 6 * 8 = 48, 6 * 9 = 54
        // 7 * 7 = 49, 7 * 8 = 56, 7 * 9 = 63, 7 * 10 = 70
        // 8 * 8 = 64, 8 * 9 = 72, 8 * 10 = 80
        // 9 * 9 = 81, 9 * 10 = 90
        // 10 * 10 = 100
        let sizeValue = countRows * countColumns
        let sizeMultiplierArray: [Int:CGFloat] = [   9: 0.5, 12: 0.55, 15: 0.6, 18: 0.7,
                                                    16: 0.48, 20: 0.55,  24: 0.6, 28: 0.7,
                                                    25: 0.55, 30: 0.55, 35: 0.65, 40: 0.7,
                                                    36: 0.6, 42: 0.65, 48: 0.7, 54: 0.75,
                                                    49: 0.6, 56: 0.65, 63: 0.7, 70: 0.75,
                                                    64: 0.65, 72: 0.70, 80: 0.75,
                                                    81: 0.70, 90: 0.70,
                                                    100: 0.70]
        let height = (gameArray[0][1].position.y - gameArray[0][0].position.y)
        let width = height * (cardSizeMultiplier.width / cardSizeMultiplier.height)
        if let sizeMultiplier = sizeMultiplierArray[sizeValue] {
            cardSize = CGSize(width: width, height: height) * sizeMultiplier
        } else {
            cardSize = CGSize(width: width, height: height) * 0.5
        }
    }



    func pull(createTipps: Bool) {
        let duration = 0.5
        var actionMoveArray = [SKAction]()
        if let savedCard:SavedCard  = stack.pull() {
            var savedCardInCycle = savedCard
            var run = true
            var stopSoon = false
            
            repeat {
                
                switch savedCardInCycle.status {
                case .added: break
                case .addedFromCardStack:
                    if stack.countChangesInStack() > 0 {
                        let cardName = savedCardInCycle.name
                        let searchName = "\(cardName)"
                        let cardToPush = self.childNode(withName: searchName)! as! MySKCard
                        cardToPush.zPosition = 20
                        cardStack.push(card: cardToPush)
                        
                        gameArray[savedCardInCycle.column][savedCardInCycle.row].used = false
//                        cardManager!.check(color: cardToPush.colorIndex)
                        makeEmptyCard(savedCardInCycle.column, row: savedCardInCycle.row)
                        let aktPosition = gameArray[savedCardInCycle.column][savedCardInCycle.row].position
                        let duration = Double((cardPackage!.position - aktPosition).length()) / 500.0
                        let actionMove = SKAction.move(to: cardPackage!.position, duration: duration)
                        let removeOldCard = SKAction.run({
                            self.childNode(withName: searchName)!.removeFromParent()
                        })
                        let actionAddCardToMovingCards = SKAction.run {
                            self.movingCards.append(cardToPush)
                        }
                        let actionRemoveCardFromMovingCards = SKAction.run {
                            self.movingCards.remove(at: self.movingCards.index(where: { $0 === cardToPush })!)
                        }
                        cardToPush.run(SKAction.sequence([actionAddCardToMovingCards,actionMove, removeOldCard, actionRemoveCardFromMovingCards]))
                    }
//                case .addedFromShowCard:
//                    if cardPlaceButtonAddedToParent {
//                        cardPlaceButton?.removeFromParent()
//                        cardPlaceButtonAddedToParent = false
//                    }
//                    let oldShowCardExists = showCard != nil
//                    var removeOldShowCard = SKAction()
//                    if oldShowCardExists {
//                        var oldShowCard = showCard
////                        showCardStack.push(showCard!)
//                        removeOldShowCard = SKAction.run({
//                            oldShowCard!.removeFromParent()
//                            oldShowCard = nil
//                        })
//                    }
//                    let cardName = savedCardInCycle.name
//                    let searchName = "\(cardName)"
//                    showCard = self.childNode(withName: searchName)! as? MySKCard
//                    showCard!.position = savedCardInCycle.endPosition //(cardPlaceButton?.position)!
//                    showCard!.size = (cardPlaceButton?.size)!
//                    showCard!.type = .showCardType
//                    self.childNode(withName: searchName)!.removeFromParent()
//                    self.addChild(showCard!)
//                    gameArray[savedCardInCycle.column][savedCardInCycle.row].used = false
//                    makeEmptyCard(savedCardInCycle.column, row: savedCardInCycle.row)
//                    let actionMove = SKAction.move(to: cardPlaceButton!.position, duration: 0.5)
//                    let actionAddCardToMovingCards = SKAction.run {
//                        self.movingCards.append(self.showCard!)
//                    }
//                    let actionRemoveCardFromMovingCards = SKAction.run {
//                        self.movingCards.remove(at: self.movingCards.index(where: { $0 === self.showCard! })!)
//                    }
//                    if oldShowCardExists {
//                        showCard!.run(SKAction.sequence([actionAddCardToMovingCards, actionMove, removeOldShowCard, actionRemoveCardFromMovingCards]))
//                    } else {
//                        showCard!.run(SKAction.sequence([actionAddCardToMovingCards, actionMove, actionRemoveCardFromMovingCards]))
//                    }
                case .removed:
                    //let cardTexture = SKTexture(imageNamed: "card\(savedCardInCycle.colorIndex)")
//                    let card = MySKCard(colorIndex: savedCardInCycle.colorIndex, type: savedCardInCycle.type, value: savedCardInCycle.minValue)
                    
                    if let card = savedCardInCycle.card {
                        card.colorIndex = savedCardInCycle.colorIndex
                        card.position = savedCardInCycle.endPosition
                        card.startPosition = savedCardInCycle.startPosition
                        card.size = savedCardInCycle.size
                        card.column = savedCardInCycle.column
                        card.row = savedCardInCycle.row
                        card.minValue = savedCardInCycle.minValue
                        card.maxValue = savedCardInCycle.maxValue
                        card.BGPictureAdded = savedCardInCycle.BGPictureAdded
                        card.countTransitions = savedCardInCycle.countTransitions
                        card.name = savedCardInCycle.name
                        card.mirrored = 0
                        levelScore = savedCardInCycle.countScore
     
                        cardManager!.updateGameArrayCell(card: card)
//                        cardManager!.check(color: card.colorIndex)
                        self.addChild(card)
                        updateCardCount(1)
//                        deleteLastHistoryRecord()
                        card.reload()
                    }
                    
                case .unification:
                    let card = self.childNode(withName: savedCardInCycle.name)! as! MySKCard
                    card.size = savedCardInCycle.size
                    card.minValue = savedCardInCycle.minValue
                    card.maxValue = savedCardInCycle.maxValue
                    card.BGPictureAdded = savedCardInCycle.BGPictureAdded
                    card.countTransitions = savedCardInCycle.countTransitions
                    if card.type == .cardType {
                        cardManager!.updateGameArrayCell(card: card)
                    }
//                    cardManager!.check(color: card.colorIndex)
                    //card.hitLabel.text = "\(card.hitCounter)"
                    card.reload()
                    
                case .firstCardAdded:
                    let container = containers[findIndex(savedCardInCycle.colorIndex)]
                    container.minValue = savedCardInCycle.minValue
                    container.maxValue = savedCardInCycle.maxValue
                    container.BGPictureAdded = savedCardInCycle.BGPictureAdded
                    container.countTransitions = savedCardInCycle.countTransitions
                    container.colorIndex = NoColor
                    container.belongsToPackageMax = allPackages
                    container.belongsToPackageMin = allPackages
                    container.reload()
                    
                    
                case .movingStarted:
                    let card = self.childNode(withName: savedCardInCycle.name)! as! MySKCard
                    card.startPosition = savedCardInCycle.startPosition
                    card.minValue = savedCardInCycle.minValue
                    card.maxValue = savedCardInCycle.maxValue

                    cardManager!.updateGameArrayCell(card: card)
//                    cardManager!.check(color: card.colorIndex)
                    card.BGPictureAdded = savedCardInCycle.BGPictureAdded
                    card.countTransitions = savedCardInCycle.countTransitions
                    actionMoveArray.append(SKAction.move(to: savedCardInCycle.endPosition, duration: duration))
                    actionMoveArray.append(SKAction.run({
                            self.cardManager!.removeNodesWithName("\(self.emptyCardTxt)-\(card.column)-\(card.row)")
                        })
                    )
                    let actionAddCardToMovingCards = SKAction.run {
                        self.movingCards.append(card)
                    }
                    let actionRemoveCardFromMovingCards = SKAction.run {
                        self.movingCards.remove(at: self.movingCards.index(where: { $0 === card })!)
                    }
                    actionMoveArray.insert(actionAddCardToMovingCards, at: 0)
                    actionMoveArray.append(actionRemoveCardFromMovingCards)
                    card.run(SKAction.sequence(actionMoveArray))
                    card.reload()
                    
//                case .fallingMovingCard:
////                    let card = self.childNodeWithName(savedCardInCycle.name)! as! MySKCard
//                    actionMoveArray.append(SKAction.move(to: savedCardInCycle.endPosition, duration: duration))
//                    
//                case .fallingCard:
//                    let card = self.childNode(withName: savedCardInCycle.name)! as! MySKCard
//                    card.startPosition = savedCardInCycle.startPosition
//                    let moveFallingCard = SKAction.move(to: savedCardInCycle.startPosition, duration: duration)
//                    card.run(SKAction.sequence([moveFallingCard]))
                    
                case .mirrored:
                    //var card = self.childNodeWithName(savedCardInCycle.name)! as! MySKCard
                    actionMoveArray.append(SKAction.move(to: savedCardInCycle.endPosition, duration: duration))
                case .stopCycle: break
                case .nothing: break
                }
                if let savedCard:SavedCard = stack.pull() {
                    savedCardInCycle = savedCard
                    if ((savedCardInCycle.status == .addedFromCardStack /*|| savedCardInCycle.status == .addedFromShowCard*/) && stack.countChangesInStack() == 0) || stopSoon  || savedCardInCycle.status == .stopCycle {
                        stack.push(card: savedCardInCycle)
                        run = false
                    }
                    if savedCardInCycle.status == .movingStarted {
                        stopSoon = true
                    }
                } else {
                    run = false
                }
            } while run
            generateCards(generatingType: .normal)  // Nachgenerierung
            showScore()
        }
        
        if createTipps {
            lastChange.color = NoColor
            gameArrayChanged = true
        }
        //printFunc(function: "pull", start: false)

    }
    
    private func findIndex(_ colorIndex: Int)->Int {
        for index in 0..<countContainers {
            if containers[index].colorIndex == colorIndex {
                return index
            }
        }
        return NoColor
    }
    
    func readNextLevel() -> Int {
        return GV.levelsForPlay.getNextLevel()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let firstTouch = touches.first
        let touchLocation = firstTouch!.location(in: self)
        myTouchesBegan(touchLocation: touchLocation)
    }
    
    var touchLocationForMyTouchesBegan: CGPoint = CGPoint(x: 0, y: 0)
    var waitingInMyTouchesBegan: Bool = false
    
    @objc func myTouchesBegan(touchLocation: CGPoint) {
        var touchLocationParam: CGPoint// = CGPoint(x: 0, y: 0)
        if waitingInMyTouchesBegan {
            touchLocationParam = touchLocationForMyTouchesBegan
        } else {
            touchLocationParam = touchLocation
        }
        if movingCards.count == 0 {
            waitingInMyTouchesBegan = false
            myTouchesBeganContinued(touchLocation: touchLocationParam)
        } else {
            if !waitingInMyTouchesBegan {
                touchLocationForMyTouchesBegan = touchLocation // save the orig
                waitingInMyTouchesBegan = true
            }
            _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.myTouchesBegan(touchLocation: )), userInfo: touchLocationParam, repeats: false)
            // start timer for check

        }
        
    }
    func myTouchesBeganContinued(touchLocation: CGPoint) {
        
        oldFromToColumnRow = FromToColumnRow()
        lastPair.color = .none
        lineWidthMultiplier = lineWidthMultiplierNormal
        touchesBeganAt = Date()
        inTouches = true
        movedFromNode = nil
        let nodes = self.nodes(at: touchLocation)
        for node in nodes {
            switch node  {
                case is MySKButton:
                    movedFromNode = (node as! MySKButton) as MySKCard
                    if movedFromNode.name! == helpButtonName && autoPlayerActive {
                        autoPlayer!.stopAutoplay()
                    }
                case is MySKCard:
                    if (node as! MySKCard).type == .cardType {
                        movedFromNode = (node as! MySKCard)
                        self.addChild(showValue(movedFromNode))
                        if showFingerNode {
                            let fingerNode = SKSpriteNode(imageNamed: "finger.png")
                            fingerNode.name = fingerName
                            fingerNode.position = touchLocation
                            fingerNode.size = CGSize(width: 50,height: 50)
                            fingerNode.zPosition = 100
                            addChild(fingerNode)
                        }
                    }
                    break
                default:
                    dummy = 0
            }
        }
        
        
        if movedFromNode != nil {
            movedFromNode.zPosition = 50
        }
        
        if cardManager!.tremblingCards.count > 0 {
            cardManager!.stopTrembling()
            cardManager!.removeNodesWithName(myLineName)
        }
    }
    
    
    func showValue(_ card: MySKCard)->SKSpriteNode {
        let score = SKLabelNode()
        let showValueDelta = card.size.width * 1.0
        let delta = CGPoint(x: showValueDelta, y: showValueDelta)
        score.position = card.position + delta
        score.text = String(card.countScore)
        score.fontColor = UIColor.white
        score.fontName = "ArialMT"
        score.fontSize = 30
        score.zPosition = 1000
        
        let labelBackground = SKSpriteNode()
        labelBackground.size = score.frame.size * 1.3
        labelBackground.position = score.position
        score.position = CGPoint(x: 0, y: 0)
        score.verticalAlignmentMode = .center
        labelBackground.color = UIColor.gray
    
        labelBackground.addChild(score)
        
        let showAction = SKAction.sequence([SKAction.fadeIn(withDuration: 0.5), SKAction.fadeOut(withDuration: 1.5), SKAction.removeFromParent()])
        let scoreActions = SKAction.group([showAction])
        labelBackground.run(scoreActions)
        return labelBackground
        
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let firstTouch = touches.first
        let touchLocation = firstTouch!.location(in: self)
        myTouchesMoved(touchLocation: touchLocation)
    }
    
    func myTouchesMoved(touchLocation: CGPoint) {
        if inGeneratingCards || movingCards.count > 0 {
            return
        }
        if movedFromNode != nil {
            cardManager!.removeNodesWithName(myLineName)

            //let countTouches = touches.count
            
            var aktNode: SKNode? = movedFromNode
            
            let testNode = self.atPoint(touchLocation)
            let aktNodeType = analyzeNode(testNode)
//            var myLine: SKShapeNode = SKShapeNode()
            switch aktNodeType {
                case MyNodeTypes.LabelNode: aktNode = self.atPoint(touchLocation).parent as! MySKCard
                case MyNodeTypes.CardNode: aktNode = self.atPoint(touchLocation) as! MySKCard
                case MyNodeTypes.ButtonNode: aktNode = self.atPoint(touchLocation) as! MySKCard
                default: aktNode = nil
            }
            if movedFromNode == aktNode && cardManager!.tremblingCards.count > 0 { // stop trembling
                lastPair.color = .none
                cardManager!.stopTrembling()
                cardManager!.lastNextPoint = nil
            } else if movedFromNode != aktNode {
                if movedFromNode.type == .buttonType {
                    //movedFromNode.texture = atlas.textureNamed("\(movedFromNode.name!)")
                } else if movedFromNode.type == .emptyCardType {
                    
                } else {
                    var movedFrom = ColumnRow()
                    movedFrom.column = movedFromNode.column
                    movedFrom.row = movedFromNode.row
                    
                    let (foundedPoint, myPoints) = cardManager!.createHelpLines(movedFrom: movedFrom, toPoint: touchLocation, inFrame: self.frame, lineSize: movedFromNode.size.width, showLines: true)
                    var actFromToColumnRow = FromToColumnRow()
                    actFromToColumnRow.fromColumnRow = movedFrom
                    actFromToColumnRow.toColumnRow.column = foundedPoint!.column
                    actFromToColumnRow.toColumnRow.row = foundedPoint!.row
                    let color = cardManager!.calculateLineColor(foundedPoint: foundedPoint!, movedFrom: movedFrom)
                    switch color {
                    case .green :
                        if lastPair.color == .none || lastPair.color == .red {
                            lastPair.setValue(.green, pair: actFromToColumnRow, founded: foundedPoint!, startTime: Date(), points: myPoints)
                        } else if lastPair.color == .green && lastPair.pair ==  actFromToColumnRow && lastPair.points.count == myPoints.count {
                            lastPair.points = myPoints
                        } else if lastPair.points.count <= myPoints.count { // other longer green pair found
                            lastPair.setValue(.green, pair: actFromToColumnRow, founded: foundedPoint!, startTime: Date(), points: myPoints)
                        } else { // other green pair found
                            lineWidthMultiplier = lineWidthMultiplierNormal
                            if lastPair.fixed {
                                if lastPair.changeTime == lastPair.startTime { // first time changed
                                    lastPair.changeTime = Date()
                                } else {
                                    if Date().timeIntervalSince(lastPair.changeTime) > fixationTime {
                                        lastPair.setValue(.green, pair: actFromToColumnRow, founded: foundedPoint!, startTime: Date(), points: myPoints)                                }
                                }
                            } else {
//                                lastPair.setValue(.Red, pair: actFromToColumnRow, founded: foundedPoint!, startTime: NSDate(), points: myPoints)
                            }
                        }
                        
                    case .red:
                        lastPair.setValue(.red)
                        lineWidthMultiplier = lineWidthMultiplierNormal
                        cardManager!.drawHelpLinesSpec()
                        if lastPair.fixed {
                            if lastPair.changeTime == lastPair.startTime {
                                lastPair.changeTime = Date()
                            } else {
                                if Date().timeIntervalSince(lastPair.changeTime) > 0.5 {
                                    lastPair.setValue(.green, pair: actFromToColumnRow, founded: foundedPoint!, startTime: Date(), points: myPoints)                                }
                            }
                        } else {
                            lastPair.setValue(.red, pair: actFromToColumnRow, founded: foundedPoint!, startTime: Date(), points: myPoints)
                        }
                    default: break

                    }
                }
            }
            
            if showFingerNode {
                
                if let fingerNode = self.childNode(withName: fingerName)! as? SKSpriteNode {
                    fingerNode.position = touchLocation
                }
                
            }
        }
    }
    
    enum TouchType: Int {
        case manual = 0, auto
    }
    var touchType: TouchType = .manual
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchType = .manual
        durationMultiplier = durationMultiplierForPlayer
        let firstTouch = touches.first
        let touchLocation = firstTouch!.location(in: self)
        myTouchesEnded(touchLocation: touchLocation)
    }
    
    func autoTouchesEnded(touchLocation: CGPoint) {
        touchType = .auto
        durationMultiplier = durationMultiplierForAutoplayer
        myTouchesEnded(touchLocation: touchLocation)
    }
    
    func myTouchesEnded(touchLocation: CGPoint) {
        if inGeneratingCards || movingCards.count > 0 {
            return
        }
        cardManager!.stopTrembling()
        cardManager!.removeNodesWithName(myLineName)
        if showFingerNode {
            while true {
                if let node = self.childNode(withName: fingerName) {
                    node.removeFromParent()
                } else {
                    break
                }
            }
        }
        let testNode = self.atPoint(touchLocation)
        
        let aktNodeType = analyzeNode(testNode)
        if movedFromNode != nil && !stopped {
            //let countTouches = touches.count
            var aktNode: MySKCard?
            
            movedFromNode.zPosition = 0
            let startNode = movedFromNode
            
            switch aktNodeType {
            case MyNodeTypes.LabelNode: aktNode = testNode.parent as? MySKCard
            case MyNodeTypes.CardNode: aktNode = testNode as? MySKCard
            case MyNodeTypes.ButtonNode:
                aktNode = (testNode as! MySKCard).parent as? MySKCard
            default: aktNode = nil
            }
            
            if aktNode != nil && aktNode!.type == .buttonType && startNode?.type == .buttonType && aktNode!.name == movedFromNode.name {
                //            if aktNode != nil && MySKCard.type == .ButtonType && startNode.type == .ButtonType  {
                var MySKCard = aktNode!
                
                //                var name = (aktNode as! MySKCard).parent!.name
                if MySKCard.name == buttonName {
                    MySKCard = (MySKCard.parent) as! MySKCard
                }
                //switch (aktNode as! MySKCard).name! {
                switch MySKCard.name! {
                case settingsButtonName: settingsButtonPressed()
                case undoButtonName: undoButtonPressed()
                case restartButtonName: restartButtonPressed()
                case helpButtonName: helpButtonPressed()
                default: specialButtonPressed(MySKCard.name!)
                }
                return
            }
            
            if startNode!.type == .cardType && movedFromNode != nil && (aktNode == nil || aktNode! != movedFromNode) {
                startMovingCard(touchLocation: touchLocation)
            } else {
//                startTippTimer()
            }
            
        } else {
//            startTippTimer()
        }
        inTouches = false
    }
    
    @objc func waitWhileInGeneratingCards() {
        while inGeneratingCards {
            self.waitWhileInGeneratingCardsTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(CardGameScene.waitWhileInGeneratingCards), userInfo: nil, repeats: false) // start timer for check
        }
        self.waitWhileInGeneratingCardsTimer?.invalidate()
    }
    
    func startMovingCard(touchLocation: CGPoint) {
        waitWhileInGeneratingCards()
        let card = movedFromNode// as! SKSpriteNode
        let movedFrom = ColumnRow(column: movedFromNode.column, row: movedFromNode.row)
        var (foundedPoint, myPoints) = cardManager!.createHelpLines(movedFrom: movedFrom, toPoint: touchLocation, inFrame: self.frame, lineSize: movedFromNode.size.width, showLines: false)
        var actFromToColumnRow = FromToColumnRow()
        actFromToColumnRow.fromColumnRow = movedFrom
        actFromToColumnRow.toColumnRow.column = foundedPoint!.column
        actFromToColumnRow.toColumnRow.row = foundedPoint!.row
        
        var color = cardManager!.calculateLineColor(foundedPoint: foundedPoint!, movedFrom: movedFrom)
        
        if lastPair.fixed {
            actFromToColumnRow.toColumnRow.column = lastPair.pair.toColumnRow.column
            actFromToColumnRow.toColumnRow.row = lastPair.pair.toColumnRow.row
            myPoints = lastPair.points // set Back to last green line
            color = .green
        }
        
        lastPair = PairStatus()
        push(card!, status: .movingStarted)
        
        
        let countAndPushAction = SKAction.run({
            self.push(card!, status: .mirrored)
        })
        
        let actionEmpty = SKAction.run({
            self.makeEmptyCard((card?.column)!, row: (card?.row)!)
        })
        
        let speed = CGFloat(durationMultiplier)
        
        card?.zPosition += 5
        
        //                var mirroredScore = 0
        
        var actionArray = [SKAction]()
        actionArray.append(actionEmpty)
        actionArray.append(SKAction.move(to: myPoints[1], duration: Double((myPoints[1] - myPoints[0]).length() * speed)))
        
        let soundArray = ["Mirror1", "Mirror2", "Mirror3", "Mirror4", "Mirror5"]
        for pointsIndex in 2...6 {
            if myPoints.count > pointsIndex {
                if color == .green {
                    actionArray.append(SKAction.run({
                        self.movedFromNode.mirrored += 1
//                        self.addChild(self.showCountScore("+\(self.movedFromNode.countScore)", position: (card?.position)!))
                        self.playSound(soundArray[pointsIndex - 2], volume: GV.player!.soundVolume, soundPlayerIndex: pointsIndex - 2)
                    }))
                }
                
                actionArray.append(countAndPushAction)
                actionArray.append(SKAction.move(to: myPoints[pointsIndex], duration: Double((myPoints[pointsIndex] - myPoints[pointsIndex - 1]).length() * speed)))
            }
        }
        var collisionAction: SKAction
        if actFromToColumnRow.toColumnRow.row == NoValue {
            let containerNode = containers[actFromToColumnRow.toColumnRow.column] //self.childNode(withName: containers[actFromToColumnRow.toColumnRow.column].name!) as! MySKCard
            collisionAction = SKAction.run({
                self.cardDidCollideWithContainer(node1: self.movedFromNode, node2: containerNode, points: myPoints)
            })
        } else {
            let cardNode = gameArray[actFromToColumnRow.toColumnRow.column][actFromToColumnRow.toColumnRow.row].card
            
            //                    let cardNode = self.childNode(withName: gameArray[actFromToColumnRow.toColumnRow.column][actFromToColumnRow.toColumnRow.row].name) as! MySKCard
            //                    let startNode = gameArray[movedFromNode.column][movedFromNode.row].card
            collisionAction = SKAction.run({
                self.cardDidCollideWithMovingCard(node1: self.movedFromNode, node2: cardNode, points: myPoints)
            })
        }
        let userInteractionEnablingAction = SKAction.run({
            self.isUserInteractionEnabled = true
            self.checkGameFinished()
        })
        actionArray.append(collisionAction)
        actionArray.append(userInteractionEnablingAction)
        
        tippsButton!.activateButton(false)
        
        
        
        
        //let actionMoveDone = SKAction.removeFromParent()
        //                collisionActive = true
        lastMirrored = ""
        
        self.isUserInteractionEnabled = false  // userInteraction forbidden!
//        countMovingCards = 1
        waitForMovingCards()
//        self.waitForSKActionEndedTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.waitForMovingCards), userInfo: nil, repeats: false) // start timer for check
        let actionAddCardToMovingCards = SKAction.run {
            self.movingCards.append(self.movedFromNode)
        }
        let actionRemoveCardFromMovingCards = SKAction.run {
            self.movingCards.remove(at: self.movingCards.index(where: { $0 === self.movedFromNode })!)
        }
        actionArray.insert(actionAddCardToMovingCards, at: 0)
        actionArray.append(actionRemoveCardFromMovingCards)
        
        movedFromNode.run(SKAction.sequence(actionArray))

    }

    
    func ActionsForMirroring(_ card: MySKCard, adder: Int, color: MyColors, fromPoint: CGPoint, toPoint: CGPoint)->[SKAction] {
        var actions = [SKAction]()
        if color == .green {
            actions.append(SKAction.run({
//                self.addChild(self.showCountScore("+\(adder)", position: card.position))
                self.push(card, status: .mirrored)
            }))
        }
        
//        actionArray.append(countAndPushAction)
        actions.append(SKAction.move(to: toPoint, duration: Double((toPoint - fromPoint).length() * speed)))

        return actions
    }
    
    func removeShowCardFromStack() {
        if showCardFromStackAddedToParent {
            showCardFromStack!.removeFromParent()
            showCardFromStack = nil
            showCardFromStackAddedToParent = false
        }
        if cardPlaceButtonAddedToParent {
            cardPlaceButton!.removeFromParent()
            cardPlaceButtonAddedToParent = false
        }
    }

    
    func playMusic(_ fileName: String, volume: Float, loops: Int) {
        if volume > 0 {
            let url = URL(
                fileURLWithPath: Bundle.main.path(forResource: fileName, ofType: "m4a")!)
            do {
                try musicPlayer = AVAudioPlayer(contentsOf: url)
                musicPlayer?.delegate = self
                musicPlayer?.prepareToPlay()
                musicPlayer?.volume = 0.001 * volume
                musicPlayer?.numberOfLoops = loops
                musicPlayer?.play()
            } catch {
                print("audioPlayer error")
            }
        }
    }
    
    func playSound(_ fileName: String, volume: Float) {
        if volume > 0 {
            let url = URL(
                fileURLWithPath: Bundle.main.path(forResource: fileName, ofType: "m4a")!)
            
            do {
                try soundPlayer = AVAudioPlayer(contentsOf: url)
                soundPlayer?.delegate = self
                soundPlayer?.prepareToPlay()
                soundPlayer?.volume = 0.001 * volume
                soundPlayer?.numberOfLoops = 0
                soundPlayer?.play()
            } catch {
                print("soundPlayer error")
            }
        }
    }
    
    func playSound(_ fileName: String, volume: Float, soundPlayerIndex: Int) {
        if volume > 0 {
            let url = URL(
                fileURLWithPath: Bundle.main.path(forResource: fileName, ofType: "m4a")!)
            
            do {
                try soundPlayerArray[soundPlayerIndex] = AVAudioPlayer(contentsOf: url)
                soundPlayerArray[soundPlayerIndex]!.delegate = self
                soundPlayerArray[soundPlayerIndex]!.prepareToPlay()
                soundPlayerArray[soundPlayerIndex]!.volume = 0.001 * volume
                soundPlayerArray[soundPlayerIndex]!.numberOfLoops = 0
                soundPlayerArray[soundPlayerIndex]!.play()
            } catch {
                print("soundPlayer error")
            }
        }        
    }
    
    
//    func calculateColumnRowFromPosition(_ position: CGPoint)->ColumnRow {
//        var columnRow  = ColumnRow()
//        let offsetToFirstPosition = position - gameArray[0][0].position
//        let tableCellSize = gameArray[1][1].position - gameArray[0][0].position
//        
//        
//        columnRow.column = Int(round(Double(offsetToFirstPosition.x / tableCellSize.x)))
//        columnRow.row = Int(round(Double(offsetToFirstPosition.y / tableCellSize.y)))
//        return columnRow
//    }
//    
//    func makeLineAroundGameboard(_ linePosition: LinePosition) {
//        var myWallP1: CGPoint
//        var myWallP2: CGPoint
//
//        let lineSize: CGFloat = size.width / 100
//        switch linePosition {
//        case .bottomHorizontal:
//            myWallP1 = CGPoint(x: position.x, y: position.y)
//            myWallP2 = CGPoint(x: size.width, y: myWallP1.y)
//        case .rightVertical:
//            myWallP1 = CGPoint(x: position.x + size.width, y: position.y)
//            myWallP2 = CGPoint(x: myWallP1.x, y: size.height)
//        case .upperHorizontal:
//            myWallP1 = CGPoint(x: position.x, y: position.y + size.height)
//            myWallP2 = CGPoint(x: size.width, y: myWallP1.y)
//        case .leftVertical:
//            myWallP1 = CGPoint(x: position.x, y: position.y)
//            myWallP2 = CGPoint(x: myWallP1.x, y: size.height)
//         }
//
//        let pathToDraw:CGMutablePath = CGMutablePath()
//
//        let myWallLine:SKShapeNode = SKShapeNode()
//        myWallLine.lineWidth = lineSize
//        myWallLine.name = linePosition.linePositionName
//        pathToDraw.move(to: myWallP1)
//        pathToDraw.addLine(to: myWallP2)
//
//        myWallLine.path = pathToDraw
//
//        myWallLine.strokeColor = UIColor.green
//
//        self.addChild(myWallLine)
//    }
//
    func makeLinesAroundGameboard(color: UIColor) {
        let lineSize: CGFloat = size.width / 100
        let path:CGMutablePath = CGMutablePath()
        if GV.deviceType == iPhone_X {
            let adder = lineSize / 2
            let radius: CGFloat = size.width / 9.7
            let point1 = CGPoint(x: position.x + adder, y: size.height - radius + adder)
            path.move(to: point1)
            let point2 = CGPoint(x: point1.x, y: position.y + radius + adder)
            path.addLine(to: point2)
            let center1 = CGPoint(x: position.x + radius + adder, y: position.y + radius + adder)
            path.addArc(center: center1, radius: radius, startAngle: 180 * GV.oneGrad, endAngle: 270 * GV.oneGrad, clockwise: false)
            let point3 = CGPoint(x: size.width - radius - adder, y: position.y + adder)
            path.addLine(to: point3)
            let center2 = CGPoint(x: point3.x, y: position.y + radius + adder)
            path.addArc(center: center2, radius: radius, startAngle: 270 * GV.oneGrad, endAngle: 0 * GV.oneGrad, clockwise: false)
            let point4 = CGPoint(x: size.width - adder, y: size.height - radius + adder)
            path.addLine(to: point4)
        } else {
            let points: [CGPoint] =
            [
                CGPoint(x: position.x, y: position.y),
                CGPoint(x: size.width, y: position.y),
                CGPoint(x: size.width, y: size.height),
                CGPoint(x: position.x, y: size.height),
                CGPoint(x: position.x, y: position.y),
            ]
            path.addLines(between: points)
        }
        let myWallLine:SKShapeNode = SKShapeNode()
        myWallLine.path = path
        myWallLine.strokeColor = color
        myWallLine.lineWidth = lineSize

        
        self.addChild(myWallLine)
    }

    func push(_ card: MySKCard, status: CardStatusInStack) {
        var savedCard = SavedCard()
        savedCard.card = card
        savedCard.type = card.type
        savedCard.name = card.name!
        savedCard.status = status
        savedCard.startPosition = card.startPosition
        savedCard.endPosition = card.position
        savedCard.colorIndex = card.colorIndex
        savedCard.size = card.size
        savedCard.countScore = levelScore
        savedCard.minValue = card.minValue
        savedCard.maxValue = card.maxValue
        savedCard.countTransitions = card.countTransitions
        savedCard.column = card.column
        savedCard.row = card.row
        stack.push(card: savedCard)
    }
    
    func showScore() {
    }
    
    
    func analyzeNode (_ node: AnyObject) -> UInt32 {
        let testNode = node as! SKNode
        switch node  {
        case is CardGameScene: return MyNodeTypes.MyGameScene
        case is SKLabelNode:
            switch testNode.parent {
            case is CardGameScene: return MyNodeTypes.MyGameScene
            case is SKSpriteNode: return MyNodeTypes.none
            default: break
            }
            return MyNodeTypes.LabelNode
        case is MySKCard:
            var MySKCard: MySKCard = (testNode as! MySKCard)
            switch MySKCard.type {
            case .containerType: return MyNodeTypes.ContainerNode
            case .cardType, .emptyCardType/*, .showCardType*/: return MyNodeTypes.CardNode
            case .buttonType:
                if MySKCard.name == buttonName {
                    MySKCard = MySKCard.parent as! MySKCard
                }
                return MyNodeTypes.ButtonNode
            }
        default: return MyNodeTypes.none
        }
    }

    func prepareHelpButtonForStepByStep(callBack: ()->()) {
    }
    

    func helpButtonPressed() {
        if autoPlayerActive {
            autoPlayer!.stopAutoplay()
        } else {
            doTimeCount = false
            let url = GV.language.getText(.tcHelpURL)
            if let url = URL(string: url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
            doTimeCount = true
        }
    }
    var SKPlayerObject: MySKPlayer?
    var SKSliderObject: MySKSlider?
    var SKLanguagesObject: MySKLanguages?
    
    func settingsButtonPressed() {
        #if TEST
            let arrow = UIBezierPath.arrow(from: CGPoint(x:10, y:10), to: CGPoint(x:200, y:180),tailWidth: 10, headWidth: 30, headLength: 40)
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = arrow.cgPath
        gameCenterSync.printAllGamers()
        #endif
        playMusic("NoSound", volume: GV.player!.musicVolume, loops: 0)
        doTimeCount = false
//        countUpAdder = 0
        inSettings = true
            let parentNode = SKSpriteNode()
            self.addChild(parentNode)
            let alert = UIAlertController(title: GV.language.getText(.tcSettings),
                                          message: "",
                                          preferredStyle: .alert)
//            nameLabel.text = GV.language.getText(.tcChooseName)
//            soundLabel.text = GV.language.getText(.tcSoundVolume)
//            musicLabel.text = GV.language.getText(.tcMusicVolume)
//            languageLabel.text = GV.language.getText(.tcLanguage)
//            playerStatisticLabel.text = GV.language.getText(.tcStatistic)
//            writeReviewLabel.text = GV.language.getText(.tcWriteReview)
//            returnLabel.text = GV.language.getText(.tcReturn)
            let chooseNameAction = UIAlertAction(title: GV.language.getText(.tcChooseName), style: .default,
                                           handler: {(paramAction:UIAlertAction!) in
                                            self.SKPlayerObject = MySKPlayer(parent: parentNode, view: self.view!, callBack: self.comeBackFromSettings)

            })
            alert.addAction(chooseNameAction)
            let soundVolumeAction = UIAlertAction(title: GV.language.getText(.tcSoundVolume), style: .default,
                                                 handler: {(paramAction:UIAlertAction!) in
                                                    self.SKSliderObject = MySKSlider(parent: parentNode, soundType: .sound, callBack: self.comeBackFromSettings)
            })
            alert.addAction(soundVolumeAction)
            let musicVolumeAction = UIAlertAction(title: GV.language.getText(.tcMusicVolume), style: .default,
                                                  handler: {(paramAction:UIAlertAction!) in
                                                    self.SKSliderObject = MySKSlider(parent: parentNode, soundType: .music, callBack: self.comeBackFromSettings)
            })
            alert.addAction(musicVolumeAction)
            let chooseLanguageAction = UIAlertAction(title: GV.language.getText(.tcChooseLanguage), style: .default,
                                                  handler: {(paramAction:UIAlertAction!) in
                                                    self.SKLanguagesObject = MySKLanguages(parent: parentNode, callBack: self.comeBackFromSettings)
            })
            alert.addAction(chooseLanguageAction)
            let playerStatisticAction = UIAlertAction(title: GV.language.getText(.tcStatistic), style: .default,
                                                     handler: {(paramAction:UIAlertAction!) in
                                                        let _ = MySKStatistic(parent: parentNode, callBack: self.comeBackFromSettingsWithStart)
            })
            alert.addAction(playerStatisticAction)
            let writeReviewAction = UIAlertAction(title: GV.language.getText(.tcWriteReview), style: .default,
                                                     handler: {(paramAction:UIAlertAction!) in
                                                        let url = "https://itunes.apple.com/app/id1143924460"
                                                        if let url = URL(string: url) {
                                                            if #available(iOS 10.0, *) {
                                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                                            } else {
                                                                UIApplication.shared.openURL(url)
                                                            }
                                                        }

            })
            alert.addAction(writeReviewAction)
            if GV.player!.GCEnabled == GCEnabledType.GameCenterEnabled.rawValue {
                let connectToGamecenter = UIAlertAction(title: GV.language.getText(.tcDisconnectGC), style: .default,
                                                        handler: {(paramAction:UIAlertAction!) in
                                                            //                                                self.GCEnabled = !self.GCEnabled
                                                            try! realm.write({
                                                                GV.player!.GCEnabled = GCEnabledType.AskForGameCenter.rawValue
                                                            })
                                                            
                })
                alert.addAction(connectToGamecenter)
            }
            let returnAction = UIAlertAction(title: GV.language.getText(.tcReturn), style: .default,
                                                     handler: {(paramAction:UIAlertAction!) in
                                                        self.playMusic("MyMusic", volume: GV.player!.musicVolume, loops: self.playMusicForever)
                                                        self.inSettings = false
                                                        self.doTimeCount = true
            })
            alert.addAction(returnAction)
        

            GV.mainViewController!.showAlert(alert, delay: 100)
//            panel = MySKPanel(view: view!, frame: CGRect(x: self.frame.midX, y: self.frame.midY, width: self.frame.width * 0.5, height: self.frame.height * 0.5), type: .settings, parent: self, callBack: comeBackFromSettings)
//            panel = nil
    }
//    var GCEnabled = false
    let LEADERBOARD_ID = "P1L1"
    func comeBackFromSettings() {
        playMusic("MyMusic", volume: GV.player!.musicVolume, loops: playMusicForever)
        var myName = ""
        if let name = GKLocalPlayer.localPlayer().alias {
            myName = name
        } else {
            myName = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        }
        GV.peerToPeerService!.changeIdentifier(myName)
        playerNameLabel.text = myName
        doTimeCount = true
        SKPlayerObject = nil
        SKSliderObject = nil
        SKLanguagesObject = nil
        inSettings = false
    }
    func comeBackFromSettingsWithStart(_ restart: Bool, gameNumber: Int, levelIndex: Int, countPackages: Int) {
        inSettings = false
        
        if restart {
            self.gameNumber = gameNumber
            try! realm.write({
                GV.player!.levelID = levelIndex
                GV.player!.countPackages = countPackages
            })
            prepareNextGame(newGame: false) // start with choosed gamenumber
            generateCards(generatingType: .first)
        } else {
            comeBackFromSettings()
        }
    }
    func connectToGameCenter() {
        if !GKLocalPlayer.localPlayer().isAuthenticated {
            authenticateLocalPlayer()
        }
//        gameCenterSync.startGameCenterSync()
    }
    // AUTHENTICATE LOCAL PLAYER
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1. Show login if player is not logged in
                GV.mainViewController?.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated & logged in, load gamecenter
//                self.gcEnabled = true
                
                // Get the default leaderboard ID
                
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil {
                        realm.beginWrite()
                        GV.player!.GCEnabled = GCEnabledType.AskForGameCenter.rawValue
                        try! realm.commitWrite()
                    } else {
                        realm.beginWrite()
                        GV.player!.GCEnabled = GCEnabledType.GameCenterEnabled.rawValue
                        self.createLabelsForBestPlace()
                        GV.peerToPeerService!.changeIdentifier(GKLocalPlayer.localPlayer().alias!)
                        self.gameCenterSync.startGameCenterSync()
                        try! realm.commitWrite()
//                        self.gameCenterSync.printAllGamers()
                    }
                })
                
            }
        }
        if !GKLocalPlayer.localPlayer().isAuthenticated {
            realm.beginWrite()
            GV.player!.GCEnabled = GCEnabledType.AskForGameCenter.rawValue
            try! realm.commitWrite()
        }
    }
    
    func createLabelsForBestPlace() {
        let bestPlaceLabelName = "bestPlaceLabelName"
        if self.playerType == .singlePlayer {
            let (bestPlaceLabelText, myPlaceLabelText) = self.setRankingLabels()
            if self.childNode(withName: bestPlaceLabelName) == nil {
                self.createLabels(label: self.bestPlaceLabel, text:bestPlaceLabelText, row: 4, xPosProzent: self.whoIsPos)
                self.createLabels(label: self.myPlaceLabel, text:myPlaceLabelText, row: 4, xPosProzent: self.scorePos)
                bestPlaceLabel.name = bestPlaceLabelName
            } else {
                self.bestPlaceLabel.text = bestPlaceLabelText
                self.myPlaceLabel.text = myPlaceLabelText
            }
            self.playerNameLabel.text = self.getName()
        }
    }
    
    func addScoreAndSubmitToGC(score: Int, countPackages: Int, level: Int) {
        let leaderBoardID = "P\(countPackages)L\(level)"
        // Submit score to GC leaderboard
        let bestScore = GKScore(leaderboardIdentifier: leaderBoardID)
        bestScore.value = Int64(score)
        let scoreArray = [bestScore]
        GKScore.report(scoreArray) { (error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Best Score submitted to your Leaderboard!")
            }
        }
    }
    
    func goToGameCenter(countPackages: Int, level: Int) {
        // MARK: - OPEN GAME CENTER LEADERBOARD
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = "P\(countPackages)L\(level)"
        GV.mainViewController?.present(gcVC, animated: true, completion: nil)
    }
    
    
    func comeBackFromSettings(_ restart: Bool, gameNumberChoosed: Bool, gameNumber: Int, levelIndex: Int, countPackages: Int) {
        inSettings = false
        
        if restart {
            if gameNumberChoosed {
                self.gameNumber = gameNumber
                try! realm.write({ 
                    GV.player!.levelID = levelIndex
                    GV.player!.countPackages = countPackages
                })
                prepareNextGame(newGame: false) // start with choosed gamenumber
            } else {
                prepareNextGame(newGame: true)  // start a random game
            }
            generateCards(generatingType: .first)
        } else {
            playMusic("MyMusic", volume: GV.player!.musicVolume, loops: playMusicForever)
            let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
            playerNameLabel.text = name
            doTimeCount = true
        }
    }
    
    func undoButtonPressed() {

        pull(createTipps: true)
    }

    
    
    func stopTimer( _ timer: inout Timer?) {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    


//    func startTimer( _ timer: inout Timer?, sleepTime: Double, selector: String, repeats: Bool)->Timer {
//        stopTimer(&timer)
//        let myTimer = Timer.scheduledTimer(timeInterval: sleepTime, target: self, selector: Selector(selector), userInfo: nil, repeats: repeats)
//
//        return myTimer
//    }
    
    @objc func showTime() {
        
        if doTimeCount {
            timeCount += 1 // countUpAdder
            playerTimeLabel.text = timeCount.HourMinSec
            if playerType == .multiPlayer {
                opponentTimeLabel.text = timeCount.HourMinSec
            }
        }
    }
    
    func waitForMovingCards() {
        countCheckCounts = 0
        checkCountMovingCards()
    }
    
    @objc func checkCountMovingCards() {
        if  movingCards.count > 0 && countCheckCounts < 1000 {
            countCheckCounts += 1
            self.waitForSKActionEndedTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.checkCountMovingCards), userInfo: nil, repeats: false)
        } else {
            countCheckCounts = 0
            self.isUserInteractionEnabled = true
        }
    }

    func connectedDevicesChanged(_ manager : PeerToPeerServiceManager, connectedDevices: [String]) {
        
    }
    
    func messageReceived(_ fromPeer: MCPeerID, command: PeerToPeerCommands, message: [String], messageNr:Int) {
        switch command {
        case .myNameIs: break
        case .iWantToPlayWithYou:
            if inSettings {
                GV.peerToPeerService!.sendAnswer(messageNr: messageNr, answer: [GV.IAmBusy])
            } else if message[1] > GV.peerToPeerVersion { // want the opponent play an other peerToPeerVerion ?
                GV.peerToPeerService!.sendAnswer(messageNr: messageNr, answer: [peerToPeerVersionOfOpponentIsLower])
            } else if message[1] < GV.peerToPeerVersion { // want the opponent play an other peerToPeerVerion ?
                GV.peerToPeerService!.sendAnswer(messageNr: messageNr, answer: [peerToPeerVersionOfOpponentIsHigher])
            } else if playerType == .multiPlayer {
                GV.peerToPeerService!.sendAnswer(messageNr: messageNr, answer: [GV.IAmPlaying])
            } else {
                alertStartMultiPlay(fromPeer: fromPeer, message: message, messageNr: messageNr)
            }
        case .myScoreHasChanged:
            if playerType == .multiPlayer {
                opponent.score = Int(message[0])!
                opponent.cardCount = Int(message[1])!
            }
        case .gameIsFinished:
            if playerType == .multiPlayer {
                opponent.score = Int(message[0])!
                opponent.finish = .finished // save in update!!!
                alertOpponentHasGameFinished()
            }
        case .stopCompetition:
            if playerType == .multiPlayer {
                opponent.finish = .interrupted
                alertStopCompetetion()
                showBestPlaceLineIfNeaded()
            }
        default:
            return
        }
//        print("message received - command: \(command), message: \(message)")
    }
    
    func alertOpponentHasGameFinished() {
        let bonus = opponent.score / 10
        let hisScore = opponent.score + bonus
        let opponentWon = hisScore > levelScore
        let wonText = opponentWon ? GV.language.getText(.tcHeWon, values: self.opponent.name, String(hisScore), String(levelScore)) : GV.language.getText(.tcYouWon, values: String(levelScore), String(hisScore))
        let alert = UIAlertController(title: GV.language.getText(.tcOpponentHasFinished,
            values: self.opponent.name,
                    String(gameNumber),
                    String(bonus),
                    String(self.opponent.score),
                    String(levelScore)) +
            "\r\n" +
            "\r\n" +
            wonText,
            message: "",
            preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: GV.language.getText(.tcok), style: .default,
                                    handler: {(paramAction:UIAlertAction!) in
                                    DispatchQueue.main.async {
                                        self.startGetNextPlayArt = true
                                    }
        })
        alert.addAction(OKAction)
        
        DispatchQueue.main.async(execute: {
            GV.mainViewController!.showAlert(alert, delay: 20)
        })

    }
    
    func alertStopCompetetion() {
        let alert = UIAlertController(title: GV.language.getText(.tcOpponentStoppedTheGame,
            values: self.opponent.name),
          message: "",
          preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: GV.language.getText(.tcok), style: .default,
                                     handler: {(paramAction:UIAlertAction!) in
                                        DispatchQueue.main.async {
                                            
                                        }
        })
        alert.addAction(OKAction)
        
        DispatchQueue.main.async(execute: {
            GV.mainViewController!.showAlert(alert, delay: 20)
        })
        
    }
    
    func calculateWinner()->(bonus:Int, myScore:Int, IWon: Bool){
        let bonus = levelScore / 10
        let myScore = levelScore + bonus
        let IWon = myScore > opponent.score
        return(bonus, myScore, IWon)
    }
    
    func alertIHaveGameFinished() {
        let (bonus, myScore, IWon) = calculateWinner()
        let wonText = IWon ? GV.language.getText(.tcYouWon, values: String(myScore), String(opponent.score)) : GV.language.getText(.tcHeWon, values: opponent.name, String(opponent.score), String(myScore) )
        let alert = UIAlertController(title: GV.language.getText(.tcYouHaveFinished,
            values: String(gameNumber),
            String(bonus),
            String(levelScore),
            opponent.name,
            String(self.opponent.score)) +
            "\r\n" +
            "\r\n" +
            wonText,
          message: "",
          preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: GV.language.getText(.tcok), style: .default,
                                     handler: {(paramAction:UIAlertAction!) in
                                        DispatchQueue.main.async {
                                            self.startGetNextPlayArt = true
                                        }
        })
        alert.addAction(OKAction)
        playerType = .singlePlayer
        GV.peerToPeerService!.changeStatusToFree()
        GV.mainViewController!.showAlert(alert, delay: 20)
        
    }
    

    func alertStartMultiPlay(fromPeer: MCPeerID, message: [String], messageNr: Int) {
        let alert = UIAlertController(title: GV.language.getText(.tcWantToPlayWithYou, values: message[0]),
                                      message: "",
                                      preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: GV.language.getText(.tcok), style: .default,
                                     handler: {(paramAction:UIAlertAction!) in
                                        DispatchQueue.main.async {
                                            self.playerType = .multiPlayer
                                            self.opponent.name = message[0]
                                            self.opponent.peerID = fromPeer
                                            self.opponent.score = 0
                                            try! realm.write({ 
                                                GV.player!.levelID = Int(message[2])!
                                                GV.player!.countPackages = Int(message[3])!
                                            })
                                            self.levelIndex = Int(message[2])!
                                            countPackages = Int(message[3])!
                                            self.gameNumber = Int(message[4])!
                                            self.restartGame = true
                                            GV.peerToPeerService!.changeStatusToIsPlaying(isPlayingWith: self.opponent.name)
                                            GV.peerToPeerService!.sendAnswer(messageNr: messageNr, answer: [self.answerYes])
                                        }
        })
        alert.addAction(OKAction)
        
        let cancelAction = UIAlertAction(title: GV.language.getText(.tcCancel), style: .default,
                                         handler: {(paramAction:UIAlertAction!) in
                                            GV.peerToPeerService!.sendAnswer(messageNr: messageNr, answer: [self.answerNo])
        })
        alert.addAction(cancelAction)
        DispatchQueue.main.async(execute: {
            GV.mainViewController!.showAlert(alert, delay: 20)
        })
        
    }
    

    func sendAlertToUser(_ fromPeerIndex: Int) {
        
    }
    
}
