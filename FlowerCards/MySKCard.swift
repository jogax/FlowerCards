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
    
    var cardHashValue: Int {
        get {
            let hash = column |
                row << 4 |
                colorIndex << 8 |
                minValue << 12 |
                maxValue << 16 |
                countTransitions << 20
            return hash
        }
    }

    static func ==(left: MySKCard, right: MySKCard)->Bool {
        return left.cardHashValue == right.cardHashValue
    }
//    static func !=(left: MySKCard, right: MySKCard)->Bool {
//        return left.cardHashValue != left.cardHashValue
//    }
    
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
        var maxValue: Int
        var minValue: Int
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
                standardFontSize = size.width * fontSizeMultiplier
                fontSize10 = size.width * fontSizeMultiplier * 0.85
                maxPackageLabel.fontSize = size.width * packageFontSizeMultiplier
                minPackageLabel.fontSize = size.width * packageFontSizeMultiplier
                let valueOffsetMultiplier = CGPoint(x: -0.48, y: 0.48)
                let packageOffsetMultiplier = CGPoint(x: -0.10, y: 0.48)
                let positionOffset = CGPoint(x: self.size.width * valueOffsetMultiplier.x,  y: self.size.height * valueOffsetMultiplier.y)
                let packageOffset = CGPoint(x:self.size.width * packageOffsetMultiplier.x,  y: self.size.height * packageOffsetMultiplier.y)
                minValueLabel.position = positionOffset
                maxValueLabel.position = positionOffset
                minPackageLabel.position = packageOffset
                maxPackageLabel.position = packageOffset
                if BGPictureAdded {
                    BGPicture.size = size
                }
