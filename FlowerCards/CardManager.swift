//
//  GameArrayManager.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 30/12/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import SpriteKit

struct ConnectablePair {
    var card1: MySKCard
    var card2: MySKCard
    func convertCard(card: MySKCard)->Int {
        var hash = card.countTransitions << 0
        hash |= card.minValue << 2
        hash |= card.maxValue << 6
        hash |= card.maxValue << 10
        hash |= card.column << 14
        hash |= card.row << 18
        hash |= card.type.rawValue << 22
        return hash
        //            return "\(card.countTransitions)-\(card.minValue)-\(card.maxValue)-\(card.column)-\(card.row)-\(card.type)"
    }
    var printValue: (String, String) {
        get {
            let value1 = card1.printValue
            let value2 = card2.printValue
            return (value1, value2)
        }
    }
    var hashValue : Int {
        get {
            return  convertCard(card: card1) << 32 | convertCard(card: card2)
        }
    }
    var hashValue1 : Int {
        get {
            return convertCard(card: card2) << 32 | convertCard(card: card1)
        }
    }
    static func ==(left: ConnectablePair, right: ConnectablePair) -> Bool {
        return left.hashValue == right.hashValue || left.hashValue == right.hashValue1
    }
    
    static func !=(left: ConnectablePair, right: ConnectablePair) -> Bool {
        return !(left == right)
    }
}

struct Tipp {
    var removed: Bool
    var card1: MySKCard
    var card2: MySKCard
    var twoArrows: Bool
    var points:[CGPoint]
    var value: Int
    var lineLength: CGFloat
    
    init() {
        removed = false
        points = [CGPoint]()
        twoArrows = false
        value = 0
        lineLength = 0
        card1 = MySKCard()
        card2 = MySKCard()
    }
    func printValue() {
        print(card1.printValue)
        print(card2.printValue)
    }
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

struct FoundedCardParameters {
    
    var colorIndex: Int = NoColor
    var value1: Int = NoValue
    var value2: Int = NoValue
    var hashValue: Int {
        get {
            var hash = colorIndex
            hash |= (value1 & 0xf) << 4
            hash |= (value1 & 0xf) << 4
            return hash
        }
    }
    static func ==(left: FoundedCardParameters, right: FoundedCardParameters) -> Bool {
        return left.hashValue == right.hashValue
    }


}



let EmptyValue = 0xf
var allPackages: UInt8 = 0
var maxPackage: UInt8 = 0
var minPackage: UInt8 = 0
let bitMaskForPackages: [UInt8] = [1, 2, 4, 8]
let maxPackageCount = 4

var stopCreateTippsInBackground = false
var tippArray = [Tipp]()
var showHelpLines: ShowHelpLine = .green
var cardSize:CGSize = CGSize(width: 0, height: 0)

let myLineName = "myLine"

var lineWidthMultiplierNormal = CGFloat(0.04) //(0.0625)
let lineWidthMultiplierSpecial = CGFloat(0.125)
var lineWidthMultiplier: CGFloat?
let fixationTime = 0.1






// for managing of connectibility of gameArray members
class CardManager {
    
    var setOfBinarys: [String] = []
    var tremblingCards: [MySKCard] = []

    var tippIndex = 0
    var lastNextPoint: Founded?


    struct DataForColor {
        let colorNames = ["Purple", "Blue", "Green", "Red"]
        var colorIndex: Int
        var container: MySKCard?
        var allCards: [MySKCard] = []
        var cardsWithTransitions: [MySKCard] = []
        var connectablePairs: [ConnectablePair] = []
        var pairsToRemove: [Int] = []
        var countTransitions = 0
        init(colorIndex: Int) {
//            allCards = []
//            cardsWithTransitions = []
//            connectablePairs = []
            
            self.colorIndex = colorIndex
        }
        func printValue() {
            print("color: \(colorNames[colorIndex]), countTransitions: \(countTransitions)")
            if container != nil {
                print(container!.printValue)
            }
            for card in allCards {
                print(card.printValue)
            }
            if connectablePairs.count > 0 {
                print("========== Connectable Pairs: ===========")
                for pair in connectablePairs {
                    let (value1, value2) = pair.printValue
                    print("card1: \(value1)")
                    print("card2: \(value2)")
                }
                print("=========================================")
            }
        }
    }
    private let colorNames = ["Purple", "Blue", "Green", "Red"]
    private let purple = 0
    private let blue = 1
    private let green = 2
    private let red = 3
    private var colorArray: [DataForColor] = []
    private var lastDrawHelpLinesParameters = DrawHelpLinesParameters()

