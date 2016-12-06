//
//  GameEngine.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 02/12/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import SpriteKit

enum CardStatus: Int {
    case CardStack = 0, OnScreen, Deleted
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


struct Card {
    var used: Bool
    var position: CGPoint
    let bitMaskForPackages: [UInt8] = [1, 2, 4, 8]
    var status: CardStatus
    var colorIndex: Int
    var column: Int
    var row: Int
    var name: String
    var originalValue: Int
    var minValue: Int
    var maxValue: Int
    var deleted: Bool
    var countTransitions: Int
    var belongsToPkg: UInt8 // belongs to package
    var countScore: Int {
        get {
            return(calculateScore())
        }
    }
    
    init() {
        self.used = false
        self.position = CGPoint(x: 0, y: 0)
        self.colorIndex = NoValue
        self.status = .CardStack
        self.column = 0
        self.row = 0
        self.originalValue = NoValue
        self.name = ""
        self.minValue = NoValue
        self.maxValue = NoValue
        self.deleted = false
        self.belongsToPkg = 0
        self.countTransitions = 0
        self.belongsToPkg = 0
    }
    
    init(color: Int, row: Int, column: Int, originalValue: Int, status: CardStatus, cardName: String) {
        self.used = false
        self.position = CGPoint(x: 0, y: 0)
        self.colorIndex = color
        self.status = status
        self.column = column
        self.row = row
        self.originalValue = originalValue
        self.name = cardName
        self.minValue = originalValue
        self.maxValue = originalValue
        self.deleted = false
        self.belongsToPkg = 0
        self.countTransitions = 0
        self.belongsToPkg = 0
    }
    
    init(colorIndex: Int, minValue: Int, maxValue: Int, origValue: Int) {
        self.used = false
        self.position = CGPoint(x: 0, y: 0)
        self.colorIndex = colorIndex
        self.status = .CardStack
        self.column = 0
        self.row = 0
        self.originalValue = origValue
        self.name = ""
        self.minValue = minValue
        self.maxValue = maxValue
        self.deleted = false
        self.belongsToPkg = 0
        self.countTransitions = 0
        self.belongsToPkg = 0
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
}


//struct GameArrayPositions {
//    var used: Bool
//    var position: CGPoint
////    var cardIndex: CardIndex
//    var colorIndex: Int
//    var name: String
//    var origValue: Int
//    var minValue: Int
//    var maxValue: Int
//    var countTransitions: Int
//    var countScore: Int {
//        get {
//            return(calculateScore())
//        }
//    }
//    init() {
//        self.used = false
//        self.position = CGPoint(x: 0, y: 0)
//        self.colorIndex = NoColor
//        self.name = ""
//        self.origValue = NoValue
//        self.minValue = NoValue
//        self.maxValue = NoValue
//        self.countTransitions = 0
//    }
//    
//    init(colorIndex: Int, minValue: Int, maxValue: Int, origValue: Int) {
//        self.used = false
//        self.position = CGPoint(x: 0, y: 0)
//        self.colorIndex = colorIndex
//        self.name = ""
//        self.origValue = origValue
//        self.minValue = minValue
//        self.maxValue = maxValue
//        self.countTransitions = 0
//    }
//    
//    func calculateScore()->Int {
//        var actValue: Int
//        if countTransitions == 0 {
//            let midValue = Double(minValue + maxValue + 2) / Double(2)
//            actValue = Int(midValue * Double((maxValue - minValue + 1)))
//        } else {
//            var midValue = Double(minValue + LastCardValue + 2) / Double(2)
//            actValue = Int(midValue * Double((LastCardValue - minValue + 1)))
//            midValue = Double(maxValue + 2) / Double(2)
//            actValue += Int(midValue * Double((maxValue + 1)))
//            actValue += countTransitions == 1 ? 0 : 91 * (countTransitions - 1)
//        }
//        return actValue
//    }
//    
//}


class GameEngine: IteratorProtocol, Sequence {
    public typealias Element = MySKCard
    private var countRows: Int
    private var countColumns: Int
    private var countPackages: Int
    private var gameArray = [[Card]]()
    private var containers = [MySKCard]()
    private var cardIndexArray: [CardIndex] = []
    private var cards: [CardIndex:Card] = [:]
    private let countContainers = 4

