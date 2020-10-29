//
//  GameArrayManager.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 30/12/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import SpriteKit

class ConnectablePair {
    var card1: MySKCard
    var card2: MySKCard
    var supressed: Bool
    var connectedValues: (upper:Int, lower:Int) {
        get {
            if (card1.minValue - 1 == card2.maxValue) || (card1.minValue == FirstCardValue && card2.maxValue == LastCardValue) {
                return (upper: card1.minValue, lower: card2.maxValue)
            } else if (card1.maxValue + 1 == card2.minValue) || (card1.maxValue == LastCardValue && card2.minValue == FirstCardValue){
                return (upper: card2.minValue, lower: card1.maxValue)
            } else if card2.type == .containerType {
                return (upper: NoValue, lower: card1.maxValue)
            } else {
                return (upper: NoValue, lower: NoValue)
            }
        }
    }
    var connectedCards: (upperCard: MySKCard?, lowerCard: MySKCard?) {
        get {
            if (card1.minValue - 1 == card2.maxValue) || (card1.minValue == FirstCardValue && card2.maxValue == LastCardValue) {
                return (upperCard: card1, lowerCard: card2)
            } else if (card1.maxValue + 1 == card2.minValue) || (card1.maxValue == LastCardValue && card2.minValue == FirstCardValue){
                return (upperCard: card2, lowerCard: card1)
            } else if card2.type == .containerType {
                return (upperCard: nil, lowerCard: card1)
            } else {
                return (upperCard: nil, lowerCard: nil)
            }
        }
    }
    init(card1: MySKCard, card2: MySKCard) {
        self.card1 = card1
        self.card2 = card2
        supressed = false
    }
    func convertCard(card: MySKCard)->Int64 {
        var hash = card.countTransitions << 0
        hash |= card.minValue << 2
        hash |= card.maxValue << 6
        hash |= card.column << 10
        hash |= (card.row & 0xf) << 14
        hash |= card.type.rawValue << 18
        return Int64(hash)
        //            return "\(card.countTransitions)-\(card.minValue)-\(card.maxValue)-\(card.column)-\(card.row)-\(card.type)"
    }
    var printValue: (String, String) {
        get {
            let value1 = card1.printValue
            let value2 = card2.printValue
            return (value1, value2)
        }
    }
    var hashValue : Int64 {
        get {
            return  Int64(convertCard(card: card1) << 32 | convertCard(card: card2))
        }
    }
    var hashValue1 : Int64 {
        get {
            return Int64(convertCard(card: card2) << 32 | convertCard(card: card1))
        }
    }
    static func ==(left: ConnectablePair, right: ConnectablePair) -> Bool {
        return left.hashValue == right.hashValue || left.hashValue == right.hashValue1
    }
    
    static func !=(left: ConnectablePair, right: ConnectablePair) -> Bool {
        return !(left == right)
    }
}

class Tipp: ConnectablePair {
    struct InnerTipp {
        var points: [CGPoint]
        var value: Int
        var twoArrows: Bool
        init() {
            points = []
            value = 0
            twoArrows = false
        }
        init(points: [CGPoint], value: Int, twoArrows: Bool = false) {
            self.points = points
            self.value = value
            self.twoArrows = twoArrows
        }
    }
    var removed: Bool
    var innerTipps: [InnerTipp]
    
    init() {
        removed = false
        innerTipps = [InnerTipp]()
        super.init(card1: MySKCard(), card2: MySKCard())
//        card1 = MySKCard()
//        card2 = MySKCard()
    }
    func hasThisInnerTipp(count:Int, firstPoint: CGPoint)->Bool {
        for innerTipp in innerTipps {
            if innerTipp.points.count == count && firstPoint == innerTipp.points.first! {
                return true
            }
        }
        return false
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
    var fromPosition: ColumnRow = ColumnRow()
    var max: Bool = false
    var value: Int = NoValue
    var myPoints:[CGPoint] = []
    private var hashValue: Int {
        get {
            var hash = colorIndex
            hash |= (value & 0xf) << 4
            hash |= myPoints.count << 8
            return hash
        }
    }
    static func ==(left: FoundedCardParameters, right: FoundedCardParameters) -> Bool {
        return left.hashValue == right.hashValue
    }
    var printValue: String {
        get {
            if let cardValue = MySKCard.cardLib[value] {
                return "(\(fromPosition.column):\(fromPosition.row)) - \(max ? "max" : "min") - \(cardValue))"
            }
            return ""
        }
    }


}

struct ColorsByCounts {
    var colorIndex: Int
    var count: Int
    init(colorIndex: Int, count: Int) {
        self.colorIndex = colorIndex
        self.count = count
    }
}


var allPackages: UInt8 = 0
var maxPackage: UInt8 = 0
var minPackage: UInt8 = 0
let bitMaskForPackages: [UInt8] = [1, 2, 4, 8]
// let maxPackageCount = 4

var stopCreateTippsInBackground = false
var tippArray = [Tipp]()
var supressedTipps = [Tipp]()
var tippArrayCreatedInSeconds = 0.0
//var showHelpLines: ShowHelpLine = .green
var cardSize:CGSize = CGSize(width: 0, height: 0)

let myLineName = "myLine"

var lineWidthMultiplierNormal = CGFloat(0.02) //(0.0625)
let lineWidthMultiplierSpecial = CGFloat(0.125)
var lineWidthMultiplier: CGFloat?
let fixationTime = 0.1


func printGameArrayInhalt() {
    print(Date())
    var string: String = ""
    for container in containers {
        if container.minValue != NoColor {
            let minStr = (container.minValue != 9 ? " " : "") + MySKCard.cardLib[container.minValue]!
            let maxStr = (container.maxValue != 9 ? " " : "") + MySKCard.cardLib[container.maxValue]!
            let colorName:String? = String(CardManager.colorNames[container.colorIndex])
            if colorName != nil {
                string += "(" + colorName! + ")"
            }
            string += maxStr + "-" + minStr
        } else {
            string += "( )" + " --- "
            
        }
    }
    print("======== Containers ========")
    print(string)
    print("======== GameArray ========")
    for row in 0..<countRows {
        let rowIndex = countRows - row - 1
        string = ""
        for column in 0..<countColumns {
            if gameArray[column][rowIndex].used {
                let card = gameArray[column][rowIndex].card
                let minStr = (card.minValue != 9 ? " " : "") + MySKCard.cardLib[card.minValue]!
                let maxStr = (card.minValue != 9 ? " " : "") + MySKCard.cardLib[card.maxValue]!
                let colorName:String? = String(CardManager.colorNames[card.colorIndex])
                if colorName != nil  {
                    string += "(" + colorName! + ")"
                }
                string += maxStr + "-" + minStr
            } else {
                string += "( )" + " --- "
            }
        }
        print(string)
    }
}

// for managing of connectibility of gameArray members
class CardManager {
    
    var noMoreSteps = false
    var setOfBinarys: [String] = []
    var tremblingCards: [MySKCard] = []
    
    var tippIndex = 0
    var lastNextPoint: Founded?
    static let colorNames = ["P", "B", "G", "R"]
    private let multiplierForSearch = CGFloat(3.0)