//              print("name: \(name), type: \(type), size: \(size), self.position: \(position), minValueLabel.position: \(minValueLabel.position)")
            }
        }
    }
    private static let bitMaskForPackages: [UInt8] = [1, 2, 4, 8]
    private static let colorNames = ["Purple", "Blue  ", "Green ", "Red   "]
    var type: MySKCardType
    var colorIndex = NoColor
    var column = 0
    var row = 0
    var maxValue: Int
    var minValue: Int
    var belongsToPackageMax: UInt8 = 0
    var belongsToPackageMin: UInt8 = 0
    var countTransitions = 0
    
    var startPosition = CGPoint.zero
    var countScore: Int {
        get {
            return(calculateScore())
//            let midValue = Double(minValue + maxValue + 2) / Double(2)
//            return Int(midValue * Double((maxValue - minValue + 1)))
        }
    }
    var origValue: Int
    var isCard = false
    var mirrored: Int
    let device = GV.deviceType
    let modelConstantLocal = UIDevice.current.modelName
    var printValue: String {
        get {
            var value = String(type == .cardType ? "Card:" : "Container:") + "color: " + MySKCard.colorNames[colorIndex]
            value += ", column: " + String(column) + ", row: " + String(row)
            value += ", max: " + cardLib[maxValue]! + ", min: " + cardLib[minValue]!
            value += ", belongs: " + String(belongsToPackageMax) + "/" + String(belongsToPackageMin)
            value += ", transitions: " + String(countTransitions)
            return value
        }
    }
    var countCards: Int {
        get {
            if countTransitions == 0 {
                return maxValue - minValue + 1
            } else {
                return maxValue + 1 + (countTransitions - 1) * MaxCardValue + LastCardValue - minValue + 1
            }
        }
    }
    

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

    var hitLabel = SKLabelNode()
    var maxValueLabel = SKLabelNode()
    var minValueLabel = SKLabelNode()
    var maxPackageLabel = SKLabelNode()
    var minPackageLabel = SKLabelNode()
    var BGPicture = SKSpriteNode()
    var BGPictureAdded = false
    private var standardFontSize: CGFloat = 0
    private var fontSize10: CGFloat = 0
    
    let cardLib: [Int:String] = [
        0:"A", 1:"2", 2:"3", 3:"4", 4:"5", 5:"6", 6:"7", 7:"8", 8:"9", 9:"10", 10: GV.language.getText(.tcj), 11: GV.language.getText(.tcd), 12: GV.language.getText(.tck), NoColor: ""]
    
    let fontSizeMultiplier: CGFloat = 0.38
    let packageFontSizeMultiplier: CGFloat = 0.28
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
            setLabelText(upper:false)
            minValueLabel.zPosition = self.zPosition + 1
            minPackageLabel.zPosition = self.zPosition + 1
            
            
        }
        
        setLabel(hitLabel, fontSize: 15)
        setLabel(maxValueLabel, fontSize: size.width * fontSizeMultiplier)
        setLabel(minValueLabel, fontSize: size.width * fontSizeMultiplier)
        setLabel(maxPackageLabel, fontSize: size.width * packageFontSizeMultiplier)
        setLabel(minPackageLabel, fontSize: size.width * packageFontSizeMultiplier)
        

        
        if isCard {
            if minValue == NoColor {
                switch type {
                    case .containerType: alpha = 0.5
                    case .emptyCardType: alpha = 0.1
                    default: alpha = 1.0
                }
            }
            self.addChild(minValueLabel)
            self.addChild(minPackageLabel)
        } else {
            self.addChild(hitLabel)
        }

    }
    
    func generateBelongsToPackageString(upper: Bool)->String {
        if MySKCard.countPackages == 1 {
            return ""
        }
        if self.type == .containerType && self.colorIndex != NoValue {
            if upper {
                switch MySKCard.countPackages {
                case 2:
                    return "2"
                case 3:
                    return "3"
                case 4:
                    return "4"
                default: return ""
                }
            } else {
                switch (MySKCard.countPackages, self.countTransitions) {
                case (2, 0):
                    return "2"
                case (2, 1):
                    return "1"
                case (3, 0):
                    return "3"
                case (3, 1):
                    return "2"
                case (3, 2):
                    return "1"
                case (4, 0):
                    return "4"
                case (4, 1):
                    return "3"
                case (4, 2):
                    return "2"
                case (4, 3):
                    return "1"
                default: return ""
                }
            }
        }
        let belongsTo: UInt8 = upper ? belongsToPackageMax : belongsToPackageMin
        switch (MySKCard.countPackages, belongsTo) {
        case (2, MySKCard.maxPackage):
            return "2"
        case (2, MySKCard.minPackage):
            return "1"
        case (3, 6): // 110
            return "32"
        case (3, 5): // 101
            return "31"
        case (3, 4): // 100
            return "3"
        case (3, 3): // 011
            return "21"
        case (3, 2): // 010
            return "2"
        case (3, 1): // 001
            return "1"
        case (4, 14): // 1110
            return "432"
        case (4, 13): // 1101
            return "431"
       case (4, 12): // 1100
            return "43"
        case (4, 11): // 1011
            return "421"
        case (4, 10): // 1010
            return "42"
        case (4, 9): // 1001
            return "41"
        case (4, 8): // 1100
            return "4"
        case (4, 7): // 0111
            return "321"
        case (4, 6): // 0110
            return "32"
        case (4, 5): // 0101
            return "31"
        case (4, 4): // 0100
            return "3"
        case (4, 3): // 0011
            return "21"
        case (4, 2): // 0010
            return "2"
        case (4, 1): // 0001
            return "1"
        default:
            return ""
        }
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
            setLabelText(upper: false)
            setLabelText(upper:true)
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
                        BGPicture.addChild(maxPackageLabel)
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
                    maxValueLabel.zPosition = self.zPosition + 1
                    maxPackageLabel.zPosition = self.zPosition + 1
                }
            } else {
                if BGPictureAdded || self.childNode(withName: bgPictureName) != nil {
                    maxValueLabel.removeFromParent()
                    maxPackageLabel.removeFromParent()
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
    
    func setBelongsLabels() {
        setLabelText(upper: false)
        setLabelText(upper: true)
    }

    func setLabelText(upper: Bool) {
        if colorIndex != NoColor && (type == .cardType || type == .containerType) {
            let valueLabel = upper ? maxValueLabel : minValueLabel
            let packageLabel = upper ? maxPackageLabel : minPackageLabel
            let value = upper ? maxValue : minValue
            guard let text = cardLib[minValue == NoColor ? NoColor : value % MaxCardValue] else {
                return
            }
            valueLabel.text = "\(text)"
            valueLabel.fontSize = value == 9 ? fontSize10 : standardFontSize // 9 is on card 10
            let packageLabelText = generateBelongsToPackageString(upper: upper)
            packageLabel.text = packageLabelText
        }
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
            let text1 = "\(cardCountTxt) move \(MySKCard.colorNames[colorIndex]) \(createCardText(card: otherCard, from: true)) to \(createCardText(card: self, from: false))"
        #endif
        self.countTransitions += otherCard.countTransitions
        if self.minValue == otherCard.maxValue + 1  && self.belongsToPackageMin & otherCard.belongsToPackageMax != 0 {
            self.minValue = otherCard.minValue
//            self.belongsToPackageMax = self.belongsToPackageMax & otherCard.belongsToPackageMax
//            self.belongsToPackageMin = self.belongsToPackageMin & otherCard.belongsToPackageMin
//            if self.type == .containerType {
//                resetMaxPackageAtMyBrothers()
//            }
        } else if self.maxValue == otherCard.minValue - 1 && self.belongsToPackageMax & otherCard.belongsToPackageMin != 0 {
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
        let betweenTxt = "-" + String(card.countTransitions) + "-"
        return "\(card.type == .containerType ? "Container" : "Card     ")(\(maxValueText)\(betweenTxt)\(minValueText)) \(from ? "from" : "at") [\(card.column):\(card.row)]"
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
    static var cardCount: Int = 0
    

    
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
    
    deinit {
        if type == .cardType {
//            print ("Card deinit: \(self.printValue)")
        }
    }

}