    enum SequenceType: Int {
        case Container = 0, GameArray
    }
    init() {
        self.countColumns = 0
        self.countRows = 0
        self.countPackages = 0
    }
    init(countColumns: Int, countRows: Int, countPackages: Int) {
        self.countColumns = countColumns
        self.countRows = countRows
        self.countPackages = countPackages
    }
    private var containerColumn = 0
    func setIterationForContainer() {
        containerColumn = -1
    }
    func next() -> Element? {
        containerColumn += 1
        if containerColumn < containers.count {
            return containers[containerColumn]
        } else {
            return nil
        }
    }
    private var gameArrayColumn = 0
    private var gameArrayRow = 0
    func setIterationForGameArray() {
        gameArrayRow = -1
        gameArrayColumn = 0
    }

    func next() -> Card? {
        gameArrayRow += 1
        if gameArrayRow == countRows {
            gameArrayRow = 0
            gameArrayColumn += 1
            if gameArrayColumn == countColumns {
                return nil
            }
        }
        return gameArray[gameArrayColumn][gameArrayRow]
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
    
    func clearGame() {
        gameArray.removeAll(keepingCapacity: false)
        containers.removeAll(keepingCapacity: false)
        for _ in 0..<countColumns {
            gameArray.append(Array(repeating: Card(), count: countRows))
        }
        containers.removeAll()
        for _ in 0..<countContainers {
            containers.append(MySKCard(texture: getTexture(NoColor), type: .containerType, value: NoColor))
        }
    }
    
    
    func setGameArrayPositions() {
        for column in 0..<countColumns {
            for row in 0..<countRows {
                gameArray[column][row].position = calculateCardPosition(column, row: row)
            }
        }
    }
    private func calculateCardPosition(_ column: Int, row: Int) -> CGPoint {
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

    
    func resetGameArrayCell(_ card:MySKCard) {
        let (column, row) = card.getColumnRow()
        gameArray[column][row].used = false
        gameArray[column][row].colorIndex = NoColor
        gameArray[column][row].minValue = NoValue
        gameArray[column][row].maxValue = NoValue
    }
    
    func updateGameArrayCell(_ card:MySKCard) {
        let (column, row) = card.getColumnRow()
        gameArray[column][row].used = true
        gameArray[column][row].name = card.name!
        gameArray[column][row].colorIndex = card.getColorIndex()
        gameArray[column][row].minValue = card.getMinValue()
        gameArray[column][row].maxValue = card.getMaxValue()
        gameArray[column][row].countTransitions = card.getCountTransitions()
        gameArray[column][row].originalValue = card.getOrigValue()
    }
    
    func setGameArrayPosition(column: Int, row: Int, position: CGPoint) {
        gameArray[column][row].position = position
    }
    
    func setGameArrayParams(column: Int,
                            row: Int,
                            position: CGPoint? = nil,
                            used: Bool? = nil,
                            colorIndex: Int? = nil,
                            minValue: Int? = nil,
                            maxValue: Int? = nil,
                            name: String? = nil) {
        if let inPosition = position {
            gameArray[column][row].position = inPosition
        }
        if let inUsed = used {
            gameArray[column][row].used = inUsed
        }
        if let inColorIndex = colorIndex {
            gameArray[column][row].colorIndex = inColorIndex
        }
        if let inMinValue = minValue {
            gameArray[column][row].minValue = inMinValue

        }
        if let inMaxValue = maxValue {
            gameArray[column][row].maxValue = inMaxValue
        }
        if let inName = name {
            gameArray[column][row].name = inName
            
        }
    }

    func setContainerParams(column: Int,
                            position: CGPoint? = nil,
                            size: CGSize? = nil,
                            colorIndex: Int? = nil,
                            minValue: Int? = nil,
                            maxValue: Int? = nil,
                            name: String? = nil,
                            belongsToPackage: Int? = nil,
                            BGPictureAdded: Bool? = nil) {
        if let inPosition = position {
            containers[column].position = inPosition
        }
        containers[column].setParam(column: column, row: NoValue, colorIndex: colorIndex, minValue: minValue, maxValue: maxValue, belongsToPackage: belongsToPackage, BGPictureAdded: BGPictureAdded)
//        if let inColorIndex = colorIndex {
//            containers[column].colorIndex = inColorIndex
//        }
//        if let inMinValue = minValue {
//            containers[column].minValue = inMinValue
//            
//        }
//        if let inMaxValue = maxValue {
//            containers[column].maxValue = inMaxValue
//        }
        if let inName = name {
            containers[column].name = inName
        }
        if let inSize = size {
            containers[column].size = inSize
        }
//        if let inBelongsToPackage = belongsToPackage {
//            containers[column].belongsToPackage = inBelongsToPackage
//        }
//        if let inBGPictureAdded = BGPictureAdded {
//            containers[column].BGPictureAdded = inBGPictureAdded
//        }
    }
    func checkContainers()->Bool {
//        var first = true
//        while true {
//            if let container = game.getIteratedContainerPosition(first: first) {
//                if container.minValue != FirstCardValue || container.maxValue % MaxCardValue != LastCardValue {
//                    return false
//                }
//                first = false
//            } else {
//                break
//            }
//        }
        setIterationForContainer()
        for container in self {
            if container.getMinValue() != FirstCardValue || container.getMaxValue() % MaxCardValue != LastCardValue {
                return false
            }
        }
        return true
    }

    
    func getGameArrayPosition(column: Int, row: Int)->Card {
        return gameArray[column][row]
    }
    
    func getContainer(column: Int)->MySKCard {
        return containers[column]
    }
    
    private func getTexture(_ index: Int)->SKTexture {
        if index == NoColor {
            return atlas.textureNamed("emptycard")
        } else {
            return atlas.textureNamed ("card\(index)")
        }
    }
    

    
    private var iterateColumn: Int = 0
    private var iterateRow: Int = 0
    func getIteratedGameArrayPosition(first: Bool = false)->Card? {
        if first {
            iterateColumn = 0
            iterateRow = NoValue
        }
        iterateRow += 1
        if iterateRow == countRows {
            iterateRow = 0
            iterateColumn += 1
            if iterateColumn == countColumns {
                return nil
            }
        }
        return gameArray[iterateColumn][iterateRow]
    }
  
    func areConnectable(first: Card, second: Card, secondIsContainer: Bool = false)->Bool {
        if first.colorIndex == second.colorIndex &&
            (first.minValue == second.maxValue + 1 ||
                first.maxValue == second.minValue - 1 ||
                (countPackages > 1 && first.maxValue == LastCardValue && second.minValue == FirstCardValue) ||
                (countPackages > 1 && first.minValue == FirstCardValue && second.maxValue == LastCardValue && !secondIsContainer))
        {
            return true
        }
        
        return false
        
    }
    

    
    
    
    func getRandomCard(random: MyRandom?)->(MySKCard, Bool) {
        let index = random!.getRandomInt(0, max: cardIndexArray.count - 1)
        let cardIndex = cardIndexArray[index]
        let color = cards[cardIndex]!.colorIndex
        let texture = atlas.textureNamed ("card\(color)")
        let card = cards[cardIndex]
        cardIndexArray.remove(at: index)
        let newCard = MySKCard(texture: texture, type: .cardType, card: card!)
        return (newCard, cardIndexArray.count != 0)
    }
    func setCountPackages(countPackages: Int) {
        self.countPackages = countPackages
        
    }
    
    func cleanForNewGame() {
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
    
    

}
