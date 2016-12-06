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

struct Card {
    let bitMaskForPackages: [UInt8] = [1, 2, 4, 8]
    var status: CardStatus
    var color: Int
    var column: Int
    var row: Int
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
        self.column = column
        self.row = row
        self.originalValue = originalValue
        self.cardName = cardName
        self.minValue = originalValue
        self.maxValue = originalValue
        self.deleted = false
        self.belongsToPkg = 0
        self.countTransitions = 0
        self.belongsToPkg = 0
    }
}

struct GameArrayPositions {
    var used: Bool
    var position: CGPoint
    var colorIndex: Int
    var name: String
    var origValue: Int
    var minValue: Int
    var maxValue: Int
    var countTransitions: Int
    var countScore: Int {
        get {
            return(calculateScore())
        }
    }
    init() {
        self.used = false
        self.position = CGPoint(x: 0, y: 0)
        self.colorIndex = NoColor
        self.name = ""
        self.origValue = NoValue
        self.minValue = NoValue
        self.maxValue = NoValue
        self.countTransitions = 0
    }
    
    init(colorIndex: Int, minValue: Int, maxValue: Int, origValue: Int) {
        self.used = false
        self.position = CGPoint(x: 0, y: 0)
        self.colorIndex = colorIndex
        self.name = ""
        self.origValue = origValue
        self.minValue = minValue
        self.maxValue = maxValue
        self.countTransitions = 0
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


class GameEngine: IteratorProtocol, Sequence {
    public typealias Element = MySKCard
    var countRows: Int
    var countColumns: Int
    private var gameArray = [[GameArrayPositions]]()
    private var containers = [MySKCard]()
    private let countContainers = 4

    enum SequenceType: Int {
        case Container = 0, GameArray
    }
    init() {
        self.countColumns = 0
        self.countRows = 0
    }
    init(countColumns: Int, countRows: Int) {
        self.countColumns = countColumns
        self.countRows = countRows
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

    func next() -> GameArrayPositions? {
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
            gameArray.append(Array(repeating: GameArrayPositions(), count: countRows))
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
        gameArray[column][row].origValue = card.getOrigValue()
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

    
    func getGameArrayPosition(column: Int, row: Int)->GameArrayPositions {
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
    func getIteratedGameArrayPosition(first: Bool = false)->GameArrayPositions? {
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
    
    private var iterateContainerColumn: Int = 0

//    func getIteratedContainerPosition(first: Bool = false)->MySKCard? {
//        if first {
//            iterateContainerColumn = NoValue
//        }
//        iterateContainerColumn += 1
//        if iterateContainerColumn == countContainers {
//            return nil
//        }
//        return containers[iterateContainerColumn]
//    }
    

}
