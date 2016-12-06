//
//  MySKContainer.swift
//  JLines
//
//  Created by Jozsef Romhanyi on 13.07.15.
//  Copyright (c) 2015 Jozsef Romhanyi. All rights reserved.
//

enum MySKCardType: Int {
    case cardType = 0, containerType, buttonType, emptyCardType, showCardType
}

enum TremblingType: Int {
    case noTrembling = 0, changeSize, changeSizeOnce, changePos, changeDirection
}

// Global Variables
let NoValue = -1
let NoColor = 1000
let MaxColorValue = 4
let MaxCardValue = 13
let LastCardValue = MaxCardValue - 1
let FirstCardValue = 0

import SpriteKit

class MySKCard: SKSpriteNode {
    
//    enum CardStatus: Int {
//        case CardStack = 0, OnScreen, Deleted
//    }
//    struct Card {
//        let bitMaskForPackages: [UInt8] = [1, 2, 4, 8]
//        var status: CardStatus
//        var color: Int
//        var column: Int
//        var row: Int
//        var cardName: String
//        var originalValue: Int
//        var minValue: Int
//        var maxValue: Int
//        var deleted: Bool
//        var countTransitions: Int
//        var belongsToPkg: UInt8 // belongs to package
//        
//        init(color: Int, row: Int, column: Int, originalValue: Int, status: CardStatus, cardName: String) {
//            self.color = color
//            self.status = status
//            self.column = column
//            self.row = row
//            self.originalValue = originalValue
//            self.cardName = cardName
//            self.minValue = originalValue
//            self.maxValue = originalValue
//            self.deleted = false
//            self.belongsToPkg = 0
//            self.countTransitions = 0
//            for i in 0...countPackages - 1 {
//                belongsToPkg += bitMaskForPackages[i]
//            }
//        }
//    }
    
//    struct CardIndex: Hashable {
//        var hashValue: Int {
//            get {
//                return packageIndex * 1000 + colorIndex * 100 + origValue
//            }
//        }
//        var packageIndex: Int
//        var colorIndex: Int
//        var origValue: Int
//        static func ==(left: CardIndex, right: CardIndex) -> Bool {
//            return left.hashValue == right.hashValue
//        }
//
//    }
    
    override var size: CGSize {
        didSet {
            if oldValue != CGSize(width: 0,height: 0) && (type != .buttonType) {
                minValueLabel.fontSize = size.width * fontSizeMultiplier
                maxValueLabel.fontSize = size.width * fontSizeMultiplier
                let positionOffset = CGPoint(x: self.size.width * offsetMultiplier.x,  y: self.size.height * offsetMultiplier.y)
                minValueLabel.position = positionOffset
                maxValueLabel.position = positionOffset
                if BGPictureAdded {
                    BGPicture.size = size
                }
//              print("name: \(name), type: \(type), size: \(size), self.position: \(position), minValueLabel.position: \(minValueLabel.position)")
            }
        }
    }
    private var colorIndex = NoColor
    private var column = 0
    private var row = 0
    private var origValue: Int
    private var minValue: Int
    private var maxValue: Int
    private var countTransitions = 0
    private var belongsToPackage = NoValue
    private var card: Card?
    private var isCard = false
    private var cardIndex = CardIndex(packageIndex: 0, colorIndex: 0,origValue: 0)
    private var startPosition = CGPoint.zero
    private var OKPackages: Set<Int> = Set()
    var countScore: Int {
        get {
            return(calculateScore())
//            let midValue = Double(minValue + maxValue + 2) / Double(2)
//            return Int(midValue * Double((maxValue - minValue + 1)))
        }
    }
    private var mirrored: Int
    private let device = GV.deviceType
    private let modelConstantLocal = UIDevice.current.modelName

    private var origSize = CGSize(width: 0, height: 0)

    var trembling: CGFloat = 0
    var tremblingType: TremblingType = .noTrembling {
        didSet {
            if oldValue != tremblingType {
                if tremblingType == .noTrembling {
                    self.size = self.origSize
                    trembling = 0
                } else {
                    self.origSize = self.size
                }
            }
        }
    }
    
    

//    private var hitCounter: Int = 0

    private var type: MySKCardType
    private var hitLabel = SKLabelNode()
    private var maxValueLabel = SKLabelNode()
    private var minValueLabel = SKLabelNode()
    private var packageLabel = SKLabelNode()
    private var BGPicture = SKSpriteNode()
    private var BGPictureAdded = false
    
