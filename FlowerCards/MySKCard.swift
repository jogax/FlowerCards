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
    
    enum CardStatus: Int {
        case CardStack = 0, OnScreen, Deleted
    }
    struct Card {
        var color: Int
        var status: CardStatus
        var row: Int
        var column: Int
        var cardName: String
        var originalValue: Int
        var minValue: Int
        var maxValue: Int
        var deleted: Bool
        var countTransitions: Int
        var belongsToPkg: UInt8 // belongs to package
        
        init(color: Int, row: Int, column: Int, originalValue: Int, status: CardStatus, cardName: String) {
            self.color = color
            self.status = status
            self.row = row
            self.column = column
            self.originalValue = originalValue
            self.cardName = cardName
            self.minValue = originalValue
            self.maxValue = originalValue
            self.deleted = false
            self.belongsToPkg = 0
            self.countTransitions = 0
        }
    }
    
    struct CardIndex: Hashable {
        var hashValue: Int {
            get {
                return packageIndex * 1000 + colorIndex * 100 + origValue
            }
        }
        var packageIndex: Int
        var colorIndex: Int
        var origValue: Int
        static func ==(left: CardIndex, right: CardIndex) -> Bool {
            return left.hashValue == right.hashValue
        }

    }
    
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
    private static let bitMaskForPackages: [UInt8] = [1, 2, 4, 8]
    private static let colorNames = ["Purple", "Blue  ", "Green ", "Red   "]
    var column = 0
    var row = 0
    var isCard = false
//    var cardIndex = CardIndex(packageIndex: 0, colorIndex: 0,origValue: 0)
    var colorIndex = NoColor
    var startPosition = CGPoint.zero
    var minValue: Int
    var maxValue: Int
    var origValue: Int
    
    var belongsToPackageMin: UInt8 = 0
    var belongsToPackageMax: UInt8 = 0
    
    var countTransitions = 0
    var countScore: Int {
        get {
            return(calculateScore())
//            let midValue = Double(minValue + maxValue + 2) / Double(2)
//            return Int(midValue * Double((maxValue - minValue + 1)))
        }
    }
    var mirrored: Int
    let device = GV.deviceType
    let modelConstantLocal = UIDevice.current.modelName

    var origSize = CGSize(width: 0, height: 0)

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
    
    