    private let purple = 0
    private let blue = 1
    private let green = 2
    private let red = 3
    private var colorArray: [DataForColor] = []
    private var lastDrawHelpLinesParameters = DrawHelpLinesParameters()
    var countGameArrayItems: Int {
        get {
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
    }


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

    private func updateColorArray() {
        if lastChange.color != NoColor && !lastChange.toContainer {
            colorArray[lastChange.color].analyzeColor()
        } else {
            for colorIndex in 0..<MaxColorValue {
                colorArray[colorIndex].analyzeColor()
            }
        }
        noMoreSteps = (colorArray[purple].cardsWithTransitions.count > 0  && colorArray[purple].cardMapIndexes.count == 0) ||
                        (colorArray[blue].cardsWithTransitions.count > 0   && colorArray[blue].cardMapIndexes.count == 0)   ||
                        (colorArray[green].cardsWithTransitions.count > 0  && colorArray[green].cardMapIndexes.count == 0)  ||
                        (colorArray[red].cardsWithTransitions.count > 0    && colorArray[red].cardMapIndexes.count == 0)
    }
    
    func areConnectable(first: MySKCard, second: MySKCard)->(OK: Bool, supressed: Bool) {
        if first.colorIndex != second.colorIndex && second.colorIndex != NoColor {
            return (false, false)
        }
        var OK = false
        var supressed = false
        let searchPair = ConnectablePair(card1: first, card2: second)
        for (_, pair) in colorArray[first.colorIndex].connectablePairs.enumerated() {
            if pair == searchPair {
                OK = true
                supressed = pair.supressed
                break
            }
        }
        return (OK, supressed)
    }
    
//    func startCreateTipps() {
//        _ = createTipps()
//    }
//    
    func printTippArray() {
        print("======== \(tippArray.count) tipps created in: \(tippArrayCreatedInSeconds) seconds  ========")
        for tipp in tippArray {
            print(tipp.printValue())
            print("----------------------")
        }
    }
    
//    func delay(time: Double, closure:@escaping ()->()) {
//        let delayTime = DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
//        DispatchQueue.main.asyncAfter(deadline: delayTime)  {
//            closure()
//        }
//        
//    }
    

    
    struct FoundedCardsProColor {
        var cards: [FoundedCardParameters] // for saving all usable cards
        var specialCards: [FoundedCardParameters] // for saving special cards ==> to use only if no others exists
        init() {
            self.cards = []
            self.specialCards = []
        }
        func printValue() {
            print("======== cards: \(cards.count) ========")
            for (cardIndex, card) in cards.enumerated() {
                print("\(cardIndex): Pos: \(card.printValue)")
            }
            print("======== specialCards: \(specialCards.count) ========")
            for (cardIndex, specialCard) in specialCards.enumerated() {
                print("\(cardIndex): Pos: \(specialCard.printValue)")
            }

        }
    }
    
    //    @objc func nextStep(timerX: Timer) {
    //    }
    

    
    func findNewCardsForGameArray()->[MySKCard] {
    
        // saves how many cards of each color are in gameArray and Containers
        var colorCounts: [ColorsByCounts] = []
        
        func updateCountColors() {
            colorCounts.removeAll()
            for color in 0...MaxColorValue - 1 {
                let colorData = colorArray[color]
                if cardStack.count(color: color) > 0 {
                    colorCounts.append(ColorsByCounts(colorIndex: color, count: colorData.allCards.count + (colorData.container == nil ? 0 : 1)))
                }
            }
            colorCounts = colorCounts.sorted(by: {$0.count < $1.count})
        }
        
        func chooseColorIndexes()->[Int] {
            var returnColors: [Int] = []
            updateCountColors()
            returnColors.append(colorCounts[0].colorIndex)
            for index in 0..<colorCounts.count - 1 {
                var atBegin = false
                if colorCounts[index].count == colorCounts[index + 1].count {
                    atBegin = random!.getRandomInt(0, max: 1) == 0 ? true : false
                }
                returnColors.insert(colorCounts[index + 1].colorIndex, at: atBegin ? 0 : returnColors.count)
            }
            return returnColors
        }
        
        createTipps()
        updateCountColors()
        
        var cardArray: [MySKCard] = []
        var specialCards: [FoundedCardParameters] = []
        let gameArraySize = countColumns * countRows
        var actFillingsProcent = Double(countGameArrayItems) / Double(gameArraySize)
        if actFillingsProcent > 0.25 && checkCardTippCountInTippArray() > 2 {
            return cardArray
        }
        var positionsTab = [ColumnRow]()
        for column in 0..<countColumns {
            for row in 0..<countRows {
                if !gameArray[column][row].used {
                    let appendValue = ColumnRow(column:column, row:row)
                    positionsTab.append(appendValue)
                }
            }
        }
        lastChange.color = NoColor
        lastChange.toContainer = false
        var needColorArrayUpdate = false
        while actFillingsProcent < 0.40 && cardStack.count(type: .MySKCardType) > 0 && positionsTab.count > 0 {
            let colorIndexes = chooseColorIndexes()
            let card = cardStack.pull(color: colorIndexes[0])!
            let index = random!.getRandomInt(0, max: positionsTab.count - 1)
            card.column = positionsTab[index].column
            card.row = positionsTab[index].row
            card.belongsToPackageMax = allPackages
            card.belongsToPackageMin = allPackages
            colorArray[card.colorIndex].addCardToUsedCards(card: card)
            let newPairs = colorArray[card.colorIndex].addCardToColor(card: card)
            if newPairs.count > 0 {
                for pair in newPairs {
                    checkPathToFoundedCards(pair: pair)
                }
            }
            positionsTab.remove(at: index)
            updateGameArrayCell(card: card)
            cardArray.append(card)
            actFillingsProcent = Double(countGameArrayItems) / Double(gameArraySize)
            needColorArrayUpdate = true
        }
        if needColorArrayUpdate {
            updateColorArray()
            updateCountColors()
        }
        while actFillingsProcent < 0.98 && cardStack.count(type: .MySKCardType) > 0 && positionsTab.count > 0 && checkCardTippCountInTippArray() < 20 /*tippArray.count < 10*/ {
            let index = random!.getRandomInt(0, max: positionsTab.count - 1)
            let gameArrayPos = positionsTab[index]
            positionsTab.remove(at: index)
            var suitableCards = findSuitableCardsForGameArrayPosition(gameArrayPos: gameArrayPos)
            for index in 0..<suitableCards.count {
                if suitableCards[index].specialCards.count > 0 {
                    specialCards.append(contentsOf: suitableCards[index].specialCards)
                }
            }
            var go = true
            var searchColorIndex = chooseColorIndexes()

            while go {
                
                let actColorIndex = searchColorIndex[0]
                var countSearches = suitableCards[actColorIndex].cards.count

                while countSearches > 0 {
                    let max = suitableCards[actColorIndex].cards.count - 1
                    if max >= 0 {
                        let cardIndex = random!.getRandomInt(0, max: max)
                        let cardToSearch = suitableCards[actColorIndex].cards[cardIndex]
                        if let card = cardStack.search(colorIndex: cardToSearch.colorIndex, value: cardToSearch.value) {
                            let actColorData = colorArray[card.colorIndex]
                            card.column = gameArrayPos.column
                            card.row = gameArrayPos.row
                            card.belongsToPackageMax = allPackages
                            card.belongsToPackageMin = allPackages
                            let newPairs = actColorData.addCardToColor(card: card)
                            if newPairs.count > 0 {
                                actColorData.addCardToUsedCards(card: card)
                                updateGameArrayCell(card: card)
                                cardArray.append(card)
                                for pair in newPairs {
                                    checkPathToFoundedCards(pair: pair)
                                }
                                actFillingsProcent = Double(countGameArrayItems) / Double(gameArraySize)
                                go = false
                                break
                            } else {
                                cardStack.push(card: card)
                                suitableCards[actColorIndex].cards.remove(at: cardIndex)
                            }
                        } else {
                            suitableCards[actColorIndex].cards.remove(at: cardIndex)
                        }
                        countSearches -= 1
                    }
                }
                searchColorIndex.remove(at: 0)
                if searchColorIndex.count == 0 {
                    go = false
                }
            }
        }
        while actFillingsProcent < 0.90 && cardStack.count(type: .MySKCardType) > 0 && specialCards.count > 0 && checkCardTippCountInTippArray() < 20 {
            let cardIndex = random!.getRandomInt(0, max: specialCards.count - 1)
            let cardToSearch = specialCards[cardIndex]
            if !gameArray[cardToSearch.fromPosition.column][cardToSearch.fromPosition.row].used {
                if let card = cardStack.search(colorIndex: cardToSearch.colorIndex, value: cardToSearch.value) {
                    let actColorData = colorArray[card.colorIndex]
                    card.column = cardToSearch.fromPosition.column
                    card.row = cardToSearch.fromPosition.row
                    card.belongsToPackageMax = allPackages
                    card.belongsToPackageMin = allPackages
                    let newPairs = actColorData.addCardToColor(card: card)
                    if newPairs.count > 0 {
                        actColorData.addCardToUsedCards(card: card)
                        updateGameArrayCell(card: card)
                        cardArray.append(card)
                        for pair in newPairs {
                            checkPathToFoundedCards(pair: pair)
                        }
                        actFillingsProcent = Double(countGameArrayItems) / Double(gameArraySize)
                    } else {
                        cardStack.push(card: card)
                        specialCards.remove(at: cardIndex)
                    }
                } else {
                    specialCards.remove(at: cardIndex)
                }
            } else {
                specialCards.remove(at: cardIndex)
            }
        }
        	createTipps()
        return cardArray
    }
    

    
    private func checkCardTippCountInTippArray()->Int {
        var count = 0
        for tipp in tippArray {
            if tipp.card2.type == .cardType {
                count += 1
            }
        }
        return count
    }


    enum MyStates: Int {
        case FirstState = 0, SecondState
    }
    
    private func findSuitableCardsForGameArrayPosition(gameArrayPos: ColumnRow, inState: MyStates = .FirstState)->[FoundedCardsProColor]  {
        var foundedCards: [FoundedCardsProColor] = Array(repeating: FoundedCardsProColor(), count: MaxColorValue) // one Array for each color
        
//        let firstValue: CGFloat = 10000
//        var distanceToLine = firstValue
        
        let startCard = ColumnRow(column:gameArrayPos.column, row: gameArrayPos.row)
        let startPoint = gameArray[gameArrayPos.column][gameArrayPos.row].position
        let startAngle: CGFloat = 0
        let stopAngle = startAngle + 360 * GV.oneGrad // + 360°
        //        let startNode = self.childNodeWithName(name)! as! MySKCard
        var angle = startAngle
        //==========================================
        func appendCardParameter(cardParameter: FoundedCardParameters) {
            let color = cardParameter.colorIndex
            let foundedCardUsing = colorArray[color].usedCards[cardParameter.value]
            let freeCardsOfColor = colorArray[color].getFreeConnectableCards()
            if foundedCardUsing.countInStack == 0 {
                return
            }
            let searchCard = DataForColor.FreeConnectableCards(value: cardParameter.value, max: cardParameter.max)
            if  freeCardsOfColor.contains(searchCard) {
                var founded = false
                for (index, specialCard) in foundedCards[color].specialCards.enumerated() {
                    if specialCard.value == cardParameter.value {
                        if specialCard.myPoints.count >= cardParameter.myPoints.count {
                            founded = true
                            break
                        } else {
                            foundedCards[color].specialCards[index].myPoints = cardParameter.myPoints
                            founded = true
                            break
                        }
                    }
                }
                if !founded {
                    foundedCards[color].specialCards.append(cardParameter)
                }
            } else {
                var founded = false
                for (index, card) in foundedCards[color].cards.enumerated() {
                    if card.value == cardParameter.value {
                        if card.myPoints.count >= cardParameter.myPoints.count {
                            founded = true
                            break
                        } else {
                            foundedCards[color].cards[index].myPoints = cardParameter.myPoints
                            founded = true
                            break
                        }
                        
                        

                    }
                }
                if !founded {
                    foundedCards[color].cards.append(cardParameter)
                }
           }
        }
        //==========================================
        
        while angle <= stopAngle {
//            delay(time: 0.000001, closure: {})
            let toPoint = GV.pointOfCircle(10.0, center: startPoint, angle: angle)
            let (foundedPoint, myPoints) = createHelpLines(movedFrom: startCard, toPoint: toPoint, inFrame: GV.mainScene!.frame, lineSize: cardSize.width, showLines: false)
            if foundedPoint != nil {
                var foundedCard: MySKCard
                var cardParameter = FoundedCardParameters()
                cardParameter.fromPosition = gameArrayPos
                cardParameter.myPoints = myPoints
                if foundedPoint!.foundContainer {
                    foundedCard = containers[foundedPoint!.column]
                    cardParameter.colorIndex = foundedCard.colorIndex
                    if foundedCard.minValue == NoColor { //empty Container
                        cardParameter.value = LastCardValue
                        cardParameter.max = true
                        var usedContainerColors: [Int] = []
                        for container in containers {
                            if container.colorIndex != NoColor {
                                usedContainerColors.append(container.colorIndex)
                            }
                        }
                        for colorIndex in 0...3 {
                            cardParameter.colorIndex = colorIndex
                            if !usedContainerColors.contains(cardParameter.colorIndex) {
                                appendCardParameter(cardParameter: cardParameter)
                            }
                        }
                    } else if foundedCard.minValue > 0 {
                        cardParameter.value = foundedCard.minValue - 1
                        cardParameter.max = true
                        appendCardParameter(cardParameter: cardParameter)
                    } else if foundedCard.belongsToPackageMin & minPackage == 0 && countPackages > 1 {
                        cardParameter.value = LastCardValue
                        cardParameter.max = true
                        appendCardParameter(cardParameter: cardParameter)
                    }
                } else {
                    foundedCard = gameArray[foundedPoint!.column][foundedPoint!.row].card
                    cardParameter.colorIndex = foundedCard.colorIndex
                    if foundedCard.type == .cardType {
                        if foundedCard.minValue != FirstCardValue {
                            cardParameter.value = foundedCard.minValue - 1
                            cardParameter.max = true
                            appendCardParameter(cardParameter: cardParameter)
                        }
                        if foundedCard.maxValue != LastCardValue {
                            cardParameter.value = foundedCard.maxValue + 1
                            cardParameter.max = false
                            appendCardParameter(cardParameter: cardParameter)
                        }
                        
                        if foundedCard.maxValue == LastCardValue && countPackages > 1 {
                            cardParameter.value = FirstCardValue
                            cardParameter.max = false
                            appendCardParameter(cardParameter: cardParameter)
                        }
                        
                        if foundedCard.minValue == FirstCardValue && countPackages > 1 {
                            cardParameter.value = LastCardValue
                            cardParameter.max = true
                            appendCardParameter(cardParameter: cardParameter)
                        }
                    }
                }
            }
            angle += GV.oneGrad * multiplierForSearch
        }
        return foundedCards
    }
    
    
    
    
    func getTipps() {
        //printFunc(function: "getTipps", start: true)
        if tippArray.count > 0 {
            stopTrembling()
            drawHelpLines(points: tippArray[tippIndex].innerTipps.last!.points, lineWidth: cardSize.width, twoArrows: tippArray[tippIndex].innerTipps.last!.twoArrows, color: .green, score: 0)

            addCardToTremblingCards(tippArray[tippIndex].card1.position)
            addCardToTremblingCards(tippArray[tippIndex].card2.position)
            tippIndex = tippIndex < tippArray.count - 1 ? tippIndex + 1 : 0
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
    
    private func createTipps() {
        let createTippsStartedAt = Date()
        updateColorArray()
        tippArray.removeAll()
        let pairsToCheck = getPairsToCheck()
        for pair in pairsToCheck {
            checkPathToFoundedCards(pair: pair)
            if stopCreateTippsInBackground {
                stopCreateTippsInBackground = false
            }
        }
        if supressedTipps.count > 0 {
            for (index, tipp) in tippArray.enumerated() {
                if supressedTipps.contains(where: {$0.card1 == tipp.card1 && $0.card2 == tipp.card2}) {
                    tippArray[index].supressed = true
                    let colorIndex = tipp.card1.colorIndex
                    
                    for index1 in 0..<colorArray[colorIndex].connectablePairs.count {
                        if colorArray[colorIndex].connectablePairs[index1].card1 == tipp.card1 && colorArray[colorIndex].connectablePairs[index1].card2 == tipp.card2 {
                            colorArray[colorIndex].connectablePairs[index1].supressed = true
                        }
                    }
                }
            }
        }
        
        if stopCreateTippsInBackground {
            stopCreateTippsInBackground = false
        }
        tippArray.sort(by: {checkForSort(t0: $0, t1: $1) })
        let createTippsEndedAt = Date()
        tippArrayCreatedInSeconds = CFDateGetTimeIntervalSinceDate(createTippsEndedAt as CFDate?, createTippsStartedAt as CFDate?)
        tippIndex = 0
    }
    
    func createHelpLines(movedFrom: ColumnRow, toPoint: CGPoint, inFrame: CGRect, lineSize: CGFloat, showLines: Bool)->(foundedPoint: Founded?, [CGPoint]) {
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
            let score = gameArray[movedFrom.column][movedFrom.row].card.countScore * (pointArray.count - 1)
            drawHelpLines(points: pointArray, lineWidth: lineSize, twoArrows: false, color: color, score: score)
        }
        
        return (foundedPoint, pointArray)
    }

    
    private func checkPathToFoundedCards(pair: ConnectablePair) {
        let firstValue: CGFloat = 10000
        func checkPath(card1: MySKCard, card2: MySKCard)->Tipp {
            let myTipp = Tipp()
            var distanceToLine = firstValue
            let startPoint = gameArray[card1.column][card1.row].position
            var targetPoint = CGPoint.zero
            if card2.type == .containerType {
                targetPoint = containers[card2.column].position
            } else {
                targetPoint = gameArray[card2.column][card2.row].position
            }
            let startAngle = calculateAngle(startPoint, point2: targetPoint).angleRadian - GV.oneGrad
            let stopAngle = startAngle + 360 * GV.oneGrad // + 360°
            //        let startNode = self.childNodeWithName(name)! as! MySKCard
            var angle = startAngle
            //        let fineMultiplier = CGFloat(1.0)
            while angle <= stopAngle {
                let toPoint = GV.pointOfCircle(1.0, center: startPoint, angle: angle)
                let movedFrom = ColumnRow(column: card1.column, row: card1.row)
                let (foundedPoint, myPoints) = createHelpLines(movedFrom: movedFrom, toPoint: toPoint, inFrame: GV.mainScene!.frame, lineSize: cardSize.width, showLines: false)
//                delay(time: 0.000001, closure: {})
                if foundedPoint != nil {
                    if foundedPoint!.foundContainer && card2.type == .containerType && foundedPoint!.column == card2.column ||
                        (foundedPoint!.column == card2.column && foundedPoint!.row == card2.row) {
                        let hasTipp = myTipp.hasThisInnerTipp(count: myPoints.count, firstPoint: myPoints[0])
                        if distanceToLine == firstValue ||
                            !hasTipp ||
                            (hasTipp && foundedPoint!.distanceToP0 > distanceToLine) {
                            myTipp.card1 = card1
                            myTipp.card2 = card2
                            if hasTipp {
                                
                            } else {
                                let innerTipp = Tipp.InnerTipp(points: myPoints, value: myTipp.card1.countScore * (myPoints.count - 1))
                                myTipp.innerTipps.append(innerTipp)
                            }
                            distanceToLine = foundedPoint!.distanceToP0
                            
                        }
                        //                    if distanceToLine != firstValue && distanceToLine < foundedPoint!.distanceToP0 && myTipp.points.count == 2 {
                        //                        founded = true
                        //                    }
                    }
                }
                angle += GV.oneGrad * multiplierForSearch
            }
            return myTipp
        }
        var myTipp = Tipp()
        var myTipp2 = Tipp()
        myTipp = checkPath(card1: pair.card1, card2: pair.card2)
        if pair.card2.type == .cardType {
            myTipp2 = checkPath(card1: pair.card2, card2: pair.card1)
        }
        if myTipp == Tipp() {
            if myTipp2 != Tipp() {
                myTipp = myTipp2
            }
        } else if myTipp2 != Tipp() {
            myTipp.innerTipps.append(contentsOf: myTipp2.innerTipps)
        }
        if myTipp.innerTipps.count > 0 {
            myTipp.innerTipps = myTipp.innerTipps.sorted{$0.value < $1.value}
            myTipp.supressed = pair.supressed
            tippArray.append(myTipp)
        }
    }
    
    private func calculateAngle(_ point1: CGPoint, point2: CGPoint) -> (angleRadian:CGFloat, angleDegree: CGFloat) {
        //        let pointOfCircle = CGPoint (x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        let offset = point2 - point1
        let length = offset.length()
        let sinAlpha = offset.y / length
        let angleRadian = asin(sinAlpha);
        let angleDegree = angleRadian * 180.0 / CGFloat(Double.pi)
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
    
    private func drawHelpLines(points: [CGPoint], lineWidth: CGFloat, twoArrows: Bool, color: MyColors, score: Int) {
        lastDrawHelpLinesParameters.points = points
        lastDrawHelpLinesParameters.lineWidth = lineWidth
        lastDrawHelpLinesParameters.twoArrows = twoArrows
        lastDrawHelpLinesParameters.color = color
        lastDrawHelpLinesParameters.scores = score
        drawHelpLinesSpec()
    }
    
    func drawHelpLinesSpec() {
        let points = lastDrawHelpLinesParameters.points
        var lineWidth = cardSize.width
//        if showHelpLines == .green {
            lineWidth = lastDrawHelpLinesParameters.lineWidth
//        }
        
        let twoArrows = lastDrawHelpLinesParameters.twoArrows
        let color = lastDrawHelpLinesParameters.color
        let score = lastDrawHelpLinesParameters.scores
        let arrowLength = cardSize.width * 0.30
        
        let pathToDraw:CGMutablePath = CGMutablePath()
        let myLine:SKShapeNode = SKShapeNode(path:pathToDraw)
        removeNodesWithName(myLineName)
        let headWidth: CGFloat = 20
        let headLength: CGFloat = 30
        let tailWidth: CGFloat = 10
        if lineWidthMultiplier == lineWidthMultiplierSpecial {
            let arrow = UIBezierPath.arrow(from: CGPoint(x:points[0].x, y:points[0].y), to: CGPoint(x:(points.last?.x)!, y:(points.last?.y)!),tailWidth: tailWidth, headWidth: headWidth, headLength: headLength)
            let arrowNode = SKShapeNode()
            arrowNode.path = arrow.cgPath
            arrowNode.name = myLineName
            arrowNode.fillColor = UIColor.green
            arrowNode.strokeColor = UIColor.green
            arrowNode.zPosition = 150
            GV.mainScene!.addChild(arrowNode)
            if score > 0 {
                
                let circlePath = CGMutablePath()
                let deltaX = points.first!.x - points.last!.x
                let deltaY = points.first!.y - points.last!.y
                let center = CGPoint(x: points.first!.x - deltaX / 2, y: points.first!.y - deltaY / 2)
                circlePath.addArc(center: center, radius: CGFloat(headWidth / 1.5), startAngle: 0, endAngle: CGFloat(2 * Pi), clockwise: true)

                let circleNode = SKShapeNode()
                circleNode.fillColor = UIColor.white
                circleNode.strokeColor = UIColor.green
                circleNode.lineWidth = 5
                circleNode.name = myLineName
                circleNode.path = circlePath
                circleNode.zPosition = 155
                GV.mainScene!.addChild(circleNode)
                let scoreLabel = SKLabelNode()
                scoreLabel.name = myLineName
                scoreLabel.text = String(score)
                scoreLabel.fontColor = UIColor.red
                scoreLabel.zPosition = 160
                scoreLabel.horizontalAlignmentMode = .center
                scoreLabel.verticalAlignmentMode = .center
                scoreLabel.position.x = points.first!.x - deltaX / 2
                scoreLabel.position.y = points.first!.y - deltaY / 2
                scoreLabel.fontSize = 12
                scoreLabel.color = UIColor.white
                scoreLabel.fontName = "ArialMT"
                GV.mainScene!.addChild(scoreLabel)
            }
        }
//        myLine.lineWidth = lineWidth * lineWidthMultiplier!
        myLine.lineWidth = lineWidth * lineWidthMultiplierNormal
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
        
//        switch showHelpLines {
//        case .green:
        switch color {
            case .red: myLine.strokeColor = SKColor.red //(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8)
            case .green: myLine.strokeColor = SKColor.green//(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.8)
            case .yellow: myLine.strokeColor = SKColor.yellow//(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8)
            default: break
        }
//            if color == .red {
//                myLine.strokeColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8) // GV.colorSets[GV.colorSetIndex][colorIndex + 1]
//            } else {
//                myLine.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.8) // GV.colorSets[GV.colorSetIndex][colorIndex + 1]
//            }
//        case .cyan:
//            myLine.strokeColor = SKColor.cyan
//        case .hidden:
//            myLine.strokeColor = SKColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0)
//        }
        myLine.zPosition = 100
        myLine.lineCap = .round
        
        GV.mainScene!.addChild(myLine)
        
    }

    func checkColoredLines() {
        if lastPair.color == MyColors.green { // Timer for check Green Line
            if Date().timeIntervalSince(lastPair.startTime) > fixationTime && !lastPair.fixed {
                lastPair.fixed = true
//                if showHelpLines == .green {
                    lineWidthMultiplier = lineWidthMultiplierSpecial
//                }
                drawHelpLinesSpec() // draw thick Line
            }
        }
        
        
    }

    private func findEndPoint(movedFrom: ColumnRow, fromPoint: CGPoint, toPoint: CGPoint, lineWidth: CGFloat, showLines: Bool)->(pointFounded:Bool, closestPoint: Founded?) {
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
    
    private func fastFindClosestPoint(_ P1: CGPoint, P2: CGPoint, lineWidth: CGFloat, movedFrom: ColumnRow) -> Founded? {
        
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
    
    func calculateLineColor(foundedPoint: Founded, movedFrom: ColumnRow) -> MyColors {
        
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
        if (connectable.OK && !connectable.supressed)
            ||
            (foundedPosition.card.minValue == NoColor && !actColorHasContainer) &&
            (gameArray[movedFrom.column][movedFrom.row].card.maxValue == LastCardValue) {
            color = .green
        } else if connectable.OK && connectable.supressed {
            color = .yellow
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
    
    func printGameArrayInhalt() {
        print(Date())
        var string: String = ""
        for container in containers {
            if container.minValue != NoColor {
                let minStr = (container.minValue != 9 ? " " : "") + MySKCard.cardLib[container.minValue]!
                let maxStr = (container.maxValue != 9 ? " " : "") + MySKCard.cardLib[container.maxValue]!
                let colorName: String? = String(CardManager.colorNames[container.colorIndex])
                if colorName != nil {
                    string += " (" + colorName! + ")"
                }
                string += maxStr + "-\(container.countTransitions)-" + minStr
            } else {
                string += " ( )" + " ---- "
                
            }
        }
        print("======== Containers ========")
        print(string)
        print("======== GameArray ========")
        for row in 0..<countRows {
            let rowIndex = countRows - row - 1
            string = ""
            for column in 0..<countColumns {
                if gameArray[column][rowIndex].used {
                    let card = gameArray[column][rowIndex].card
                    let minStr = (card.minValue != 9 ? " " : "") + MySKCard.cardLib[card.minValue]!
                    let maxStr = (card.minValue != 9 ? " " : "") + MySKCard.cardLib[card.maxValue]!
                    let colorName: String? = String(CardManager.colorNames[card.colorIndex])
                    if colorName != nil {
                        string += " (" + colorName! + ")"
                    }
                    string += maxStr + "-\(card.countTransitions)-" + minStr
                } else {
                    string += " ( )" + " ----- "
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
    
    class DataForColor {
        var colorIndex: Int
        var container: MySKCard?
        var allCards: [MySKCard] = []
        var cardsWithTransitions: [MySKCard] = []
        var cardMap: [[[Int]]] =  [[[]]]
        var cardMapIndexes: [Int] = []
        var compatibilityMap: [[MySKCard]] = [[]]
//        var forbiddenPairs: [(first: Int, second: Int)] = []
//        var allowedPairs: [(first: Int, second: Int)] = []
        var connectablePairs: [ConnectablePair] = []
        var pairsToRemove: [Int] = []
        var countTransitions = 0
        var usedCards: [UsedCard] = []
        struct FreeConnectableCards: Equatable {
            var value: Int
            var max: Bool
            init(value: Int, max:Bool) {
                self.value = value
                self.max = max
            }
            static func == (left: FreeConnectableCards, right: FreeConnectableCards) -> Bool {
                return left.value == right.value && left.max == right.max
            }
        }
        struct UsedCard {
            var freeMinValues: [MySKCard] = []
            var freeMaxValues: [MySKCard] = []
            var midCount: Int
            
            var countInStack: Int {
                get {
                    var returnValue = countPackages - freeMaxCount - freeMinCount - midCount
                    for card in freeMinValues {
                        // cards with countCards == 1 were counted twice, correct it
                        if card.countCards == 1 {
                            returnValue += 1
                        }
                    }
                    return returnValue
                }
            }
            var freeMaxCount: Int {
                get {
                    return freeMaxValues.count
                }
            }
            var freeMinCount: Int {
                get {
                    return freeMinValues.count
                }
            }
//            var freeMinMaxCount: Int {
//                get {
//                    return freeMinMaxValues.count
//                }
//            }
            init() {
                midCount = 0
            }
        }
        
        var freeConnectableCards: [FreeConnectableCards] = []
        
        init(colorIndex: Int) {
            self.colorIndex = colorIndex
        }
        
        func getFreeConnectableCards()->[FreeConnectableCards] {
            return freeConnectableCards
        }
        
        func addCardToUsedCards(card: MySKCard) {
            if card.minValue != NoColor {
                usedCards[card.minValue].freeMinValues.append(card)
                if card.maxValue == LastCardValue && card.type == .containerType {
                    usedCards[card.maxValue].midCount += 1
                } else {
                    usedCards[card.maxValue].freeMaxValues.append(card)
                }
                var index = 1
                while index < card.countCards - 1 {
                    let value = (card.minValue + index) % CountCardsInPackage
                    usedCards[value].midCount += 1
                    index += 1
                }
            }
        }
        
        func addCardToTipps(card: MySKCard) {
            
        }
        
        func printCardArrays() {
            print("==================== Container ====================")
            if container == nil {
                print ("empty")
            } else {
                print("\(container!.printValue)")
            }
            print("==================== CardArray ====================")
            for (index, card) in allCards.enumerated() {
                print("\(index): \(card.printValue)")
            }
        }
        
        func printConnectablePairs() {
            print("==================== connectablePairs: \(connectablePairs.count) ====================")
            for (index, pair) in connectablePairs.enumerated() {
                print("\(index): \(pair.printValue)")
            }
        }
        

        
        func addCardToColor(card: MySKCard)->[ConnectablePair] {
            var allCardsAndContainer:[MySKCard] = []
            if container != nil {
                allCardsAndContainer.append(container!)
            }
            allCardsAndContainer.append(contentsOf: allCards)
            for masterCard in allCardsAndContainer {
                if masterCard != card &&
                    masterCard.belongsToPackageMax.countOnes() <= 2 &&
                    masterCard.belongsToPackageMin.countOnes() <= 2 {
                    
                    let _ = doAction(masterCard: masterCard, otherCard: card)
                }
            }
            allCards.append(card)
            if !(card.maxValue + 1 == card.minValue - 1) {
                let freeMax = FreeConnectableCards(value: card.maxValue, max: true)
                let freeMin = FreeConnectableCards(value: card.minValue, max: false)
                if !freeConnectableCards.contains(freeMax) {
                    freeConnectableCards.append(freeMax)
                }
                if !freeConnectableCards.contains(freeMin) {
                    freeConnectableCards.append(freeMin)
                }
            }
            if container != nil {
                
            }
            let pairs = findPair(card: card)
//            if pairs.count == 0 {
//                allCards.remove(at: allCards.count - 1)
//            }
            return pairs
        }
        
        func cardHasConnection(card: MySKCard)->Bool {
            return true
        }
        
        #if TEST
        func printUsedCards() {
            for index in 0..<usedCards.count {
                if let cardName = MySKCard.cardLib[index] {
                    var printString = "card \((cardName.length == 1 ? " " : "") + cardName). "
                    printString += "freeMin: \(usedCards[index].freeMinCount), "
                    printString += "freeMax: \(usedCards[index].freeMaxCount), "
                    printString += "midCount: \(usedCards[index].midCount), "
                    printString += "inStack: \(usedCards[index].countInStack)"
                    print(printString)
                }
            }
        }
        #endif
        

        
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
        
        func printCardMaps() {
            func printLine() {
                switch countPackages {
                case 4: print("----+-------+-+-------+-+-------+-+-------+-+-------+-+-------+")
                case 3: print("----+-----+-+-----+-+-----+-+-----+-+-----+-+-----+")
                case 2: print("----+---+-+---+-+---+-+---+-+---+-+---+")
                case 1: print("----+-+-+-+-+-+-+-+-+-+-+-+")
                default: break
                }
            }
            print("=======================    CardMap    ====================")
            printLine()
            for value in 0...LastCardValue {
                let reversedValue = LastCardValue - value
                if let cardName = MySKCard.cardLib[reversedValue] {
                    let cardNameModified = (cardName.length == 1 ? " " : "") + cardName
                    var printString = "\(cardNameModified):"
                    for cardMapIndex in 0..<6 {
                        printString += " |"
                        for pkgIndex in 0..<countPackages {
                            let value = cardMap[cardMapIndex][pkgIndex][reversedValue]
                            printString += value == NoValue ? "x" : value == NoColor ? "C" : "\(value)"
                            printString += "|"
                        }
                    }
                    print(printString)
                }
                if  reversedValue == 0 {
                    printLine()
                }
            }
        }
        

        func analyzeColor() {
            container = nil
            allCards.removeAll()
            connectablePairs.removeAll()
            pairsToRemove.removeAll()
            cardsWithTransitions.removeAll()
            freeConnectableCards.removeAll()
            cardMap = Array(repeating: Array(repeating: Array(repeating: NoValue, count: CountCardsInPackage), count: countPackages), count: 6)
            usedCards = Array(repeating: UsedCard(), count: CountCardsInPackage)
            countTransitions = 0
            findContainer()
            fillAllCards()
            fillCardMaps()
            
            
            if container != nil {
                _ = findPair(card: container!)
            }
            for index in 0..<allCards.count {
                _ = findPair(card: allCards[index])
            }
            
            if container != nil {
                container!.setBelongsLabels()
            }
            for card in allCards {
                card.setBelongsLabels()
            }

        }
        
        private func fillCardMaps() {
            var checkAgain = true
            var needToCheck = true
            var belongValues: [[[UInt8]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: 6), count: CountCardsInPackage), count: allCards.count)
            func fillAllMapsWithContainer() {
                var mapCount = 0
                switch (countPackages, cardsWithTransitions.count) {
                case (2, _): mapCount = 1
                case (3, _): mapCount = 2
                case (4, 0), (4, 1): mapCount = 3
                case (4, 2), (4, 3): mapCount = 6
                default: break
                }
                if container != nil {
                    let startIndex = container!.maxValue
                    let index = NoColor
                    var packageIndex = 0
                    for adder in 0...container!.countCards - 1 {
                        let cardIndex = (startIndex - adder + (countPackages * CountCardsInPackage)) % CountCardsInPackage
                        packageIndex += cardIndex == LastCardValue && adder > 0 ? 1 : 0
                        for mapIndex in 0..<mapCount {
                            cardMap[mapIndex][packageIndex][cardIndex] = index
                            if !cardMapIndexes.contains(mapIndex) {
                                cardMapIndexes.append(mapIndex)
                            }
                        }
                    }
                }
            }
            
            func fillMap(mapIndex: Int, indexes: [Int], startPackageIndexes: [Int] = []) {
                
                var nextPkgIndexAdder = 0
                for (pkgIndex, index) in indexes.enumerated() {
                    let card = allCards[index]
                    let startIndex = card.maxValue
                    var startPackageIndex = pkgIndex
                    if startPackageIndexes.count > pkgIndex {
                        startPackageIndex = startPackageIndexes[pkgIndex]
                    }
                    var packageIndex = startPackageIndex + nextPkgIndexAdder
                    if packageIndex > countPackages - 1 {
                        break
                    }
                    let origPackageIndex = packageIndex
                    if card.countTransitions == 2 {
                        nextPkgIndexAdder = 1
                    }
                    for adder in 0...card.countCards - 1 {
                        let cardIndex = (startIndex - adder + (countPackages * CountCardsInPackage)) % CountCardsInPackage
                        
                        packageIndex += cardIndex == LastCardValue && adder > 0 ? 1 : 0
                        if cardIndex == NoValue || packageIndex > countPackages - 1 {
                            cardMap[mapIndex] = Array(repeating: Array(repeating: NoValue, count: CountCardsInPackage), count: countPackages)
                            if cardMapIndexes.contains(mapIndex) {
                                let indexToRemove = cardMapIndexes.firstIndex(of: mapIndex)
                                cardMapIndexes.remove(at: indexToRemove!)
                            }

                            return
                        }
                        if cardMap[mapIndex][packageIndex][cardIndex] == NoValue {
                            cardMap[mapIndex][packageIndex][cardIndex] = index
                            if !cardMapIndexes.contains(mapIndex) {
                                cardMapIndexes.append(mapIndex)
                            }
                        } else {
                            cardMap[mapIndex] = Array(repeating: Array(repeating: NoValue, count: CountCardsInPackage), count: countPackages)
                            if cardMapIndexes.contains(mapIndex) {
                                let indexToRemove = cardMapIndexes.firstIndex(of: mapIndex)
                                cardMapIndexes.remove(at: indexToRemove!)
                            }
                            return
                        }
                    }
                    if cardMapIndexes.contains(mapIndex) {
                        belongValues[index][startIndex][mapIndex] = maxPackage >> UInt8(origPackageIndex)
                    }
                }
            }
            // hier check all filled maps, not only the First!!!!!! Only if in all maps OK, fill the Card !!!!!
            func addCardToMap(mapIndex: Int, index: Int) {
                let card = allCards[index]
                var OKPackageIndexes: [Int] = []
                for packageIndex in 0..<countPackages {
                    var leerCount = 0
                    for value in card.minValue...card.maxValue {
                        if cardMap[mapIndex][packageIndex][value] == NoValue || cardMap[mapIndex][packageIndex][value] == index {
                            leerCount += 1
                        }
                    }
                    if leerCount == card.countCards {
                        OKPackageIndexes.append(packageIndex)
                    }
                }
                switch OKPackageIndexes.count {
                case 0:
                    for ind in 0..<cardMapIndexes.count {
                        if cardMapIndexes[ind] == mapIndex {
                            cardMapIndexes.remove(at: ind)
                            break
                        }
                    }
                    cardMap[mapIndex] = Array(repeating: Array(repeating: NoValue, count: CountCardsInPackage), count: countPackages)
                case 1:
                    let OKPKGIndex = OKPackageIndexes[0]
                    let setCheckAgain = cardMap[mapIndex][OKPKGIndex][card.minValue] != index
                    for value in card.minValue...card.maxValue {
                        cardMap[mapIndex][OKPKGIndex][value] = index
                    }
                    card.belongsToPackageMax = card.belongsToPackageMax | maxPackage >> UInt8(OKPKGIndex)
                    card.belongsToPackageMin = card.belongsToPackageMax
                    checkAgain = setCheckAgain
                case 2:
                    card.belongsToPackageMax = card.belongsToPackageMax | maxPackage >> UInt8(OKPackageIndexes[0])
                    card.belongsToPackageMax = card.belongsToPackageMax | maxPackage >> UInt8(OKPackageIndexes[1])
                    card.belongsToPackageMin = card.belongsToPackageMax
                default:
                    needToCheck = true
                }
            }
            cardMapIndexes = []
            fillAllMapsWithContainer()
            switch (countPackages, cardsWithTransitions.count) {
            case (2, 1):
                fillMap(mapIndex: 0, indexes: [0])
            case (3, 1):
                fillMap(mapIndex: 0, indexes: [0])
                fillMap(mapIndex: 1, indexes: [0], startPackageIndexes: [1])
            case (3, 2):
                fillMap(mapIndex: 0, indexes: [0, 1])
                fillMap(mapIndex: 1, indexes: [1, 0])
            case (4, 1):
                fillMap(mapIndex: 0, indexes: [0])
                fillMap(mapIndex: 1, indexes: [0], startPackageIndexes: [1])
                fillMap(mapIndex: 2, indexes: [0], startPackageIndexes: [2])
            case (4, 2):
                fillMap(mapIndex: 0, indexes: [0, 1], startPackageIndexes: [0, 1])
                fillMap(mapIndex: 1, indexes: [0, 1], startPackageIndexes: [0, 2])
                fillMap(mapIndex: 2, indexes: [0, 1], startPackageIndexes: [1, 2])
                fillMap(mapIndex: 3, indexes: [1, 0], startPackageIndexes: [0, 1])
                fillMap(mapIndex: 4, indexes: [1, 0], startPackageIndexes: [0, 2])
                fillMap(mapIndex: 5, indexes: [1, 0], startPackageIndexes: [1, 2])
            case (4, 3):
                fillMap(mapIndex: 0, indexes: [0, 1, 2])
                fillMap(mapIndex: 1, indexes: [0, 2, 1])
                fillMap(mapIndex: 2, indexes: [1, 0, 2])
                fillMap(mapIndex: 3, indexes: [1, 2, 0])
                fillMap(mapIndex: 4, indexes: [2, 0, 1])
                fillMap(mapIndex: 5, indexes: [2, 1, 0])
            default:
                break
            }
            checkAgain = true
            while checkAgain && needToCheck {
                checkAgain = false
                needToCheck = false
                for index in cardsWithTransitions.count..<allCards.count {
//                    if allCards[index].belongsToPackageMax.countOnes() > 1 {
                        let belongsMinMaxOrig = allCards[index].belongsToPackageMax
                        allCards[index].belongsToPackageMax = 0
                        allCards[index].belongsToPackageMin = 0
                        for mapIndex in cardMapIndexes {
                            addCardToMap(mapIndex: mapIndex, index: index)
                        }
                        if allCards[index].belongsToPackageMax == 0 {
                            allCards[index].belongsToPackageMax = belongsMinMaxOrig
                            allCards[index].belongsToPackageMin = belongsMinMaxOrig
                        }
//                    }
                }
            }
            for index in 0..<cardsWithTransitions.count {
                var belonging: UInt8 = 0
                let value = allCards[index].maxValue
                for mapIndex in cardMapIndexes {
                    belonging |= belongValues[index][value][mapIndex]
                }
                allCards[index].belongsToPackageMax = belonging
                allCards[index].belongsToPackageMin = belonging >> UInt8(allCards[index].countTransitions)
            }
            if cardMapIndexes.count == 1 && allCards.count > 1 { // only one possible arrangement, set the belongingflags
                var index = 0
//                var actMaxPackage = maxPackage
                let cardMapIndex = cardMapIndexes[0]
                if container != nil {
//                    if container!.minValue == 0 {
//                        actMaxPackage = container!.belongsToPackageMin >> 1
//                    } else {
//                        actMaxPackage = container!.belongsToPackageMin
//                    }
                }
                while index < allCards.count && allCards[index].countTransitions > 0 {
                    for pkg in 0..<countPackages {
                        let value = allCards[index].maxValue
                        if cardMap[cardMapIndex][pkg][value] == index {
                           allCards[index].belongsToPackageMax = maxPackage >> UInt8(pkg)
                           allCards[index].belongsToPackageMin = allCards[index].belongsToPackageMax >> UInt8(allCards[index].countTransitions)
                        break
                        }
                    }
                    index += 1
                }
            }
        }

        
        private func findUpperBelongs(belongs: UInt8)->UInt8 {
            var oper = belongs
            var shiftedBy: UInt8 = 0
            while oper & minPackage == 0 {
                oper >>= 1
                shiftedBy += 1
            }
            let upperMask: UInt8 = (oper & allPackages & ~1) << shiftedBy
            return upperMask
        }
        
        private func findLowerBelongs(belongs: UInt8)->UInt8 {
            var oper = belongs
            var shiftedBy: UInt8 = 0
            while oper & maxPackage == 0 {
                oper <<= 1
                shiftedBy += 1
            }
            let lowerMask: UInt8 = (oper & allPackages & ~maxPackage) >> shiftedBy
            return lowerMask
        }
        
        func doAction(masterCard: MySKCard, otherCard: MySKCard)->Int {
            func createMask(withMinPackage: Bool = true)->UInt8 {
                var bit = masterCard.belongsToPackageMax
                var mask = masterCard.belongsToPackageMax | (withMinPackage ? masterCard.belongsToPackageMin : 0)
                while bit != masterCard.belongsToPackageMin && bit > 0 {
                    mask |= bit
                    bit = bit >> 1
                }
                return mask
            }
            
            func createMaskUp()->UInt8 {
                var shifter = masterCard.countTransitions - 1
                var mask = masterCard.belongsToPackageMin
                while shifter > 0 {
                    mask |= mask << 1
                    shifter -= 1
                }
                return mask
            }
            
            var countChanges = 0
            let (maxInUpper, maxInLower) = masterCard.containsValue(value: otherCard.maxValue)
            let (minInUpper, minInLower) = masterCard.containsValue(value: otherCard.minValue)
            let c1 = maxInUpper ? 8 : 0
            let c2 = minInUpper ? 4 : 0
            let c3 = maxInLower ? 2 : 0
            let c4 = minInLower ? 1 : 0
            
            let toDo = c1 + c2 + c3 + c4
            let savedBelongsToPackageMin = otherCard.belongsToPackageMin
            let savedBelongsToPackageMax = otherCard.belongsToPackageMax
            if otherCard.maxValue == LastCardValue && countTransitions == countPackages - 1 {
                otherCard.belongsToPackageMax = maxPackage
                otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
            } else if otherCard.minValue == FirstCardValue && countTransitions == countPackages - 1 {
                otherCard.belongsToPackageMin = minPackage
                otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
            } else {
                switch toDo {
                case 0b0000:
                    break
                case 0b0001: // min in lower
                    otherCard.belongsToPackageMin &= ~masterCard.belongsToPackageMin
                    otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                case 0b0010: // max in lower
                    otherCard.belongsToPackageMax &= ~createMaskUp() & UInt8(allPackages)
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                case 0b0011: // min & max in lower
                    otherCard.belongsToPackageMax &= ~createMaskUp() & UInt8(allPackages)
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                case 0b0100: // min in upper                    if masterCard.belongsToPackageMax.countOnes() == 1 {
                    otherCard.belongsToPackageMin &= ~masterCard.belongsToPackageMax
                    otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                case 0b0101:
                    otherCard.belongsToPackageMin &= ~masterCard.belongsToPackageMax & ~masterCard.belongsToPackageMin
                    otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                case 0b0110:
                    otherCard.belongsToPackageMin &= ~masterCard.belongsToPackageMax
                    otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << 1
                case 0b0111:
                    otherCard.belongsToPackageMin &= ~createMask()
                    otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                case 0b1000:
                    otherCard.belongsToPackageMax &= ~masterCard.belongsToPackageMax
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                case 0b1001:
                    otherCard.belongsToPackageMax &= ~masterCard.belongsToPackageMax
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                case 0b1010:
                    otherCard.belongsToPackageMax &= ~createMask()
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                case 0b1011:
                    otherCard.belongsToPackageMax &= ~createMask()
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                case 0b1100:
                    if masterCard.belongsToPackageMax.countOnes() == 1 {
                        otherCard.belongsToPackageMax &= ~createMask(withMinPackage: false)
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                    }
                case 0b1101:
                    if masterCard.belongsToPackageMax.countOnes() == 1 {
                        otherCard.belongsToPackageMax &= ~createMask(withMinPackage: false)
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                    }
                case 0b1110:
                    otherCard.belongsToPackageMax &= ~createMask()
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                case 0b1111:
                    otherCard.belongsToPackageMax &= ~createMask()
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                default: break
                }
            }
            if otherCard.belongsToPackageMin == 0 || otherCard.belongsToPackageMax == 0 {
                otherCard.belongsToPackageMin = savedBelongsToPackageMin
                otherCard.belongsToPackageMax = savedBelongsToPackageMax
            } else {
                countChanges = 1
            }
            return countChanges
        }

        private func findPair(card: MySKCard, index: Int = NoValue)->[ConnectablePair] {
            var foundedPairs: [ConnectablePair] = []
            func saveIfPair(first: MySKCard, second: MySKCard) {
                func findCardIndexInAllCards(card: MySKCard)->Int {
                    for (index, foundedCard) in allCards.enumerated() {
                        if card === foundedCard {
                            return index
                        }
                    }
                    return NoColor
                }
                if (first.minValue == second.maxValue + 1 && first.belongsToPackageMin & second.belongsToPackageMax != 0)
                    ||
                    (first.maxValue == second.minValue - 1 && first.belongsToPackageMax & second.belongsToPackageMin != 0)
                    ||
                    (first.minValue == FirstCardValue &&
                        second.maxValue == LastCardValue &&
                        first.belongsToPackageMin & ~minPackage != 0 &&
                        second.belongsToPackageMax & ~maxPackage != 0 &&
                        countTransitions < countPackages - 1)
                    ||
                    (first.maxValue == LastCardValue &&
                        second.minValue == FirstCardValue &&
                        first.belongsToPackageMax & ~maxPackage != 0 &&
                        second.belongsToPackageMin & ~minPackage != 0 &&
                        countTransitions < countPackages - 1)
                    ||
                    (first.type == .containerType && first.colorIndex == NoColor && second.maxValue == LastCardValue)
                {
                    var founded = false
                    let connectablePair = ConnectablePair(card1: second, card2: first)
                    let searchPair = ConnectablePair(card1: first, card2: second)
                    for foundedPair in connectablePairs {
                        if foundedPair == searchPair {
                            founded = true
                            break
                        }
                    }
                    
                    if !founded {
                        connectablePairs.append(connectablePair)
                        foundedPairs.append(connectablePair)
                    }
                }
            }
            if card.maxValue == LastCardValue && container == nil {
                for container in containers {
                    if container.colorIndex == NoColor {
                        let connectablePair = ConnectablePair(card1: card, card2: container)
                        connectablePairs.append(connectablePair)
                        foundedPairs.append(connectablePair)
                    }
                }
            }
            if container != nil {
                saveIfPair(first: container!, second: card)
            }
            
            for card1 in allCards {
                if card !== card1 {
                    saveIfPair(first: card, second: card1)
                }
            }
            return foundedPairs
        }

        
        private func findContainer() {
            for container in containers {
                if container.colorIndex == colorIndex {
                    container.belongsToPackageMax = maxPackage
                    container.belongsToPackageMin = container.belongsToPackageMax >> UInt8(container.countTransitions)
                    self.container = container
                    countTransitions += container.countTransitions
                    addCardToUsedCards(card: container)
                    let freeMin = FreeConnectableCards(value: container.minValue, max: false)
                    freeConnectableCards.append(freeMin)
                }
            }
        }
        
        private func fillAllCards() {
            for cardColumn in gameArray {
                for card in cardColumn {
                    if card.used && card.card.colorIndex == colorIndex {
                        addCardToUsedCards(card: card.card)
                        allCards.append(card.card)
                        let freeMax = FreeConnectableCards(value: card.card.maxValue, max: true)
                        let freeMin = FreeConnectableCards(value: card.card.minValue, max: false)
                        if !freeConnectableCards.contains(freeMax) {
                            freeConnectableCards.append(freeMax)
                        }
                        if !freeConnectableCards.contains(freeMin) {
                            freeConnectableCards.append(freeMin)
                        }
                        if card.card.countTransitions > 0 {
                            countTransitions += card.card.countTransitions
                            cardsWithTransitions.append(card.card)
                            switch (countPackages, card.card.countTransitions) {
                            case (2, 1), (3, 2), (4, 3):
                                card.card.belongsToPackageMax = maxPackage
                                card.card.belongsToPackageMin = minPackage
                            case (3, 1), (4, 1):
                                var actAllPackages = allPackages
                                if container != nil {
                                    actAllPackages = allPackages >> UInt8(container!.countTransitions)
                                }
                                card.card.belongsToPackageMax = actAllPackages & ~minPackage
                                card.card.belongsToPackageMin = card.card.belongsToPackageMax >> 1
                            case (4, 2):
                                card.card.belongsToPackageMax = maxPackage + maxPackage >> 1
                                card.card.belongsToPackageMin = minPackage + minPackage << 1
                            default: break
                            }
                        } else if container == nil {
                            card.card.belongsToPackageMax = allPackages
                            card.card.belongsToPackageMin = card.card.belongsToPackageMax
                        } else if container!.minValue > card.card.maxValue {
                            card.card.belongsToPackageMax = allPackages >> UInt8(container!.countTransitions)
                            card.card.belongsToPackageMin = card.card.belongsToPackageMax
                        } else {
                            card.card.belongsToPackageMax = allPackages >> UInt8(container!.countTransitions + 1)
                            card.card.belongsToPackageMin = card.card.belongsToPackageMax
                        }
                    }
                }
            }
            allCards = allCards.sorted(by: {$0.countTransitions > $1.countTransitions || $0.countTransitions == $1.countTransitions && ($0.countCards > $1.countCards || $0.countCards == $1.countCards && $0.maxValue > $1.maxValue)})
            cardsWithTransitions = cardsWithTransitions.sorted(by: {$0.countTransitions > $1.countTransitions || $0.countTransitions == $1.countTransitions && ($0.countCards > $1.countCards || $0.countCards == $1.countCards && $0.maxValue > $1.maxValue)})
        }


    }
}
