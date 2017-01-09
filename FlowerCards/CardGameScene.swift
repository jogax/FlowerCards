
//  CardGameScene.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 2015. 11. 26..
//  Copyright © 2015. Jozsef Romhanyi. All rights reserved.
//

import SpriteKit
import AVFoundation
import MultipeerConnectivity

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

struct Tipps {
    var removed: Bool
    var fromColumn: Int
    var fromRow: Int
    var toColumn: Int
    var toRow: Int
    var twoArrows: Bool
    var points:[CGPoint]
    var value: Int
    var lineLength: CGFloat
    
    init() {
        removed = false
        fromColumn = 0
        fromRow = 0
        toColumn = 0
        toRow = 0
        points = [CGPoint]()
        twoArrows = false
        value = 0
        lineLength = 0
    }
}



var gameArray = [[GameArrayPositions]]()
var containers = [MySKCard]()
var cardStack:Stack<MySKCard> = Stack()
var countPackages = 1

class CardGameScene: SKScene, SKPhysicsContactDelegate, AVAudioPlayerDelegate, PeerToPeerServiceManagerDelegate { //,  JGXLineDelegate { //MyGameScene {

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
    
    struct Opponent {
        enum FinishType: Int {
            case none = 0, finished, interrupted
        }
        var peerIndex: Int = 0
        var ID = 0
        var name: String = ""
        var score: Int = 0
        var cardCount: Int = 0
        var finish: FinishType = .none
    }
    
    struct Founded {
        let maxDistance: CGFloat = 100000.0
        var point: CGPoint
        var column: Int
        var row: Int
        var foundContainer: Bool
        var distanceToP1: CGFloat
        var distanceToP0: CGFloat
        init(column: Int, row: Int, foundContainer: Bool, point: CGPoint, distanceToP1: CGFloat, distanceToP0: CGFloat) {
            self.distanceToP1 = distanceToP1
            self.distanceToP0 = distanceToP0
            self.column = column
            self.row = row
            self.foundContainer = foundContainer
            self.point = point
        }
        init() {
            self.distanceToP1 = maxDistance
            self.distanceToP0 = maxDistance
            self.point = CGPoint(x: 0, y: 0)
            self.column = 0
            self.row = 0
            self.foundContainer = false
        }
    }
    
    enum ShowHelpLine: Int {
        case green = 0, cyan, hidden
    }
    

    enum MyColors: Int {
        case none = 0, red, green
    }
    
    enum PlayerType: Int {
        case singlePlayer = 0, multiPlayer, bestPlayer
    }
    
    enum CardGeneratingType: Int {
        case first = 0, normal, special
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
    
    struct DrawHelpLinesParameters {
        var points: [CGPoint]
        var lineWidth: CGFloat
        var twoArrows: Bool
        var color: MyColors
        