    private let cardLib: [Int:String] = [
        0:"A", 1:"2", 2:"3", 3:"4", 4:"5", 5:"6", 6:"7", 7:"8", 8:"9", 9:"10", 10: GV.language.getText(.tcj), 11: GV.language.getText(.tcd), 12: GV.language.getText(.tck), NoColor: ""]
    
    private let fontSizeMultiplier: CGFloat = 0.35
    private let offsetMultiplier = CGPoint(x: -0.48, y: 0.48)
    private let BGOffsetMultiplier = CGPoint(x: -0.10, y: 0.25)
    

    init(texture: SKTexture, type:MySKCardType, value: Int = 0, card: Card? = nil) {
        //let modelMultiplier: CGFloat = 0.5 //UIDevice.currentDevice().modelSizeConstant
        self.type = type
        self.card = card
        
//        if card == nil {
//            self.card = Card(color: <#T##Int#>, row: <#T##Int#>, column: <#T##Int#>, originalValue: <#T##Int#>, status: <#T##MySKCard.CardStatus#>, cardName: <#T##String#>)
//        }
        self.minValue = value
        self.maxValue = value
        self.origValue = value
        self.mirrored = 0
        
        
        
        
//        switch type {
//        case .containerType, .emptyCardType, .showCardType:
//            hitCounter = 0
//        case .buttonType:
//            hitCounter = 0
//        case .cardType:
//            hitCounter = 1
//        }
        
        

        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        
        if card != nil {
            self.colorIndex = card!.colorIndex
            self.minValue = card!.minValue
            self.maxValue = card!.maxValue
            self.origValue = card!.originalValue
            self.name = card!.name
        }
        
        if value > NoValue {
            isCard = true
        }

        if type == .buttonType {
            hitLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
            hitLabel.fontSize = 20;
            hitLabel.zPosition = self.zPosition + 1
        } else {
            
            hitLabel.position = CGPoint(x: self.position.x, y: self.position.y + self.size.width * 0.08)
            hitLabel.fontSize = 15;
//            hitLabel.text = "\(hitCounter)"
            
            //print(minValue, text)
            setLabelText(minValueLabel, value: minValue, dotCount: belongsToPackage == NoValue ? 0 : belongsToPackage)
            minValueLabel.zPosition = self.zPosition + 1
            
            
        }
        
        setLabel(hitLabel, fontSize: 15)
        setLabel(maxValueLabel, fontSize: size.width * fontSizeMultiplier)
        setLabel(minValueLabel, fontSize: size.width * fontSizeMultiplier)
        

        
        if isCard {
            if minValue == NoColor {
                switch type {
                    case .containerType: alpha = 0.5
                    case .emptyCardType: alpha = 0.1
                    default: alpha = 1.0
                }
            }
            self.addChild(minValueLabel)
        } else {
            self.addChild(hitLabel)
        }

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLabel(_ label: SKLabelNode, fontSize: CGFloat) {
        label.fontName = "ArielItalic"
        label.fontColor = SKColor.black
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top
        label.isUserInteractionEnabled = false
    }
    
    func reload() {
        if isCard {
            setLabelText(minValueLabel, value: minValue, dotCount: countTransitions == 0 ? 0 : countTransitions)
            setLabelText(maxValueLabel, value: maxValue, dotCount: countTransitions == 0 ? 0 : countTransitions + 1)
            if minValue != NoColor {
                self.alpha = 1.0
            } else {
                switch type {
                    case .containerType: alpha = 0.5
                    case .emptyCardType: alpha = 0.1
                    default: alpha = 1.0
                }
            }
            let BGPicturePosition = CGPoint(x: self.size.width * BGOffsetMultiplier.x, y: self.size.height * BGOffsetMultiplier.y)
            let bgPictureName = "BGPicture"
            if minValue != maxValue  || countTransitions > 0  {
                if !BGPictureAdded {
                    if self.childNode(withName: bgPictureName) == nil {
                        self.addChild(BGPicture)
                        BGPicture.addChild(maxValueLabel)
                        BGPicture.name = bgPictureName
                        BGPicture.alpha = 1.0
                    }
                    BGPicture.texture = self.texture
                    BGPictureAdded = true
                    BGPicture.position = BGPicturePosition // CGPointMake(-3, 25)
                    BGPicture.size = size
                    self.zPosition = 0
                    BGPicture.zPosition = self.zPosition - 1
                    BGPicture.isUserInteractionEnabled = false
                    //maxValueLabel.position = positionOffset //CGPointMake(-20, 35)
                    maxValueLabel.zPosition = self.zPosition + 1
                    //minValueLabel.zPosition = maxValueLabel.zPosition + 1
                }
            } else {
                if BGPictureAdded || self.childNode(withName: bgPictureName) != nil {
                    maxValueLabel.removeFromParent()
                    BGPicture.removeFromParent()
                    BGPictureAdded = false
                    if type == .containerType && minValue == NoValue {
                        self.alpha = 0.5
                    }
                } else {
                    if colorIndex == NoColor {
                        self.texture = atlas.textureNamed("emptycard")
                    }
                }
            }
        } else {
//            hitLabel.text = "\(hitCounter)"
        }

    }

    func setLabelText(_ label: SKLabelNode, value: Int, dotCount: Int) {
        guard let text = cardLib[minValue == NoColor ? NoColor : value % MaxCardValue] else {
            return
        }
        let starString = " " + String(repeating: "*", count: dotCount)
        label.text = "\(value == 10 ? " " : "")\(text + starString)"
    }
    
    func getMirroredScore() -> Int {
        return countScore * mirrored
    }
    
    func calculateScore()->Int {
        var actValue: Int
        if countTransitions == 0 {
            let midValue = Double(minValue + maxValue + 2) / Double(2)
            actValue = Int(midValue * Double((maxValue - minValue + 1)))
        } else {
            var midValue = Double(minValue + LastCardValue + 2) / Double(2)
            actValue = Int(midValue * Double((LastCardValue - minValue + 1)))
            midValue = Double(maxValue + 2) / Double(2)
            actValue += Int(midValue * Double((maxValue + 1)))
            actValue += countTransitions == 1 ? 0 : 91 * (countTransitions - 1)
        }
        return actValue
    }
    
    func getColumnRow()->(column: Int, row: Int) {
        return (self.column, self.row)
    }
    
    func setColumnRow(column: Int, row: Int) {
        self.column = column
        self.row = row
    }
    func getColorIndex() -> Int {
        return colorIndex
    }
    func setColorIndex(colorIndex: Int) {
        self.colorIndex = colorIndex
    }
    
    func getMinValue()->Int {
        return self.minValue
    }
    
    func setMinValue(minValue: Int) {
        self.minValue = minValue
    }

    func getMaxValue()->Int {
        return self.maxValue
    }
    
    func setMaxValue(maxValue: Int) {
        self.maxValue = maxValue
    }
    
    func getOrigValue()->Int {
        return self.origValue
    }
    
    func getCountTransitions()->Int{
        return self.countTransitions
    }
    
    func getOrigSize() -> CGSize {
        return self.origSize
    }
    
    func getType()-> MySKCardType {
        return self.type
    }
    
    func getStartPosition()->CGPoint {
        return self.startPosition
    }
    
    func getMirrored()->Int {
        return self.mirrored
    }
    
    func getBelongsToPackage()->Int {
        return self.belongsToPackage
    }
    
    func setParam(column: Int? = nil,
                  row: Int? = nil,
                  colorIndex: Int? = nil,
                  minValue: Int? = nil,
                  maxValue: Int? = nil,
                  belongsToPackage: Int? = nil,
                  BGPictureAdded: Bool? = nil,
                  startPosition: CGPoint? = nil,
                  type: MySKCardType? = nil,
                  mirrored: Int? = nil) {
        if column != nil {
            self.column = column!
        }
        if row != nil {
            self.row = row!
        }
        if colorIndex != nil {
            self.colorIndex = colorIndex!
        }
        if minValue != nil {
            self.minValue = minValue!
        }
        if maxValue != nil {
            self.maxValue = maxValue!
        }
        if belongsToPackage != nil {
            self.belongsToPackage = belongsToPackage!
        }
        if BGPictureAdded != nil {
            self.belongsToPackage = belongsToPackage!
        }
        if startPosition != nil {
            self.startPosition = startPosition!
        }
        if type != nil {
            self.type = type!
        }
        if mirrored != nil {
            self.mirrored = mirrored!
        }
    }
    
    func connectWith(otherCard: MySKCard) {

        self.countTransitions += otherCard.countTransitions
        if self.minValue == otherCard.maxValue + 1 {
            self.minValue = otherCard.minValue
        } else if self.maxValue == otherCard.minValue - 1 {
            self.maxValue = otherCard.maxValue
        } else if self.minValue == FirstCardValue && otherCard.maxValue == LastCardValue {
            self.minValue = otherCard.minValue
            countTransitions += 1
        } else if self.maxValue == LastCardValue && otherCard.minValue == FirstCardValue {
            self.maxValue = otherCard.maxValue
            countTransitions += 1
        } else if self.maxValue == NoColor {  // empty Container
            self.maxValue = otherCard.maxValue
            self.minValue = otherCard.minValue
        }
//        var countCardsInThisPackage = 0
//        switch countTransitions {
//        case 0:
//            countCardsInThisPackage = maxValue - minValue + 1
//        case 1:
//            countCardsInThisPackage = maxValue + 1 + LastCardValue - minValue + 1
//        case 2:
//            countCardsInThisPackage = maxValue + 1 + LastCardValue - minValue + 1 + 13
//        case 3:
//            countCardsInThisPackage = maxValue + 1 + LastCardValue - minValue + 1 + 26
//        default:
//            break
//        }
//        print("countCardsInThisPackage: \(countCardsInThisPackage)")
    }
    
    
    
//    func setCardValues(color: Int? = nil, row: Int? = nil, column: Int? = nil, minValue: Int? = nil, maxValue: Int? = nil, status: CardStatus? = nil) {
//        var card = MySKCard.cards[cardIndex]
//        if color != nil {
//            card!.color = color!
//        }
//        if row != nil {
//            card!.row = row!
//        }
//        if column != nil {
//            card!.column = column!
//        }
//        if minValue != nil {
//            card!.minValue = minValue!
//        }
//        if maxValue != nil {
//            card!.maxValue = maxValue!
//        }
//        if status != nil {
//            card!.status = status!
//        }
//        MySKCard.cards[cardIndex] = card
//    }
    
    
    
    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
//    static var cardIndexArray: [CardIndex] = []
//    static var cards: [CardIndex:Card] = [:]
//    static var countPackages: Int = 0
//    
//
//    
//    static func getRandomCard(random: MyRandom?)->(MySKCard, Bool) {
//        let index = random!.getRandomInt(0, max: cardIndexArray.count - 1)
//        let cardIndex = cardIndexArray[index]
//        let color = cards[cardIndex]!.colorIndex
//        let texture = atlas.textureNamed ("card\(color)")
//        let card = cards[cardIndex]
//        cardIndexArray.remove(at: index)
//        let newCard = MySKCard(texture: texture, type: .cardType, card: card!)
//        return (newCard, cardIndexArray.count != 0)
//    }
//    static func setCountPackages(countPackages: Int) {
//        self.countPackages = countPackages
//        
//    }
//    
//    static func cleanForNewGame() {
//        cards.removeAll()
//        // generate all cards
//        for pkgIndex in 0..<countPackages {
//            for colorIndex in 0..<MaxColorValue {
//                for cardIndex in 0..<MaxCardValue {
//                    let index = CardIndex(packageIndex: pkgIndex, colorIndex: colorIndex, origValue: cardIndex)
//                    cardIndexArray.append(index)
//                    let name = "\(pkgIndex)-\(colorIndex)-\(cardIndex)"
//                    cards[index] = Card(color: colorIndex, row: NoValue, column: NoValue, originalValue: cardIndex, status: .CardStack, cardName: name)
//                }
//            }
//                    
//        }
//        
//    }
//    
//    static func areConnectable(first: GameArrayPositions, second: GameArrayPositions, secondIsContainer: Bool = false)->Bool {
//        if first.colorIndex == second.colorIndex &&
//            (first.minValue == second.maxValue + 1 ||
//             first.maxValue == second.minValue - 1 ||
//                (countPackages > 1 && first.maxValue == LastCardValue && second.minValue == FirstCardValue) ||
//                (countPackages > 1 && first.minValue == FirstCardValue && second.maxValue == LastCardValue && !secondIsContainer))
//        {
//            return true
//        }
//        
//        return false
//        
//    }
//
    
//    deinit {
//        if type == .cardType {
//            game.cards[cardIndex]!.status = .Deleted
//            MySKCard.cards[cardIndex]!.belongsToPkg = 0
//        }
//    }
//
}
