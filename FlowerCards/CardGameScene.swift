
//  CardGameScene.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 2015. 11. 26..
//  Copyright © 2015. Jozsef Romhanyi. All rights reserved.
//

import SpriteKit
import AVFoundation
import MultipeerConnectivity

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
    struct GameArrayPositions {
        var used: Bool
        var position: CGPoint
        var colorIndex: Int
        var name: String
        var minValue: Int
        var maxValue: Int
        init() {
            self.used = false
            self.position = CGPoint(x: 0, y: 0)
            self.colorIndex = NoColor
            self.name = ""
            self.minValue = NoValue
            self.maxValue = NoValue
        }
    }
    
    struct ColorTabLine {
        var colorIndex: Int
        var spriteName: String
        var spriteValue: Int
        init(colorIndex: Int, spriteName: String){
            self.colorIndex = colorIndex
            self.spriteName = spriteName
            self.spriteValue = 0
        }
        init(colorIndex: Int, spriteName: String, spriteValue: Int){
            self.colorIndex = colorIndex
            self.spriteName = spriteName
            self.spriteValue = spriteValue
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
    

    enum MyColors: Int {
        case none = 0, red, green
    }
    
    enum PlayerType: Int {
        case singlePlayer = 0, multiPlayer, bestPlayer
    }
    
    enum SpriteGeneratingType: Int {
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
    
    struct Tipps {
        var removed: Bool
        var fromColumn: Int
        var fromRow: Int
        var toColumn: Int
        var toRow: Int
        var twoArrows: Bool
        var points:[CGPoint]
        var lineLength: CGFloat
        
        init() {
            removed = false
            fromColumn = 0
            fromRow = 0
            toColumn = 0
            toRow = 0
            points = [CGPoint]()
            twoArrows = false
            lineLength = 0
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
    
    let answerYes = "YES"
    let answerNo = "NO"
    
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
    
    
    let emptySpriteTxt = "emptySprite"
    
    var cardStack:Stack<MySKNode> = Stack()
    var showCardStack:Stack<MySKNode> = Stack()
    var tippCountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    var cardPackage: MySKButton?
    var cardPlaceButton: MySKButton?
    var tippsButton: MySKButton?
    
    var cardPlaceButtonAddedToParent = false
    var cardToChange: MySKNode?
    
    var showCard: MySKNode?
    var showCardFromStack: MySKNode?
    var showCardFromStackAddedToParent = false
    var backGroundOperation = Operation()


    var lastCollisionsTime = Date()
    var cardArray: [[GenerateCard]] = []
//    var valueTab = [Int]()
    var countPackages = 0
    let nextLevel = true
    let previousLevel = false
    var lastUpdateSec = 0
    var lastNextPoint: Founded?
    var generatingTipps = false
    var tippArray = [Tipps]()
    var tippIndex = 0
//    var showTippAtTimer: NSTimer?
    var dummy = 0
    
    var labelFontSize = CGFloat(0)
    var labelYPosProcent = CGFloat(0)
    var labelHeight = CGFloat(0)
    var labelBGSize = CGVector(dx: 0,dy: 0)
    var labelBGPos = CGVector(dx: 0,dy: 0)
    var screwMultiplier = CGVector(dx: 0, dy: 0)
    
    var tremblingSprites: [MySKNode] = []
    var random: MyRandom?
    // Values from json File
    var params = ""
    var countCardsProContainer: Int?
    var countColumns = 0
    var countRows = 0
    var countContainers = 0
    var targetScoreKorr: Int = 0
    var tableCellSize: CGFloat = 0
    var sizeMultiplier: CGSize = CGSize(width: 1, height: 1)
    var buttonSizeMultiplier: CGSize = CGSize(width: 1, height: 1)
    var containerSize:CGSize = CGSize(width: 0, height: 0)
    var spriteSize:CGSize = CGSize(width: 0, height: 0)
    var minUsedCells = 0
    var maxUsedCells = 0
    var gameNumber = 0
    
    var scoreModifyer = 0
    var showTippCounter = 0
//    var mirroredScore = 0
    
    var touchesBeganAt: Date?
    
    let containerSizeOrig: CGFloat = 40
    let spriteSizeOrig: CGFloat = 35
    
    var showFingerNode = false
    var countMovingSprites = 0
    var countCheckCounts = 0
    var freeUndoCounter = 0
    var freeTippCounter = 0
    var showValueDelta: CGFloat = 0
    
    
    
    //let timeLimitKorr = 5 // sec for pro Sprite
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
    var stack:Stack<SavedSprite> = Stack()
    //var gameArray = [[Bool]]() // true if Cell used
    var gameArray = [[GameArrayPositions]]()
    var containers = [MySKNode]()
    var colorTab = [ColorTabLine]()
    var containersPosCorr = CGPoint.zero
    var countColorsProContainer = [Int]()
    var labelBackground = SKSpriteNode()
    
    var levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    var gameNumberLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
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
    var movedFromNode: MySKNode!
    var settingsButton: MySKButton?
    var undoButton: MySKButton?
    var helpButton: MySKButton?
    var restartButton: MySKButton?
    var exchangeButton: MySKButton?
    var nextLevelButton: MySKButton?
    var targetScore = 0
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
    //let showHelpLines = 4
    let maxHelpLinesCount = 4
    //    var undoCount = 0
    var inFirstGenerateSprites = false
    var lastShownNode: MySKNode?
//    var parentViewController: UIViewController?
    var settingsSceneStarted = false
    var settingsDelegate: SettingsDelegate?
    //var settingsNode = SettingsNode()
    var gameDifficulty: Int = 0
    var spriteTabRect = CGRect.zero
    
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
    
    var spriteGameLastPosition = CGPoint.zero
    
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
                    let startWaiting = Date()
                    while generatingTipps && stopCreateTippsInBackground {
                        
                         _ = 0
                    }
                    print ("waiting for Stop Creating Tipps:", Date().timeIntervalSince(startWaiting).nDecimals(5))
                    stopCreateTippsInBackground = false

                }
            }
        }
    }
        
    var gameArrayChanged = false {
        didSet {
//            print("in gameArrayChanged: bevor stopCreateTippsInBackground var generatingTipps = ", generatingTipps)
            stopCreateTippsInBackground = true
//            print("in gameArrayChanged: after stopCreateTippsInBackground var generatingTipps = ", generatingTipps)
            startCreateTippsInBackground()

//            switch (oldValue, gameArrayChanged, generatingTipps) {
//                case (false, true, false):
//                    startCreateTippsInBackground()
//                case (true, true, true):
//                    stopCreateTippsInBackground = true
//                    startCreateTippsInBackground()
//                case (true, true, false):
//                    startCreateTippsInBackground()
//
//                default: break
//            }
        }
    }
    
    var tapLocation: CGPoint?
    let qualityOfServiceClass = DispatchQoS.QoSClass.background
    let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
    let playMusicForever = -1
    
    override func didMove(to view: SKView) {
        
        if !settingsSceneStarted {
//            let modelURL = NSBundle.mainBundle().URLForResource("FlowerCards", withExtension: "momd")!

            myView = view
            
            GV.peerToPeerService!.delegate = self
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            print(documentsPath)
            
            spriteTabRect.origin = CGPoint(x: self.frame.midX, y: self.frame.midY * 0.80)
            spriteTabRect.size = CGSize(width: self.frame.size.width * 0.80, height: self.frame.size.height * 0.80)
            
            let width:CGFloat = 64.0
            let height: CGFloat = 89.0
            sizeMultiplier = CGSize(width: GV.deviceConstants.sizeMultiplier, height: GV.deviceConstants.sizeMultiplier * height / width)
            buttonSizeMultiplier = CGSize(width: GV.deviceConstants.buttonSizeMultiplier, height: GV.deviceConstants.buttonSizeMultiplier * height / width)
            levelIndex = GV.player!.levelID
            GV.levelsForPlay.setAktLevel(levelIndex)
            
            buttonSize = (myView.frame.width / 15) * buttonSizeMultiplier.width
            buttonYPos = myView.frame.height * 0.07
            buttonXPosNormalized = myView.frame.width / 10
            self.name = "CardGameScene"
            
            prepareNextGame(true)
//            restartButtonPressed()
            generateSprites(.first)
        } else {
            playMusic("MyMusic", volume: GV.player!.musicVolume, loops: playMusicForever)
            
        }
    }
    
    func prepareNextGame(_ newGame: Bool) {
        
        setMyDeviceConstants()
        levelIndex = GV.player!.levelID
        GV.levelsForPlay.setAktLevel(levelIndex)
        specialPrepareFuncFirst()
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
        if newGame {
            gameNumber = -1
            let allGames = realm.objects(GameModel.self).filter("levelID = %d and played = true", levelIndex) //search all games on this level
            for game in allGames {
                if realm.objects(GameModel.self).filter("gameNumber = %d and levelID = %d and playerID = %d and played = true", game.gameNumber, levelIndex, GV.player!.ID).count == 0 {
                    gameNumber = game.gameNumber  // founded a game not played by actPlayer
                    createGameRecord(gameNumber)
                    break
                }
            }
            
            if gameNumber == -1 {
                gameNumber = randomGameNumber()
                if gameNumber == realm.objects(GamePredefinitionModel.self).count {  // all Plays played
                    // search plays with score = 0
                }
                createGameRecord(gameNumber)
            }
        } else {
            createGameRecord(gameNumber)
        }
        
        random = MyRandom(gameNumber: gameNumber)
        
        stopTimer(&countUp)
        
        gameArray.removeAll(keepingCapacity: false)
        containers.removeAll(keepingCapacity: false)
        //undoCount = 3
        
        // fill gameArray
        for _ in 0..<countColumns {
            gameArray.append(Array(repeating: GameArrayPositions(), count: countRows))
        }
        
        // calvulate Sprite Positions
        
        for column in 0..<countColumns {
            for row in 0..<countRows {
                gameArray[column][row].position = calculateSpritePosition(column, row: row)
            }
        }
        
        for column in 0..<countColumns {
            for row in 0..<countRows {
                let columnRow = calculateColumnRowFromPosition(gameArray[column][row].position)
                if column != columnRow.column || row != columnRow.row {
//                    print("column:", column, "row:",row, "calculated:", columnRow, column != columnRow.column || row != columnRow.row ? "Error" : "")
                    dummy = 0
                }
            }
        }


        
        
        prepareContainers()
        
        labelBackground.color = UIColor.white
        labelBackground.alpha = 0.7
        labelBackground.position = CGPoint(x: self.size.width * labelBGPos.dx, y: self.size.height * labelBGPos.dy)
        labelBackground.size = CGSize(width: self.size.width * labelBGSize.dx, height: self.size.height * labelBGSize.dy)
        
        let screw1 = SKSpriteNode(imageNamed: "screw.png")
        let screw2 = SKSpriteNode(imageNamed: "screw.png")
        let screw3 = SKSpriteNode(imageNamed: "screw.png")
        let screw4 = SKSpriteNode(imageNamed: "screw.png")
        let screwWidth = self.size.width * 0.025
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
        
        let cardSize = CGSize(width: buttonSize * sizeMultiplier.width * 0.8, height: buttonSize * sizeMultiplier.height * 0.8)
        let cardPackageButtonTexture = SKTexture(image: images.getCardPackage())
        cardPackage = MySKButton(texture: cardPackageButtonTexture, frame: CGRect(x: buttonXPosNormalized * 4.0, y: buttonYPos, width: cardSize.width, height: cardSize.height), makePicture: false)
        cardPackage!.name = "cardPackege"
        addChild(cardPackage!)
        
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
        //        self.inFirstGenerateSprites = false
        cardCount = Int(CGFloat(countContainers * countCardsProContainer!))
        let cardCountText: String = String(cardStack.count(.mySKNodeType))
        let tippCountText: String = "\(tippArray.count)"
//        let showScoreText: String = GV.language.getText(.TCGameScore, values: "\(levelScore)")
        let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        
        
        createLabels(gameNumberLabel, text: GV.language.getText(.tcGameNumber) + " \(gameNumber + 1)", column: 2, row: 1)
        createLabels(levelLabel, text: GV.language.getText(.tcLevel) + ": \(levelIndex + 1)", column: 4, row: 1)
        
        createLabels(whoIsHeaderLabel, text: GV.language.getText(.tcWhoIs), column: 1, row: 2)
        createLabels(playerHeaderLabel, text: GV.language.getText(.tcName), column: 2, row: 2)
        createLabels(timeHeaderLabel, text: GV.language.getText(.tcTime), column: 3, row: 2)
        createLabels(scoreHeaderLabel, text: GV.language.getText(.tcScoreHead), column: 4, row: 2)
        createLabels(cardCountHeaderLabel, text: GV.language.getText(.tcCardHead), column: 5, row: 2)

        createLabels(whoIsLabel, text: GV.language.getText(.tcPlayerType), column: 1, row: 3)
        createLabels(playerNameLabel, text: name, column: 2, row: 3)
        createLabels(playerTimeLabel, text: "0", column: 3, row: 3)
        createLabels(playerScoreLabel, text: String(levelScore), column: 4, row: 3)
        createLabels(playerCardCountLabel, text: String(cardCount), column: 5, row: 3)

        if playerType == .multiPlayer {
            createLabels(opponentTypeLabel, text: GV.language.getText(.tcOpponentType), column: 1, row: 4)
            createLabels(opponentNameLabel, text: opponent.name, column: 2, row: 4)
            createLabels(opponentTimeLabel, text: "0", column: 3, row: 4)
            createLabels(opponentScoreLabel, text: String(opponent.score), column: 4, row: 4)
            createLabels(opponentCardCountLabel, text: String(opponent.cardCount), column: 5, row: 4)
        } else {
            let gamesWithSameNumber = realm.objects(GameModel.self).filter("gameNumber = %d and levelID = %d and played = true", gameNumber, levelIndex )
            if gamesWithSameNumber.count == 0 { // this game is played 1st time
                playerType = .singlePlayer
                opponentTypeLabel.isHidden = true
                opponentNameLabel.isHidden = true
                opponentTimeLabel.isHidden = true
                opponentScoreLabel.isHidden = true
                opponentCardCountLabel.isHidden = true
            } else {
                playerType = .bestPlayer
                let maxScore = gamesWithSameNumber.max(ofProperty: "playerScore") as Int?
                let bestPlay = gamesWithSameNumber.filter("playerScore = %d", maxScore!).first!
                let bestPlayerName = realm.objects(PlayerModel.self).filter("ID = %d", bestPlay.playerID).first!.name
                let bestTime = bestPlay.time
                createLabels(opponentTypeLabel, text: GV.language.getText(.tcBestPlayerType), column: 1, row: 4)
                createLabels(opponentNameLabel, text: bestPlayerName, column: 2, row: 4)
                createLabels(opponentTimeLabel, text: bestTime.dayHourMinSec, column: 3, row: 4)
                createLabels(opponentScoreLabel, text: String(maxScore!), column: 4, row: 4)
                createLabels(opponentCardCountLabel, text: String(0), column: 5, row: 4)
                opponentTypeLabel.isHidden = false
                opponentNameLabel.isHidden = false
                opponentTimeLabel.isHidden = false
                opponentScoreLabel.isHidden = false
                opponentCardCountLabel.isHidden = false
            }
        }
        createLabels(cardCountLabel, text: cardCountText, column: 1, row: 5)
        createLabels(tippCountLabel, text: tippCountText, column: 2, row: 5)

    }
    
    func createGameRecord(_ gameNumber: Int) {
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
    }
    
    func createLabels(_ label: SKLabelNode, text: String, column: Int, row: Int) {
        label.text = text
        var xPos = CGFloat(0)
        var horAlignment = SKLabelHorizontalAlignmentMode.left
        if row < 5 {
            switch column {
            case 1:
                xPos = self.position.x + self.size.width * 0.065
                horAlignment = .left
            case 2:
                xPos = self.position.x + self.size.width * 0.30
                horAlignment = .left
            case 3:
                xPos = self.position.x + self.size.width * 0.50
            case 4:
                xPos = self.position.x + self.size.width * 0.65
            case 5:
                xPos = self.position.x + self.size.width * 0.82
            case 6:
                xPos = self.cardPackage!.position.x
            default: break
            }
            let yPos = CGFloat(self.size.height * labelYPosProcent / 100) + CGFloat((5 - row)) * labelHeight
            label.position = CGPoint(x: xPos, y: yPos)
            label.fontSize = labelFontSize;
            label.horizontalAlignmentMode = horAlignment
        } else {
            label.position = (column == 1 ? self.cardPackage!.position : self.tippsButton!.position)
            label.fontSize = labelFontSize * 1.5
            label.zPosition = 5
            label.horizontalAlignmentMode = .center
        }
        label.fontColor = SKColor.black
        label.verticalAlignmentMode = .center
        label.color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.addChild(label)
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
        if index == NoColor {
            return atlas.textureNamed("emptycard")
        } else {
            return atlas.textureNamed ("card\(index)")
        }
    }
    
    func specialPrepareFuncFirst() {
//        print("stopCreateTippsInBackground from specialPrepareFuncFirst")
        stopCreateTippsInBackground = true
        

        countContainers = GV.levelsForPlay.aktLevel.countContainers
        countPackages = GV.levelsForPlay.aktLevel.countPackages
        countCardsProContainer = MaxCardValue //levelsForPlay.aktLevel.countSpritesProContainer
        countColumns = GV.levelsForPlay.aktLevel.countColumns
        countRows = GV.levelsForPlay.aktLevel.countRows
        minUsedCells = GV.levelsForPlay.aktLevel.minProzent * countColumns * countRows / 100
        maxUsedCells = GV.levelsForPlay.aktLevel.maxProzent * countColumns * countRows / 100
        containerSize = CGSize(width: CGFloat(containerSizeOrig) * sizeMultiplier.width, height: CGFloat(containerSizeOrig) * sizeMultiplier.height)
        spriteSize = CGSize(width: CGFloat(GV.levelsForPlay.aktLevel.spriteSize) * sizeMultiplier.width, height: CGFloat(GV.levelsForPlay.aktLevel.spriteSize) * sizeMultiplier.height )
        scoreFactor = GV.levelsForPlay.aktLevel.scoreFactor
        scoreTime = GV.levelsForPlay.aktLevel.scoreTime
        //gameArrayPositions.removeAll(keepCapacity: false)
        tableCellSize = spriteTabRect.width / CGFloat(countColumns)
        
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
    }
    
    func updateSpriteCount(_ adder: Int) {
        cardCount += adder
        showCardCount()
    }
    
    func showCardCount() {
        cardCountLabel.text = String(cardStack.count(.mySKNodeType))
    }

    
    func changeLanguage()->Bool {
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

        showCardCount()
        showTippCount()
        showLevelScore()
        return true
    }
    
    func showTippCount() {
        tippCountLabel.text = String(tippArray.count)
        if tippArray.count > 9 {
            tippCountLabel.fontSize = labelFontSize
        } else {
            tippCountLabel.fontSize = labelFontSize * 1.5
        }
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
 
    func createSpriteStack() {
        cardStack.removeAll(.mySKNodeType)
        showCardStack.removeAll(.mySKNodeType)
        while colorTab.count > 0 && checkGameArray() < maxUsedCells {
            let colorTabIndex = random!.getRandomInt(0, max: colorTab.count - 1)//colorTab.count - 1 //
            let colorIndex = colorTab[colorTabIndex].colorIndex
            let spriteName = colorTab[colorTabIndex].spriteName
            let value = colorTab[colorTabIndex].spriteValue
            colorTab.remove(at: colorTabIndex)
            let sprite = MySKNode(texture: getTexture(colorIndex), type: .spriteType, value:value)
            sprite.name = spriteName
            sprite.colorIndex = colorIndex
            cardStack.push(sprite)
        }
    }
    
    func fillEmptySprites() {
        for column in 0..<countColumns {
            for row in 0..<countRows {
                makeEmptyCard(column, row: row)
            }
        }
    }

    func generateSprites(_ generatingType: SpriteGeneratingType) {
        var waitForStart: TimeInterval = 0.0
//        print("generateSprites:", generatingType)
        var generateSpecial = generatingType ==  .special
        var positionsTab = [(Int, Int)]() // search all available Positions
        for column in 0..<countColumns {
            for row in 0..<countRows {
                if !gameArray[column][row].used {
                    let appendValue = (column, row)
                    positionsTab.append(appendValue)
                }
            }
        }
//        print(positionsTab.count)
        
        while cardStack.count(.mySKNodeType) > 0 && (checkGameArray() < maxUsedCells || (generateSpecial && positionsTab.count > 0)) {
            var sprite: MySKNode = cardStack.pull()!
//            var sprite: MySKNode?
//            sprite = cardStack.random(random)
            
            if generateSpecial {
                while true {
                    if findPairForSprite(sprite.colorIndex, minValue: sprite.minValue, maxValue: sprite.maxValue) {
                        break
                        // checkPath
                    }
//                    sprite = cardStack.random(random)!
                    cardStack.pushLast(sprite)
                    sprite = cardStack.pull()!
                    
                }
                generateSpecial = false
            }
            showCardCount()
//            cardStack.removeAtLastRandomIndex()
            let index = random!.getRandomInt(0, max: positionsTab.count - 1)
            let (actColumn, actRow) = positionsTab[index]
            
            let zielPosition = gameArray[actColumn][actRow].position
            sprite.position = cardPackage!.position
            sprite.startPosition = zielPosition
            

            positionsTab.remove(at: index)
            
            sprite.column = actColumn
            sprite.row = actRow
            
            sprite.size = CGSize(width: spriteSize.width, height: spriteSize.height)
//            sprite.zPosition = 10
            updateGameArrayCell(sprite)

//            addPhysicsBody(sprite)
            push(sprite, status: .addedFromCardStack)
            addChild(sprite)
            let duration:Double = Double((zielPosition - cardPackage!.position).length()) / 500
            let actionMove = SKAction.move(to: zielPosition, duration: duration)
            
            let waitingAction = SKAction.wait(forDuration: waitForStart)
            waitForStart += 0.2
            
            let zPositionPlus = SKAction.run({
                sprite.zPosition += 100
            })

            let zPositionMinus = SKAction.run({
                sprite.zPosition -= 100
            })

            let actionHideEmptyCard = SKAction.run({
                self.deleteEmptySprite(actColumn, row: actRow)
//                sprite.zPosition = 0
                
            })
            sprite.run(SKAction.sequence([waitingAction, zPositionPlus, actionMove, zPositionMinus, actionHideEmptyCard]))
            if cardStack.count(.mySKNodeType) == 0 {
                cardPackage!.changeButtonPicture(SKTexture(imageNamed: "emptycard"))
                cardPackage!.alpha = 0.3
            }

        }
        
        
//        print("Count Columns:", countColumns)
//        printGameArrayInhalt("after generateSprites")
        
        if generatingType != .special {
            gameArrayChanged = true
        }
        if generatingType == .first {
            countUp = Timer.scheduledTimer(timeInterval: doCountUpSleepTime, target: self, selector: Selector(doCountUpSelector), userInfo: nil, repeats: true)
            doTimeCount = true
//            countUpAdder = 1
        }
        stopped = false
    }
    
    func printGameArrayInhalt(_ calledFrom: String) {
        print(calledFrom, Date())
        var string: String
        for row in 0..<countRows {
            let rowIndex = countRows - row - 1
            string = ""
            for column in 0..<countColumns {
                let color = gameArray[column][rowIndex].colorIndex
                if gameArray[column][rowIndex].used {
                    let minInt = gameArray[column][rowIndex].minValue + 1
                    let maxInt = gameArray[column][rowIndex].maxValue + 1
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
                    self.generateSprites(.special)
                    _ = self.createTipps()
                }
            } while !(self.tippArray.count > 2 || self.countColumns * self.countRows - self.checkGameArray() == 0 || self.checkGameArray() < 2)
            
            if self.tippArray.count == 0 && self.cardCount > 0{
                
                print ("You have lost!")
            }
            self.generatingTipps = false
        } ~>
        {
            self.generatingTipps = false
        }
    }
    
    
    func deleteEmptySprite(_ column: Int, row: Int) {
        let searchName = "\(emptySpriteTxt)-\(column)-\(row)"
        if self.childNode(withName: searchName) != nil {
            self.childNode(withName: searchName)!.removeFromParent()
        }

    
    }
    
    func makeEmptyCard(_ column:Int, row: Int) {
        let searchName = "\(emptySpriteTxt)-\(column)-\(row)"
        if self.childNode(withName: searchName) == nil {
            let emptySprite = MySKNode(texture: getTexture(NoColor), type: .emptyCardType, value: NoColor)
            emptySprite.position = gameArray[column][row].position
            emptySprite.size = CGSize(width: spriteSize.width, height: spriteSize.height)
            emptySprite.name = "\(emptySpriteTxt)-\(column)-\(row)"
            emptySprite.column = column
            emptySprite.row = row
            gameArray[column][row].used = false
            gameArray[column][row].colorIndex = NoColor
            gameArray[column][row].name = searchName
            addChild(emptySprite)
        }
    }

    func specialButtonPressed(_ buttonName: String) {
//        if buttonName == "cardPackege" {
//            if cardStack.count(.MySKNodeType) > 0 {
//                if showCard != nil {
//                    showCardStack.push(showCard!)
//                    showCard?.removeFromParent()
//                }
//                showCard = cardStack.pull()!
//                showCard!.position = (cardPlaceButton?.position)!
//                showCard!.size = (cardPlaceButton?.size)!
//                showCard!.type = .ShowCardType
//                cardPlaceButton?.removeFromParent()
//                cardPlaceButtonAddedToParent = false
//                addChild(showCard!)
//                if cardStack.count(.MySKNodeType) == 0 {
//                    cardPackage!.changeButtonPicture(SKTexture(imageNamed: "emptycard"))
//                    cardPackage!.alpha = 0.3
//                }
//            }
//        }
        if buttonName == "tipps" {
            if !generatingTipps {
                getTipps()
                if showTippCounter > 0 {
                    showTippCounter -= 1
                } else {
                    freeTippCounter -= 1
                    let modifyer = freeTippCounter > 0 ? 0 : freeTippCounter > -freeAmount ? penalty : 2 * penalty
                    scoreModifyer -= modifyer
                    levelScore -= modifyer
                    if modifyer > 0 {
                        self.addChild(showCountScore("-\(modifyer)", position: undoButton!.position))
                    }
                }
            }
        }
        startTippTimer()
    }
    
    func startTippTimer(){
    }
    
    func getTipps() {
        if tippArray.count > 0 && !generatingTipps {
                stopTrembling()
                drawHelpLines(tippArray[tippIndex].points, lineWidth: spriteSize.width, twoArrows: tippArray[tippIndex].twoArrows, color: .green)
                var position = CGPoint.zero
                if tippArray[tippIndex].fromRow == NoValue {
                    position = containers[tippArray[tippIndex].fromColumn].position
                } else {
                    position = gameArray[tippArray[tippIndex].fromColumn][tippArray[tippIndex].fromRow].position
                }
                addSpriteToTremblingSprites(position)
                if tippArray[tippIndex].toRow == NoValue {
                    position = containers[tippArray[tippIndex].toColumn].position
                } else {
                    position = gameArray[tippArray[tippIndex].toColumn][tippArray[tippIndex].toRow].position
                }
                addSpriteToTremblingSprites(position)
//            }
            tippIndex += 1
            tippIndex %= tippArray.count
        }
        
    }
    
    func createTipps()->Bool {
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
                            if stopCreateTippsInBackground {
                                print("stopped while searching pairs")
                                stopCreateTippsInBackground = false
                                return false
                            }
                            if (column1 != column2 || row1 != row2) && gameArray[column2][row2].colorIndex == gameArray[column1][row1].colorIndex &&
                                (gameArray[column2][row2].minValue == gameArray[column1][row1].maxValue + 1 ||
                                    gameArray[column2][row2].maxValue == gameArray[column1][row1].minValue - 1) {
                                        let aktPair = FromToColumnRow(fromColumnRow: ColumnRow(column: column1, row: row1), toColumnRow: ColumnRow(column: column2, row: row2))
                                        if !pairExists(pairsToCheck, aktPair: aktPair) {
                                            pairsToCheck.append(aktPair)
                                            pairsToCheck.append(FromToColumnRow(fromColumnRow: aktPair.toColumnRow, toColumnRow: aktPair.fromColumnRow))
                                        }
                            }
                        }
                    }
                    for index in 0..<containers.count {
                        if containers[index].minValue == NoColor && gameArray[column1][row1].maxValue == LastCardValue {
                            let actContainerPair = FromToColumnRow(fromColumnRow: ColumnRow(column: column1, row: row1), toColumnRow: ColumnRow(column: index, row: NoValue))
                            pairsToCheck.append(actContainerPair)
                        }
                        if containers[index].colorIndex == gameArray[column1][row1].colorIndex &&
                         containers[index].minValue == gameArray[column1][row1].maxValue + 1 {
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
                            switch tippArray[ind].points.count {
                            case 2:
                                tippArray[ind].twoArrows = true
                                removeIndex.insert(ind + 1, at: 0)
                            case 3:
                                if (tippArray[ind].points[1] - tippArray[ind + 1].points[1]).length() < spriteSize.height{
                                    tippArray[ind].twoArrows = true
                                    removeIndex.insert(ind + 1, at: 0)
                                }
                            case 4:
                                if tippArray[ind + 1].points.count == 4 && (tippArray[ind].points[1] - tippArray[ind + 1].points[2]).length() < spriteSize.height && (tippArray[ind].points[2] - tippArray[ind + 1].points[1]).length() < spriteSize.height
                                {
                                    tippArray[ind].twoArrows = true
                                    removeIndex.insert(ind + 1, at: 0)
                                }
                            default:
                                tippArray[ind].twoArrows = false
                            }
                    }
                    if gameArray[fromColumn][fromRow].maxValue == LastCardValue && toRow == NoValue && containers[toColumn].minValue == NoColor {
                        // King to empty Container
                        var index = 1
                        while (ind + index) < tippArray.count && index < 4 {
                            let fromColumn1 = tippArray[ind + index].fromColumn
                            let toColumn1 = tippArray[ind + index].toColumn
                            let fromRow1 = tippArray[ind + index].fromRow
                            let toRow1 = tippArray[ind + index].toRow
                            
                            if fromColumn == fromColumn1 && fromRow == fromRow1 && toRow1 == NoValue && containers[toColumn1].minValue == NoColor
                                && toColumn != toColumn1 {
                                if tippArray[ind].lineLength > tippArray[ind + index].lineLength {
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
                return false
            }
            tippArray.sort(by: {checkForSort($0, t1: $1) })
            
        }
//        let tippCountText: String = GV.language.getText(.TCTippCount)
//        print("Tippcount:", tippArray.count, tippArray)
        showTippCount()
        if tippArray.count > 0 {
            tippsButton!.activateButton(true)
        }

        tippIndex = 0  // set tipps to first
        return true
     }
    
    func findPairForSprite (_ colorIndex: Int, minValue: Int, maxValue: Int)->Bool {
        var founded = false
        for column in 0..<countColumns {
            for row in 0..<countRows {
                if gameArray[column][row].colorIndex == colorIndex &&
                    (gameArray[column][row].minValue == maxValue + 1 ||
                    gameArray[column][row].maxValue == minValue - 1) {
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
    
    func checkForSort(_ t0: Tipps, t1:Tipps)->Bool {
        let returnValue = gameArray[t0.fromColumn][t0.fromRow].colorIndex < gameArray[t1.fromColumn][t1.fromRow].colorIndex
            || (gameArray[t0.fromColumn][t0.fromRow].colorIndex == gameArray[t1.fromColumn][t1.fromRow].colorIndex &&
                (gameArray[t0.fromColumn][t0.fromRow].maxValue < gameArray[t1.fromColumn][t1.fromRow].minValue
            || (t0.toRow != NoValue && t1.toRow != NoValue && gameArray[t0.toColumn][t0.toRow].maxValue < gameArray[t1.toColumn][t1.toRow].minValue)))
        return returnValue
    }
    
    func pairExists(_ pairsToCheck:[FromToColumnRow], aktPair: FromToColumnRow)->Bool {
        for index in 0..<pairsToCheck.count {
            let aktPairToCheck = pairsToCheck[index]
            if aktPairToCheck.fromColumnRow.column == aktPair.fromColumnRow.column && aktPairToCheck.fromColumnRow.row == aktPair.fromColumnRow.row && aktPairToCheck.toColumnRow.column == aktPair.toColumnRow.column && aktPairToCheck.toColumnRow.row == aktPair.toColumnRow.row {
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
//        let startNode = self.childNodeWithName(name)! as! MySKNode
        var founded = false
        var angle = startAngle
        let multiplierForSearch = CGFloat(3.0)
//        let fineMultiplier = CGFloat(1.0)
        let multiplier:CGFloat = multiplierForSearch
        while angle <= stopAngle && !founded {
            let toPoint = GV.pointOfCircle(1.0, center: startPoint, angle: angle)
            let (foundedPoint, myPoints) = createHelpLines(actPair.fromColumnRow, toPoint: toPoint, inFrame: self.frame, lineSize: spriteSize.width, showLines: false)
            if foundedPoint != nil {
                if foundedPoint!.foundContainer && actPair.toColumnRow.row == NoValue && foundedPoint!.column == actPair.toColumnRow.column ||
                    (foundedPoint!.column == actPair.toColumnRow.column && foundedPoint!.row == actPair.toColumnRow.row) {
                    if distanceToLine == firstValue ||
                    myPoints.count < myTipp.points.count ||
                    (myTipp.points.count == myPoints.count && foundedPoint!.distanceToP0 < distanceToLine) {
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
                print("in else zweig von checkPathToFoundedCards !")
            }
            angle += GV.oneGrad * multiplier
        }

        if distanceToLine.between(0, max: firstValue - 0.1) {
            
            for ind in 0..<myTipp.points.count - 1 {
                myTipp.lineLength += (myTipp.points[ind] - myTipp.points[ind + 1]).length()
            }
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
        var foundedColorIndex: Int
        var foundedMinValue: Int
        var foundedMaxValue: Int
        
        if foundedPoint.distanceToP0 == foundedPoint.maxDistance {
            return color
        }
        
        if foundedPoint.foundContainer {
            foundedColorIndex = containers[foundedPoint.column].colorIndex
            foundedMaxValue = containers[foundedPoint.column].maxValue
            foundedMinValue = containers[foundedPoint.column].minValue
        } else {
            foundedColorIndex = gameArray[foundedPoint.column][foundedPoint.row].colorIndex
            foundedMaxValue = gameArray[foundedPoint.column][foundedPoint.row].maxValue
            foundedMinValue = gameArray[foundedPoint.column][foundedPoint.row].minValue
        }
        if (gameArray[movedFrom.column][movedFrom.row].colorIndex == foundedColorIndex &&
            (gameArray[movedFrom.column][movedFrom.row].maxValue == foundedMinValue - 1 ||
                gameArray[movedFrom.column][movedFrom.row].minValue == foundedMaxValue + 1)) ||
            (foundedMinValue == NoColor && gameArray[movedFrom.column][movedFrom.row].maxValue == LastCardValue) {
                color = .green
        }
        return color
    }
    
//    func findColumnRowDelegateFunc(fromPoint:CGPoint, toPoint:CGPoint)->FromToColumnRow {
//        let fromToColumnRow = FromToColumnRow()
//        return fromToColumnRow
//    }
    
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
        let lineWidth = lastDrawHelpLinesParameters.lineWidth
//         lineWidthMultiplier = lineWidthMultiplierSpecial

        let twoArrows = lastDrawHelpLinesParameters.twoArrows
        let color = lastDrawHelpLinesParameters.color
        let arrowLength = spriteSize.width * 0.30
    
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
        
        if color == .red {
            myLine.strokeColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8) // GV.colorSets[GV.colorSetIndex][colorIndex + 1]
        } else {
            myLine.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.8) // GV.colorSets[GV.colorSetIndex][colorIndex + 1]
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
                if nodes[index] is MySKNode {
                    (nodes[index] as! MySKNode).tremblingType = .noTrembling

                    tremblingSprites.removeAll()
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
            addSpriteToTremblingSprites(tremblingCardPosition)
            lastNextPoint = nextPoint
        }
        
    }
    
    func addSpriteToTremblingSprites(_ position: CGPoint) {
        let nodes = self.nodes(at: position)
        for index in 0..<nodes.count {
            if nodes[index] is MySKNode {
                tremblingSprites.append(nodes[index] as! MySKNode)
                (nodes[index] as! MySKNode).tremblingType = .changeSize
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
            for index in 0..<tremblingSprites.count {
                let aktSprite = tremblingSprites[index]
                switch aktSprite.trembling {
                    case 0: aktSprite.trembling = adder
                    case adder: aktSprite.trembling = -adder
                    case -adder: aktSprite.trembling = adder
                    default: aktSprite.trembling = adder
                }
                switch aktSprite.tremblingType {
                    case .noTrembling: break
                    case .changeSize:  aktSprite.size = CGSize(width: aktSprite.origSize.width +  aktSprite.trembling, height: aktSprite.origSize.height +  aktSprite.trembling)
                    case .changePos: break
                    case .changeDirection: aktSprite.zRotation = CGFloat(CGFloat(M_PI)/CGFloat(aktSprite.trembling == 0 ? 16 : aktSprite.trembling * CGFloat(8)))
                    case .changeSizeOnce:
                        if aktSprite.size == aktSprite.origSize {
                            aktSprite.size.width += adder
                            aktSprite.size.height += adder
                        }
                }
            }

        }
        lastUpdateSec = sec10
        if restartGame {
            restartGame = false
            newGame(false)
        }
        
        checkMultiplayer()
        checkColoredLines()
        
    }
    
    func checkColoredLines() {
        if lastPair.color == MyColors.green { // Timer for check Green Line
            if Date().timeIntervalSince(lastPair.startTime) > 0.5 && !lastPair.fixed {
                lastPair.fixed = true
                lineWidthMultiplier = lineWidthMultiplierSpecial
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
                let statistic = realm.objects(StatisticModel.self).filter("playerID = %d AND levelID = %d", GV.player!.ID, GV.player!.levelID).first!
                saveStatisticAndGame(statistic)
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
            for card in gameRow {
                if card.used {
                    let cardToMove = self.childNode(withName: card.name) as! MySKNode
                    makeEmptyCard(cardToMove.column, row: cardToMove.row)
                    animateMovingCard(cardToMove)
                }
            }
            repeat {
                if let cardToMove: MySKNode = cardStack.pull() {
                    cardToMove.position = cardPackage!.position
                    animateMovingCard(cardToMove)
                } else {
                    break
                }
            } while true
        }
    }
    
    func animateMovingCard(_ card: MySKNode) {
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
    
    func spriteDidCollideWithContainer(_ node1:MySKNode, node2:MySKNode) {
        let movingSprite = node1
        let container = node2
        
        var containerColorIndex = container.colorIndex
        let movingSpriteColorIndex = movingSprite.colorIndex
        
        
        if container.minValue == container.maxValue && container.maxValue == NoColor && movingSprite.maxValue == LastCardValue {
            var containerNotFound = true
            for index in 0..<countContainers {
                if containers[index].colorIndex == movingSpriteColorIndex {
                    containerNotFound = false
                }
            }
            if containerNotFound {
                containerColorIndex = movingSpriteColorIndex
                container.colorIndex = containerColorIndex
                container.texture = getTexture(containerColorIndex)
                push(container, status: .firstCardAdded)
            }
        }
        
        let OK = movingSpriteColorIndex == containerColorIndex &&
        (
            container.minValue == NoColor ||
            movingSprite.maxValue + 1 == container.minValue ||
            movingSprite.minValue - 1 == container.maxValue ||
            (container.maxValue == LastCardValue && container.minValue == FirstCardValue && movingSprite.maxValue == LastCardValue)         )

        
        
        if OK  {
            push(container, status: .hitcounterChanged)
            push(movingSprite, status: .removed)
//            let adder = movingSprite.maxValue * (movingSprite.maxValue - movingSprite.minValue + 1)
            if container.maxValue < movingSprite.minValue {
                container.maxValue = movingSprite.maxValue
            } else {
                container.minValue = movingSprite.minValue
                if container.maxValue == NoColor {
                    container.maxValue = movingSprite.maxValue
                }
            }

            self.addChild(showCountScore("+\(movingSprite.countScore)", position: movingSprite.position))
            
//            movingSprite.countScore += mirroredScore
            levelScore += movingSprite.countScore
            levelScore += movingSprite.getMirroredScore()
            
            container.reload()
            //gameArray[movingSprite.column][movingSprite.row] = false
            resetGameArrayCell(movingSprite)
            movingSprite.removeFromParent()
            playSound("Container", volume: GV.player!.soundVolume)
            countMovingSprites = 0
            
            updateSpriteCount(-1)
            
            collisionActive = false
            //movingSprite.removeFromParent()
            checkGameFinished()
        } else {
            updateSpriteCount(-1)
            movingSprite.removeFromParent()
            countMovingSprites = 0
            push(movingSprite, status: .removed)
            pull(false) // no createTipps
            startTippTimer()
            tippsButton!.activateButton(true)

        }
        
     }
    
    func resetGameArrayCell(_ sprite:MySKNode) {
        gameArray[sprite.column][sprite.row].used = false
        gameArray[sprite.column][sprite.row].colorIndex = NoColor
        gameArray[sprite.column][sprite.row].minValue = NoValue
        gameArray[sprite.column][sprite.row].maxValue = NoValue
    }
    
    func updateGameArrayCell(_ sprite:MySKNode) {
        gameArray[sprite.column][sprite.row].used = true
        gameArray[sprite.column][sprite.row].name = sprite.name!
        gameArray[sprite.column][sprite.row].colorIndex = sprite.colorIndex
        gameArray[sprite.column][sprite.row].minValue = sprite.minValue
        gameArray[sprite.column][sprite.row].maxValue = sprite.maxValue
    }

    func spriteDidCollideWithMovingSprite(_ node1:MySKNode, node2:MySKNode) {
//        let collisionsTime = NSDate()
//        let timeInterval: Double = collisionsTime.timeIntervalSinceDate(lastCollisionsTime); // <<<<< Difference in seconds (double)
//
//        if timeInterval < 1 {
//            return
//        }
//        lastCollisionsTime = collisionsTime
        let movingSprite = node1
        let sprite = node2
        let movingSpriteColorIndex = movingSprite.colorIndex
        let spriteColorIndex = sprite.colorIndex
        
        //let aktColor = GV.colorSets[GV.colorSetIndex][sprite.colorIndex + 1].CGColor
        collisionActive = false
        
        let OK = movingSpriteColorIndex == spriteColorIndex &&
        (
            movingSprite.maxValue + 1 == sprite.minValue ||
            movingSprite.minValue - 1 == sprite.maxValue //||
        )
        if OK {
            push(sprite, status: .unification)
            push(movingSprite, status: .removed)
            
            if sprite.maxValue < movingSprite.minValue {
                sprite.maxValue = movingSprite.maxValue
            } else {
                sprite.minValue = movingSprite.minValue
            }
            
//            for adder in movingSprite.minValue + 1...movingSprite.maxValue + 1 {
//                movingSprite.countScore += adder
//                levelScore += adder
//            }
            
            self.addChild(showCountScore("+\(movingSprite.countScore)", position: movingSprite.position))
            levelScore += movingSprite.countScore
            levelScore += movingSprite.getMirroredScore()

            sprite.reload()
            
            playSound("OK", volume: GV.player!.soundVolume)
        
            updateGameArrayCell(sprite)
            resetGameArrayCell(movingSprite)
            
            movingSprite.removeFromParent()
            countMovingSprites = 0
            updateSpriteCount(-1)
            checkGameFinished()
       } else {

            updateSpriteCount(-1)
            movingSprite.removeFromParent()
            countMovingSprites = 0
            push(movingSprite, status: .removed)
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
        score.fontName = "Helvetica Bold"
        score.fontSize = 30
        score.zPosition = 1000
        let showAction = SKAction.moveTo(y: position.y + 1000, duration: 10.0)
        let hideAction = SKAction.sequence([SKAction.fadeOut(withDuration: 3.0), SKAction.removeFromParent()])
        let scoreActions = SKAction.group([showAction, hideAction])
        score.run(scoreActions)
        return score
    }

    func checkGameFinished() {
        
        
        let usedCellCount = checkGameArray()
//        let containersOK = checkContainers()
        
        let finishGame = GV.player!.name != "tester" ? cardCount == 0 : cardCount < 52
        
        if finishGame { // Level completed, start a new game
            
            stopTimer(&countUp)
            playMusic("Winner", volume: GV.player!.musicVolume, loops: 0)
            if playerType == .multiPlayer {
                GV.peerToPeerService?.sendInfo(.gameIsFinished, message: [String(levelScore)], toPeerIndex: opponent.peerIndex)
            }
            
            
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
            // get && modify the statistic record
            
            let statistic = realm.objects(StatisticModel.self).filter("playerID = %d AND levelID = %d", GV.player!.ID, GV.player!.levelID).first!
            saveStatisticAndGame(statistic)
            if playerType == .multiPlayer {
                alertIHaveGameFinished()
            } else {
                let alert = getNextPlayArt(true, statistic: statistic)
                GV.mainViewController!.showAlert(alert)
            }
        } else if usedCellCount <= minUsedCells && usedCellCount > 1 { //  && spriteCount > maxUsedCells {
            generateSprites(.normal)  // Nachgenerierung
        } else {
            if cardCount > 0 /*&& cardStack.count(.MySKNodeType) > 0*/ {
                gameArrayChanged = true
            }
        }
    }
    
    func saveStatisticAndGame (_ statistic: StatisticModel) {
        
        realm.beginWrite()
        statistic.actTime = timeCount
        statistic.allTime += timeCount
        
        if statistic.bestTime == 0 || timeCount < statistic.bestTime {
            statistic.bestTime = timeCount
        }
        
        
        statistic.actScore = levelScore
        statistic.levelScore += levelScore
        if statistic.bestScore < levelScore {
            statistic.bestScore = levelScore
        }
        
        if statistic.bestScore < levelScore {
            statistic.bestScore = levelScore
        }
        
        actGame!.time = timeCount
        actGame!.playerScore = levelScore
        actGame!.played = true
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
        } else {
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
            alertOpponentDoesNotWantPlay()
            self.opponent = Opponent()
            self.playerType = .singlePlayer
        default:
            break
        }
    }
    
    func alertOpponentDoesNotWantPlay() {
        let alert = UIAlertController(title: GV.language.getText(.tcOpponentNotPlay, values: String(opponent.name)),
            message: "",
            preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: GV.language.getText(.tcok), style: .default,
                                        handler: {(paramAction:UIAlertAction!) in
                                            
        })
        alert.addAction(OKAction)

        
        GV.mainViewController!.showAlert(alert, delay: 5)
        
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
    
    func chooseGameNumber () {
        let _ = ChooseGamePanel(
            view: view!,
            frame: CGRect(x: self.frame.midX, y: self.frame.midY, width: self.frame.width * 0.5, height: self.frame.height * 0.5),
            parent: self,
            callBack: callBackFromMySKTextField
        )
    }
    
    func callBackFromMySKTextField(_ gameNumber: Int) {
        self.gameNumber = gameNumber
        self.isUserInteractionEnabled = true
        newGame(false)
    }
    
    func newGame(_ next: Bool) {
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
        generateSprites(.first)
    }

//    func timeFactor()->Double {
//        
//        let y: Double = scoreTime * 60 / (scoreFactor - 1)
//        let x: Double = y * scoreFactor
//        
//        
//        return Double(x / (y + Double(timeCount)))
//    }

    func getNextPlayArt(_ congratulations: Bool, statistic: StatisticModel...)->UIAlertController {
        let playerName = GV.player!.name + "!"
        let statisticsTxt = ""
        var congratulationsTxt = ""
        
        
        if congratulations {
            
            let actGames = realm.objects(GameModel.self).filter("levelID = %d and gameNumber = %d", levelIndex, actGame!.gameNumber)
            
            let bestGameScore: Int = actGames.max(ofProperty: "playerScore")!
            let bestScorePlayerID = actGames.filter("playerScore = %d", bestGameScore).first!.playerID
            let bestScorePlayerName = realm.objects(PlayerModel.self).filter("ID = %d",bestScorePlayerID).first!.name
            
            tippCountLabel.text = String(0)

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
            congratulationsTxt += "\r\n" + GV.language.getText(.tcActTime) + String(statistic[0].actTime.dayHourMinSec)
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
            let againAction = UIAlertAction(title: GV.language.getText(.tcGameAgain), style: .default,
                handler: {(paramAction:UIAlertAction!) in
                    self.newGame(false)
            })
            alert.addAction(againAction)
            let newGameAction = UIAlertAction(title: GV.language.getText(TextConstants.tcNewGame), style: .default,
                handler: {(paramAction:UIAlertAction!) in
                    self.newGame(true)
                    //self.gameArrayChanged = true

            })
            alert.addAction(newGameAction)
            
            let chooseGameAction = UIAlertAction(title: GV.language.getText(.tcChooseGameNumber), style: .default,
                                              handler: {(paramAction:UIAlertAction!) in
                                                self.chooseGameNumber()
                                                //self.gameArrayChanged = true
                                                
            })
            alert.addAction(chooseGameAction)
            
            if levelIndex > 0 {
                let easierAction = UIAlertAction(title: GV.language.getText(.tcPreviousLevel), style: .default,
                    handler: {(paramAction:UIAlertAction!) in
    //                    print("newGame from set Previous Level")
                        self.setLevel(self.previousLevel)
                        self.newGame(true)
                })
                alert.addAction(easierAction)
            }
            
            if GV.peerToPeerService!.hasOtherPlayers() {
                let competitionAction = UIAlertAction(title: GV.language.getText(.tcCompetition), style: .default,
                                                     handler: {(paramAction:UIAlertAction!) in
                                                        self.choosePartner()
                                                        //self.gameArrayChanged = true
                                                        
                })
                alert.addAction(competitionAction)
                
            }
            
            let countGamesOfActLevel = realm.objects(GameModel.self).filter("playerID = %d and levelID = %d and played = yes", GV.player!.ID, levelIndex).count

            if levelIndex < GV.levelsForPlay.levelParam.count - 1 && countGamesOfActLevel > 10 {
                let complexerAction = UIAlertAction(title: GV.language.getText(TextConstants.tcNextLevel), style: .default,
                    handler: {(paramAction:UIAlertAction!) in
    //                    print("newGame from set Next Level")
                        self.setLevel(self.nextLevel)
                        self.newGame(true)
                })
                alert.addAction(complexerAction)
            }
        }
//        if !congratulations {
            let cancelAction = UIAlertAction(title: GV.language.getText(TextConstants.tcCancel), style: .default,
                handler: {(paramAction:UIAlertAction!) in
            })
            alert.addAction(cancelAction)
//        }
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
    
    func prepareContainers() {
       
        colorTab.removeAll(keepingCapacity: false)
        var spriteName = 10000
        
        for cardIndex in 0..<countCardsProContainer! * countPackages {
            for containerIndex in 0..<countContainers {
                let colorTabLine = ColorTabLine(colorIndex: containerIndex, spriteName: "\(spriteName)",
                    spriteValue: cardArray[containerIndex][cardIndex % MaxCardValue].cardValue) //generateValue(containerIndex) - 1)
                colorTab.append(colorTabLine)
                spriteName += 1
            }
        }
        
        createSpriteStack()
        fillEmptySprites()

        
        let xDelta = size.width / CGFloat(countContainers)
        for index in 0..<countContainers {
            let centerX = (size.width / CGFloat(countContainers)) * CGFloat(index) + xDelta / 2
            let centerY = size.height * containersPosCorr.y
            containers.append(MySKNode(texture: getTexture(NoColor), type: .containerType, value: NoColor))
            containers[index].name = "\(index)"
            containers[index].position = CGPoint(x: centerX, y: centerY)
            containers[index].size = CGSize(width: containerSize.width, height: containerSize.height)
//            containers[index].size.width = containerSize.width
//            containers[index].size.height = containerSize.height
            
            containers[index].colorIndex = NoValue
            containers[index].physicsBody = SKPhysicsBody(circleOfRadius: containers[index].size.width / 3) // 1
            containers[index].physicsBody?.isDynamic = true // 2
            containers[index].physicsBody?.categoryBitMask = PhysicsCategory.Container
            containers[index].physicsBody?.contactTestBitMask = PhysicsCategory.MovingSprite
            containers[index].physicsBody?.collisionBitMask = PhysicsCategory.None
            countColorsProContainer.append(countCardsProContainer!)
            addChild(containers[index])
            containers[index].reload()
        }
    }
    
    


    func pull(_ createTipps: Bool) {
        let duration = 0.2
        var actionMoveArray = [SKAction]()
        if let savedSprite:SavedSprite  = stack.pull() {
            var savedSpriteInCycle = savedSprite
            var run = true
            var stopSoon = false
            
            repeat {
                
                switch savedSpriteInCycle.status {
                case .added: break
                case .addedFromCardStack:
                    if stack.countChangesInStack() > 0 {
                        let spriteName = savedSpriteInCycle.name
//                        let colorIndex = savedSpriteInCycle.colorIndex
                        let searchName = "\(spriteName)"
                        let cardToPush = self.childNode(withName: searchName)! as! MySKNode
                        cardToPush.zPosition = 20
                        cardStack.push(cardToPush)
                        
//                        let colorTabLine = ColorTabLine(colorIndex: colorIndex, spriteName: spriteName, spriteValue: savedSpriteInCycle.minValue)
//                        colorTab.append(colorTabLine)
                        gameArray[savedSpriteInCycle.column][savedSpriteInCycle.row].used = false
                        makeEmptyCard(savedSpriteInCycle.column, row: savedSpriteInCycle.row)
                        let aktPosition = gameArray[savedSpriteInCycle.column][savedSpriteInCycle.row].position
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
                        showCardStack.push(showCard!)
                        removeOldShowCard = SKAction.run({
                            oldShowCard!.removeFromParent()
                            oldShowCard = nil
                        })
                    }
                    let spriteName = savedSpriteInCycle.name
                    let searchName = "\(spriteName)"
                    showCard = self.childNode(withName: searchName)! as? MySKNode
                    showCard!.position = savedSpriteInCycle.endPosition //(cardPlaceButton?.position)!
                    showCard!.size = (cardPlaceButton?.size)!
                    showCard!.type = .showCardType
                    self.childNode(withName: searchName)!.removeFromParent()
                    self.addChild(showCard!)
                    gameArray[savedSpriteInCycle.column][savedSpriteInCycle.row].used = false
                    makeEmptyCard(savedSpriteInCycle.column, row: savedSpriteInCycle.row)
                    let actionMove = SKAction.move(to: cardPlaceButton!.position, duration: 0.5)
                    if oldShowCardExists {
                        showCard!.run(SKAction.sequence([actionMove, removeOldShowCard]))
                    } else {
                        showCard!.run(actionMove)
                    }
                case .removed:
                    //let spriteTexture = SKTexture(imageNamed: "sprite\(savedSpriteInCycle.colorIndex)")
                    let spriteTexture = getTexture(savedSpriteInCycle.colorIndex)
                    let type = savedSpriteInCycle.type
                    let sprite = MySKNode(texture: spriteTexture, type: type, value: savedSpriteInCycle.minValue) //NoValue)
                    
                    
                    sprite.colorIndex = savedSpriteInCycle.colorIndex
                    sprite.position = savedSpriteInCycle.endPosition
                    sprite.startPosition = savedSpriteInCycle.startPosition
                    sprite.size = savedSpriteInCycle.size
                    sprite.column = savedSpriteInCycle.column
                    sprite.row = savedSpriteInCycle.row
                    sprite.minValue = savedSpriteInCycle.minValue
                    sprite.maxValue = savedSpriteInCycle.maxValue
                    sprite.BGPictureAdded = savedSpriteInCycle.BGPictureAdded
                    sprite.name = savedSpriteInCycle.name
                    levelScore = savedSpriteInCycle.countScore
 
                    updateGameArrayCell(sprite)
//                    gameArray[sprite.column][sprite.row].colorIndex = sprite.colorIndex
//                    gameArray[sprite.column][sprite.row].minValue = sprite.minValue
//                    gameArray[sprite.column][sprite.row].maxValue = sprite.maxValue
                    
//                    gameArray[sprite.column][sprite.row].used = true
//                    addPhysicsBody(sprite)
                    self.addChild(sprite)
                    updateSpriteCount(1)
                    sprite.reload()
                    
                case .unification:
                    let sprite = self.childNode(withName: savedSpriteInCycle.name)! as! MySKNode
                    sprite.size = savedSpriteInCycle.size
                    sprite.minValue = savedSpriteInCycle.minValue
                    sprite.maxValue = savedSpriteInCycle.maxValue
                    sprite.BGPictureAdded = savedSpriteInCycle.BGPictureAdded
                    updateGameArrayCell(sprite)
                    //sprite.hitLabel.text = "\(sprite.hitCounter)"
                    sprite.reload()
                    
                case .hitcounterChanged:
                    
                    let container = containers[findIndex(savedSpriteInCycle.colorIndex)]
                    container.minValue = savedSpriteInCycle.minValue
                    container.maxValue = savedSpriteInCycle.maxValue
                    container.BGPictureAdded = savedSpriteInCycle.BGPictureAdded
                    container.reload()
                    showScore()
                    
                case .firstCardAdded:
                    let container = containers[findIndex(savedSpriteInCycle.colorIndex)]
                    container.minValue = savedSpriteInCycle.minValue
                    container.maxValue = savedSpriteInCycle.maxValue
                    container.BGPictureAdded = savedSpriteInCycle.BGPictureAdded
                    container.colorIndex = NoColor
                    container.reload()
                    
                    
                case .movingStarted:
                    let sprite = self.childNode(withName: savedSpriteInCycle.name)! as! MySKNode
                    sprite.startPosition = savedSpriteInCycle.startPosition
                    sprite.minValue = savedSpriteInCycle.minValue
                    sprite.maxValue = savedSpriteInCycle.maxValue

                    updateGameArrayCell(sprite)
//                    gameArray[sprite.column][sprite.row].colorIndex = sprite.colorIndex
//                    gameArray[sprite.column][sprite.row].minValue = sprite.minValue
//                    gameArray[sprite.column][sprite.row].maxValue = sprite.maxValue
//                    
                    sprite.BGPictureAdded = savedSpriteInCycle.BGPictureAdded
                    actionMoveArray.append(SKAction.move(to: savedSpriteInCycle.endPosition, duration: duration))
                    actionMoveArray.append(SKAction.run({
                    self.removeNodesWithName("\(self.emptySpriteTxt)-\(sprite.column)-\(sprite.row)")
//                        if self.childNodeWithName("\(self.emptySpriteTxt)-\(sprite.column)-\(sprite.row)") != nil {
//                            self.childNodeWithName("\(self.emptySpriteTxt)-\(sprite.column)-\(sprite.row)")!.removeFromParent()
//                        }
                    }))
                    sprite.run(SKAction.sequence(actionMoveArray))
                    sprite.reload()
                    
                case .fallingMovingSprite:
//                    let sprite = self.childNodeWithName(savedSpriteInCycle.name)! as! MySKNode
                    actionMoveArray.append(SKAction.move(to: savedSpriteInCycle.endPosition, duration: duration))
                    
                case .fallingSprite:
                    let sprite = self.childNode(withName: savedSpriteInCycle.name)! as! MySKNode
                    sprite.startPosition = savedSpriteInCycle.startPosition
                    let moveFallingSprite = SKAction.move(to: savedSpriteInCycle.startPosition, duration: duration)
                    sprite.run(SKAction.sequence([moveFallingSprite]))
                    
                case .mirrored:
                    //var sprite = self.childNodeWithName(savedSpriteInCycle.name)! as! MySKNode
                    actionMoveArray.append(SKAction.move(to: savedSpriteInCycle.endPosition, duration: duration))
                case .stopCycle: break
                case .nothing: break
                }
                if let savedSprite:SavedSprite = stack.pull() {
                    savedSpriteInCycle = savedSprite
                    if ((savedSpriteInCycle.status == .addedFromCardStack || savedSpriteInCycle.status == .addedFromShowCard) && stack.countChangesInStack() == 0) || stopSoon  || savedSpriteInCycle.status == .stopCycle {
                        stack.push(savedSpriteInCycle)
                        run = false
                    }
                    if savedSpriteInCycle.status == .movingStarted {
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
        //        if inFirstGenerateSprites {
        //            return
        //        }
        //let countTouches = touches.count
        
//        stopTimer(&showTippAtTimer)
        oldFromToColumnRow = FromToColumnRow()
//        lastGreenPair = nil
//        lastRedPair = nil
        lastPair.color = .none
        lineWidthMultiplier = lineWidthMultiplierNormal
        touchesBeganAt = Date()
        let firstTouch = touches.first
        let touchLocation = firstTouch!.location(in: self)
        
//        let testNode = self.nodeAtPoint(touchLocation)
        movedFromNode = nil
        let nodes = self.nodes(at: touchLocation)
        for nodesIndex in 0..<nodes.count {
            switch nodes[nodesIndex]  {
                case is MySKButton:
                    movedFromNode = (nodes[nodesIndex] as! MySKButton) as MySKNode
                    break
                case is MySKNode:
                    if (nodes[nodesIndex] as! MySKNode).type == .spriteType ||
                       (nodes[nodesIndex] as! MySKNode).type == .showCardType ||
                       (nodes[nodesIndex] as! MySKNode).type == .emptyCardType
                    {
                        movedFromNode = (nodes[nodesIndex] as! MySKNode)
                        if movedFromNode.type == .spriteType {
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
        
        if tremblingSprites.count > 0 {
            stopTrembling()
            removeNodesWithName(myLineName)
        }
    }
    
    func showValue(_ card: MySKNode)->SKLabelNode {
        let score = SKLabelNode()
        let delta = CGPoint(x: showValueDelta, y: showValueDelta)
        score.position = card.position + delta
        score.text = String(card.countScore)
        score.fontColor = UIColor.white
        score.fontName = "Helvetica Bold"
        score.fontSize = 30
        score.zPosition = 1000
        let showAction = SKAction.sequence([SKAction.fadeIn(withDuration: 0.5), SKAction.fadeOut(withDuration: 1.5), SKAction.removeFromParent()])
        let scoreActions = SKAction.group([showAction])
        score.run(scoreActions)
        return score
        
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //        if inFirstGenerateSprites {
        //            return
        //        }
        if movedFromNode != nil {
            removeNodesWithName(myLineName)

            //let countTouches = touches.count
            let firstTouch = touches.first
            let touchLocation = firstTouch!.location(in: self)
            
            var aktNode: SKNode? = movedFromNode
            
            let testNode = self.atPoint(touchLocation)
            let aktNodeType = analyzeNode(testNode)
//            var myLine: SKShapeNode = SKShapeNode()
            switch aktNodeType {
                case MyNodeTypes.LabelNode: aktNode = self.atPoint(touchLocation).parent as! MySKNode
                case MyNodeTypes.SpriteNode: aktNode = self.atPoint(touchLocation) as! MySKNode
                case MyNodeTypes.ButtonNode: aktNode = self.atPoint(touchLocation) as! MySKNode
                default: aktNode = nil
            }
            if movedFromNode.type == .showCardType {
                movedFromNode.position = touchLocation
                if showCardStack.count(.mySKNodeType) > 0 {
                    if !showCardFromStackAddedToParent {
                        showCardFromStackAddedToParent = true
                        showCardFromStack = showCardStack.last()
                        showCardFromStack!.position = cardPlaceButton!.position
                        showCardFromStack!.size = cardPlaceButton!.size
                        addChild(showCardFromStack!)
                    }
                } else if !cardPlaceButtonAddedToParent {
                    cardPlaceButtonAddedToParent = true
                    addChild(cardPlaceButton!)
                }
            }  else if movedFromNode == aktNode && tremblingSprites.count > 0 { // stop trembling
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
                            // nothing to do hier - update sets to fixed after 3.0 sec
                        } else { // other green pair found
                            lineWidthMultiplier = lineWidthMultiplierNormal
                            if lastPair.fixed {
                                if lastPair.changeTime == lastPair.startTime { // first time changed
                                    lastPair.changeTime = Date()
                                } else {
                                    if Date().timeIntervalSince(lastPair.changeTime) > 0.5 {
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
//        lineWidthMultiplier = lineWidthMultiplierNormal
//        stopTimer(&greenLineTimer)
        stopTrembling()
        let firstTouch = touches.first
        let touchLocation = firstTouch!.location(in: self)
        
        removeNodesWithName(myLineName)
        let testNode = self.atPoint(touchLocation)
        
        let aktNodeType = analyzeNode(testNode)
        if movedFromNode != nil && !stopped {
            //let countTouches = touches.count
            var aktNode: MySKNode?
            
            movedFromNode.zPosition = 0
            let startNode = movedFromNode
            
            switch aktNodeType {
            case MyNodeTypes.LabelNode: aktNode = testNode.parent as? MySKNode
            case MyNodeTypes.SpriteNode: aktNode = testNode as? MySKNode
            case MyNodeTypes.ButtonNode:
                aktNode = (testNode as! MySKNode).parent as? MySKNode
            default: aktNode = nil
            }
            
            if showFingerNode {
                if let node = self.childNode(withName: fingerName) {
                  node.removeFromParent()
                }
            }
            if aktNode != nil && aktNode!.type == .buttonType && startNode?.type == .buttonType && aktNode!.name == movedFromNode.name {
                //            if aktNode != nil && mySKNode.type == .ButtonType && startNode.type == .ButtonType  {
                var mySKNode = aktNode!
                
                //                var name = (aktNode as! MySKNode).parent!.name
                if mySKNode.name == buttonName {
                    mySKNode = (mySKNode.parent) as! MySKNode
                }
                //switch (aktNode as! MySKNode).name! {
                switch mySKNode.name! {
                    case "settings": settingsButtonPressed()
                    case "undo": undoButtonPressed()
                    case "restart": restartButtonPressed()
                    case "help": helpButtonPressed()
                    default: specialButtonPressed(mySKNode.name!)
                }
                return
            }
            
            if startNode!.type == .spriteType && (aktNode == nil || aktNode! != movedFromNode) {
                let sprite = movedFromNode// as! SKSpriteNode
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
                push(sprite!, status: .movingStarted)
                
                
                let countAndPushAction = SKAction.run({
                    self.push(sprite!, status: .mirrored)
                })
                
                let actionEmpty = SKAction.run({
                    self.makeEmptyCard((sprite?.column)!, row: (sprite?.row)!)
                })

                let speed: CGFloat = 0.001
                
                sprite?.zPosition += 5

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
                                self.addChild(self.showCountScore("+\(self.movedFromNode.countScore)", position: (sprite?.position)!))
                                self.playSound(soundArray[pointsIndex - 2], volume: GV.player!.soundVolume, soundPlayerIndex: pointsIndex - 2)
                            }))
                        }
                        
                        actionArray.append(countAndPushAction)
                        actionArray.append(SKAction.move(to: myPoints[pointsIndex], duration: Double((myPoints[pointsIndex] - myPoints[pointsIndex - 1]).length() * speed)))
                    }
                }
                var collisionAction: SKAction
                if actFromToColumnRow.toColumnRow.row == NoValue {
                    let containerNode = self.childNode(withName: containers[actFromToColumnRow.toColumnRow.column].name!) as! MySKNode
                    collisionAction = SKAction.run({
                        self.spriteDidCollideWithContainer(self.movedFromNode, node2: containerNode)
                    })
                } else {
                    let cardNode = self.childNode(withName: gameArray[actFromToColumnRow.toColumnRow.column][actFromToColumnRow.toColumnRow.row].name) as! MySKNode
                    collisionAction = SKAction.run({
                        self.spriteDidCollideWithMovingSprite(self.movedFromNode, node2: cardNode)
                    })
                }
                let userInteractionEnablingAction = SKAction.run({self.isUserInteractionEnabled = true})
                actionArray.append(collisionAction)
                actionArray.append(userInteractionEnablingAction)
                
                tippsButton!.activateButton(false)
                
                
                
                
                //let actionMoveDone = SKAction.removeFromParent()
                collisionActive = true
                lastMirrored = ""
                
                self.isUserInteractionEnabled = false  // userInteraction forbidden!
                countMovingSprites = 1
                self.waitForSKActionEnded = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CardGameScene.checkCountMovingSprites), userInfo: nil, repeats: false) // start timer for check
                
                movedFromNode.run(SKAction.sequence(actionArray))
                
            } else if startNode!.type == .spriteType && aktNode == movedFromNode {
                startTippTimer()
            } else if startNode?.type == .showCardType {
                var foundedCard: MySKNode?
                let nodes = self.nodes(at: touchLocation)
                var founded = false
                for index in 0..<nodes.count {
                    foundedCard = nodes[index] as? MySKNode
                   if nodes[index] is MySKNode && foundedCard!.type == .emptyCardType {
                        startNode?.column = foundedCard!.column
                        startNode?.row = foundedCard!.row
                        push(startNode!, status: .stopCycle)
                        push(startNode!, status: .addedFromShowCard)
                        startNode?.size = foundedCard!.size
                        startNode?.position = foundedCard!.position
                        startNode?.type = .spriteType
                        foundedCard!.removeFromParent()
                        founded = true
                        updateGameArrayCell(startNode!)
                        pullShowCard()
                        gameArrayChanged = true

                        break
                    } else if nodes[index] is MySKNode && foundedCard!.type == .spriteType && startNode?.colorIndex == foundedCard!.colorIndex &&
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
                            gameArray[(startNode?.column)!][(startNode?.row)!].minValue = foundedCard!.minValue
                            gameArray[(startNode?.column)!][(startNode?.row)!].maxValue = foundedCard!.maxValue
                            startNode?.removeFromParent()
                            pullShowCard()
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
    
    func createActionsForMirroring(_ sprite: MySKNode, adder: Int, color: MyColors, fromPoint: CGPoint, toPoint: CGPoint)->[SKAction] {
        var actions = [SKAction]()
        if color == .green {
            actions.append(SKAction.run({
                self.addChild(self.showCountScore("+\(adder)", position: sprite.position))
                self.push(sprite, status: .mirrored)
            }))
        }
        
//        actionArray.append(countAndPushAction)
        actions.append(SKAction.move(to: toPoint, duration: Double((toPoint - fromPoint).length() * speed)))

        return actions
    }
    
    func stopTrembling() {
        for index in 0..<tremblingSprites.count {
            tremblingSprites[index].tremblingType = .noTrembling
        }
        tremblingSprites.removeAll()
    }
    func pullShowCard() {
        showCard = nil
        if showCardStack.count(.mySKNodeType) > 0 {
            removeShowCardFromStack()
            showCard = showCardStack.pull()
            self.addChild(showCard!)
        } else if !cardPlaceButtonAddedToParent {
            addChild(cardPlaceButton!)
            cardPlaceButtonAddedToParent = true
        }
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
    
    func calculateSpritePosition(_ column: Int, row: Int) -> CGPoint {
        let cardPositionMultiplier = GV.deviceConstants.cardPositionMultiplier
        var x = spriteTabRect.origin.x
            x -= spriteTabRect.size.width / 2
            x += CGFloat(column) * tableCellSize
            x += tableCellSize / 2
        var y = spriteTabRect.origin.y
            y -= spriteTabRect.size.height / 3.0
            y += tableCellSize * cardPositionMultiplier / 2
            y += CGFloat(row) * tableCellSize * cardPositionMultiplier
        let point = CGPoint(
            x: x,
            y: y
        )
        return point
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
    
    
    func push(_ sprite: MySKNode, status: SpriteStatus) {
        var savedSprite = SavedSprite()
        savedSprite.type = sprite.type
        savedSprite.name = sprite.name!
        savedSprite.status = status
        savedSprite.startPosition = sprite.startPosition
        savedSprite.endPosition = sprite.position
        savedSprite.colorIndex = sprite.colorIndex
        savedSprite.size = sprite.size
        savedSprite.hitCounter = sprite.hitCounter
        savedSprite.countScore = levelScore
        savedSprite.minValue = sprite.minValue
        savedSprite.maxValue = sprite.maxValue
        savedSprite.column = sprite.column
        savedSprite.row = sprite.row
        stack.push(savedSprite)
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
        case is MySKNode:
            var mySKNode: MySKNode = (testNode as! MySKNode)
            switch mySKNode.type {
            case .containerType: return MyNodeTypes.ContainerNode
            case .spriteType, .emptyCardType, .showCardType: return MyNodeTypes.SpriteNode
            case .buttonType:
                if mySKNode.name == buttonName {
                    mySKNode = mySKNode.parent as! MySKNode
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
                prepareNextGame(true)
            }
            generateSprites(.first)
        } else {
            playMusic("MyMusic", volume: GV.player!.musicVolume, loops: playMusicForever)
            let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
            playerNameLabel.text = name
            doTimeCount = true
        }
    }
    
    func undoButtonPressed() {
        pull(true)
        freeUndoCounter -= 1
        let modifyer = freeUndoCounter > 0 ? 0 : freeUndoCounter > -freeAmount ? penalty : 2 * penalty
        scoreModifyer -= modifyer
        levelScore -= modifyer
        if modifyer > 0 {
            self.addChild(showCountScore("-\(modifyer)", position: undoButton!.position))
        }
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
    
    func checkCountMovingSprites() {
        if  countMovingSprites > 0 && countCheckCounts < 80 {
            countCheckCounts += 1
            self.waitForSKActionEnded = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CardGameScene.checkCountMovingSprites), userInfo: nil, repeats: false)
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

    
    func setMyDeviceConstants() {
        
        switch GV.deviceConstants.type {
        case .iPadPro12_9:
            labelFontSize = 20
            labelYPosProcent = 92
            labelHeight = 20
            showValueDelta = 80
            screwMultiplier = CGVector(dx: 0.48, dy: 0.35)
            labelBGPos = CGVector(dx: 0.5, dy: 0.958)
            labelBGSize = CGVector(dx: 0.95, dy: 0.06)
            containersPosCorr = CGPoint(x: 0.98, y: 0.85)
        case .iPadPro9_7:
            labelFontSize = 17
            labelYPosProcent = 90
            labelHeight = 18
            showValueDelta = 60
            screwMultiplier = CGVector(dx: 0.48, dy: 0.35)
            labelBGPos = CGVector(dx: 0.5, dy: 0.945)
            labelBGSize = CGVector(dx: 0.95, dy: 0.07)
            containersPosCorr = CGPoint(x: 0.98, y: 0.85)
        case .iPad2:
            labelFontSize = 17
            labelYPosProcent = 90
            labelHeight = 18
            showValueDelta = 60
            screwMultiplier = CGVector(dx: 0.48, dy: 0.35)
            labelBGPos = CGVector(dx: 0.5, dy: 0.945)
            labelBGSize = CGVector(dx: 0.95, dy: 0.07)
            containersPosCorr = CGPoint(x: 0.98, y: 0.85)
        case .iPadMini:
            labelFontSize = 17
            labelYPosProcent = 90
            labelHeight = 18
            showValueDelta = 50
            screwMultiplier = CGVector(dx: 0.48, dy: 0.35)
            labelBGPos = CGVector(dx: 0.5, dy: 0.945)
            labelBGSize = CGVector(dx: 0.95, dy: 0.08)
            containersPosCorr = CGPoint(x: 0.98, y: 0.85)
        case .iPhone6Plus:
            labelFontSize = 14
            labelYPosProcent = 88
            labelHeight = 15
            showValueDelta = 50
            screwMultiplier = CGVector(dx: 0.48, dy: 0.35)
            labelBGPos = CGVector(dx: 0.5, dy: 0.936)
            labelBGSize = CGVector(dx: 0.95, dy: 0.083)
            containersPosCorr = CGPoint(x: 0.98, y: 0.83)
        case .iPhone6:
            labelFontSize = 12
            labelYPosProcent = 88
            labelHeight = 13
            showValueDelta = 50
            screwMultiplier = CGVector(dx: 0.48, dy: 0.35)
            labelBGPos = CGVector(dx: 0.5, dy: 0.927)
            labelBGSize = CGVector(dx: 0.95, dy: 0.080)
            containersPosCorr = CGPoint(x: 0.98, y: 0.82)
        case .iPhone5:
            labelFontSize = 10
            labelYPosProcent = 87
            labelHeight = 12
            showValueDelta = 50
            screwMultiplier = CGVector(dx: 0.48, dy: 0.35)
            labelBGPos = CGVector(dx: 0.5, dy: 0.925)
            labelBGSize = CGVector(dx: 0.95, dy: 0.081)
            containersPosCorr = CGPoint(x: 0.98, y: 0.81)
        case .iPhone4:
            labelFontSize = 10
            labelYPosProcent = 87
            labelHeight = 10
            showValueDelta = 50
            screwMultiplier = CGVector(dx: 0.48, dy: 0.35)
            labelBGPos = CGVector(dx: 0.5, dy: 0.925)
            labelBGSize = CGVector(dx: 0.95, dy: 0.081)
            containersPosCorr = CGPoint(x: 0.98, y: 0.80)
        default:
            break
        }
        
    }
    


    

}