        init() {
            points = [CGPoint]()
            lineWidth = 0
            twoArrows = false
            color = .red
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
    let answerLevelNotOK = "LevelNotOK"
    
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
    let myLineName = "myLine"
    let fingerName = "finger"
    
    
    let emptyCardTxt = "emptycard"
    
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
    let maxLevelForiPhone = GV.levelsForPlay.getLastLevelWithColumnCount(maxColumnCount: 7)
    let countContainers = 4

    var lastUpdateSec = 0
    var lastNextPoint: Founded?
    var generatingTipps = false
    var tippArray = [Tipps]()
    var tippIndex = 0
    
//    var showTippAtTimer: NSTimer?
    var dummy = 0
    
    var labelFontSize = CGFloat(0)
    
    var tremblingCards: [MySKCard] = []
    var random: MyRandom?
    // Values from json File
    var params = ""
    var countCardsProContainer: Int?
    var countColumns = 0
    var countRows = 0
    var showHelpLines: ShowHelpLine = .green
    let maxColumnForiPhone = 6
    var targetScoreKorr: Int = 0
    var tableCellSize: CGFloat = 0
    var cardSizeMultiplier: CGSize = CGSize(width: 1, height: 1)
    var containerSize:CGSize = CGSize(width: 0, height: 0)
    var cardSize:CGSize = CGSize(width: 0, height: 0)
    var minUsedCells = 0
    var maxUsedCells = 0
    var gameNumber = 0
    
    var scoreModifyer = 0
    var showTippCounter = 0
//    var mirroredScore = 0
    
    var touchesBeganAt: Date?
    
    let containerSizeOrig: CGFloat = 40
    
    var showFingerNode = false
    var countMovingCards = 0
    var countCheckCounts = 0
    var freeUndoCounter = 0
    var freeTippCounter = 0
    
    
    
    //let timeLimitKorr = 5 // sec for pro card
    //    var startTime: NSDate?
    //    var startTimeOrig: NSDate?
    var timer: Timer?
    var countUp: Timer?
    var greenLineTimer: Timer?
    var waitForSKActionEnded: Timer?
    var lastMirrored = ""
    var musicPlayer: AVAudioPlayer?
    var soundPlayer: AVAudioPlayer?
    var soundPlayerArray = [AVAudioPlayer?](repeating: nil, count: 5)
    var myView = SKView()
    var levelIndex = GV.player!.levelID
    var maxLevelIndex = 0
    var stack:Stack<SavedCard> = Stack()
    //var gameArray = [[Bool]]() // true if Cell used
    var colorTab = [ColorTabLine]()
    var countColorsProContainer = [Int]()
    var labelBackground = SKSpriteNode()
    let labelRowCorr = CGFloat(0.1)
    let countLabelRows = CGFloat(4.0)
    
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
    
    var cardCountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
//    var showScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
//    var opponentScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    
//    var gameScore = GV.player!.gameScore
    var levelScore: Int = 0 {
        didSet {
            showLevelScore()
            if playerType == .multiPlayer {
                GV.peerToPeerService!.sendInfo(.myScoreHasChanged, message: [String(levelScore), String(cardCount)], toPeerIndex: opponent.peerIndex)
            }
        }
    }
    
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

    var cardCount = 0 {
        didSet {
            if playerType == .multiPlayer {
                GV.peerToPeerService!.sendInfo(.myScoreHasChanged, message: [String(levelScore), String(cardCount)], toPeerIndex: opponent.peerIndex)
            }
        }
    }


    //var restartCount = 0
    var stopped = true
    var collisionActive = false
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
    var cardTabRect = CGRect.zero
    
    var buttonField: SKSpriteNode?
    //var levelArray = [Level]()
    var countLostGames = 0
    var lineUH: JGXLine?
    var lineLV: JGXLine?
    var lineRV: JGXLine?
    var lineBH: JGXLine?
    
//    var lastGreenPair: PairStatus?
//    var lastRedPair: PairStatus?
    var lastPair = PairStatus() {
        didSet {
            if oldValue.color != lastPair.color {
                lastPair.startTime = Date()
                lastPair.changeTime = lastPair.startTime
            }
        }
    }
    
    var lastDrawHelpLinesParameters = DrawHelpLinesParameters()

    
    var lineWidthMultiplierNormal = CGFloat(0.04) //(0.0625)
    let lineWidthMultiplierSpecial = CGFloat(0.125)
    
    var lineWidthMultiplier: CGFloat?
    var actPair: PairStatus?
    var oldFromToColumnRow: FromToColumnRow?
    
    var buttonSize = CGFloat(0)
    var buttonYPos = CGFloat(0)
    var buttonXPosNormalized = CGFloat(0)
    let images = DrawImages()
    
    var panel: MySKPanel?
//    var countUpAdder = 0
    
    var doTimeCount: Bool = false
    
//    var actGame: GameModel?
    var actGame: GameModel?
    
    var playerType: PlayerType = .singlePlayer
    var opponent = Opponent()
    var startGetNextPlayArt = false
    var restartGame: Bool = false
    var inSettings: Bool = false
    var receivedMessage: [String] = []

    
    var stopCreateTippsInBackground = false {
        didSet {
            if stopCreateTippsInBackground {
                if !generatingTipps {
                    stopCreateTippsInBackground = false
                } else {
//                    let startWaiting = Date()
                    while generatingTipps && stopCreateTippsInBackground {
                        
                         _ = 0
                    }
//                    print ("waiting for Stop Creating Tipps:", Date().timeIntervalSince(startWaiting).nDecimals(5))
                    stopCreateTippsInBackground = false

                }
            }
        }
    }
        
    var gameArrayChanged = false {
        didSet {
            startCreateTippsInBackground()
        }
    }
    
    var tapLocation: CGPoint?
    let qualityOfServiceClass = DispatchQoS.QoSClass.background
    let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
    let playMusicForever = -1
    let fixationTime = 0.1
    
    var autoPlayerActive = false
    var autoPlayer: AutoPlayer?
    var replaying = false
    var durationMultiplier = 0.001
    let durationMultiplierForPlayer = 0.001
    let durationMultiplierForAutoplayer = 0.0001
    var cardManager: GameArrayManager?
    
    override func didMove(to view: SKView) {
//        //printFunc(function: "didMove", start: true)
        // generate Played Games when GamesModel empty
//        #if REALM_V1
//            
//        #else
//            if realm.objects(GameModel.self).count == 0 {
//                generateGamesForTest(countRecordsProLevel: 10)
//            }
//        #endif
        
        if !settingsSceneStarted {
//            let modelURL = NSBundle.mainBundle().URLForResource("FlowerCards", withExtension: "momd")!

            myView = view
            
            GV.peerToPeerService!.delegate = self
//            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
//            print(documentsPath)
            
//            cardTabRect.origin = CGPoint(x: self.frame.midX, y: self.frame.midY * 0.80)
//            cardTabRect.size = CGSize(width: self.frame.size.width * 0.80, height: self.frame.size.height * 0.80)
            
            let width:CGFloat = 64.0
            let height: CGFloat = 89.0
            let sizeMultiplierConstant = CGFloat(0.0020)

            cardSizeMultiplier = CGSize(width: self.size.width * sizeMultiplierConstant,
                                    height: self.size.width * sizeMultiplierConstant * height / width)

            levelIndex = GV.player!.levelID
            

            GV.levelsForPlay.setAktLevel(levelIndex)
            
            let buttonSizeMultiplierConstant = CGFloat(GV.onIpad ? 10 : 8)
            buttonSize = self.size.width / buttonSizeMultiplierConstant
            buttonYPos = self.size.height * 0.07
            buttonXPosNormalized = self.size.width / 10
            self.name = "CardGameScene"
            autoPlayer = AutoPlayer(scene: self)
            prepareNextGame(true)
            generateCards(.first)
        } else {
            playMusic("MyMusic", volume: GV.player!.musicVolume, loops: playMusicForever)
            
        }
//        //printFunc(function: "didMove", start: false)
    }
    
    func prepareNextGame(_ newGame: Bool) {
//        //printFunc(function: "prepareNextGame", start: true)

//        labelFontSize = GV.onIpad ? 20 : 15
        labelFontSize = GV.onIpad ? self.size.height / 50 : self.size.height / 70

        durationMultiplier = durationMultiplierForPlayer
        levelIndex = GV.player!.levelID
        GV.levelsForPlay.setAktLevel(levelIndex)
        if newGame {
            gameNumber = randomGameNumber()
            createGameRecord(gameNumber: gameNumber)
        } else {
            getGameRecord(gameNumber: gameNumber)
        }
        specialPrepareFuncFirst()
        cardManager = GameArrayManager()
        freeUndoCounter = freeAmount
        freeTippCounter = freeAmount
        scoreModifyer = 0
        levelScore = 0
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

        
        random = MyRandom(gameNumber: gameNumber)
        
        stopTimer(&countUp)
        
        gameArray.removeAll(keepingCapacity: false)
        containers.removeAll(keepingCapacity: false)
        //undoCount = 3
        
        // fill gameArray

        for _ in 0..<countColumns {
            gameArray.append(Array(repeating: GameArrayPositions(), count: countRows))
        }
        
        // calvulate card Positions
        
//        for column in 0..<countColumns {
//            for row in 0..<countRows {
//                let columnRow = calculateColumnRowFromPosition(gameArray[column][row].position)
//                if column != columnRow.column || row != columnRow.row {
////                    print("column:", column, "row:",row, "calculated:", columnRow, column != columnRow.column || row != columnRow.row ? "Error" : "")
//                    dummy = 0
//                }
//            }
//        }
        
        labelBackground.color = UIColor.white
        labelBackground.alpha = 0.7
        let labelBGHeight = CGFloat(countLabelRows) * labelFontSize + labelRowCorr * 100
        labelBackground.position = CGPoint(x: self.size.width / 2, y: self.size.height - labelBGHeight / 2 - 2)
        labelBackground.size = CGSize(width: self.size.width * 0.95, height: labelBGHeight)
        
        let screw1 = SKSpriteNode(imageNamed: "screw.png")
        let screw2 = SKSpriteNode(imageNamed: "screw.png")
        let screw3 = SKSpriteNode(imageNamed: "screw.png")
        let screw4 = SKSpriteNode(imageNamed: "screw.png")
        let screwWidth = self.size.width * 0.025
        let screwMultiplier = CGVector(dx: 0.48, dy: 0.35)

        screw1.position = CGPoint(x: -labelBackground.size.width * screwMultiplier.dx, y: labelBackground.size.height * screwMultiplier.dy)
        screw1.size = CGSize(width: screwWidth, height: screwWidth)
        screw2.position = CGPoint(x: labelBackground.size.width * screwMultiplier.dx, y: labelBackground.size.height * screwMultiplier.dy)
        screw2.size = CGSize(width: screwWidth, height: screwWidth)
        screw3.position = CGPoint(x: -labelBackground.size.width * screwMultiplier.dx, y: -labelBackground.size.height * screwMultiplier.dy)
        screw3.size = CGSize(width: screwWidth, height: screwWidth)
        screw4.position = CGPoint(x: labelBackground.size.width * screwMultiplier.dx, y: -labelBackground.size.height * screwMultiplier.dy)
        screw4.size = CGSize(width: screwWidth, height: screwWidth)
        
        labelBackground.addChild(screw1)
        labelBackground.addChild(screw2)
        labelBackground.addChild(screw3)
        labelBackground.addChild(screw4)
        
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
        

        showCardFromStack = nil
        
        
        bgImage = setBGImageNode()
        bgAdder = 0.1
        
        bgImage!.anchorPoint = CGPoint.zero
//        bgImage!.position = self.position //CGPointMake(0, 0)
        bgImage!.zPosition = -15
        self.addChild(bgImage!)
        
        let settingsTexture = SKTexture(image: images.getSettings())
        settingsButton = MySKButton(texture: settingsTexture, frame: CGRect(x: buttonXPosNormalized * 1, y: buttonYPos, width: buttonSize, height: buttonSize))
        settingsButton!.name = "settings"
        addChild(settingsButton!)
        
        let restartTexture = SKTexture(image: images.getRestart())
        restartButton = MySKButton(texture: restartTexture, frame: CGRect(x: buttonXPosNormalized * 2.5, y: buttonYPos, width: buttonSize, height: buttonSize))
        restartButton!.name = "restart"
        addChild(restartButton!)
        
        let undoTexture = SKTexture(image: images.getUndo())
        undoButton = MySKButton(texture: undoTexture, frame: CGRect(x: buttonXPosNormalized * 9.0, y: buttonYPos, width: buttonSize, height: buttonSize))
        undoButton!.name = "undo"
        addChild(undoButton!)
        
        let helpTexture = atlas.textureNamed("help")
        helpButton = MySKButton(texture: helpTexture, frame: CGRect(x: buttonXPosNormalized * 6.0, y: buttonYPos, width: buttonSize, height: buttonSize))
        helpButton!.name = "help"
        addChild(helpButton!)
        
        
        backgroundColor = UIColor.white //SKColor.whiteColor()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        makeLineAroundGameboard(.upperHorizontal)
        makeLineAroundGameboard(.rightVertical)
        makeLineAroundGameboard(.bottomHorizontal)
        makeLineAroundGameboard(.leftVertical)
        //        self.inFirstGenerateCards = false
        cardCount = Int(CGFloat(countContainers * countCardsProContainer! * countPackages))
        let cardCountText: String = String(cardStack.count(.MySKCardType))
        let tippCountText: String = "\(tippArray.count)"
//        let showScoreText: String = GV.language.getText(.TCGameScore, values: "\(levelScore)")
        let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        
        let gameNumberText = GV.language.getText(.tcGameNumber) + "\(gameNumber + 1)"
        let size = " \(GV.levelsForPlay.aktLevel.countColumns) x \(GV.levelsForPlay.aktLevel.countRows)"
        let sizeText = GV.language.getText(.tcSize) + size
        let packageText = GV.language.getText(.tcPackages) + "\(countPackages)"
        
        let whoIsText = GV.language.getText(.tcWhoIs)
        let whoIsTypeText1 = GV.language.getText(.tcPlayerType)
        let whoIsTypeText2 = GV.language.getText(.tcOpponentType)
        let whoIsLenght = max(whoIsText.length, whoIsTypeText1.length, whoIsTypeText2.length) * 2
        
        let playerHeaderText = GV.language.getText(.tcName)
        let playerNameText = name
        let opponentNameText = opponent.name
        let playerNameLength = max(playerHeaderText.length + 4, playerNameText.length, opponentNameText.length) * 2
        
        let timeHeaderText = GV.language.getText(.tcTime)
        let timeLength = (timeHeaderText.length + 5) * 2
        
        let scoreHeaderText = GV.language.getText(.tcScoreHead)
        let scoreLength = (scoreHeaderText.length + 5) * 2
        
        let gameNumberPos = 10
        let sizePos = gameNumberPos + gameNumberText.length * 2
        let packagePos = sizePos + sizeText.length * 2
        let levelPos = packagePos + packageText.length * 2
        
        let whoIsPos = 10
        let playerNamePos = whoIsPos + whoIsLenght
        let timePos = playerNamePos + playerNameLength
        let scorePos = timePos + timeLength
        let cardCountPos = scorePos + scoreLength
        
        createLabels(gameNumberLabel, text: gameNumberText, row: 1, xPosProzent: gameNumberPos)
        createLabels(sizeLabel, text: sizeText, row: 1, xPosProzent: sizePos)
        createLabels(packageLabel, text: packageText, row: 1, xPosProzent: packagePos)
        createLabels(levelLabel, text: GV.language.getText(.tcLevel) + ": \(levelIndex + 1)", row: 1, xPosProzent: levelPos)
        
        createLabels(whoIsHeaderLabel, text: whoIsText, row: 2, xPosProzent: whoIsPos)
        createLabels(playerHeaderLabel, text: playerHeaderText, row: 2, xPosProzent: playerNamePos)
        createLabels(timeHeaderLabel, text: timeHeaderText, row: 2, xPosProzent: timePos)
        createLabels(scoreHeaderLabel, text: scoreHeaderText, row: 2, xPosProzent: scorePos)
        createLabels(cardCountHeaderLabel, text: GV.language.getText(.tcCardHead), row: 2, xPosProzent: cardCountPos)

        createLabels(whoIsLabel, text: whoIsTypeText1, row: 3, xPosProzent: whoIsPos)
        createLabels(playerNameLabel, text: playerNameText, row: 3, xPosProzent: playerNamePos)
        createLabels(playerTimeLabel, text: "0", row: 3, xPosProzent: timePos)
        createLabels(playerScoreLabel, text: String(levelScore), row: 3, xPosProzent: scorePos)
        createLabels(playerCardCountLabel, text: String(cardCount), row: 3, xPosProzent: cardCountPos)

        if playerType == .multiPlayer {
            createLabels(opponentTypeLabel, text: whoIsTypeText2, row: 4, xPosProzent: whoIsPos)
            createLabels(opponentNameLabel, text: opponentNameText, row: 4, xPosProzent: playerNamePos)
            createLabels(opponentTimeLabel, text: "0", row: 4, xPosProzent: timePos)
            createLabels(opponentScoreLabel, text: String(opponent.score), row: 4, xPosProzent: scorePos)
            createLabels(opponentCardCountLabel, text: String(opponent.cardCount), row: 4, xPosProzent: cardCountPos)
        } else {
//            let gamesWithSameNumber = realm.objects(GameModel.self).filter("gameNumber = %d and levelID = %d and played = true", gameNumber, levelIndex )
//            if gamesWithSameNumber.count == 0 { // this game is played 1st time
                playerType = .singlePlayer
                opponentTypeLabel.isHidden = true
                opponentNameLabel.isHidden = true
                opponentTimeLabel.isHidden = true
                opponentScoreLabel.isHidden = true
                opponentCardCountLabel.isHidden = true
//            } else {
//                playerType = .bestPlayer
//                let maxScore = gamesWithSameNumber.max(ofProperty: "playerScore") as Int?
//                let bestPlay = gamesWithSameNumber.filter("playerScore = %d", maxScore!).first!
//                let bestPlayerName = realm.objects(PlayerModel.self).filter("ID = %d", bestPlay.playerID).first!.name
//                let bestTime = bestPlay.time
//                createLabels(opponentTypeLabel, text: GV.language.getText(.tcBestPlayerType), column: 1, row: 4)
//                createLabels(opponentNameLabel, text: bestPlayerName, column: 2, row: 4)
//                createLabels(opponentTimeLabel, text: bestTime.dayHourMinSec, column: 3, row: 4)
//                createLabels(opponentScoreLabel, text: String(maxScore!), column: 4, row: 4)
//                createLabels(opponentCardCountLabel, text: String(0), column: 5, row: 4)
//                opponentTypeLabel.isHidden = false
//                opponentNameLabel.isHidden = false
//                opponentTimeLabel.isHidden = false
//                opponentScoreLabel.isHidden = false
//                opponentCardCountLabel.isHidden = false
//            }
        }
        createLabels(cardCountLabel, text: cardCountText, row: 5, buttonLabel: 1)
        createLabels(tippCountLabel, text: tippCountText, row: 5, buttonLabel: 2)
        
        let mySortedPlays = realm.objects(GameModel.self).filter("playerID = %d and played = true", GV.player!.ID).sorted(byProperty: "levelID")
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
        try! realm.write() {
            realm.add(gameNew)
        }
        actGame = gameNew
//        //printFunc(function: "createGameRecord", start: false)
    }
    
    func getGameRecord(gameNumber: Int) {
        actGame = realm.objects(GameModel.self).filter("gameNumber = %d and levelID = %d and playerID = %d", gameNumber, levelIndex, GV.player!.ID).first
    }
    
    
    
    func createLabels(_ label: SKLabelNode, text: String, row: Int, xPosProzent: Int = 0, buttonLabel: Int = NoValue) {
//        //printFunc(function: "createLabels", start: true)
        
        // values for buttonLabel: NoValue - No Button, 1 - cardPackage, 2 tippsButton
        label.text = text
        label.fontName = "ArialMT"
        let xPos = self.size.width * CGFloat(xPosProzent) * 0.01
        
        if buttonLabel == NoValue {
            let posAdder = CGFloat(row - 1) * labelFontSize * (1 + labelRowCorr)
            var yPos = CGFloat(labelBackground.position.y - 120 * labelRowCorr)
            yPos += labelBackground.size.height / 2
            yPos -= labelFontSize / 2 + posAdder
            label.position = CGPoint(x: xPos, y: yPos)
            label.fontSize = labelFontSize;
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .baseline
        } else {
           label.position = (buttonLabel == 1 ? self.cardPackage!.position : self.tippsButton!.position)
            label.fontSize = labelFontSize * 1.5
            label.zPosition = 5
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
        }
        label.fontColor = SKColor.black
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
    
    func specialPrepareFuncFirst() {
        //printFunc(function: "specialPrepareFuncFirst", start: true)
        stopCreateTippsInBackground = true
//        #if REALM_V1
            countPackages = GV.levelsForPlay.aktLevel.countPackages
//        #endif
        maxCardCount = countPackages * countContainers * MaxCardValue
        countCardsProContainer = MaxCardValue //levelsForPlay.aktLevel.countCardsProContainer
        countColumns = GV.levelsForPlay.aktLevel.countColumns
        countRows = GV.levelsForPlay.aktLevel.countRows
        minUsedCells = GV.levelsForPlay.aktLevel.minProzent * countColumns * countRows / 100
        maxUsedCells = GV.levelsForPlay.aktLevel.maxProzent * countColumns * countRows / 100
        showHelpLines = .green
        containerSize = CGSize(width: CGFloat(containerSizeOrig) * cardSizeMultiplier.width, height: CGFloat(containerSizeOrig) * cardSizeMultiplier.height)
        cardSize = CGSize(width: CGFloat(GV.levelsForPlay.aktLevel.cardSize) * cardSizeMultiplier.width, height: CGFloat(GV.levelsForPlay.aktLevel.cardSize) * cardSizeMultiplier.height )
        
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
        cardCountLabel.text = String(cardStack.count(.MySKCardType))
    }

    
    func changeLanguage()->Bool {
        //printFunc(function: "changeLanguage", start: true)
        let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        
        whoIsHeaderLabel.text = GV.language.getText(.tcWhoIs)
        playerHeaderLabel.text = GV.language.getText(.tcName)
        timeHeaderLabel.text = GV.language.getText(.tcTime)
        scoreHeaderLabel.text = GV.language.getText(.tcScoreHead)
        cardCountHeaderLabel.text = GV.language.getText(.tcCardHead)
        
        playerNameLabel.text = name
        whoIsLabel.text = GV.language.getText(.tcPlayerType)

        levelLabel.text = GV.language.getText(.tcLevel) + ": \(levelIndex + 1)"
        gameNumberLabel.text = GV.language.getText(.tcGameNumber) + "\(gameNumber + 1)"
        sizeLabel.text = GV.language.getText(.tcSize) + "\(GV.levelsForPlay.aktLevel.countColumns) x \(GV.levelsForPlay.aktLevel.countRows)"
        packageLabel.text = GV.language.getText(.tcPackages) + "\(countPackages)"

        showCardCount()
        showTippCount()
        showLevelScore()
        //printFunc(function: "changeLanguage", start: false)
        return true
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
        //printFunc(function: "createCardStack", start: true)
        cardStack.removeAll(.MySKCardType)
//        showCardStack.removeAll(.MySKCardType)
//        MySKCard.cleanForNewGame(countPackages: countPackages)
//        while colorTab.count > 0 && checkGameArray() < maxUsedCells {
//            let colorTabIndex = random!.getRandomInt(0, max: colorTab.count - 1)//colorTab.count - 1 //
//            let colorIndex = colorTab[colorTabIndex].colorIndex
//            let cardName = colorTab[colorTabIndex].cardName
//            let value = colorTab[colorTabIndex].cardValue
//            colorTab.remove(at: colorTabIndex)
//            let card = MySKCard(texture: getTexture(colorIndex), type: .cardType, value:value)
//            card.name = cardName
//            card.colorIndex = colorIndex
//            cardStack.push(card)
//            card.setCardValues(color: colorIndex)
//            
//        }
        var newCard: MySKCard
        var go = true
        while go {
            (newCard, go) = MySKCard.getRandomCard(random: random)
            cardStack.push(newCard)
        }
        //printFunc(function: "createCardStack", start: false)
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

    func generateCards(_ generatingType: CardGeneratingType) {
        //printFunc(function: "generateCards", start: true)
        var waitForStart: TimeInterval = 0.0
        var generateSpecial = generatingType ==  .special
        var positionsTab = [(Int, Int)]()
//        countMovingCards = 0
        // search all available Positions in gameArray
        for column in 0..<countColumns {
            for row in 0..<countRows {
                if !gameArray[column][row].used {
                    let appendValue = (column, row)
                    positionsTab.append(appendValue)
                }
            }
       }
        
        while cardStack.count(.MySKCardType) > 0 && (checkGameArray() < maxUsedCells || (generateSpecial && positionsTab.count > 0)) {
            var card: MySKCard = cardStack.pull()!
            
            if generateSpecial {
                while true {
                    if findPairForCard(card.colorIndex, minValue: card.minValue, maxValue: card.maxValue) {
                        break
                    }
                    cardStack.pushLast(card)
                    card = cardStack.pull()!
                    
                }
                generateSpecial = false
            }
            showCardCount()
            let index = random!.getRandomInt(0, max: positionsTab.count - 1)
            let (actColumn, actRow) = positionsTab[index]
            
            let zielPosition = gameArray[actColumn][actRow].position
            card.position = cardPackage!.position
            card.startPosition = zielPosition
            

            positionsTab.remove(at: index)
            
            card.column = actColumn
            card.row = actRow
            
            card.size = CGSize(width: cardSize.width, height: cardSize.height)
            
            updateGameArrayCell(card)

            push(card, status: .addedFromCardStack)
            
            cardManager!.addCard(card: card)
            addChild(card)
            card.alpha = 0
            let duration:Double = Double((zielPosition - cardPackage!.position).length()) * durationMultiplier
            let actionMove = SKAction.move(to: zielPosition, duration: duration)
            
            let waitingAction = SKAction.wait(forDuration: waitForStart)
            waitForStart += 0.1
            
            let zPositionPlus = SKAction.run({
                card.zPosition += 100
            })

            let zPositionMinus = SKAction.run({
                card.zPosition -= 100
            })

            let actionHideEmptyCard = SKAction.run({
                self.deleteEmptyCard(column: actColumn, row: actRow)
            })
            
            let actionFadeAlpha = SKAction.fadeAlpha(to: 1, duration: 0.2)
            let actionMoveAndFadeIn = SKAction.group([actionMove, actionFadeAlpha])
            let actionCountMovingCards = SKAction.run {
                self.countMovingCards -= 1
            }
            countMovingCards += 1
            card.run(SKAction.sequence([waitingAction, zPositionPlus, actionMoveAndFadeIn, zPositionMinus, actionHideEmptyCard, actionCountMovingCards]))
            if cardStack.count(.MySKCardType) == 0 {
                cardPackage!.changeButtonPicture(SKTexture(imageNamed: "emptycard"))
                cardPackage!.alpha = 0.3
            }
//            card.setCardValues(color: card.colorIndex, row: card.row, column: card.column, minValue: card.minValue, maxValue: card.maxValue, status: .OnScreen)

        }
        
        self.waitForSKActionEnded = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CardGameScene.checkCountMovingCards), userInfo: nil, repeats: false) // start timer for check

        if generatingType != .special {
            gameArrayChanged = true
        }
        if generatingType == .first {
            countUp = Timer.scheduledTimer(timeInterval: doCountUpSleepTime, target: self, selector: Selector(doCountUpSelector), userInfo: nil, repeats: true)
            doTimeCount = true
        }
        stopped = false
        //printFunc(function: "generateCards", start: false)
    }
    
    func startAutoplay() {
        autoPlayerActive = true
        durationMultiplier = durationMultiplierForAutoplayer
        autoPlayer?.startPlay(replay: false)
    }
    
    func replay() {
        autoPlayerActive = true
        durationMultiplier = durationMultiplierForAutoplayer
        autoPlayer?.startPlay(replay: true)
    }
    
    func printGameArrayInhalt(_ calledFrom: String) {
        print(calledFrom, Date())
        var string: String
        for row in 0..<countRows {
            let rowIndex = countRows - row - 1
            string = ""
            for column in 0..<countColumns {
                let color = gameArray[column][rowIndex].card.colorIndex
                if gameArray[column][rowIndex].used {
                    let minInt = gameArray[column][rowIndex].card.minValue + 1
                    let maxInt = gameArray[column][rowIndex].card.maxValue + 1
                    string += " (" + String(color) + ")" +
                    (minInt < 10 ? "0" : "") + String(minInt) + "-" +
                    (maxInt < 10 ? "0" : "") + String(maxInt)
                } else {
                    string += " (N)" + "xx-xx"
                }
            }
            print(string)
        }
    }
    
    
    func startCreateTippsInBackground() {
        {
            self.generatingTipps = true
//            self.stopTimer(&self.showTippAtTimer)
            _ = self.createTipps()
            
            repeat {
                if self.tippArray.count <= 2 && self.checkGameArray() > 2 {
                    self.generateCards(.special)
                    _ = self.createTipps()
                }
            } while !(self.tippArray.count > 2 || self.countColumns * self.countRows - self.checkGameArray() == 0 || self.checkGameArray() < 2)
            
            if self.tippArray.count == 0 && self.cardCount > 0 {
                
                print ("You have lost!")
            }
            self.generatingTipps = false
        } ~>
        {
            self.generatingTipps = false
        }
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
//        //printFunc(function: "specialButtonPressed", start: true)
        if buttonName == "tipps" {
            if !generatingTipps {
                getTipps()
//                if showTippCounter > 0 {
//                    showTippCounter -= 1
//                } else {
//                    freeTippCounter -= 1
//                    let modifyer = freeTippCounter > 0 ? 0 : freeTippCounter > -freeAmount ? penalty : 2 * penalty
//                    scoreModifyer -= modifyer
//                    levelScore -= modifyer
//                    if modifyer > 0 {
//                        self.addChild(showCountScore("-\(modifyer)", position: undoButton!.position))
//                    }
//                }
            }
        }
//        //printFunc(function: "specialButtonPressed", start: false)
    }
    
    func startTippTimer(){
    }
    
    func getTipps() {
        //printFunc(function: "getTipps", start: true)
        if tippArray.count > 0 && !generatingTipps {
                stopTrembling()
                drawHelpLines(tippArray[tippIndex].points, lineWidth: cardSize.width, twoArrows: tippArray[tippIndex].twoArrows, color: .green)
                var position = CGPoint.zero
                if tippArray[tippIndex].fromRow == NoValue {
                    position = containers[tippArray[tippIndex].fromColumn].position
                } else {
                    position = gameArray[tippArray[tippIndex].fromColumn][tippArray[tippIndex].fromRow].position
                }
                addCardToTremblingCards(position)
                if tippArray[tippIndex].toRow == NoValue {
                    position = containers[tippArray[tippIndex].toColumn].position
                } else {
                    position = gameArray[tippArray[tippIndex].toColumn][tippArray[tippIndex].toRow].position
                }
                addCardToTremblingCards(position)
//            }
            tippIndex += 1
            tippIndex %= tippArray.count
        }
        
        //printFunc(function: "getTipps", start: false)
    }
    
    func createTipps()->Bool {
        //printFunc(function: "createTipps", start: true)
//        printGameArrayInhalt("from createTipps")
        tippArray.removeAll()
//        while gameArray.count < countColumns * countRows {
//            sleep(1) //wait until gameArray is filled!!
//        }
        
        tippsButton!.activateButton(false)
        var pairsToCheck = [FromToColumnRow]()
        for column1 in 0..<countColumns {
            for row1 in 0..<countRows {
                if gameArray[column1][row1].used {
                    for column2 in 0..<countColumns {
                        for row2 in 0..<countRows {
                            if gameArray[column2][row2].used {
                                if stopCreateTippsInBackground {
    //                                print("stopped while searching pairs")
                                    stopCreateTippsInBackground = false
                                    return false
                                }
                                let first = gameArray[column2][row2].card
                                let second = gameArray[column1][row1].card
                                let connectable = cardManager?.areConnectable(first: first, second: second)
                                if (column1 != column2 || row1 != row2) && connectable! {
//                                    MySKCard.areConnectable(first: first, second: second) {
                                    let aktPair = FromToColumnRow(fromColumnRow: ColumnRow(column: column1, row: row1), toColumnRow: ColumnRow(column: column2, row: row2))
                                    if !pairExists(pairsToCheck: pairsToCheck, aktPair: aktPair) {
                                        pairsToCheck.append(aktPair)
                                        pairsToCheck.append(FromToColumnRow(fromColumnRow: aktPair.toColumnRow, toColumnRow: aktPair.fromColumnRow))
                                    }
                                }
                            }
                        }
                    }
                    var thisColorHasContainer = false
                    for container in containers {
                        if gameArray[column1][row1].card.colorIndex == container.colorIndex {
                            thisColorHasContainer = true
                        }
                    }
                    for index in 0..<containers.count {
                        if !thisColorHasContainer && containers[index].minValue == NoColor && gameArray[column1][row1].card.maxValue == LastCardValue {
                            let actContainerPair = FromToColumnRow(fromColumnRow: ColumnRow(column: column1, row: row1), toColumnRow: ColumnRow(column: index, row: NoValue))
                            pairsToCheck.append(actContainerPair)
                        }
                        if containers[index].colorIndex == gameArray[column1][row1].card.colorIndex &&
                            (containers[index].minValue == gameArray[column1][row1].card.maxValue + 1 ||
                            (containers[index].minValue ==  FirstCardValue && gameArray[column1][row1].card.maxValue == LastCardValue))   {
                            let actContainerPair = FromToColumnRow(fromColumnRow: ColumnRow(column: column1, row: row1), toColumnRow: ColumnRow(column: index, row: NoValue))
                            pairsToCheck.append(actContainerPair)
                        }
                    }
                }
            }
        }

//        let startCheckTime = NSDate()
        for ind in 0..<pairsToCheck.count {
            checkPathToFoundedCards(pairsToCheck[ind])
            if stopCreateTippsInBackground {
                stopCreateTippsInBackground = false
                return false
            }
        }

        var removeIndex = [Int]()
        if tippArray.count > 0 {
            for ind in 0..<tippArray.count - 1 {
                if !tippArray[ind].removed {
                    let fromColumn = tippArray[ind].fromColumn
                    let toColumn = tippArray[ind].toColumn
                    let fromRow = tippArray[ind].fromRow
                    let toRow = tippArray[ind].toRow
                    if fromColumn == tippArray[ind + 1].toColumn &&
                       fromRow == tippArray[ind + 1].toRow &&
                       toColumn == tippArray[ind + 1].fromColumn  &&
                       toRow == tippArray[ind + 1].fromRow {
                            removeIndex.insert(ind + 1, at: 0)
//                            switch tippArray[ind].points.count {
//                            case 2:
//                                tippArray[ind].twoArrows = true
//                                removeIndex.insert(ind + 1, at: 0)
//                            case 3:
//                                if (tippArray[ind].points[1] - tippArray[ind + 1].points[1]).length() < cardSize.height{
//                                    tippArray[ind].twoArrows = true
//                                    removeIndex.insert(ind + 1, at: 0)
//                                }
//                            case 4:
//                                if tippArray[ind + 1].points.count == 4 && (tippArray[ind].points[1] - tippArray[ind + 1].points[2]).length() < cardSize.height && (tippArray[ind].points[2] - tippArray[ind + 1].points[1]).length() < cardSize.height
//                                {
//                                    tippArray[ind].twoArrows = true
//                                    removeIndex.insert(ind + 1, at: 0)
//                                }
//                            default:
//                                tippArray[ind].twoArrows = false
//                            }
                    }
                    if gameArray[fromColumn][fromRow].card.maxValue == LastCardValue && toRow == NoValue && containers[toColumn].minValue == NoColor {
                        // King to empty Container
                        var index = 1
                        while (ind + index) < tippArray.count && index < 4 {
                            let fromColumn1 = tippArray[ind + index].fromColumn
                            let toColumn1 = tippArray[ind + index].toColumn
                            let fromRow1 = tippArray[ind + index].fromRow
                            let toRow1 = tippArray[ind + index].toRow
                            
                            if fromColumn == fromColumn1 && fromRow == fromRow1 && toRow1 == NoValue && containers[toColumn1].minValue == NoColor
                                && toColumn != toColumn1 {
                                if tippArray[ind].lineLength < tippArray[ind + index].lineLength {
                                    let tippArchiv = tippArray[ind]
                                    tippArray[ind] = tippArray[ind + index]
                                    tippArray[ind + index] = tippArchiv
                                }
                                tippArray[ind + index].removed = true
                                removeIndex.insert(ind + index, at: 0)
                            }
                            index += 1
                        }
                        dummy = 0
                    }
                }
            }
            
            
            for ind in 0..<removeIndex.count {
                tippArray.remove(at: removeIndex[ind])
            }
            
            
            if stopCreateTippsInBackground {
//                print("stopped before sorting Tipp pairs")

                stopCreateTippsInBackground = false
                //printFunc(function: "createTipps", start: false)
                return false
            }
            tippArray.sort(by: {checkForSort(t0: $0, t1: $1) })
            
        }
//        let tippCountText: String = GV.language.getText(.TCTippCount)
//        print("Tippcount:", tippArray.count, tippArray)
        showTippCount()
//        if tippArray.count > 0 {
            tippsButton!.activateButton(true)
//        } else {
//            print("No Tipps")
//        }

        tippIndex = 0  // set tipps to first
        //printFunc(function: "createTipps", start: false)
        return true
     }
    
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
    
    func checkForSort(t0: Tipps, t1:Tipps)->Bool {
        let returnValue = gameArray[t0.fromColumn][t0.fromRow].card.colorIndex < gameArray[t1.fromColumn][t1.fromRow].card.colorIndex
            || (gameArray[t0.fromColumn][t0.fromRow].card.colorIndex == gameArray[t1.fromColumn][t1.fromRow].card.colorIndex &&
                (gameArray[t0.fromColumn][t0.fromRow].card.maxValue < gameArray[t1.fromColumn][t1.fromRow].card.minValue
            || (t0.toRow != NoValue && t1.toRow != NoValue && gameArray[t0.toColumn][t0.toRow].card.maxValue < gameArray[t1.toColumn][t1.toRow].card.minValue)))
        return returnValue
    }
    
    func pairExists(pairsToCheck:[FromToColumnRow], aktPair: FromToColumnRow)->Bool {
        for pair in pairsToCheck {
            if pair.fromColumnRow.column == aktPair.fromColumnRow.column && pair.fromColumnRow.row == aktPair.fromColumnRow.row &&
                pair.toColumnRow.column == aktPair.toColumnRow.column && pair.toColumnRow.row == aktPair.toColumnRow.row {
                return true
            }
        }
        return false
    }

    
    func checkPathToFoundedCards(_ actPair:FromToColumnRow) {
        var targetPoint = CGPoint.zero
        var myTipp = Tipps()
        let firstValue: CGFloat = 10000
        var distanceToLine = firstValue
       let startPoint = gameArray[actPair.fromColumnRow.column][actPair.fromColumnRow.row].position
//        let name = gameArray[index.card1.column][index.card1.row].name
        if actPair.toColumnRow.row == NoValue {
            targetPoint = containers[actPair.toColumnRow.column].position
        } else {
            targetPoint = gameArray[actPair.toColumnRow.column][actPair.toColumnRow.row].position
        }
        let startAngle = calculateAngle(startPoint, point2: targetPoint).angleRadian - GV.oneGrad
        let stopAngle = startAngle + 360 * GV.oneGrad // + 360°
//        let startNode = self.childNodeWithName(name)! as! MySKCard
        var founded = false
        var angle = startAngle
        let multiplierForSearch = CGFloat(3.0)
//        let fineMultiplier = CGFloat(1.0)
        let multiplier:CGFloat = multiplierForSearch
        while angle <= stopAngle && !founded {
            let toPoint = GV.pointOfCircle(1.0, center: startPoint, angle: angle)
            let (foundedPoint, myPoints) = createHelpLines(actPair.fromColumnRow, toPoint: toPoint, inFrame: self.frame, lineSize: cardSize.width, showLines: false)
            if foundedPoint != nil {
                if foundedPoint!.foundContainer && actPair.toColumnRow.row == NoValue && foundedPoint!.column == actPair.toColumnRow.column ||
                    (foundedPoint!.column == actPair.toColumnRow.column && foundedPoint!.row == actPair.toColumnRow.row) {
                    if distanceToLine == firstValue ||
                    myPoints.count > myTipp.points.count ||
                    (myTipp.points.count == myPoints.count && foundedPoint!.distanceToP0 > distanceToLine) {
                        myTipp.fromColumn = actPair.fromColumnRow.column
                        myTipp.fromRow = actPair.fromColumnRow.row
                        myTipp.toColumn = actPair.toColumnRow.column
                        myTipp.toRow = actPair.toColumnRow.row
                        myTipp.points = myPoints
                        distanceToLine = foundedPoint!.distanceToP0
                        
                    }
                    if distanceToLine != firstValue && distanceToLine < foundedPoint!.distanceToP0 && myTipp.points.count == 2 {
                        founded = true
                    }
                }
            } else {
//                print("in else zweig von checkPathToFoundedCards !")
            }
            angle += GV.oneGrad * multiplier
        }

        if distanceToLine.between(0, max: firstValue - 0.1) {
            
            for ind in 0..<myTipp.points.count - 1 {
                myTipp.lineLength += (myTipp.points[ind] - myTipp.points[ind + 1]).length()
            }
            // calculate the value for this tipp
//            myTipp.value = (self.childNode(withName: gameArray[myTipp.fromColumn][myTipp.fromRow].name) as! MySKCard).countScore * (myTipp.points.count - 1)
            myTipp.value = gameArray[myTipp.fromColumn][myTipp.fromRow].card.countScore * (myTipp.points.count - 1)
            tippArray.append(myTipp)
        }
     }
    
    
    func createHelpLines(_ movedFrom: ColumnRow, toPoint: CGPoint, inFrame: CGRect, lineSize: CGFloat, showLines: Bool)->(foundedPoint: Founded?, [CGPoint]) {
        var pointArray = [CGPoint]()
        var foundedPoint: Founded?
        var founded = false
        //        var myLine: SKShapeNode?
        let fromPosition = gameArray[movedFrom.column][movedFrom.row].position
        let line = JGXLine(fromPoint: fromPosition, toPoint: toPoint, inFrame: inFrame, lineSize: lineSize) //, delegate: self)
        let pointOnTheWall = line.line.toPoint
        pointArray.append(fromPosition)
        (founded, foundedPoint) = findEndPoint(movedFrom, fromPoint: fromPosition, toPoint: pointOnTheWall, lineWidth: lineSize, showLines: showLines)
        //        linesArray.append(myLine)
        //        if showLines {self.addChild(myLine)}
        if founded {
            pointArray.append(foundedPoint!.point)
        } else {
            pointArray.append(pointOnTheWall)
            let mirroredLine1 = line.createMirroredLine()
            (founded, foundedPoint) = findEndPoint(movedFrom, fromPoint: mirroredLine1.line.fromPoint, toPoint: mirroredLine1.line.toPoint, lineWidth: lineSize, showLines: showLines)
            
            //            linesArray.append(myLine)
            //            if showLines {self.addChild(myLine)}
            if founded {
                pointArray.append(foundedPoint!.point)
            } else {
                pointArray.append(mirroredLine1.line.toPoint)
                let mirroredLine2 = mirroredLine1.createMirroredLine()
                (founded, foundedPoint) = findEndPoint(movedFrom, fromPoint: mirroredLine2.line.fromPoint, toPoint: mirroredLine2.line.toPoint, lineWidth: lineSize, showLines: showLines)
                //                linesArray.append(myLine)
                //                if showLines {self.addChild(myLine)}
                if founded {
                    pointArray.append(foundedPoint!.point)
                } else {
                    pointArray.append(mirroredLine2.line.toPoint)
                    let mirroredLine3 = mirroredLine2.createMirroredLine()
                    (founded, foundedPoint) = findEndPoint(movedFrom, fromPoint: mirroredLine3.line.fromPoint, toPoint: mirroredLine3.line.toPoint, lineWidth: lineSize, showLines: showLines)
                    //                    linesArray.append(myLine)
                    //                    if showLines {self.addChild(myLine)}
                    if founded {
                        pointArray.append(foundedPoint!.point)
                    } else {
                        pointArray.append(mirroredLine3.line.toPoint)
                        let mirroredLine4 = mirroredLine3.createMirroredLine()
                        (founded, foundedPoint) = findEndPoint(movedFrom, fromPoint: mirroredLine4.line.fromPoint, toPoint: mirroredLine4.line.toPoint, lineWidth: lineSize, showLines: showLines)
                        //                    linesArray.append(myLine)
                        //                    if showLines {self.addChild(myLine)}
                        if founded {
                            pointArray.append(foundedPoint!.point)
                        } else {
                            pointArray.append(mirroredLine4.line.toPoint)
                            let mirroredLine5 = mirroredLine4.createMirroredLine()
                            (founded, foundedPoint) = findEndPoint(movedFrom, fromPoint: mirroredLine5.line.fromPoint, toPoint: mirroredLine5.line.toPoint, lineWidth: lineSize, showLines: showLines)
                            //                    linesArray.append(myLine)
                            //                    if showLines {self.addChild(myLine)}
                            if founded {
                                pointArray.append(foundedPoint!.point)
                            } else {
                                pointArray.append(mirroredLine5.line.toPoint)
                            }
                        }

                    }
                    
                }
            }
        }
        
        if showLines {
            let color = calculateLineColor(foundedPoint!, movedFrom:  movedFrom)
            drawHelpLines(pointArray, lineWidth: lineSize, twoArrows: false, color: color)
        }
        
        return (foundedPoint, pointArray)
    }
    
    func calculateLineColor(_ foundedPoint: Founded, movedFrom: ColumnRow) -> MyColors {
        
        var color = MyColors.red
        var foundedPosition = GameArrayPositions()
        
        if foundedPoint.distanceToP0 == foundedPoint.maxDistance {
            return color
        }
        
        var actColorHasContainer = false
        for container in containers {
            if container.colorIndex == gameArray[movedFrom.column][movedFrom.row].card.colorIndex {
                actColorHasContainer = true
            }
        }
        
        if foundedPoint.foundContainer {
            foundedPosition.card = containers[foundedPoint.column]
//            foundedPosition.card.colorIndex = containers[foundedPoint.column].colorIndex
            foundedPosition.card.maxValue = containers[foundedPoint.column].maxValue
            foundedPosition.card.minValue = containers[foundedPoint.column].minValue
        } else {
            foundedPosition = gameArray[foundedPoint.column][foundedPoint.row]
        }
        let first = gameArray[movedFrom.column][movedFrom.row].card
        let second = foundedPosition.card
        let connectable = cardManager!.areConnectable(first: first, second: second)
        if connectable //MySKCard.areConnectable(first: first, second: second)
                ||
            (foundedPosition.card.minValue == NoColor && !actColorHasContainer) &&
                (gameArray[movedFrom.column][movedFrom.row].card.maxValue == LastCardValue) {
                color = .green
        }
        return color
    }
    
    func findEndPoint(_ movedFrom: ColumnRow, fromPoint: CGPoint, toPoint: CGPoint, lineWidth: CGFloat, showLines: Bool)->(pointFounded:Bool, closestPoint: Founded?) {
        var foundedPoint = Founded()
        let toPoint = toPoint
        var pointFounded = false
//        var closestCardfast = Founded()
        if let closestCard = fastFindClosestPoint(fromPoint, P2: toPoint, lineWidth: lineWidth, movedFrom: movedFrom) {
            if showLines {
                makeTrembling(closestCard)
            }
           foundedPoint = closestCard
            pointFounded = true
        }
        return (pointFounded, foundedPoint)
    }
    
    func findClosestPoint(_ P1: CGPoint, P2: CGPoint, lineWidth: CGFloat, movedFrom: ColumnRow) -> Founded? {
        
        /*
        Ax+By=C  - Equation of a line
        Line is given with 2 Points (x1, y1) and (x2, y2)
        A = y2-y1
        B = x1-x2
        C = A*x1+B*y1
        */
        //let offset = P1 - P2
        var founded = Founded()
        for column in 0..<countColumns {
            for row in 0..<countRows {
                if gameArray[column][row].used {
                    let P0 = gameArray[column][row].position
                    //                    if (P0 - P1).length() > lineWidth { // check all others but not me!!!
                    if !(movedFrom.column == column && movedFrom.row == row) {
                        let intersectionPoint = findIntersectionPoint(P1, b:P2, c:P0)
                        
                        let distanceToP0 = (intersectionPoint - P0).length()
                        let distanceToP1 = (intersectionPoint - P1).length()
                        let distanceToP2 = (intersectionPoint - P2).length()
                        let lengthOfLineSegment = (P1 - P2).length()
                        
                        if distanceToP0 < lineWidth && distanceToP2 < lengthOfLineSegment {
                            if founded.distanceToP1 > distanceToP1 {
                                founded.point = intersectionPoint
                                founded.distanceToP1 = distanceToP1
                                founded.distanceToP0 = distanceToP0
                                founded.column = column
                                founded.row = row
                                founded.foundContainer = false
                            }
                        }
                    }
                }
            }
        }
        
        for index in 0..<countContainers {
            let P0 = containers[index].position
            if (P0 - P1).length() > lineWidth { // check all others but not me!!!
                let intersectionPoint = findIntersectionPoint(P1, b:P2, c:P0)
                
                let distanceToP0 = (intersectionPoint - P0).length()
                let distanceToP1 = (intersectionPoint - P1).length()
                let distanceToP2 = (intersectionPoint - P2).length()
                let lengthOfLineSegment = (P1 - P2).length()
                
                if distanceToP0 < lineWidth && distanceToP2 < lengthOfLineSegment {
                    if founded.distanceToP1 > distanceToP1 {
                        founded.point = intersectionPoint
                        founded.distanceToP1 = distanceToP1
                        founded.distanceToP0 = distanceToP0
                        founded.column = index
                        founded.row = NoValue
                        founded.foundContainer = true
                    }
                }
            }
            
        }
        if founded.distanceToP1 != founded.maxDistance {
            return founded
        } else {
            return nil
        }
    }
    func fastFindClosestPoint(_ P1: CGPoint, P2: CGPoint, lineWidth: CGFloat, movedFrom: ColumnRow) -> Founded? {
        
        /*
        Ax+By=C  - Equation of a line
        Line is given with 2 Points (x1, y1) and (x2, y2)
        A = y2-y1
        B = x1-x2
        C = A*x1+B*y1
        */
        //let offset = P1 - P2
        
        var fromToColumnRowFirst = FromToColumnRow()
        var fromToColumnRow = FromToColumnRow()
        var fromWall = false
        
        fromToColumnRowFirst.fromColumnRow = calculateColumnRowFromPosition(P1)
        fromToColumnRowFirst.toColumnRow = calculateColumnRowFromPosition(P2)
        fromToColumnRow = calculateColumnRowWhenPointOnTheWall(fromToColumnRowFirst)
        
        fromWall = !(fromToColumnRowFirst == fromToColumnRow)
            
        var actColumnRow = fromToColumnRow.fromColumnRow
        var founded = Founded()
        var stopCycle = false
        while !stopCycle {
            if fromWall {
                (actColumnRow, stopCycle) = (actColumnRow, false)
                fromWall = false
            } else {
                (actColumnRow, stopCycle) = findNextPointToCheck(actColumnRow, fromToColumnRow: fromToColumnRow)
            }
            if gameArray[actColumnRow.column][actColumnRow.row].used {
                let P0 = gameArray[actColumnRow.column][actColumnRow.row].position
                //                    if (P0 - P1).length() > lineWidth { // check all others but not me!!!
                if !(movedFrom.column == actColumnRow.column && movedFrom.row == actColumnRow.row) {
                    let intersectionPoint = findIntersectionPoint(P1, b:P2, c:P0)
                    
                    let distanceToP0 = (intersectionPoint - P0).length()
                    let distanceToP1 = (intersectionPoint - P1).length()
                    let distanceToP2 = (intersectionPoint - P2).length()
                    let lengthOfLineSegment = (P1 - P2).length()
                    
                    if distanceToP0 < lineWidth && distanceToP2 < lengthOfLineSegment {
                        if founded.distanceToP1 > distanceToP1 {
                            founded.point = intersectionPoint
                            founded.distanceToP1 = distanceToP1
                            founded.distanceToP0 = distanceToP0
                            founded.column = actColumnRow.column
                            founded.row = actColumnRow.row
                            founded.foundContainer = false
                        }
                    }
                }
            }
        }
        for index in 0..<countContainers {
            let P0 = containers[index].position
            if (P0 - P1).length() > lineWidth { // check all others but not me!!!
                let intersectionPoint = findIntersectionPoint(P1, b:P2, c:P0)
                
                let distanceToP0 = (intersectionPoint - P0).length()
                let distanceToP1 = (intersectionPoint - P1).length()
                let distanceToP2 = (intersectionPoint - P2).length()
                let lengthOfLineSegment = (P1 - P2).length()
                
                if distanceToP0 < lineWidth && distanceToP2 < lengthOfLineSegment {
                    if founded.distanceToP1 > distanceToP1 {
                        founded.point = intersectionPoint
                        founded.distanceToP1 = distanceToP1
                        founded.distanceToP0 = distanceToP0
                        founded.column = index
                        founded.row = NoValue
                        founded.foundContainer = true
                    }
                }
            }
            
        }
        if founded.distanceToP1 != founded.maxDistance {
            return founded
        } else {
            return nil
        }
    }
    
    func calculateColumnRowWhenPointOnTheWall(_ fromToColumnRow: FromToColumnRow)->FromToColumnRow {
        var myFromToColumnRow = fromToColumnRow
        if fromToColumnRow.fromColumnRow.column <= NoValue {
           myFromToColumnRow.fromColumnRow.column = 0
        }
        if fromToColumnRow.fromColumnRow.row <= NoValue {
            myFromToColumnRow.fromColumnRow.row = 0
        }
        if fromToColumnRow.fromColumnRow.column >= countColumns {
            myFromToColumnRow.fromColumnRow.column = countColumns - 1
        }
        if fromToColumnRow.fromColumnRow.row >= countRows {
            myFromToColumnRow.fromColumnRow.row = countRows - 1
        }
        if fromToColumnRow.toColumnRow.column <= NoValue {
            myFromToColumnRow.toColumnRow.column = 0
        }
        if fromToColumnRow.toColumnRow.row <= NoValue {
            myFromToColumnRow.toColumnRow.row = 0
        }
        if fromToColumnRow.toColumnRow.column >= countColumns {
            myFromToColumnRow.toColumnRow.column = countColumns - 1
        }
        if fromToColumnRow.toColumnRow.row >= countRows {
            myFromToColumnRow.toColumnRow.row = countRows - 1
        }
        
        return myFromToColumnRow
    }
    
    func findNextPointToCheck(_ actColumnRow: ColumnRow, fromToColumnRow: FromToColumnRow)->(ColumnRow, Bool) {

        var myActColumnRow = actColumnRow
        let columnAdder = fromToColumnRow.fromColumnRow.column < fromToColumnRow.toColumnRow.column ? 1 : -1
        let rowAdder = fromToColumnRow.fromColumnRow.row < fromToColumnRow.toColumnRow.row ? 1 : -1
        
        if myActColumnRow.column != fromToColumnRow.toColumnRow.column {
            myActColumnRow.column += columnAdder
        } else {
            myActColumnRow.column = fromToColumnRow.fromColumnRow.column
            if myActColumnRow.row != fromToColumnRow.toColumnRow.row {
                myActColumnRow.row += rowAdder
            }
        }
            

        if myActColumnRow == fromToColumnRow.toColumnRow {
            return (myActColumnRow, true) // toPoint reached
        }
        return (myActColumnRow, false)
    }
    
    func findIntersectionPoint(_ a:CGPoint, b:CGPoint, c:CGPoint) ->CGPoint {
        let x1 = a.x
        let y1 = a.y
        let x2 = b.x
        let y2 = b.y
        let x3 = c.x
        let y3 = c.y
        let px = x2-x1
        let py = y2-y1
        let dAB = px * px + py * py
        let u = ((x3 - x1) * px + (y3 - y1) * py) / dAB
        let x = x1 + u * px
        let y = y1 + u * py
        return CGPoint(x: x, y: y)
    }
    
    
    

    
    func drawHelpLines(_ points: [CGPoint], lineWidth: CGFloat, twoArrows: Bool, color: MyColors) {
        lastDrawHelpLinesParameters.points = points
        lastDrawHelpLinesParameters.lineWidth = lineWidth
        lastDrawHelpLinesParameters.twoArrows = twoArrows
        lastDrawHelpLinesParameters.color = color
        drawHelpLinesSpec()
    }
    
    func drawHelpLinesSpec() {
        let points = lastDrawHelpLinesParameters.points
        var lineWidth = cardSize.width
        if showHelpLines == .green {
            lineWidth = lastDrawHelpLinesParameters.lineWidth
        }

        let twoArrows = lastDrawHelpLinesParameters.twoArrows
        let color = lastDrawHelpLinesParameters.color
        let arrowLength = cardSize.width * 0.30
    
        let pathToDraw:CGMutablePath = CGMutablePath()
        let myLine:SKShapeNode = SKShapeNode(path:pathToDraw)
        removeNodesWithName(myLineName)
        myLine.lineWidth = lineWidth * lineWidthMultiplier!
        myLine.name = myLineName
        
        // check if valid data
        for index in 0..<points.count {
            if points[index].x.isNaN || points[index].y.isNaN {
                print("isNan")
                return
            }
        }
        
//        CGPathMoveToPoint(pathToDraw, nil, points[0].x, points[0].y)
        pathToDraw.move(to: points[0])
        for index in 1..<points.count {
//            CGPathAddLineToPoint(pathToDraw, nil, points[index].x, points[index].y)
            pathToDraw.addLine(to: points[index])
        }
        
        let lastButOneIndex = points.count - 2
        
        let offset = points.last! - points[lastButOneIndex]
        var angleR:CGFloat = 0.0
        
        if offset.x > 0 {
            angleR = asin(offset.y / offset.length())
        } else {
            if offset.y > 0 {
                angleR = acos(offset.x / offset.length())
            } else {
                angleR = -acos(offset.x / offset.length())
                
            }
        }
        
        let p1 = GV.pointOfCircle(arrowLength, center: points.last!, angle: angleR - (150 * GV.oneGrad))
        let p2 = GV.pointOfCircle(arrowLength, center: points.last!, angle: angleR + (150 * GV.oneGrad))
        
        
        
//        CGPathAddLineToPoint(pathToDraw, nil, p1.x, p1.y)
//        CGPathMoveToPoint(pathToDraw, nil, points.last!.x, points.last!.y)
//        CGPathAddLineToPoint(pathToDraw, nil, p2.x, p2.y)
        pathToDraw.addLine(to: p1)
        pathToDraw.move(to: points.last!)
        pathToDraw.addLine(to: p2)
        
        
        if twoArrows {
            let offset = points.first! - points[1]
            var angleR:CGFloat = 0.0
            
            if offset.x > 0 {
                angleR = asin(offset.y / offset.length())
            } else {
                if offset.y > 0 {
                    angleR = acos(offset.x / offset.length())
                } else {
                    angleR = -acos(offset.x / offset.length())
                    
                }
            }
            
            let p1 = GV.pointOfCircle(arrowLength, center: points.first!, angle: angleR - (150 * GV.oneGrad))
            let p2 = GV.pointOfCircle(arrowLength, center: points.first!, angle: angleR + (150 * GV.oneGrad))
            
            
//            CGPathMoveToPoint(pathToDraw, nil, points[0].x, points[0].y)
//            CGPathAddLineToPoint(pathToDraw, nil, p1.x, p1.y)
//            CGPathMoveToPoint(pathToDraw, nil, points[0].x, points[0].y)
//            CGPathAddLineToPoint(pathToDraw, nil, p2.x, p2.y)
            pathToDraw.move(to: points[0])
            pathToDraw.addLine(to: p1)
            pathToDraw.move(to: points[0])
            pathToDraw.addLine(to: p2)
        }
        
        myLine.path = pathToDraw

        switch self.showHelpLines {
        case .green:
            if color == .red {
                myLine.strokeColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8) // GV.colorSets[GV.colorSetIndex][colorIndex + 1]
            } else {
                myLine.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.8) // GV.colorSets[GV.colorSetIndex][colorIndex + 1]
            }
        case .cyan:
            myLine.strokeColor = SKColor.cyan
        case .hidden:
            myLine.strokeColor = SKColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0)
        }
        myLine.zPosition = 100
        myLine.lineCap = .round
        