    init () {
        for _ in 1...4 {
            colorArray.append(DataForColor(colorIndex: colorArray.count))
        }
        allPackages = 0
        for packageNr in 0..<countPackages {
            allPackages += bitMaskForPackages[packageNr]
        }
        maxPackage = bitMaskForPackages[countPackages - 1]
        minPackage = bitMaskForPackages[0]
    }

//    func check(color: Int) {
//        analyzeColor(data: &colorArray[color])
//    }
    
    private func updateColorArray() {
        for colorIndex in 0..<MaxColorValue {
            analyzeColor(data: &colorArray[colorIndex])
        }
    }
    
    func areConnectable(first: MySKCard, second: MySKCard)->Bool {
        if first.colorIndex != second.colorIndex || first.colorIndex == NoColor {
            return false
        }
        let searchPair = ConnectablePair(card1: first, card2: second)
        var OK = false
        for pair in colorArray[first.colorIndex].connectablePairs {
            if pair == searchPair {
                OK = true
            }
        }
        _ = colorArray[first.colorIndex].countTransitions
        if OK
        {
            return true
        }
        return false
    }
    
    func startCreateTipps() {
        _ = createTipps()
        
        repeat {
            if tippArray.count <= 2 && self.checkGameArray() > 2 {
                if cardStack.count(.MySKCardType) > 0 {
//                    generateCards(.special)
                    //                    cardManager!.check()
                    _ = createTipps()
                } else {
                    break
                }
            }
        } while !(tippArray.count > 2 || countColumns * countRows - self.checkGameArray() == 0 || self.checkGameArray() < 5)
        
//        self.generatingTipps = false
        tippIndex = 0  // set tipps to first
        
    }
    