//    var hitCounter: Int = 0

    var type: MySKCardType
    var hitLabel = SKLabelNode()
    var maxValueLabel = SKLabelNode()
    var minValueLabel = SKLabelNode()
    var packageLabel = SKLabelNode()
    var BGPicture = SKSpriteNode()
    var BGPictureAdded = false
    
    let cardLib: [Int:String] = [
        0:"A", 1:"2", 2:"3", 3:"4", 4:"5", 5:"6", 6:"7", 7:"8", 8:"9", 9:"10", 10: GV.language.getText(.tcj), 11: GV.language.getText(.tcd), 12: GV.language.getText(.tck), NoColor: ""]
    
    let fontSizeMultiplier: CGFloat = 0.35
    let offsetMultiplier = CGPoint(x: -0.48, y: 0.48)
    let BGOffsetMultiplier = CGPoint(x: -0.10, y: 0.25)
    
    convenience init() {
        self.init(colorIndex: NoColor, type: .emptyCardType, value: NoColor)
    }
    
    convenience init(colorIndex: Int, type:MySKCardType, value: Int = 0, card: Card? = nil) {
        let texture = colorIndex == NoColor ? atlas.textureNamed("emptycard") : atlas.textureNamed ("card\(colorIndex)")
        self.init(texture: texture, type: type, value: value, card: card)
    }

    init(texture: SKTexture, type:MySKCardType, value: Int = 0, card: Card? = nil) {
        //let modelMultiplier: CGFloat = 0.5 //UIDevice.currentDevice().modelSizeConstant
        self.type = type
        self.minValue = value
        self.maxValue = value
        self.origValue = value
        self.mirrored = 0
        for i in 0...MySKCard.countPackages - 1 {
            belongsToPackageMin += MySKCard.bitMaskForPackages[i]
            belongsToPackageMax += MySKCard.bitMaskForPackages[i]
        }
        
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        
        if card != nil {
            self.colorIndex = card!.color
            self.minValue = card!.minValue
            self.maxValue = card!.maxValue
            self.origValue = card!.originalValue
            self.name = card!.cardName
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
            setLabelText(minValueLabel, value: minValue, dotCount: calculateDotCount(forMinLabel: true))
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
    
    func calculateDotCount(forMinLabel: Bool)->Int {
        if self.type == .containerType && self.colorIndex != NoValue {
            if forMinLabel {
                return MySKCard.countPackages == 1 ? 0 : MySKCard.countPackages - self.countTransitions
            } else {
                return MySKCard.countPackages == 1 ? 0 : MySKCard.countPackages
            }
        }
        if self.countTransitions == 0 {
            return 0
        }
        var maxDotCount = 0
        if self.belongsToPackageMax == MySKCard.allPackages {
            maxDotCount = MySKCard.countPackages
        } else if countTransitions > 0 {
            maxDotCount = countTransitions + 1
        }
        
        if forMinLabel {
            return maxDotCount - countTransitions
        }
        return maxDotCount
    }
    
    func setLabel(_ label: SKLabelNode, fontSize: CGFloat) {
        label.fontName = "ArialMT"
        label.fontColor = SKColor.black
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top
        label.isUserInteractionEnabled = false
    }
    
    func reload() {
        if isCard {
            setLabelText(minValueLabel, value: minValue, dotCount: calculateDotCount(forMinLabel: true))
            setLabelText(maxValueLabel, value: maxValue, dotCount: calculateDotCount(forMinLabel: false))
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
        let starString = "" + String(repeating: "*", count: dotCount)
        label.text = "\(value == 10 ? "" : "")\(text + starString)"
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
    
    
    func connectWith(otherCard: MySKCard) {
        #if TEST
            let cardCountTxt = (MySKCard.cardCount > 100 ? "" : MySKCard.cardCount > 9 ? " " : "  ") + String(MySKCard.cardCount)
            MySKCard.cardCount += 1
            if MySKCard.cardCount == 92 {//67 {
                MySKCard.cardCount = 126  // aussteigein wenn problemfall erreicht
            }
            let text1 = "\(cardCountTxt) move \(MySKCard.colorNames[colorIndex]) \(createCardText(card: otherCard, from: true)) to \(createCardText(card: self, from: false))"
        #endif
        self.countTransitions += otherCard.countTransitions
        if self.minValue == otherCard.maxValue + 1 {
            self.minValue = otherCard.minValue
//            self.belongsToPackageMax = self.belongsToPackageMax & otherCard.belongsToPackageMax
//            self.belongsToPackageMin = self.belongsToPackageMin & otherCard.belongsToPackageMin
//            if self.type == .containerType {
//                resetMaxPackageAtMyBrothers()
//            }
        } else if self.maxValue == otherCard.minValue - 1 {
            self.maxValue = otherCard.maxValue
//            self.belongsToPackageMax = self.belongsToPackageMax & otherCard.belongsToPackageMax
//            self.belongsToPackageMin = self.belongsToPackageMin & otherCard.belongsToPackageMin
        } else if self.minValue == FirstCardValue && otherCard.maxValue == LastCardValue {  // move K to A
            self.minValue = otherCard.minValue
            countTransitions += 1
//            setMyBelongingFlags()
        } else if self.maxValue == LastCardValue && otherCard.minValue == FirstCardValue { // move A to K
            self.maxValue = otherCard.maxValue
            countTransitions += 1
//            setMyBelongingFlags()
        } else if self.maxValue == NoColor {  // empty Container
            self.maxValue = otherCard.maxValue
            self.minValue = otherCard.minValue
//            self.belongsToPackageMax = MySKCard.maxPackage
//            self.belongsToPackageMin = self.belongsToPackageMax >> UInt8(self.countTransitions)
//            resetMaxPackageAtMyBrothers()
        }
        #if TEST
            print("\(text1): new \(createCardText(card: self, from: false))")
        #endif
        
    }
    
    #if TEST
    func createCardText(card: MySKCard, from: Bool)->String {
        let minValueText = (cardLib[card.minValue]! == "10" ? "" : " ") + cardLib[card.minValue]!
        let maxValueText = (cardLib[card.maxValue]! == "10" ? "" : " ") + cardLib[card.maxValue]!
        return "\(card.type == .containerType ? "Container" : "Card     ")(\(maxValueText)-\(minValueText)) \(from ? "from" : "at") [\(card.column):\(card.row)]"
    }
    #endif
    
    
    func getTexture(color: Int)->SKTexture {
        if color == NoColor {
            return atlas.textureNamed("emptycard")
        } else {
            return atlas.textureNamed ("card\(color)")
        }
    }

    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static var cardIndexArray: [CardIndex] = []
    static var cards: [CardIndex:Card] = [:]
    static var countPackages: Int = 0
    static var allPackages: UInt8 = 0
    static var maxPackage: UInt8 = 0
    static var minPackage: UInt8 = 0
    #if TEST
    static var cardCount: Int = 0
    #endif
    

    
    static func getRandomCard(random: MyRandom?)->(MySKCard, Bool) {
        let index = random!.getRandomInt(0, max: cardIndexArray.count - 1)
        let cardIndex = cardIndexArray[index]
        let color = cards[cardIndex]!.color
//        let texture = atlas.textureNamed ("card\(color)")
        let card = cards[cardIndex]
        cardIndexArray.remove(at: index)
        let newCard = MySKCard(colorIndex: color, type: .cardType, card: card)
        return (newCard, cardIndexArray.count != 0)
    }
    
    static func cleanForNewGame(countPackages: Int) {
        self.countPackages = countPackages
        self.allPackages = 0
        cardCount = 1
        for packageNr in 0..<countPackages {
            self.allPackages += bitMaskForPackages[packageNr]
        }
        self.maxPackage = bitMaskForPackages[countPackages - 1]
        self.minPackage = bitMaskForPackages[0]
        cards.removeAll()
        // generate all cards
        for pkgIndex in 0..<countPackages {
            for colorIndex in 0..<MaxColorValue {
                for cardIndex in 0..<MaxCardValue {
                    let index = CardIndex(packageIndex: pkgIndex, colorIndex: colorIndex, origValue: cardIndex)
                    cardIndexArray.append(index)
                    let name = "\(pkgIndex)-\(colorIndex)-\(cardIndex)"
                    cards[index] = Card(color: colorIndex, row: NoValue, column: NoValue, originalValue: cardIndex, status: .CardStack, cardName: name)
                }
            }
                    
        }
        
    }
    
    
    static func areConnectable(first: MySKCard, second: MySKCard)->Bool {
//        let (countAllTransitions, _) = findMyBrothers(me: first)
//        analyzeGame(colorIndex: first.colorIndex)
        if first.colorIndex == second.colorIndex &&
            ((first.minValue == second.maxValue + 1 && first.belongsToPackageMin & second.belongsToPackageMax != 0) ||
             (first.maxValue == second.minValue - 1 && first.belongsToPackageMax & second.belongsToPackageMin != 0) ||
                (countPackages > 1 &&
                    first.maxValue == LastCardValue &&
                    second.minValue == FirstCardValue &&
                    second.belongsToPackageMin & ~minPackage != 0 &&
                    first.belongsToPackageMax & ~maxPackage != 0 &&
                    first.countTransitions + second.countTransitions + 1 <= countPackages - 1) ||
                (countPackages > 1 &&
                    first.minValue == FirstCardValue &&
                    second.maxValue == LastCardValue &&
                    first.belongsToPackageMin & ~minPackage != 0 &&
                    second.belongsToPackageMax & ~maxPackage != 0 &&
                    first.countTransitions + second.countTransitions + 1 <= countPackages - 1))
        {
            return true
        }
        
        return false
        
    }
    
    static func analyzeGame(colorIndex: Int) {
        var usedCardValues: [[Bool]] = []
        for _ in 1...countPackages {
            usedCardValues.append(Array(repeating: false, count: MaxCardValue))
        }

        var countTransitionsForColor = 0
        var containerValues = [Int]()
        var actContainer: MySKCard? = nil
        for container in containers {
            if container.colorIndex == colorIndex {
                actContainer = container
                container.belongsToPackageMax = MySKCard.maxPackage
                container.belongsToPackageMin = 0
                container.belongsToPackageMin = MySKCard.bitMaskForPackages[MySKCard.countPackages - container.countTransitions - 1]
                countTransitionsForColor = container.countTransitions
                containerValues = findCardValues(card: container)
                for index in 0..<containerValues.count {
                    let myIndex = containerValues[containerValues.count - index - 1]
                    let packageIndex = countPackages - (index / MaxCardValue) - 1
                    usedCardValues[packageIndex][myIndex] = true
                }

            }
        }
        // search cards with countTransitions > 0
        var myCards: [MySKCard] = []
        var cardsWithTransitions: [MySKCard] = []
        for gameRow in gameArray {
            for game in gameRow {
                if game.used && game.card.colorIndex == colorIndex {
                    if game.card.countTransitions > 0 {
                        cardsWithTransitions.append(game.card)
                        countTransitionsForColor += game.card.countTransitions
                    }
                    game.card.belongsToPackageMin = allPackages
                    game.card.belongsToPackageMax = allPackages
                    myCards.append(game.card)
                }
            }
        }
        for card in cardsWithTransitions {
            let cardValues = findCardValues(card: card)
            for index in 0..<cardValues.count {
            }
        }
        for myCard in myCards {
            if countTransitionsForColor == countPackages - 1 {
                if myCard.countTransitions == 0 {
                    
                } else {
//                    hier analyse the cardsWithTransitions
//                    nothing to do
                }
            }
        }
    }
    
    private static func findCardValues(card: MySKCard)->[Int] {
        var cardValues: [Int] = []
        var value = card.minValue
        var countValues = 0
        if card.countTransitions == 0 {
            countValues = card.maxValue - card.minValue + 1
        } else {
            countValues = card.maxValue + MaxCardValue - card.minValue + 1 + (MaxCardValue * (card.countTransitions - 1))
        }
        for _ in 0..<countValues {
            cardValues.append(value)
            value += 1
            if value > LastCardValue {
                value = 0
            }
        }
        return cardValues
    }
    
    deinit {
        if type == .cardType {
//            MySKCard.cards[cardIndex]!.status = .Deleted
//            MySKCard.cards[cardIndex]!.belongsToPkg = 0
        }
    }

}