        self.addChild(myLine)
        
    }
    
    func makeTrembling(_ nextPoint: Founded) {
        var tremblingCardPosition = CGPoint.zero
        if lastNextPoint != nil && ((lastNextPoint!.column != nextPoint.column) ||  (lastNextPoint!.row != nextPoint.row)) {
            if lastNextPoint!.foundContainer {
                tremblingCardPosition = containers[lastNextPoint!.column].position
            } else {
                tremblingCardPosition = gameArray[lastNextPoint!.column][lastNextPoint!.row].position
            }
            let nodes = self.nodes(at: tremblingCardPosition)
            
            for index in 0..<nodes.count {
                if nodes[index] is MySKCard {
                    (nodes[index] as! MySKCard).tremblingType = .noTrembling

                    tremblingCards.removeAll()
                }
            }
            lastNextPoint = nil
        }

//        stopTrembling()
        if lastNextPoint == nil {
            if nextPoint.foundContainer {
                tremblingCardPosition = containers[nextPoint.column].position
            } else {
                tremblingCardPosition = gameArray[nextPoint.column][nextPoint.row].position
            }
            addCardToTremblingCards(tremblingCardPosition)
            lastNextPoint = nextPoint
        }
        
    }
    
    func addCardToTremblingCards(_ position: CGPoint) {
        let nodes = self.nodes(at: position)
        for index in 0..<nodes.count {
            if nodes[index] is MySKCard {
                tremblingCards.append(nodes[index] as! MySKCard)
                (nodes[index] as! MySKCard).tremblingType = .changeSize
            }
        }
        
    }
    