    func findNewCardsForGameArray()->[MySKCard] {
//        func generateCards(_ generatingType: CardGeneratingType) {
        var cardArray: [MySKCard] = []
        let gameArraySize = countColumns * countRows
        var actFillingsProcent = Double(checkGameArray() / gameArraySize)
        if actFillingsProcent > 0.60 {
            return cardArray
        }
        var positionsTab = [(column: Int, row:Int)]()
        for column in 0..<countColumns {
            for row in 0..<countRows {
                if !gameArray[column][row].used {
                    let appendValue = (column, row)
                    positionsTab.append(appendValue)
                }
            }
        }
        while actFillingsProcent < 0.50 && cardStack.count(.MySKCardType) > 0 {
            let card: MySKCard = cardStack.pull()!
            let index = random!.getRandomInt(0, max: positionsTab.count - 1)
            card.column = positionsTab[index].column
            card.row = positionsTab[index].row
            card.belongsToPackageMax = allPackages
            card.belongsToPackageMin = allPackages
            positionsTab.remove(at: index)
            updateGameArrayCell(card: card)
            cardArray.append(card)
            actFillingsProcent = Double(checkGameArray()) / Double(gameArraySize)
        }
        
        while actFillingsProcent < 0.80 && cardStack.count(.MySKCardType) > 0 {
            let index = random!.getRandomInt(0, max: positionsTab.count - 1)
            var suitableCards: [FoundedCardParameters] = findSuitableCardsForGameArrayPosition(gameArrayPos: positionsTab[index])
            var cards: [MySKCard] = []
            for _ in suitableCards {
                let cardIndex = random!.getRandomInt(0, max: suitableCards.count - 1)
                var go = true
                var countSearches = cardStack.count(.MySKCardType)
                while go && countSearches > 0 {
                    let cards = cardStack.search(searchParameter: suitableCards[cardIndex])
                    if cards.count > 0 {
                        go = false
                    } else {
                        suitableCards.remove(at: cardIndex)
                    }
                    countSearches -= 1
                }
                if cards.count > 0 {
                    let card = cards[random!.getRandomInt(0, max: 1)]
                    card.column = positionsTab[index].column
                    card.row = positionsTab[index].row
                    card.belongsToPackageMax = allPackages
                    card.belongsToPackageMin = allPackages
                    updateGameArrayCell(card: card)
                    cardArray.append(card)
                    break
                }
            }
        }
        return cardArray
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
    
    private func findSuitableCardsForGameArrayPosition(gameArrayPos: (column: Int, row: Int))->[FoundedCardParameters] {
        var foundedCards: [FoundedCardParameters] = []
//        let firstValue: CGFloat = 10000
//        var distanceToLine = firstValue
        let startCard = gameArray[gameArrayPos.column][gameArrayPos.row].card
        let startPoint = gameArray[gameArrayPos.column][gameArrayPos.row].position
        let startAngle: CGFloat = 0
        let stopAngle = startAngle + 360 * GV.oneGrad // + 360°
        //        let startNode = self.childNodeWithName(name)! as! MySKCard
        var angle = startAngle
        let multiplierForSearch = CGFloat(2.0)
        //        let fineMultiplier = CGFloat(1.0)
        let multiplier:CGFloat = multiplierForSearch
        while angle <= stopAngle {
            let toPoint = GV.pointOfCircle(1.0, center: startPoint, angle: angle)
            let (foundedPoint, myPoints) = createHelpLines(movedFrom: startCard, toPoint: toPoint, inFrame: GV.mainScene!.frame, lineSize: cardSize.width, showLines: false)
            if foundedPoint != nil {
                var foundedCard: MySKCard
                var cardParameter = FoundedCardParameters()
                if foundedPoint!.foundContainer {
                    foundedCard = containers[foundedPoint!.column]
                    if foundedCard.minValue == NoColor { //empty Container
                        cardParameter.value1 = EmptyValue
                    } else if foundedCard.minValue > 0 {
                        cardParameter.value1 = foundedCard.minValue - 1
                    } else if foundedCard.belongsToPackageMin & minPackage == 0 {
                        cardParameter.value1 = LastCardValue
                    }
                } else {
                    foundedCard = gameArray[foundedPoint!.column][foundedPoint!.row].card
                    if foundedCard.type == .cardType {
                        if foundedCard.maxValue == LastCardValue {
                            if foundedCard.belongsToPackageMax & maxPackage == 0 {
                                cardParameter.value1 = FirstCardValue
                            }
                        } else if foundedCard.minValue == FirstCardValue {
                            if foundedCard.belongsToPackageMin & minPackage == 0 {
                                cardParameter.value1 = LastCardValue
                            }
                        } else {
                            cardParameter.value1 = foundedCard.minValue - 1
                            cardParameter.value2 = foundedCard.maxValue + 1
                        }
                    }
                }
                func appendCardParameter(cardParameter: FoundedCardParameters) {
                    var cardNotFound = true
                    for card in foundedCards {
                        if card == cardParameter {
                            cardNotFound = false
                        }
                    }
                    if cardNotFound {
                        foundedCards.append(cardParameter)
                    }
                }
                if cardParameter.value1 != NoValue {
                    if cardParameter.value1 == EmptyValue {
                        for colorIndex in 0...3 {
                            cardParameter.colorIndex = colorIndex
                            cardParameter.value1 = LastCardValue
                            appendCardParameter(cardParameter: cardParameter)
                        }
                    } else {
                        cardParameter.colorIndex = foundedCard.colorIndex
                        appendCardParameter(cardParameter: cardParameter)
                    }
                }
            }
            angle += GV.oneGrad * multiplier
        }
        return foundedCards
    }
    
    private func analyzeColor(data: inout DataForColor) {
        data.connectablePairs.removeAll()
        data.cardsWithTransitions.removeAll()
        data.countTransitions = 0
        func findContainer() {
            for container in containers {
                if container.colorIndex == data.colorIndex {
                    container.belongsToPackageMax = maxPackage
                    container.belongsToPackageMin = container.belongsToPackageMax >> UInt8(container.countTransitions)
                    data.container = container
                    data.countTransitions += container.countTransitions
                }
            }
        }
        func fillAllCards() {
            data.allCards.removeAll()
            for cardColumn in gameArray {
                for card in cardColumn {
                    if card.used && card.card.colorIndex == data.colorIndex {
                        data.allCards.append(card.card)
                        if card.card.countTransitions > 0 {
                            data.countTransitions += card.card.countTransitions
                            data.cardsWithTransitions.append(card.card)
                            switch (countPackages, card.card.countTransitions) {
                            case (2, 1):
                                card.card.belongsToPackageMax = maxPackage
                                card.card.belongsToPackageMin = minPackage
                            case (3, 1):
                                card.card.belongsToPackageMax = allPackages & ~minPackage
                                card.card.belongsToPackageMin = allPackages & ~maxPackage
                            case (3, 2):
                                card.card.belongsToPackageMax = maxPackage
                                card.card.belongsToPackageMin = minPackage
                            case (4, 1):
                                card.card.belongsToPackageMax = allPackages & ~minPackage
                                card.card.belongsToPackageMin = allPackages & ~maxPackage
                            case (4, 2):
                                card.card.belongsToPackageMax = maxPackage + maxPackage >> 1
                                card.card.belongsToPackageMin = minPackage + minPackage << 1
                            case (4, 3):
                                card.card.belongsToPackageMax = maxPackage
                                card.card.belongsToPackageMin = minPackage
                            default: break
                            }
                        } else {
                            card.card.belongsToPackageMax = allPackages
                            card.card.belongsToPackageMin = allPackages
                        }
                    }
                }
            }
            
        }
        func findPair(card: MySKCard) {
            if card.maxValue == LastCardValue && data.container == nil {
                for container in containers {
                    if container.colorIndex == NoColor {
                        let connectablePair = ConnectablePair(card1: card, card2: container)
                        data.connectablePairs.append(connectablePair)
                    }
                }
            }
            for card1 in data.allCards {
                if card != card1 {
                    if (card.minValue == card1.maxValue + 1 && card.belongsToPackageMin & card1.belongsToPackageMax != 0)
                    ||
                        (card.maxValue == card1.minValue - 1 && card.belongsToPackageMax & card1.belongsToPackageMin != 0)
                    ||
                        (card.minValue == FirstCardValue &&
                        card1.maxValue == LastCardValue &&
                        card.belongsToPackageMin & ~minPackage != 0 &&
                        card1.belongsToPackageMax & ~maxPackage != 0 &&
                        data.countTransitions < countPackages - 1)
                    ||
                        (card.maxValue == LastCardValue &&
                        card1.minValue == FirstCardValue &&
                        card.belongsToPackageMax & ~maxPackage != 0 &&
                        card1.belongsToPackageMin & ~minPackage != 0 &&
                        data.countTransitions < countPackages - 1)
                    ||
                        (card.type == .containerType && card.colorIndex == NoColor && card1.maxValue == LastCardValue)
                    {
                        var founded = false
                        let connectablePair = ConnectablePair(card1: card1, card2: card)
                        let searchPair = ConnectablePair(card1: card, card2: card1)
                        for foundedPair in data.connectablePairs {
                            if foundedPair == searchPair {
                                founded = true
                                break
                            }
                        }
                        if !founded {
                            data.connectablePairs.append(connectablePair)
                        }
                    }
                }
            }
        }
        func setOtherCardBelonging(cardWithTransition: MySKCard)->Int {

            let (upperValues, _, lowerValues) = findCardValues(card: cardWithTransition)
            var countChanges = 0
            var switchValue: UInt8 = 0
            var index = 0
            for (ind, otherCard) in data.allCards.enumerated() {
                func doAction(toDo: UInt8) {
                    let savedBelongsToPackageMin = otherCard.belongsToPackageMin
                    let savedBelongsToPackageMax = otherCard.belongsToPackageMax
                    if otherCard.maxValue == LastCardValue && data.countTransitions == countPackages - 1 {
                        otherCard.belongsToPackageMax = maxPackage
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                    } else if otherCard.minValue == FirstCardValue && data.countTransitions == countPackages - 1 {
                        otherCard.belongsToPackageMin = minPackage
                        otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                    } else {
                        switch toDo {
                        case 0b0000:
                            break
                        case 0b0001:
                            set0b0001()
                        case 0b0010:
                            set0b0010()
                        case 0b0011:
                            set0b0011()
                        case 0b0100:
                            set0b0100()
                        case 0b0101:
                            set0b0101()
                        case 0b0110:
                            set0b0110()
                        case 0b0111:
                            set0b0111()
                        case 0b1000:
                            set0b1000()
                        case 0b1001:
                            set0b1001()
                        case 0b1010:
                            set0b1010()
                        case 0b1011:
                            set0b1011()
                        case 0b1100:
                            set0b1100()
                        case 0b1101:
                            set0b1101()
                        case 0b1110:
                            set0b1110()
                        case 0b1111:
                            set0b1111()
                        default: break
                        }
                    }
                    if otherCard.belongsToPackageMin == 0 || otherCard.belongsToPackageMax == 0 {
                        otherCard.belongsToPackageMin = savedBelongsToPackageMin
                        otherCard.belongsToPackageMax = savedBelongsToPackageMax
                    } else {
                        countChanges += 1
                    }
                }
                func set0b0001() {
                    otherCard.belongsToPackageMin &= ~cardWithTransition.belongsToPackageMin
                    otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                }
                func set0b0010() {
                    otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMin
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b0011() {
                    otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMin
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b0100() {
                    otherCard.belongsToPackageMin &= ~cardWithTransition.belongsToPackageMax
                    otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                }
                func set0b0101() {
                    otherCard.belongsToPackageMin &= ~cardWithTransition.belongsToPackageMax & ~cardWithTransition.belongsToPackageMin
                    otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                }
                func set0b0110() {
                    otherCard.belongsToPackageMin &= ~cardWithTransition.belongsToPackageMax
                    otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << 1
                }
                func set0b0111() {
                    otherCard.belongsToPackageMin &= ~createMask()
                    otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                }
                func set0b1000() {
                    otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1001() {
                    otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1010() {
                    otherCard.belongsToPackageMax &= ~createMask()
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1011() {
                    otherCard.belongsToPackageMax &= ~createMask()
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1100() {
                    otherCard.belongsToPackageMax &= ~createMask(withMinPackage: false)
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1101() {
                    otherCard.belongsToPackageMax &= ~createMask(withMinPackage: false)
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1110() {
                    otherCard.belongsToPackageMax &= ~createMask()
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1111() {
                    otherCard.belongsToPackageMax &= ~createMask()
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                
                func createMask(withMinPackage: Bool = true)->UInt8 {
                    var bit = cardWithTransition.belongsToPackageMax
                    var mask = cardWithTransition.belongsToPackageMax | (withMinPackage ? cardWithTransition.belongsToPackageMin : 0)
                    while bit != cardWithTransition.belongsToPackageMin {
                        mask |= bit
                        bit = bit >> 1
                    }
                    return mask
                }
                index = ind
                if cardWithTransition != otherCard &&
                    cardWithTransition.belongsToPackageMax.countOnes() <= 2 &&
                    cardWithTransition.belongsToPackageMin.countOnes() <= 2 &&
                    otherCard.belongsToPackageMax.countOnes() > 1 &&
                    otherCard.belongsToPackageMin.countOnes() > 1 {
                    
//                    let b1 = UInt16(countPackages - 1) << 8
//                    let b2 = UInt16(cardWithTransition.countTransitions) << 6
//                    let b3 = UInt16(otherCard.countTransitions) << 4
                    
                    let c1 = UInt8(upperValues.contains(otherCard.maxValue) ? 8 : 0)
                    let c2 = UInt8(upperValues.contains(otherCard.minValue) ? 4 : 0)
                    let c3 = UInt8(lowerValues.contains(otherCard.maxValue) ? 2 : 0)
                    let c4 = UInt8(lowerValues.contains(otherCard.minValue) ? 1 : 0)
                    //switchValue = b1 + b2 + b3
                    switchValue = c1 + c2 + c3 + c4
                    doAction(toDo: switchValue)
                }
            }
            return countChanges
        }
        

        findContainer()
        fillAllCards()
        
        var countChanges = 0
        if let container = data.container {
            // set the belongingsFlags by all other Cards
            countChanges += setOtherCardBelonging(cardWithTransition: container)
        }
        for card in data.cardsWithTransitions {
            countChanges += setOtherCardBelonging(cardWithTransition: card)
        }
        var counter = data.allCards.count
        while countChanges > 0 && counter > 0 {
            countChanges = 0
            for card in data.allCards {
                if card.belongsToPackageMax.countOnes() == 1 {  // if more then one possible connections
                    countChanges += setOtherCardBelonging(cardWithTransition: card)
                }
            }
            counter -= 1
        }

        if data.container != nil {
            findPair(card: data.container!)
        }
        for index in 0..<data.allCards.count {
            findPair(card: data.allCards[index])
        }
        
        if data.connectablePairs.count > 0 {
            data.pairsToRemove.removeAll()
            for pair in data.connectablePairs {
                checkPair(data: &data, actPair: pair)
            }
            if data.pairsToRemove.count > 0 {
                for index in data.pairsToRemove.reversed() {
//                    print(data.connectablePairs[index].printValue)
                    if index < data.pairsToRemove.count {
                        data.connectablePairs.remove(at: index)
                    }
                }
            }
        }
        if data.container != nil {
            data.container!.setBelongsLabels()
        }
        for card in data.allCards {
            card.setBelongsLabels()
        }
    }
    
    
    
    private func checkPair(data: inout DataForColor, actPair: ConnectablePair) {
        if actPair.card1.type == .cardType && actPair.card2.type == .cardType &&
            (actPair.card1.minValue == FirstCardValue && actPair.card2.maxValue == LastCardValue ||
             actPair.card2.minValue == FirstCardValue && actPair.card1.maxValue == LastCardValue) {
            for (index, pair) in data.connectablePairs.enumerated() {
                if pair != actPair {
                    if pair.card1.type == .cardType && pair.card2.type == .cardType &&
                        (pair.card1.minValue == FirstCardValue && pair.card2.maxValue == LastCardValue ||
                        pair.card2.minValue == FirstCardValue && pair.card1.maxValue == LastCardValue) {
                        let actPairLen = actPair.card1.countCards + actPair.card2.countCards
                        let pairLen = pair.card1.countCards + pair.card2.countCards
                        if actPairLen >= CountCardsInPackage && pairLen < CountCardsInPackage {
                            data.pairsToRemove.append(index)
                        }
                    }
                }
            }
        }
    }
    
    private func findCardValues(card: MySKCard)->([Int], [Int], [Int]) {
        var cardValuesAtLowerPackage: [Int] = []
        var cardValuesAtTheMid: [Int] = []
        var cardValuesAtHigherPackage: [Int] = []
        
        if card.countTransitions == 0 {
            for value in card.minValue...card.maxValue {
                cardValuesAtHigherPackage.append(value)
            }
        } else {
//            countValues = card.maxValue + CountCardsInPackage - card.minValue + 1 + (CountCardsInPackage * (card.countTransitions - 1))
            for value in 0...card.maxValue {
                cardValuesAtHigherPackage.append(value)
            }
            if card.countTransitions > 1 {
                for value in 0...LastCardValue {
                    cardValuesAtTheMid.append(value)
                }
            }
            for value in card.minValue...LastCardValue {
                cardValuesAtLowerPackage.append(value)
            }
        }
        return (cardValuesAtHigherPackage, cardValuesAtTheMid, cardValuesAtLowerPackage)
    }
    
    func getTipps() {
        //printFunc(function: "getTipps", start: true)
        if tippArray.count > 0 {
            stopTrembling()
            drawHelpLines(tippArray[tippIndex].points, lineWidth: cardSize.width, twoArrows: tippArray[tippIndex].twoArrows, color: .green)

            addCardToTremblingCards(tippArray[tippIndex].card1.position)
            addCardToTremblingCards(tippArray[tippIndex].card2.position)
            //            }
            tippIndex += 1
            tippIndex %= tippArray.count
        }
        
        //printFunc(function: "getTipps", start: false)
    }
    
    private func getPairsToCheck()->[ConnectablePair] {
        var pairsToCheck: [ConnectablePair] = []
        for color in 0...3 {
            for pair in colorArray[color].connectablePairs {
                pairsToCheck.append(pair)
            }
        }
        return pairsToCheck
    }


    private func createTipps()->Bool {
        
        updateColorArray()
        tippArray.removeAll()
        let pairsToCheck = getPairsToCheck()
        for pair in pairsToCheck {
            checkPathToFoundedCards(pair: pair)
            if stopCreateTippsInBackground {
                stopCreateTippsInBackground = false
                return false
            }
        }
        
        if stopCreateTippsInBackground {
            stopCreateTippsInBackground = false
            return false
        }
        tippArray.sort(by: {checkForSort(t0: $0, t1: $1) })
            
        return true
    }
    
    func createHelpLines(movedFrom: MySKCard, toPoint: CGPoint, inFrame: CGRect, lineSize: CGFloat, showLines: Bool)->(foundedPoint: Founded?, [CGPoint]) {
        var pointArray = [CGPoint]()
        var foundedPoint: Founded?
        var founded = false
        //        var myLine: SKShapeNode?
        
        let fromPosition = gameArray[movedFrom.column][movedFrom.row].position
        let line = JGXLine(fromPoint: fromPosition, toPoint: toPoint, inFrame: inFrame, lineSize: lineSize) //, delegate: self)
        let pointOnTheWall = line.line.toPoint
        pointArray.append(fromPosition)
        (founded, foundedPoint) = findEndPoint(movedFrom: movedFrom, fromPoint: fromPosition, toPoint: pointOnTheWall, lineWidth: lineSize, showLines: showLines)
        //        linesArray.append(myLine)
        //        if showLines {self.addChild(myLine)}
        if founded {
            pointArray.append(foundedPoint!.point)
        } else {
            pointArray.append(pointOnTheWall)
            let mirroredLine1 = line.createMirroredLine()
            (founded, foundedPoint) = findEndPoint(movedFrom: movedFrom, fromPoint: mirroredLine1.line.fromPoint, toPoint: mirroredLine1.line.toPoint, lineWidth: lineSize, showLines: showLines)
            
            //            linesArray.append(myLine)
            //            if showLines {self.addChild(myLine)}
            if founded {
                pointArray.append(foundedPoint!.point)
            } else {
                pointArray.append(mirroredLine1.line.toPoint)
                let mirroredLine2 = mirroredLine1.createMirroredLine()
                (founded, foundedPoint) = findEndPoint(movedFrom: movedFrom, fromPoint: mirroredLine2.line.fromPoint, toPoint: mirroredLine2.line.toPoint, lineWidth: lineSize, showLines: showLines)
                //                linesArray.append(myLine)
                //                if showLines {self.addChild(myLine)}
                if founded {
                    pointArray.append(foundedPoint!.point)
                } else {
                    pointArray.append(mirroredLine2.line.toPoint)
                    let mirroredLine3 = mirroredLine2.createMirroredLine()
                    (founded, foundedPoint) = findEndPoint(movedFrom: movedFrom, fromPoint: mirroredLine3.line.fromPoint, toPoint: mirroredLine3.line.toPoint, lineWidth: lineSize, showLines: showLines)
                    //                    linesArray.append(myLine)
                    //                    if showLines {self.addChild(myLine)}
                    if founded {
                        pointArray.append(foundedPoint!.point)
                    } else {
                        pointArray.append(mirroredLine3.line.toPoint)
                        let mirroredLine4 = mirroredLine3.createMirroredLine()
                        (founded, foundedPoint) = findEndPoint(movedFrom: movedFrom, fromPoint: mirroredLine4.line.fromPoint, toPoint: mirroredLine4.line.toPoint, lineWidth: lineSize, showLines: showLines)
                        //                    linesArray.append(myLine)
                        //                    if showLines {self.addChild(myLine)}
                        if founded {
                            pointArray.append(foundedPoint!.point)
                        } else {
                            pointArray.append(mirroredLine4.line.toPoint)
                            let mirroredLine5 = mirroredLine4.createMirroredLine()
                            (founded, foundedPoint) = findEndPoint(movedFrom: movedFrom, fromPoint: mirroredLine5.line.fromPoint, toPoint: mirroredLine5.line.toPoint, lineWidth: lineSize, showLines: showLines)
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
            let color = calculateLineColor(foundedPoint: foundedPoint!, movedFrom:  movedFrom)
            drawHelpLines(pointArray, lineWidth: lineSize, twoArrows: false, color: color)
        }
        
        return (foundedPoint, pointArray)
    }

    
    private func checkPathToFoundedCards(pair:ConnectablePair) {
        var myTipp = Tipp()
        let firstValue: CGFloat = 10000
        var distanceToLine = firstValue
        let startPoint = gameArray[pair.card1.column][pair.card1.row].position
        var targetPoint = CGPoint.zero
        if pair.card2.type == .containerType {
            targetPoint = containers[pair.card2.column].position
        } else {
            targetPoint = gameArray[pair.card2.column][pair.card2.row].position
        }
        let startAngle = calculateAngle(startPoint, point2: targetPoint).angleRadian - GV.oneGrad
        let stopAngle = startAngle + 360 * GV.oneGrad // + 360°
        //        let startNode = self.childNodeWithName(name)! as! MySKCard
        var founded = false
        var angle = startAngle
        let multiplierForSearch = CGFloat(2.0)
        //        let fineMultiplier = CGFloat(1.0)
        let multiplier:CGFloat = multiplierForSearch
        while angle <= stopAngle && !founded {
            let toPoint = GV.pointOfCircle(1.0, center: startPoint, angle: angle)
            let (foundedPoint, myPoints) = createHelpLines(movedFrom: pair.card1, toPoint: toPoint, inFrame: GV.mainScene!.frame, lineSize: cardSize.width, showLines: false)
            if foundedPoint != nil {
                if foundedPoint!.foundContainer && pair.card2.type == .containerType && foundedPoint!.column == pair.card2.column ||
                    (foundedPoint!.column == pair.card2.column && foundedPoint!.row == pair.card2.row) {
                    if distanceToLine == firstValue ||
                        myPoints.count > myTipp.points.count ||
                        (myTipp.points.count == myPoints.count && foundedPoint!.distanceToP0 > distanceToLine) {
                        myTipp.card1 = pair.card1
                        myTipp.card2 = pair.card2
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
            myTipp.value = myTipp.card1.countScore * (myTipp.points.count - 1)
            tippArray.append(myTipp)
        }
    }
    
    private func calculateAngle(_ point1: CGPoint, point2: CGPoint) -> (angleRadian:CGFloat, angleDegree: CGFloat) {
        //        let pointOfCircle = CGPoint (x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        let offset = point2 - point1
        let length = offset.length()
        let sinAlpha = offset.y / length
        let angleRadian = asin(sinAlpha);
        let angleDegree = angleRadian * 180.0 / CGFloat(M_PI)
        return (angleRadian, angleDegree)
    }
    
    private func checkForSort(t0: Tipp, t1:Tipp)->Bool {
        let returnValue = t0.card1.colorIndex < t1.card1.colorIndex
            || (t0.card1.colorIndex == t1.card1.colorIndex &&
                (t0.card1.maxValue < t1.card1.minValue
                    || (t0.card2.type != .containerType && t1.card2.type != .containerType && t0.card1.maxValue < t1.card1.minValue)))
        return returnValue
    }
    
    private func pairExists(pairsToCheck:[FromToColumnRow], aktPair: FromToColumnRow)->Bool {
        for pair in pairsToCheck {
            if pair.fromColumnRow.column == aktPair.fromColumnRow.column && pair.fromColumnRow.row == aktPair.fromColumnRow.row &&
                pair.toColumnRow.column == aktPair.toColumnRow.column && pair.toColumnRow.row == aktPair.toColumnRow.row {
                return true
            }
        }
        return false
    }
    
    private func drawHelpLines(_ points: [CGPoint], lineWidth: CGFloat, twoArrows: Bool, color: MyColors) {
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
            
            
            pathToDraw.move(to: points[0])
            pathToDraw.addLine(to: p1)
            pathToDraw.move(to: points[0])
            pathToDraw.addLine(to: p2)
        }
        
        myLine.path = pathToDraw
        
        switch showHelpLines {
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
        
        GV.mainScene!.addChild(myLine)
        
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

    private func findEndPoint(movedFrom: MySKCard, fromPoint: CGPoint, toPoint: CGPoint, lineWidth: CGFloat, showLines: Bool)->(pointFounded:Bool, closestPoint: Founded?) {
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
    
    private func fastFindClosestPoint(_ P1: CGPoint, P2: CGPoint, lineWidth: CGFloat, movedFrom: MySKCard) -> Founded? {
        
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
    
    func calculateLineColor(foundedPoint: Founded, movedFrom: MySKCard) -> MyColors {
        
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
        let connectable = areConnectable(first: first, second: second)
        if connectable //MySKCard.areConnectable(first: first, second: second)
            ||
            (foundedPosition.card.minValue == NoColor && !actColorHasContainer) &&
            (gameArray[movedFrom.column][movedFrom.row].card.maxValue == LastCardValue) {
            color = .green
        }
        return color
    }
    

    func makeTrembling(_ nextPoint: Founded) {
        var tremblingCardPosition = CGPoint.zero
        if lastNextPoint != nil && ((lastNextPoint!.column != nextPoint.column) ||  (lastNextPoint!.row != nextPoint.row)) {
            if lastNextPoint!.foundContainer {
                tremblingCardPosition = containers[lastNextPoint!.column].position
            } else {
                tremblingCardPosition = gameArray[lastNextPoint!.column][lastNextPoint!.row].position
            }
            let nodes = GV.mainScene!.nodes(at: tremblingCardPosition)
            
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
        let nodes = GV.mainScene!.nodes(at: position)
        for index in 0..<nodes.count {
            if nodes[index] is MySKCard {
                tremblingCards.append(nodes[index] as! MySKCard)
                (nodes[index] as! MySKCard).tremblingType = .changeSize
            }
        }
        
    }
    

    func stopTrembling() {
        for index in 0..<tremblingCards.count {
            tremblingCards[index].tremblingType = .noTrembling
        }
        tremblingCards.removeAll()
    }
    
    func removeNodesWithName(_ name: String) {
        while GV.mainScene!.childNode(withName: name) != nil {
            GV.mainScene!.childNode(withName: name)!.removeFromParent()
        }
    }
    
    private func calculateColumnRowFromPosition(_ position: CGPoint)->ColumnRow {
        var columnRow  = ColumnRow()
        let offsetToFirstPosition = position - gameArray[0][0].position
        let tableCellSize = gameArray[1][1].position - gameArray[0][0].position
        
        
        columnRow.column = Int(round(Double(offsetToFirstPosition.x / tableCellSize.x)))
        columnRow.row = Int(round(Double(offsetToFirstPosition.y / tableCellSize.y)))
        return columnRow
    }
    
    private func calculateColumnRowWhenPointOnTheWall(_ fromToColumnRow: FromToColumnRow)->FromToColumnRow {
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
    
    private func findIntersectionPoint(_ a:CGPoint, b:CGPoint, c:CGPoint) ->CGPoint {
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
    

    private func findNextPointToCheck(_ actColumnRow: ColumnRow, fromToColumnRow: FromToColumnRow)->(ColumnRow, Bool) {
        
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
    
    func resetGameArrayCell(_ card:MySKCard) {
        gameArray[card.column][card.row].card = MySKCard()
        gameArray[card.column][card.row].used = false
    }
    
    func updateGameArrayCell(card:MySKCard) {
        gameArray[card.column][card.row].card = card
        gameArray[card.column][card.row].used = true
    }
    


    
}