    func calculateAngle(_ point1: CGPoint, point2: CGPoint) -> (angleRadian:CGFloat, angleDegree: CGFloat) {
        //        let pointOfCircle = CGPoint (x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        let offset = point2 - point1
        let length = offset.length()
        let sinAlpha = offset.y / length
        let angleRadian = asin(sinAlpha);
        let angleDegree = angleRadian * 180.0 / CGFloat(M_PI)
        return (angleRadian, angleDegree)
    }

//    func pointOfCircle(radius: CGFloat, center: CGPoint, angle: CGFloat) -> CGPoint {
//        let pointOfCircle = CGPoint (x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
//        return pointOfCircle
//    }


    override func update(_ currentTime: TimeInterval) {
        let sec10: Int = Int(currentTime * 10) % 3
        if sec10 != lastUpdateSec && sec10 == 0 {
            let adder:CGFloat = 5
            for index in 0..<tremblingCards.count {
                let aktCard = tremblingCards[index]
                switch aktCard.trembling {
                    case 0: aktCard.trembling = adder
                    case adder: aktCard.trembling = -adder
                    case -adder: aktCard.trembling = adder
                    default: aktCard.trembling = adder
                }
                switch aktCard.tremblingType {
                    case .noTrembling: break
                    case .changeSize:  aktCard.size = CGSize(width: aktCard.origSize.width +  aktCard.trembling, height: aktCard.origSize.height +  aktCard.trembling)
                    case .changePos: break
                    case .changeDirection: aktCard.zRotation = CGFloat(CGFloat(M_PI)/CGFloat(aktCard.trembling == 0 ? 16 : aktCard.trembling * CGFloat(8)))
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
            startNewGame(false)
        }
        
        checkMultiplayer()
        checkColoredLines()
        
    }
    
    func checkColoredLines() {
        if lastPair.color == MyColors.green { // Timer for check Green Line
            if Date().timeIntervalSince(lastPair.startTime) > fixationTime && !lastPair.fixed {
                lastPair.fixed = true
                if showHelpLines == .green {
                    lineWidthMultiplier = lineWidthMultiplierSpecial
                }
                drawHelpLinesSpec() // draw thick Line
            }
        }
        

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
            let alert = getNextPlayArt(false)
            GV.mainViewController!.showAlert(alert)
        }
        
        if opponent.finish == .finished || opponent.finish == .interrupted {
            animateFinishGame()
            if opponent.finish == .finished {
                saveStatisticAndGame()
            }
            opponent.finish = .none
            playerType = .singlePlayer
            doTimeCount = false
            opponentTypeLabel.isHidden = true
            opponentNameLabel.isHidden = true
            opponentTimeLabel.isHidden = true
            opponentScoreLabel.isHidden = true
            opponentCardCountLabel.isHidden = true
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
                if container.colorIndex == NoValue {
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
        let allActions = SKAction.group([moveToContainerAction, rotateAction])
        let action = SKAction.sequence([allActions, hideAction, countAction])
        card.run(action)
    }
    
    func cardDidCollideWithContainer(_ node1:MySKCard, node2:MySKCard, points: [CGPoint]) {
        let movingCard = node1
        let container = node2
        
//        var containerColorIndex = container.colorIndex
//        let movingCardColorIndex = movingCard.colorIndex
//        let movingCardCompareValue = GameArrayPositions(colorIndex: movingCard.colorIndex, minValue: movingCard.minValue, maxValue: movingCard.maxValue, origValue: movingCard.origValue)
//        var containerCompareValue = GameArrayPositions(colorIndex: container.colorIndex, minValue: container.minValue, maxValue: container.maxValue, origValue: container.origValue)
//        
        
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
        
        let connectable = cardManager?.areConnectable(first: movingCard, second: container)

        let OK = movingCard.colorIndex == container.colorIndex &&
        (
            container.minValue == NoColor || connectable!
//            MySKCard.areConnectable(first: movingCard, second: container)
//            movingCard.maxValue + 1 == container.minValue ||
//            movingCard.minValue - 1 == container.maxValue ||
//            (container.minValue == FirstCardValue && movingCard.maxValue == LastCardValue && container.belongsToPackage < countPackages)
        )

        
        
        if OK  {
            push(container, status: .unification)
            push(movingCard, status: .removed)
            container.connectWith(otherCard: movingCard)
            cardManager!.moveCard(card: movingCard, toCard: container)
            saveHistoryRecord(colorIndex: movingCard.colorIndex, points:  points,
                              fromColumn: movingCard.column, fromRow: movingCard.row, fromMinValue: movingCard.minValue, fromMaxValue: movingCard.maxValue,
                              toColumn: container.column,   toRow: container.row,   toMinValue: container.minValue,   toMaxValue: container.maxValue)

            self.addChild(showCountScore("+\(movingCard.countScore)", position: movingCard.position))
            
//            movingCard.countScore += mirroredScore
            levelScore += movingCard.countScore
            levelScore += movingCard.getMirroredScore()
            
            container.reload()
            //gameArray[movingCard.column][movingCard.row] = false
            resetGameArrayCell(movingCard)
            movingCard.removeFromParent()
            playSound("Container", volume: GV.player!.soundVolume)
            countMovingCards = 0
            
            updateCardCount(-1)
            
            collisionActive = false
            //movingCard.removeFromParent()
            checkGameFinished()
        } else {
            updateCardCount(-1)
            movingCard.removeFromParent()
            countMovingCards = 0
            push(movingCard, status: .removed)
            pull(false) // no createTipps
            startTippTimer()
            tippsButton!.activateButton(true)

        }
        
     }
    
    func resetGameArrayCell(_ card:MySKCard) {
        gameArray[card.column][card.row].card = MySKCard()
        gameArray[card.column][card.row].used = false
    }
    
    func updateGameArrayCell(_ card:MySKCard) {
        gameArray[card.column][card.row].card = card
        gameArray[card.column][card.row].used = true
    }

    func cardDidCollideWithMovingCard(node1:MySKCard, node2:MySKCard, points: [CGPoint]) {
        let movingCard = node1
        let card = node2
        collisionActive = false
        
        let connectable = cardManager!.areConnectable(first: movingCard, second: card)

//        let OK = connectable //MySKCard.areConnectable(first: movingCard, second: card)
        if connectable {
            push(card, status: .unification)
            push(movingCard, status: .removed)
            
            card.connectWith(otherCard: movingCard)
            cardManager!.moveCard(card: movingCard, toCard: card)
            saveHistoryRecord(colorIndex: movingCard.colorIndex, points: points,
                              fromColumn: movingCard.column, fromRow: movingCard.row, fromMinValue: movingCard.minValue, fromMaxValue: movingCard.maxValue,
                              toColumn: card.column,   toRow: card.row,   toMinValue: card.minValue,   toMaxValue: card.maxValue)
            
            
            self.addChild(showCountScore("+\(movingCard.countScore)", position: movingCard.position))
            levelScore += movingCard.countScore
            levelScore += movingCard.getMirroredScore()

            card.reload()
            
            playSound("OK", volume: GV.player!.soundVolume)
        
            updateGameArrayCell(card)
            resetGameArrayCell(movingCard)
            
            movingCard.removeFromParent()
            countMovingCards = 0
            updateCardCount(-1)
            checkGameFinished()
            saveStatisticAndGame()
       } else {

            updateCardCount(-1)
            movingCard.removeFromParent()
            countMovingCards = 0
            push(movingCard, status: .removed)
            pull(false) // no createTipps
            startTippTimer()
            tippsButton!.activateButton(true)
            
        }
    }
    
    func showCountScore(_ text: String, position: CGPoint)->SKLabelNode {
        let score = SKLabelNode()
        score.position = position
        score.text = text
        score.fontColor = UIColor.red
        score.fontName = "ArialMT"
        score.fontSize = 30
        score.zPosition = 1000
        let showAction = SKAction.moveTo(y: position.y + 1000, duration: 10.0)
        let hideAction = SKAction.sequence([SKAction.fadeOut(withDuration: 3.0), SKAction.removeFromParent()])
        let scoreActions = SKAction.group([showAction, hideAction])
        score.run(scoreActions)
        return score
    }
    
    func saveHistoryRecord(colorIndex: Int, points: [CGPoint],
                           fromColumn: Int, fromRow: Int, fromMinValue: Int, fromMaxValue: Int,
                           toColumn: Int,   toRow: Int,   toMinValue: Int,   toMaxValue: Int) {
        #if REALM_V2
            if !replaying {
                let historyRecord = HistoryModel()
                historyRecord.ID = GV.createNewRecordID(.historyModel)
                historyRecord.gameID = self.actGame!.ID
                historyRecord.recordNr = realm.objects(HistoryModel.self).filter("gameID = %d", actGame!.ID).count + 1
                historyRecord.colorIndex = colorIndex
                historyRecord.fromColumn = fromColumn
                historyRecord.fromRow = fromRow
                historyRecord.fromMinValue = fromMinValue
                historyRecord.fromMaxValue = fromMaxValue
                
                historyRecord.toColumn = toColumn
                historyRecord.toRow = toRow
                historyRecord.toMinValue = toMinValue
                historyRecord.toMaxValue = toMaxValue
                try! realm.write() {
                    for point in points {
                        let realmPoint = PointModel()
                        realmPoint.x = Double(point.x)
                        realmPoint.y = Double(point.y)
                        historyRecord.points.append(realmPoint)
                        realm.add(realmPoint)
                    }
                    realm.add(historyRecord)
                }
            }
        #endif
    }
    
    func deleteLastHistoryRecord() {
        #if REALM_V2
            try! realm.write() {
                if let last = realm.objects(HistoryModel.self).filter("gameID = %d", actGame!.ID).last {
                    realm.delete(last)
                }
            }
        #endif
    }

    func checkGameFinished() {
        
        
        let usedCellCount = checkGameArray()
//        let containersOK = checkContainers()
        
        let finishGame = GV.player!.name != "tester" ? cardCount == 0 : cardCount < maxCardCount
        
        if finishGame { // Level completed, start a new game
            
            stopTimer(&countUp)
            playMusic("Winner", volume: GV.player!.musicVolume, loops: 0)
            playerCardCountLabel.text = "0"
            if playerType == .multiPlayer {
                GV.peerToPeerService?.sendInfo(.gameIsFinished, message: [String(levelScore)], toPeerIndex: opponent.peerIndex)
            }
            
            // get && modify the statistic record
            
            saveStatisticAndGame()
            if playerType == .multiPlayer {
                alertIHaveGameFinished()
            } else {
                let alert = getNextPlayArt(true)
                GV.mainViewController!.showAlert(alert)
            }
        } else if usedCellCount <= minUsedCells && usedCellCount > 1 { //  && cardCount > maxUsedCells {
            generateCards(.normal)  // Nachgenerierung
        } else {
            if cardCount > 0 /*&& cardStack.count(.MySKCardType) > 0*/ {
                gameArrayChanged = true
            }
        }
    }
    
    func saveStatisticAndGame () {
        if realm.objects(StatisticModel.self).filter("playerID = %d AND levelID = %d", GV.player!.ID, GV.player!.levelID).count == 0 {
            // create a new Statistic record if required
            let statistic = StatisticModel()
            statistic.ID = GV.createNewRecordID(.statisticModel)
            statistic.playerID = GV.player!.ID
            statistic.levelID = GV.player!.levelID
            try! realm.write({
                realm.add(statistic)
            })
        }

        let statistic = realm.objects(StatisticModel.self).filter("playerID = %d AND levelID = %d", GV.player!.ID, GV.player!.levelID).first!
        
        realm.beginWrite()
        statistic.actTime = timeCount
        statistic.allTime += timeCount
        
        if statistic.bestTime == 0 || timeCount < statistic.bestTime {
            statistic.bestTime = timeCount
        }
        
        
        statistic.actScore = levelScore
        if cardCount == 0 {
            statistic.levelScore += levelScore
            if statistic.bestScore < levelScore {
                statistic.bestScore = levelScore
            }
            if statistic.bestScore < levelScore {
                statistic.bestScore = levelScore
            }
        }
        
        actGame!.time = timeCount
        actGame!.playerScore = levelScore
        actGame!.played = true
        #if REALM_V2
            if cardCount > 0 {
                actGame!.gameFinished = false
            } else {
                actGame!.gameFinished = true
            }
        #endif
        if playerType == .multiPlayer {
            actGame!.multiPlay = true
            actGame!.opponentName = opponent.name
            actGame!.opponentScore = opponent.score
            statistic.countMultiPlays += 1
            if opponent.score > levelScore {
                statistic.defeats += 1
            } else {
                statistic.victorys += 1
            }
        } else if cardCount == 0 {  // countPlays only when game is finished
            statistic.countPlays += 1
        }
        try! realm.commitWrite()

    }
    
    func restartButtonPressed() {
        let alert = getNextPlayArt(false)
        GV.mainViewController!.showAlert(alert)
    }
    
    func choosePartner() {
        let partnerNames = GV.peerToPeerService!.getPartnerName()
        if GV.peerToPeerService!.countPartners() > 1 {
            let alert = UIAlertController(title: GV.language.getText(.tcChoosePartner),
                                          message: "",
                                          preferredStyle: .alert)
            for index in 0..<partnerNames.count {
                let identity = partnerNames[index]
                let nameAction = UIAlertAction(title: identity, style: .default,
                                                handler: {(paramAction:UIAlertAction!) in
                                                    self.opponent.name = identity
                                                    self.opponent.peerIndex = index
                                                    self.opponent.score = 0
                                                    self.callPartner(index, identity: identity)
                })
                alert.addAction(nameAction)
            }
            GV.mainViewController!.showAlert(alert)
        } else if GV.peerToPeerService!.countPartners() > 0 {
            let identity = partnerNames[0]
            callPartner(0, identity: identity )
        }
    }
    
    func callPartner(_ index: Int, identity: String) {
        let gameNumber = randomGameNumber()
        opponent.peerIndex = index
        let myName = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        var answer = GV.peerToPeerService!.sendMessage(.iWantToPlayWithYou, message: [myName, String(levelIndex), String(gameNumber)], toPeerIndex: index)
        switch answer[0] {
        case answerYes:
            self.playerType = .multiPlayer
            self.gameNumber = gameNumber
            self.opponent.name = identity
            self.opponent.score = 0
            self.restartGame = true
        case answerNo, GV.IAmBusy, GV.timeOut:
            alertOpponentDoesNotWantPlay(alert: .tcOpponentNotPlay)
            self.opponent = Opponent()
            self.playerType = .singlePlayer
        case answerLevelNotOK:
            alertOpponentDoesNotWantPlay(alert: .tcOpponentLevelIsLower, opponentName: identity)
            self.opponent = Opponent()
            self.playerType = .singlePlayer
        default:
            break
        }
    }
    
    func alertOpponentDoesNotWantPlay(alert: TextConstants, opponentName: String = "") {
        let alert = UIAlertController(title: GV.language.getText(alert, values: String(opponentName)),
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
        startNewGame(true)
    }

    
    func randomGameNumber()->Int {
        var freeGameNumbers = [Int]()
        let gameNumberSet = realm.objects(GamePredefinitionModel.self)
        for index in 0..<gameNumberSet.count {
            if realm.objects(GameModel.self).filter("gameNumber = %d and levelID = %d and played = true", gameNumberSet[index].gameNumber, levelIndex).count == 0 {
                freeGameNumbers.append(gameNumberSet[index].gameNumber)
            }
        }
        if freeGameNumbers.count > 0 {
            let foundedGameNumber = freeGameNumbers[GV.randomNumber(freeGameNumbers.count)]
            return foundedGameNumber
        }
        return 0
    }
    
    func callBackFromMySKTextField(_ gameNumber: Int) {
        self.gameNumber = gameNumber
        self.isUserInteractionEnabled = true
        startNewGame(false)
    }
    
    func startNewGame(_ next: Bool) {
        stopped = true
        if next {
            lastNextPoint = nil
        }
        
        realm.beginWrite()
        realm.delete(realm.objects(GameModel.self).filter("played = false"))
        try! realm.commitWrite()
        
        stopCreateTippsInBackground = true
        for _ in 0..<self.children.count {
            let childNode = children[self.children.count - 1]
            childNode.removeFromParent()
        }
        
        stopTimer(&countUp)
//        print("stopCreateTippsInBackground from newGame")
//
        prepareNextGame(next)
        generateCards(.first)
    }

    func getNextPlayArt(_ congratulations: Bool, firstStart: Bool = false)->UIAlertController {
        let playerName = GV.player!.name + "!"
        let statisticsTxt = ""
        var congratulationsTxt = ""
        
        
        if congratulations {
            
            let actGames = realm.objects(GameModel.self).filter("levelID = %d and gameNumber = %d", levelIndex, actGame!.gameNumber)
            
            let bestGameScore: Int = actGames.max(ofProperty: "playerScore")!
            let bestScorePlayerID = actGames.filter("playerScore = %d", bestGameScore).first!.playerID
            let bestScorePlayerName = realm.objects(PlayerModel.self).filter("ID = %d",bestScorePlayerID).first!.name
            
            tippCountLabel.text = String(0)
            let statistic = realm.objects(StatisticModel.self).filter("playerID = %d AND levelID = %d", GV.player!.ID, GV.player!.levelID).first!

            congratulationsTxt = GV.language.getText(.tcLevel, values: " \(levelIndex + 1)")
            congratulationsTxt += "\r\n" + GV.language.getText(.tcGameComplete, values: String(gameNumber + 1))
            congratulationsTxt += "\r\n" + GV.language.getText(TextConstants.tcCongratulations) + playerName
            congratulationsTxt += "\r\n ============== \r\n"
            
            if actGames.count > 1 {
                if bestScorePlayerName != GV.player!.name {
                    congratulationsTxt += "\r\n" + GV.language.getText(.tcYourScore, values: String(levelScore))
                    congratulationsTxt += "\r\n" + GV.language.getText(.tcBestScoreOfGame, values: String(bestGameScore), bestScorePlayerName)
                } else {
                    congratulationsTxt += "\r\n" + GV.language.getText(.tcYouAreTheBest, values: String(bestGameScore))
                }
            } else {
                congratulationsTxt += "\r\n" + GV.language.getText(.tcLevelScore, values: " \(bestGameScore)")
            }
            congratulationsTxt += "\r\n" + GV.language.getText(.tcActTime) + String(statistic.actTime.dayHourMinSec)
        }
        let alert = UIAlertController(title: congratulations ? congratulationsTxt : GV.language.getText(.tcChooseGame),
            message: statisticsTxt,
            preferredStyle: .alert)
        
        if playerType == .multiPlayer {
            let stopAction = UIAlertAction(title: GV.language.getText(.tcStopCompetition), style: .default,
                                            handler: {(paramAction:UIAlertAction!) in
                                                self.stopCompetition()
            })
            alert.addAction(stopAction)
            
        } else {
            if !firstStart {
                let againAction = UIAlertAction(title: GV.language.getText(.tcGameAgain), style: .default,
                    handler: {(paramAction:UIAlertAction!) in
                        self.startNewGame(false)
                })
                alert.addAction(againAction)
            }
            let newGameAction = UIAlertAction(title: GV.language.getText(TextConstants.tcNewGame), style: .default,
                handler: {(paramAction:UIAlertAction!) in
                    self.startNewGame(true)
                    //self.gameArrayChanged = true

            })
            alert.addAction(newGameAction)
            
            let chooseLevelAction = UIAlertAction(title: GV.language.getText(.tcChooseLevel), style: .default,
                                           handler: {(paramAction:UIAlertAction!) in
                                            self.chooseLevelAndOptions()
            })
            alert.addAction(chooseLevelAction)

            let autoPlayAction = UIAlertAction(title: GV.language.getText(.tcAutoPlay), style: .default,
                                                  handler: {(paramAction:UIAlertAction!) in
                                                    self.startAutoplay()
            })
            alert.addAction(autoPlayAction)
            #if TEST
                if realm.objects(HistoryModel.self).filter("gameID = %d", actGame!.ID).count > 0 {
                    let replayAction = UIAlertAction(title: GV.language.getText(.tcReplay), style: .default,
                                                       handler: {(paramAction:UIAlertAction!) in
                                                        self.replay()
                    })
                    alert.addAction(replayAction)
                }
            #endif


            if GV.peerToPeerService!.hasOtherPlayers() {
                let competitionAction = UIAlertAction(title: GV.language.getText(.tcCompetition), style: .default,
                                                      handler: {(paramAction:UIAlertAction!) in
                                                        self.choosePartner()
                                                        //self.gameArrayChanged = true
                                                        
                })
                alert.addAction(competitionAction)
                
            }
            
            

        }
        let cancelAction = UIAlertAction(title: GV.language.getText(TextConstants.tcCancel), style: .default,
            handler: {(paramAction:UIAlertAction!) in
        })
        alert.addAction(cancelAction)
        return alert
    }
    
    func stopCompetition() {
        GV.peerToPeerService!.sendInfo(.stopCompetition, message: [])
        opponent.finish = .interrupted
        checkMultiplayer()
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
            if containers[index].minValue != FirstCardValue || containers[index].maxValue % MaxCardValue != LastCardValue {
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
                    cardValue: cardArray[containerIndex][cardIndex % MaxCardValue].cardValue) //generateValue(containerIndex) - 1)
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
            
            containers[index].colorIndex = NoValue
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



    func pull(_ createTipps: Bool) {
        //printFunc(function: "pull", start: true)
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
                        cardStack.push(cardToPush)
                        
                        gameArray[savedCardInCycle.column][savedCardInCycle.row].used = false
                        cardManager!.removeCard(card: cardToPush)
                        makeEmptyCard(savedCardInCycle.column, row: savedCardInCycle.row)
                        let aktPosition = gameArray[savedCardInCycle.column][savedCardInCycle.row].position
                        let duration = Double((cardPackage!.position - aktPosition).length()) / 500.0
                        let actionMove = SKAction.move(to: cardPackage!.position, duration: duration)
                        let removeOldCard = SKAction.run({
                            self.childNode(withName: searchName)!.removeFromParent()
                        })
                        cardToPush.run(SKAction.sequence([actionMove, removeOldCard]))
                    }
                case .addedFromShowCard:
                    if cardPlaceButtonAddedToParent {
                        cardPlaceButton?.removeFromParent()
                        cardPlaceButtonAddedToParent = false
                    }
                    let oldShowCardExists = showCard != nil
                    var removeOldShowCard = SKAction()
                    if oldShowCardExists {
                        var oldShowCard = showCard
//                        showCardStack.push(showCard!)
                        removeOldShowCard = SKAction.run({
                            oldShowCard!.removeFromParent()
                            oldShowCard = nil
                        })
                    }
                    let cardName = savedCardInCycle.name
                    let searchName = "\(cardName)"
                    showCard = self.childNode(withName: searchName)! as? MySKCard
                    showCard!.position = savedCardInCycle.endPosition //(cardPlaceButton?.position)!
                    showCard!.size = (cardPlaceButton?.size)!
                    showCard!.type = .showCardType
                    self.childNode(withName: searchName)!.removeFromParent()
                    self.addChild(showCard!)
                    gameArray[savedCardInCycle.column][savedCardInCycle.row].used = false
                    makeEmptyCard(savedCardInCycle.column, row: savedCardInCycle.row)
                    let actionMove = SKAction.move(to: cardPlaceButton!.position, duration: 0.5)
                    if oldShowCardExists {
                        showCard!.run(SKAction.sequence([actionMove, removeOldShowCard]))
                    } else {
                        showCard!.run(actionMove)
                    }
                case .removed:
                    //let cardTexture = SKTexture(imageNamed: "card\(savedCardInCycle.colorIndex)")
                    let card = MySKCard(colorIndex: savedCardInCycle.colorIndex, type: savedCardInCycle.type, value: savedCardInCycle.minValue)
                    
                    
                    card.colorIndex = savedCardInCycle.colorIndex
                    card.position = savedCardInCycle.endPosition
                    card.startPosition = savedCardInCycle.startPosition
                    card.size = savedCardInCycle.size
                    card.column = savedCardInCycle.column
                    card.row = savedCardInCycle.row
                    card.minValue = savedCardInCycle.minValue
                    card.maxValue = savedCardInCycle.maxValue
                    card.belongsToPackageMin = savedCardInCycle.belongsToPackageMin
                    card.belongsToPackageMax = savedCardInCycle.belongsToPackageMax
                    card.BGPictureAdded = savedCardInCycle.BGPictureAdded
                    card.countTransitions = savedCardInCycle.countTransitions
                    card.name = savedCardInCycle.name
                    levelScore = savedCardInCycle.countScore
                    cardManager!.addCard(card: card)
 
                    updateGameArrayCell(card)
                    self.addChild(card)
                    print("in pulled: removed--> card with name: \(card.name) added")
                    updateCardCount(1)
                    deleteLastHistoryRecord()
                    card.reload()
                    
                case .unification:
                    let card = self.childNode(withName: savedCardInCycle.name)! as! MySKCard
                    card.size = savedCardInCycle.size
                    card.minValue = savedCardInCycle.minValue
                    card.maxValue = savedCardInCycle.maxValue
                    card.belongsToPackageMin = savedCardInCycle.belongsToPackageMin
                    card.belongsToPackageMax = savedCardInCycle.belongsToPackageMax
                    card.BGPictureAdded = savedCardInCycle.BGPictureAdded
                    card.countTransitions = savedCardInCycle.countTransitions
                    updateGameArrayCell(card)
                    //card.hitLabel.text = "\(card.hitCounter)"
                    card.reload()
                    
//                case .hitcounterChanged:
//                    
//                    let container = containers[findIndex(savedCardInCycle.colorIndex)]
//                    container.minValue = savedCardInCycle.minValue
//                    container.maxValue = savedCardInCycle.maxValue
//                    container.belongsToPackage = savedCardInCycle.belongsToPackage
//                    container.BGPictureAdded = savedCardInCycle.BGPictureAdded
//                    container.reload()
//                    showScore()
                    
                case .firstCardAdded:
                    let container = containers[findIndex(savedCardInCycle.colorIndex)]
                    container.minValue = savedCardInCycle.minValue
                    container.maxValue = savedCardInCycle.maxValue
                    container.belongsToPackageMin = savedCardInCycle.belongsToPackageMin
                    container.belongsToPackageMax = savedCardInCycle.belongsToPackageMax
                    container.BGPictureAdded = savedCardInCycle.BGPictureAdded
                    container.countTransitions = savedCardInCycle.countTransitions
                    container.colorIndex = NoColor
                    container.reload()
                    
                    
                case .movingStarted:
                    let card = self.childNode(withName: savedCardInCycle.name)! as! MySKCard
                    card.startPosition = savedCardInCycle.startPosition
                    card.minValue = savedCardInCycle.minValue
                    card.maxValue = savedCardInCycle.maxValue
                    card.belongsToPackageMin = savedCardInCycle.belongsToPackageMin
                    card.belongsToPackageMax = savedCardInCycle.belongsToPackageMax

                    updateGameArrayCell(card)
                    card.BGPictureAdded = savedCardInCycle.BGPictureAdded
                    card.countTransitions = savedCardInCycle.countTransitions
                    actionMoveArray.append(SKAction.move(to: savedCardInCycle.endPosition, duration: duration))
                    actionMoveArray.append(SKAction.run({
                            self.removeNodesWithName("\(self.emptyCardTxt)-\(card.column)-\(card.row)")
                        })
                    )
                    card.run(SKAction.sequence(actionMoveArray))
                    card.reload()
                    
                case .fallingMovingCard:
//                    let card = self.childNodeWithName(savedCardInCycle.name)! as! MySKCard
                    actionMoveArray.append(SKAction.move(to: savedCardInCycle.endPosition, duration: duration))
                    
                case .fallingCard:
                    let card = self.childNode(withName: savedCardInCycle.name)! as! MySKCard
                    card.startPosition = savedCardInCycle.startPosition
                    let moveFallingCard = SKAction.move(to: savedCardInCycle.startPosition, duration: duration)
                    card.run(SKAction.sequence([moveFallingCard]))
                    
                case .mirrored:
                    //var card = self.childNodeWithName(savedCardInCycle.name)! as! MySKCard
                    actionMoveArray.append(SKAction.move(to: savedCardInCycle.endPosition, duration: duration))
                case .stopCycle: break
                case .nothing: break
                }
                if let savedCard:SavedCard = stack.pull() {
                    savedCardInCycle = savedCard
                    if ((savedCardInCycle.status == .addedFromCardStack || savedCardInCycle.status == .addedFromShowCard) && stack.countChangesInStack() == 0) || stopSoon  || savedCardInCycle.status == .stopCycle {
                        stack.push(savedCardInCycle)
                        run = false
                    }
                    if savedCardInCycle.status == .movingStarted {
                        stopSoon = true
                    }
                } else {
                    run = false
                }
            } while run
            showScore()
        }
        
        if createTipps {
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
    
    func myTouchesBegan(touchLocation: CGPoint) {
        oldFromToColumnRow = FromToColumnRow()
        lastPair.color = .none
        lineWidthMultiplier = lineWidthMultiplierNormal
        touchesBeganAt = Date()
        movedFromNode = nil
        let nodes = self.nodes(at: touchLocation)
        for nodesIndex in 0..<nodes.count {
            switch nodes[nodesIndex]  {
                case is MySKButton:
                    movedFromNode = (nodes[nodesIndex] as! MySKButton) as MySKCard
                    break
                case is MySKCard:
                    if (nodes[nodesIndex] as! MySKCard).type == .cardType ||
                       (nodes[nodesIndex] as! MySKCard).type == .showCardType ||
                       (nodes[nodesIndex] as! MySKCard).type == .emptyCardType
                    {
                        movedFromNode = (nodes[nodesIndex] as! MySKCard)
                        if movedFromNode.type == .cardType {
                            self.addChild(showValue(movedFromNode))
                        }
                        if showFingerNode {
                            let fingerNode = SKSpriteNode(imageNamed: "finger.png")
                            fingerNode.name = fingerName
                            fingerNode.position = touchLocation
                            fingerNode.size = CGSize(width: 25,height: 25)
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
        
        if tremblingCards.count > 0 {
            stopTrembling()
            removeNodesWithName(myLineName)
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

        if movedFromNode != nil {
            removeNodesWithName(myLineName)

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
            if movedFromNode.type == .showCardType {
                movedFromNode.position = touchLocation
//                if showCardStack.count(.MySKCardType) > 0 {
//                    if !showCardFromStackAddedToParent {
//                        showCardFromStackAddedToParent = true
//                        showCardFromStack = showCardStack.last()
//                        showCardFromStack!.position = cardPlaceButton!.position
//                        showCardFromStack!.size = cardPlaceButton!.size
//                        addChild(showCardFromStack!)
//                    }
//                } else if !cardPlaceButtonAddedToParent {
//                    cardPlaceButtonAddedToParent = true
//                    addChild(cardPlaceButton!)
//                }
            }  else if movedFromNode == aktNode && tremblingCards.count > 0 { // stop trembling
                lastPair.color = .none
                stopTrembling()
                lastNextPoint = nil
            } else if movedFromNode != aktNode {
                if movedFromNode.type == .buttonType {
                    //movedFromNode.texture = atlas.textureNamed("\(movedFromNode.name!)")
                } else if movedFromNode.type == .emptyCardType {
                    
                } else {
                    var movedFrom = ColumnRow()
                    movedFrom.column = movedFromNode.column
                    movedFrom.row = movedFromNode.row
                    
                    let (foundedPoint, myPoints) = createHelpLines(movedFrom, toPoint: touchLocation, inFrame: self.frame, lineSize: movedFromNode.size.width, showLines: true)
                    var actFromToColumnRow = FromToColumnRow()
                    actFromToColumnRow.fromColumnRow = movedFrom
                    actFromToColumnRow.toColumnRow.column = foundedPoint!.column
                    actFromToColumnRow.toColumnRow.row = foundedPoint!.row
                    let color = calculateLineColor(foundedPoint!, movedFrom: movedFrom)
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
                        drawHelpLinesSpec()
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
    

    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let firstTouch = touches.first
        let touchLocation = firstTouch!.location(in: self)
        myTouchesEnded(touchLocation: touchLocation)
    }
    
    func myTouchesEnded(touchLocation: CGPoint) {
        
        stopTrembling()
        removeNodesWithName(myLineName)
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
            
            if showFingerNode {
                if let node = self.childNode(withName: fingerName) {
                  node.removeFromParent()
                }
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
                    case "settings": settingsButtonPressed()
                    case "undo": undoButtonPressed()
                    case "restart": restartButtonPressed()
                    case "help": helpButtonPressed()
                    default: specialButtonPressed(MySKCard.name!)
                }
                return
            }
            
            if startNode!.type == .cardType && (aktNode == nil || aktNode! != movedFromNode) {
                let card = movedFromNode// as! SKSpriteNode
                let movedFrom = ColumnRow(column: movedFromNode.column, row: movedFromNode.row)
                var (foundedPoint, myPoints) = createHelpLines(movedFrom, toPoint: touchLocation, inFrame: self.frame, lineSize: movedFromNode.size.width, showLines: false)
                var actFromToColumnRow = FromToColumnRow()
                actFromToColumnRow.fromColumnRow = movedFrom
                actFromToColumnRow.toColumnRow.column = foundedPoint!.column
                actFromToColumnRow.toColumnRow.row = foundedPoint!.row
                
                var color = calculateLineColor(foundedPoint!, movedFrom: movedFrom)
                
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
                                self.addChild(self.showCountScore("+\(self.movedFromNode.countScore)", position: (card?.position)!))
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
                        self.cardDidCollideWithContainer(self.movedFromNode, node2: containerNode, points: myPoints)
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
                })
                actionArray.append(collisionAction)
                actionArray.append(userInteractionEnablingAction)
                
                tippsButton!.activateButton(false)
                
                
                
                
                //let actionMoveDone = SKAction.removeFromParent()
                collisionActive = true
                lastMirrored = ""
                
                self.isUserInteractionEnabled = false  // userInteraction forbidden!
                countMovingCards = 1
                self.waitForSKActionEnded = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CardGameScene.checkCountMovingCards), userInfo: nil, repeats: false) // start timer for check
                
                movedFromNode.run(SKAction.sequence(actionArray))
                
            } else if startNode!.type == .cardType && aktNode == movedFromNode {
                startTippTimer()
            } else if startNode?.type == .showCardType {
                var foundedCard: MySKCard?
                let nodes = self.nodes(at: touchLocation)
                var founded = false
                for index in 0..<nodes.count {
                    foundedCard = nodes[index] as? MySKCard
                   if nodes[index] is MySKCard && foundedCard!.type == .emptyCardType {
                        startNode?.column = foundedCard!.column
                        startNode?.row = foundedCard!.row
                        push(startNode!, status: .stopCycle)
                        push(startNode!, status: .addedFromShowCard)
                        startNode?.size = foundedCard!.size
                        startNode?.position = foundedCard!.position
                        startNode?.type = .cardType
                        foundedCard!.removeFromParent()
                        founded = true
                        updateGameArrayCell(startNode!)
//                        pullShowCard()
                        gameArrayChanged = true

                        break
                    } else if nodes[index] is MySKCard && foundedCard!.type == .cardType && startNode?.colorIndex == foundedCard!.colorIndex &&
                        (foundedCard!.maxValue + 1 == startNode?.minValue ||
                         foundedCard!.minValue - 1 == startNode?.maxValue) {
                            push(startNode!, status: .stopCycle)
                            push(foundedCard!, status: .unification)
                            push(startNode!, status: .addedFromShowCard)
                            
                            if foundedCard!.maxValue < (startNode?.minValue)! {
                                foundedCard!.maxValue = (startNode?.maxValue)!
                            } else {
                                foundedCard!.minValue = (startNode?.minValue)!
                            }
                            foundedCard!.reload()
                            push(startNode!, status: .removed)
                            gameArray[(startNode?.column)!][(startNode?.row)!].card.minValue = foundedCard!.minValue
                            gameArray[(startNode?.column)!][(startNode?.row)!].card.maxValue = foundedCard!.maxValue
                            startNode?.removeFromParent()
//                            pullShowCard()
                            founded = true
                            gameArrayChanged = true

                            break
                   }
                }
                if !founded {
                    let actionMove = SKAction.move(to: cardPlaceButton!.position, duration: 0.5)
                    let actionDropShowCardFromStack = SKAction.run({
                        self.removeShowCardFromStack()
                        startNode?.zPosition = 0
                    })
                    startNode?.zPosition = 50
                    startNode?.run(SKAction.sequence([actionMove, actionDropShowCardFromStack]))
                }
            } else {
                startTippTimer()
            }
            
        } else {
            startTippTimer()
        }
        
    }
    
    func ActionsForMirroring(_ card: MySKCard, adder: Int, color: MyColors, fromPoint: CGPoint, toPoint: CGPoint)->[SKAction] {
        var actions = [SKAction]()
        if color == .green {
            actions.append(SKAction.run({
                self.addChild(self.showCountScore("+\(adder)", position: card.position))
                self.push(card, status: .mirrored)
            }))
        }
        
//        actionArray.append(countAndPushAction)
        actions.append(SKAction.move(to: toPoint, duration: Double((toPoint - fromPoint).length() * speed)))

        return actions
    }
    
    func stopTrembling() {
        for index in 0..<tremblingCards.count {
            tremblingCards[index].tremblingType = .noTrembling
        }
        tremblingCards.removeAll()
    }
//    func pullShowCard() {
//        showCard = nil
//        if showCardStack.count(.MySKCardType) > 0 {
//            removeShowCardFromStack()
//            showCard = showCardStack.pull()
//            self.addChild(showCard!)
//        } else if !cardPlaceButtonAddedToParent {
//            addChild(cardPlaceButton!)
//            cardPlaceButtonAddedToParent = true
//        }
//    }
    
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
        //levelArray = GV.cloudData.readLevelDataArray()
        let url = URL(
            fileURLWithPath: Bundle.main.path(forResource: fileName, ofType: "m4a")!)
        //backgroundColor = SKColor(patternImage: UIImage(named: "aquarium.png")!)
        
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
    
    func playSound(_ fileName: String, volume: Float) {
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
    
    func playSound(_ fileName: String, volume: Float, soundPlayerIndex: Int) {
        
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
    
    
    func calculateColumnRowFromPosition(_ position: CGPoint)->ColumnRow {
        var columnRow  = ColumnRow()
        let offsetToFirstPosition = position - gameArray[0][0].position
        let tableCellSize = gameArray[1][1].position - gameArray[0][0].position
        
        
        columnRow.column = Int(round(Double(offsetToFirstPosition.x / tableCellSize.x)))
        columnRow.row = Int(round(Double(offsetToFirstPosition.y / tableCellSize.y)))
        return columnRow
    }
    
    func makeLineAroundGameboard(_ linePosition: LinePosition) {
        var myWallP1: CGPoint
        var myWallP2: CGPoint
        
        let lineSize: CGFloat = size.width / 100
        switch linePosition {
        case .bottomHorizontal:
            myWallP1 = CGPoint(x: position.x, y: position.y)
            myWallP2 = CGPoint(x: size.width, y: myWallP1.y)
        case .rightVertical:
            myWallP1 = CGPoint(x: position.x + size.width, y: position.y)
            myWallP2 = CGPoint(x: myWallP1.x, y: size.height)
        case .upperHorizontal:
            myWallP1 = CGPoint(x: position.x, y: position.y + size.height)
            myWallP2 = CGPoint(x: size.width, y: myWallP1.y)
        case .leftVertical:
            myWallP1 = CGPoint(x: position.x, y: position.y)
            myWallP2 = CGPoint(x: myWallP1.x, y: size.height)
         }
        
        let pathToDraw:CGMutablePath = CGMutablePath()
        
        let myWallLine:SKShapeNode = SKShapeNode()
        myWallLine.lineWidth = lineSize
        myWallLine.name = linePosition.linePositionName
        pathToDraw.move(to: myWallP1)
        pathToDraw.addLine(to: myWallP2)
        
        myWallLine.path = pathToDraw
        
        myWallLine.strokeColor = UIColor.green
        
        self.addChild(myWallLine)
    }
    
    func checkGameArray() -> Int {
        var usedCellCount = 0
        for column in 0..<countColumns {
            for row in 0..<countRows {
                if gameArray[column][row].used {
                    usedCellCount += 1
                }
            }
        }
        return usedCellCount
    }
    
    
    func push(_ card: MySKCard, status: CardStatus) {
        var savedCard = SavedCard()
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
        savedCard.belongsToPackageMin = card.belongsToPackageMin
        savedCard.belongsToPackageMax = card.belongsToPackageMax
        savedCard.countTransitions = card.countTransitions
        savedCard.column = card.column
        savedCard.row = card.row
        stack.push(savedCard)
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
            case .cardType, .emptyCardType, .showCardType: return MyNodeTypes.CardNode
            case .buttonType:
                if MySKCard.name == buttonName {
                    MySKCard = MySKCard.parent as! MySKCard
                }
                return MyNodeTypes.ButtonNode
            }
        default: return MyNodeTypes.none
        }
    }
    
    func helpButtonPressed() {
        doTimeCount = false
        let url = GV.language.getText(.tcHelpURL)
        if let url = URL(string: url) {
            UIApplication.shared.openURL(url)
        }
        doTimeCount = true
    }
    
    func settingsButtonPressed() {
        playMusic("NoSound", volume: GV.player!.musicVolume, loops: 0)
        doTimeCount = false
//        countUpAdder = 0
        inSettings = true
        panel = MySKPanel(view: view!, frame: CGRect(x: self.frame.midX, y: self.frame.midY, width: self.frame.width * 0.5, height: self.frame.height * 0.5), type: .settings, parent: self, callBack: comeBackFromSettings)
        panel = nil
    }
    

    func comeBackFromSettings(_ restart: Bool, gameNumberChoosed: Bool, gameNumber: Int, levelIndex: Int) {
        inSettings = false
        
        if restart {
            if gameNumberChoosed {
                self.gameNumber = gameNumber
                try! realm.write({ 
                    GV.player!.levelID = levelIndex
                })
                prepareNextGame(false) // start with choosed gamenumber
            } else {
                prepareNextGame(true)  // start a random game
            }
            generateCards(.first)
        } else {
            playMusic("MyMusic", volume: GV.player!.musicVolume, loops: playMusicForever)
            let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
            playerNameLabel.text = name
            doTimeCount = true
        }
    }
    
    func undoButtonPressed() {
        //printFunc(function: "undoButtonPressed", start: true)

        pull(true)
//        freeUndoCounter -= 1
//        let modifyer = freeUndoCounter > 0 ? 0 : freeUndoCounter > -freeAmount ? penalty : 2 * penalty
//        scoreModifyer -= modifyer
//        levelScore -= modifyer
//        if modifyer > 0 {
//            self.addChild(showCountScore("-\(modifyer)", position: undoButton!.position))
//        }
        //printFunc(function: "undoButtonPressed", start: false)
    }

    
//    func startDoCountUpTimer() {
//        startTimer(&countUp, sleepTime: doCountUpSleepTime, selector: doCountUpSelector, repeats: true)
//        countUpAdder = 1
//    }
    
    func stopTimer( _ timer: inout Timer?) {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    


    func startTimer( _ timer: inout Timer?, sleepTime: Double, selector: String, repeats: Bool)->Timer {
        stopTimer(&timer)
        let myTimer = Timer.scheduledTimer(timeInterval: sleepTime, target: self, selector: Selector(selector), userInfo: nil, repeats: repeats)
        
        return myTimer
    }
    
    func showTime() {
        
        if doTimeCount {
            timeCount += 1 // countUpAdder
            playerTimeLabel.text = timeCount.dayHourMinSec
            if playerType == .multiPlayer {
                opponentTimeLabel.text = timeCount.dayHourMinSec
            }
        }
    }
    
    func checkCountMovingCards() {
        if  countMovingCards > 0 && countCheckCounts < 100 {
            countCheckCounts += 1
            self.waitForSKActionEnded = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CardGameScene.checkCountMovingCards), userInfo: nil, repeats: false)
        } else {
            countCheckCounts = 0
            self.isUserInteractionEnabled = true
        }
    }

    func removeNodesWithName(_ name: String) {
        while self.childNode(withName: name) != nil {
            self.childNode(withName: name)!.removeFromParent()
        }
    }
    
    func connectedDevicesChanged(_ manager : PeerToPeerServiceManager, connectedDevices: [String]) {
        
    }
    func messageReceived(_ fromPeerIndex : Int, command: PeerToPeerCommands, message: [String], messageNr:Int) {
        switch command {
        case .myNameIs: break
        case .iWantToPlayWithYou:
            if inSettings {
                GV.peerToPeerService!.sendAnswer(messageNr, answer: [GV.IAmBusy])
            } else if Int(message[1])! > maxLevelIndex { // want the opponent play a higher level ?
                GV.peerToPeerService!.sendAnswer(messageNr, answer: [answerLevelNotOK])
            } else {
                alertStartMultiPlay(fromPeerIndex, message: message, messageNr: messageNr)
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
//        let bonus = levelScore / 10
//        let myScore = levelScore + bonus
//        let IWon = myScore > opponent.score
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
        GV.mainViewController!.showAlert(alert, delay: 20)
        
    }
    

    func alertStartMultiPlay(_ fromPeerIndex: Int, message: [String], messageNr: Int) {
        let alert = UIAlertController(title: GV.language.getText(.tcWantToPlayWithYou, values: message[0]),
                                      message: "",
                                      preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: GV.language.getText(.tcok), style: .default,
                                     handler: {(paramAction:UIAlertAction!) in
                                        DispatchQueue.main.async {
                                            self.playerType = .multiPlayer
                                            self.opponent.name = message[0]
                                            self.opponent.peerIndex = fromPeerIndex
                                            self.opponent.score = 0
                                            try! realm.write({ 
                                                GV.player!.levelID = Int(message[1])!
                                            })
                                            self.levelIndex = Int(message[1])!
                                            self.gameNumber = Int(message[2])!
                                            self.restartGame = true
                                            GV.peerToPeerService!.sendAnswer(messageNr, answer: [self.answerYes])
                                        }
        })
        alert.addAction(OKAction)
        
        let cancelAction = UIAlertAction(title: GV.language.getText(.tcCancel), style: .default,
                                         handler: {(paramAction:UIAlertAction!) in
                                            GV.peerToPeerService!.sendAnswer(messageNr, answer: [self.answerNo])
        })
        alert.addAction(cancelAction)
        DispatchQueue.main.async(execute: {
            GV.mainViewController!.showAlert(alert, delay: 20)
        })
        
    }
    

    func sendAlertToUser(_ fromPeerIndex: Int) {
        
    }
    
    func generateGamesForTest(countRecordsProLevel: Int) {
        let playerID = GV.player!.ID
        realm.beginWrite()
        realm.delete(realm.objects(StatisticModel.self)) // delete the one generated statisticrecord
        
        for level in 0..<GV.levelsForPlay.count() { // create min 5 and max 35 games
            for _ in 0..<(5 + Int(arc4random_uniform(30))) {
                let game = GameModel()
                game.gameNumber = Int(arc4random_uniform(999)) // get random gamenumber 0...999
                game.levelID = level
                game.ID = GV.createNewRecordID(.gameModel)
                game.played = true
                game.playerID = playerID
                game.playerScore = 2000 + Int(arc4random_uniform(3000)) // get random score 2000...5000
                game.time = 300 + Int(arc4random_uniform(1200)) // get random time 300...1500 sec (5...25 min)
                realm.add(game)
            }
            let statistic = StatisticModel()
            statistic.ID = GV.createNewRecordID(.statisticModel)
            statistic.bestTime = 1000000
            statistic.playerID = playerID
            let games = realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = true", playerID, level)
            statistic.countPlays = games.count
            for game in games {
                statistic.actScore += game.playerScore
                statistic.actTime += game.time
                statistic.levelID = level
                if game.playerScore > statistic.bestScore {
                    statistic.bestScore = game.playerScore
                }
                if game.time < statistic.bestTime {
                    statistic.bestTime = game.time
                }
            }
            realm.add(statistic)
        }
        try! realm.commitWrite()
    }


}
