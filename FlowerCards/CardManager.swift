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
    var card1: MySKCard
    var card2: MySKCard
    var innerTipps: [InnerTipp]
    
    init() {
        removed = false
        innerTipps = [InnerTipp]()
        card1 = MySKCard()
        card2 = MySKCard()
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


}

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


func printGameArrayInhalt() {
    print(Date())
    var string: String = ""
    for container in containers {
        if container.minValue != NoColor {
            let minStr = (container.minValue != 9 ? " " : "") + MySKCard.cardLib[container.minValue]!
            let maxStr = (container.maxValue != 9 ? " " : "") + MySKCard.cardLib[container.maxValue]!
            if let colorName = String(CardManager.colorNames[container.colorIndex]) {
                string += "(" + colorName + ")"
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
                if let colorName = String(CardManager.colorNames[card.colorIndex]) {
                    string += "(" + colorName + ")"
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
    

    struct UsedCard {
        var countFree: Int
        var countAll: Int
        var countInStack: Int {
            get {
                return countPackages - countAll
            }
        }
        init() {
            countFree = 0
            countAll = 0
        }
    }
    
    var setOfBinarys: [String] = []
    var tremblingCards: [MySKCard] = []
    
    var tippIndex = 0
    var lastNextPoint: Founded?
    static let colorNames = ["P", "B", "G", "R"]
    private let multiplierForSearch = CGFloat(2.0)

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

//    func check(color: Int) {
//        analyzeColor(data: &colorArray[color])
//    }
    
    private func updateColorArray() {
        for colorIndex in 0..<MaxColorValue {
            colorArray[colorIndex].analyzeColor()
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
    }
    
    func findNewCardsForGameArray()->[MySKCard] {
        
        _ = createTipps()
        var cardArray: [MySKCard] = []
        let gameArraySize = countColumns * countRows
        var actFillingsProcent = Double(countGameArrayItems) / Double(gameArraySize)
        if actFillingsProcent > 0.35 && tippArray.count > 2 {
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
        while actFillingsProcent < 0.30 && cardStack.count(.MySKCardType) > 0 {
            let card: MySKCard = cardStack.pull()!
            let actColorData = colorArray[card.colorIndex]
            let index = random!.getRandomInt(0, max: positionsTab.count - 1)
            card.column = positionsTab[index].column
            card.row = positionsTab[index].row
            card.belongsToPackageMax = allPackages
            card.belongsToPackageMin = allPackages
            actColorData.addCardToUsedCards(card: card)
//            let newPairs = actColorData.addCardToColor(card: card)
//            if newPairs.count > 0 {
//                for pair in newPairs {
//                    checkPathToFoundedCards(pair: pair)
//                }
//            }
            positionsTab.remove(at: index)
            updateGameArrayCell(card: card)
            cardArray.append(card)
            actFillingsProcent = Double(countGameArrayItems) / Double(gameArraySize)
        }
        updateColorArray()
        
        while actFillingsProcent < 0.80 && cardStack.count(.MySKCardType) > 0 && positionsTab.count > 0 && tippArray.count < 4 {
            let index = random!.getRandomInt(0, max: positionsTab.count - 1)
            let gameArrayPos = positionsTab[index]
            positionsTab.remove(at: index)
            var suitableCards: [[FoundedCardParameters]] = findSuitableCardsForGameArrayPosition(gameArrayPos: gameArrayPos)
            var go = true
//            var colorCounts: [Int:Int] = [:]
            var searchColorIndexes: [Int] = []
            for color in 0..<MaxColorValue {
                searchColorIndexes.append(color)
//                colorCounts[color] = colorArray[color].allCards.count
            }
            

            while go {
                var searchColorIndex = 0
                while true {
                    searchColorIndex = random!.getRandomInt(0, max: searchColorIndexes.count - 1)
                    if suitableCards[searchColorIndex].count > 0 {
                        break
                    }
                    searchColorIndexes.remove(at: searchColorIndex)
                    if searchColorIndexes.count == 0 {
                        searchColorIndex = 0
                        go = false
                        break
                    }
                }
                
                var countSearches = suitableCards[searchColorIndex].count

                while countSearches > 0 {
                    let cardIndex = random!.getRandomInt(0, max: suitableCards[searchColorIndex].count - 1)
                    let cardToSearch = suitableCards[searchColorIndex][cardIndex]
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
                            cardStack.push(card)
                        }
                    } else {
                        suitableCards[searchColorIndex].remove(at: cardIndex)
                    }
                    countSearches -= 1
                }
                
            }
        }
        _ = createTipps()
        return cardArray
    }
    
    
    private func findSuitableCardsForGameArrayPosition(gameArrayPos: ColumnRow)->[[FoundedCardParameters]] {
        var foundedCards: [[FoundedCardParameters]] = [[],[],[],[]] // one Array for each color
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
            let foundedCardUsing = colorArray[cardParameter.colorIndex].usedCards[cardParameter.value]!
            if /*foundedCardUsing.countFree > 0 ||*/ foundedCardUsing.countInStack == 0 {
                return
            }
            var cardNotFound = true
            for card in foundedCards[cardParameter.colorIndex] {
                if card == cardParameter {
                    cardNotFound = false
                }
            }
            if cardNotFound {
                var usable = true
                for card in colorArray[cardParameter.colorIndex].allCards {
                    if card.countCards == 1 && card.minValue == cardParameter.value {
                        usable = false
                        break
                    }
                }
                if usable {
                    foundedCards[cardParameter.colorIndex].append(cardParameter)
                }
            }
        }
        //==========================================
        while angle <= stopAngle {
            let toPoint = GV.pointOfCircle(10.0, center: startPoint, angle: angle)
            let (foundedPoint, myPoints) = createHelpLines(movedFrom: startCard, toPoint: toPoint, inFrame: GV.mainScene!.frame, lineSize: cardSize.width, showLines: false)
            if foundedPoint != nil {
                var foundedCard: MySKCard
                var cardParameter = FoundedCardParameters()
                cardParameter.myPoints = myPoints
                if foundedPoint!.foundContainer {
                    foundedCard = containers[foundedPoint!.column]
                    cardParameter.colorIndex = foundedCard.colorIndex
                    if foundedCard.minValue == NoColor { //empty Container
                        cardParameter.value = LastCardValue
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
                        appendCardParameter(cardParameter: cardParameter)
                    } else if foundedCard.belongsToPackageMin & minPackage == 0 && countPackages > 1 {
                        cardParameter.value = LastCardValue
                        appendCardParameter(cardParameter: cardParameter)
                    }
                } else {
                    foundedCard = gameArray[foundedPoint!.column][foundedPoint!.row].card
                    cardParameter.colorIndex = foundedCard.colorIndex
                    if foundedCard.type == .cardType {
                        if foundedCard.maxValue == LastCardValue && countPackages > 1 {
                            if foundedCard.belongsToPackageMax & maxPackage == 0 {
                                cardParameter.value = FirstCardValue
                                appendCardParameter(cardParameter: cardParameter)
                            }
                        } else if foundedCard.minValue == FirstCardValue  && countPackages > 1 {
                            if foundedCard.belongsToPackageMin & minPackage == 0 {
                                cardParameter.value = LastCardValue
                                appendCardParameter(cardParameter: cardParameter)
                            }
                        } else if foundedCard.minValue != FirstCardValue && foundedCard.maxValue != LastCardValue {
                            cardParameter.value = foundedCard.minValue - 1
                            appendCardParameter(cardParameter: cardParameter)
                            cardParameter.value = foundedCard.maxValue + 1
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
            drawHelpLines(points: tippArray[tippIndex].innerTipps.last!.points, lineWidth: cardSize.width, twoArrows: tippArray[tippIndex].innerTipps.last!.twoArrows, color: .green)

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
            drawHelpLines(points: pointArray, lineWidth: lineSize, twoArrows: false, color: color)
        }
        
        return (foundedPoint, pointArray)
    }

    
    private func checkPathToFoundedCards(pair:ConnectablePair) {
        let firstValue: CGFloat = 10000
        func checkPath(card1: MySKCard, card2: MySKCard)->Tipp {
            var myTipp = Tipp()
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
        myTipp.innerTipps.append(contentsOf: myTipp2.innerTipps)
        if myTipp.innerTipps.count > 0 {
            myTipp.innerTipps = myTipp.innerTipps.sorted{$0.value < $1.value}
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
    
    private func drawHelpLines(points: [CGPoint], lineWidth: CGFloat, twoArrows: Bool, color: MyColors) {
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
    
    func printGameArrayInhalt() {
        print(Date())
        var string: String = ""
        for container in containers {
            if container.minValue != NoColor {
                let minStr = (container.minValue != 9 ? " " : "") + MySKCard.cardLib[container.minValue]!
                let maxStr = (container.maxValue != 9 ? " " : "") + MySKCard.cardLib[container.maxValue]!
                if let colorName = String(CardManager.colorNames[container.colorIndex]) {
                    string += "(" + colorName + ")"
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
                    if let colorName = String(CardManager.colorNames[card.colorIndex]) {
                        string += "(" + colorName + ")"
                    }
                    string += maxStr + "-" + minStr
                } else {
                    string += "( )" + " --- "
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
        var connectablePairs: [ConnectablePair] = []
        var pairsToRemove: [Int] = []
        var countTransitions = 0
        var usedCards: [Int:UsedCard] = [:]
        init(colorIndex: Int) {
            
            self.colorIndex = colorIndex
            for index in FirstCardValue...LastCardValue {
                usedCards[index] = UsedCard()
            }
        }
        
        func addCardToUsedCards(card: MySKCard) {
            var index = 0
            while index < card.countCards {
                let value = (card.minValue + index) % CountCardsInPackage
                usedCards[value]!.countAll += 1
                index += 1
            }
            usedCards[card.minValue]!.countFree += 1
            if card.minValue != card.maxValue || card.countTransitions > 0 {
                usedCards[card.maxValue]?.countFree += card.type == .containerType ? 0 : 1
            }
        }
        
        func addCardToTipps(card: MySKCard) {
            
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
            if container != nil {
                
            }
            let pairs = findPair(card: card)
            if pairs.count == 0 {
                allCards.remove(at: allCards.count - 1)
            }
            return pairs
        }
        
        func cardHasConnection(card: MySKCard)->Bool {
            return true
        }
        
        #if TEST
        func printUsedCards() {
            for index in 0..<usedCards.count {
                if let cardName = MySKCard.cardLib[index] {
                    print("card \(cardName). all: \(usedCards[index]!.countAll), free: \(usedCards[index]!.countFree), inStack: \(usedCards[index]!.countInStack)")
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
        

        func analyzeColor() {
            connectablePairs.removeAll()
            pairsToRemove.removeAll()
            cardsWithTransitions.removeAll()
            for index in FirstCardValue...LastCardValue {
                usedCards[index] = UsedCard()
            }
            countTransitions = 0
            findContainer()
            fillAllCards()
            checkCardsWithTransition()
            
            var countChanges = 0
            if let container = container {
                // set the belongingsFlags by all other Cards
                countChanges += setOtherCardBelonging(cardWithTransition: container)
            }
            for card in cardsWithTransitions {
                countChanges += setOtherCardBelonging(cardWithTransition: card)
            }
            var counter = allCards.count
            while countChanges > 0 && counter > 0 {
                countChanges = 0
                for card in allCards {
                    if card.belongsToPackageMax.countOnes() == 1 {  // if more then one possible connections
                        countChanges += setOtherCardBelonging(cardWithTransition: card)
                    }
                }
                counter -= 1
            }
            
            if container != nil {
                _ = findPair(card: container!)
            }
            for index in 0..<allCards.count {
                _ = findPair(card: allCards[index])
            }
            
            if connectablePairs.count > 0 {
                for (index, pair) in connectablePairs.enumerated() {
                    if !pairsToRemove.contains(index) {
                        checkPair(index: index, actPair: pair)
                    }
                }

                if pairsToRemove.count > 0 {
                    for index in pairsToRemove.reversed() {
                        //                    print(connectablePairs[index].printValue)
                        if index < pairsToRemove.count {
                            connectablePairs.remove(at: index)
                        }
                    }
                }
            }
            
            if container != nil {
                container!.setBelongsLabels()
            }
            for card in allCards {
                card.setBelongsLabels()
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

        

        
        private func checkCardsWithTransition() {
            func setBelonging(first: MySKCard, second: MySKCard)->Bool {
                let (_, maxInLower) = first.containsValue(value: second.maxValue)
                let (minInUpper, _) = first.containsValue(value: second.minValue)
                if maxInLower || minInUpper {
                    switch (minInUpper, maxInLower) {
                    case (false, true): // minValue of secondCard in upper of firstCard --> first is below, second is above
                        first.belongsToPackageMax = findLowerBelongs(belongs: first.belongsToPackageMax)
                        first.belongsToPackageMin = first.belongsToPackageMax >> UInt8(first.countTransitions)
                        second.belongsToPackageMax = findUpperBelongs(belongs: second.belongsToPackageMax)
                        second.belongsToPackageMin = second.belongsToPackageMax >> UInt8(second.countTransitions)
                        return true
                    case (true, false): // maxValue of secondCard is in lower of firstCard --> second is above, first is below
                        second.belongsToPackageMax = findUpperBelongs(belongs: second.belongsToPackageMax)
                        second.belongsToPackageMin = second.belongsToPackageMax >> UInt8(second.countTransitions)
                        first.belongsToPackageMax = findLowerBelongs(belongs: first.belongsToPackageMax)
                        first.belongsToPackageMin = first.belongsToPackageMax >> UInt8(first.countTransitions)
                        return true
                    default:
                        return false
                    }
                }
                return false
            }
            if cardsWithTransitions.count < 2 {
                return
            }
            for index in 0..<cardsWithTransitions.count - 1 {
                for index1 in index + 1..<cardsWithTransitions.count {
                    let first = cardsWithTransitions[index]
                    let second = cardsWithTransitions[index1]
                    if !setBelonging(first: first, second: second) {
                        if setBelonging(first: second, second: first) {
                            return
                        }
                    } else {
                        return
                    }
                    
                }
            }
//            let card0 = cardsWithTransitions[0]
//            let card1 = cardsWithTransitions[1]
//            switch (countPackages, cardsWithTransitions.count) {
//            case (3, 2):
//                // [0] --> firstCard, [1] --> secondCard
//                let (_, maxInLower) = card0.containsValue(value: card1.maxValue)
//                let (minInUpper, _) = card0.containsValue(value: card1.minValue)
//                switch (maxInLower, minInUpper) {
//                case (false, true): // minValue of secondCard in upper of firstCard --> first is above, second is below
//                    card0.belongsToPackageMax = findUpperBelongs(belongs: card0.belongsToPackageMax)
//                    card0.belongsToPackageMin = card0.belongsToPackageMax >> UInt8(card0.countTransitions)
//                    card1.belongsToPackageMax = findLowerBelongs(belongs: card1.belongsToPackageMax)
//                    card1.belongsToPackageMin = card1.belongsToPackageMax >> UInt8(card1.countTransitions)
//                case (true, false): // maxValue of secondCard is in lower of firstCard --> second is above, first is below
//                    card1.belongsToPackageMax = findUpperBelongs(belongs: card1.belongsToPackageMax)
//                    card1.belongsToPackageMin = card1.belongsToPackageMax >> UInt8(card1.countTransitions)
//                    card0.belongsToPackageMax = findLowerBelongs(belongs: card0.belongsToPackageMax)
//                    card0.belongsToPackageMin = card0.belongsToPackageMax >> UInt8(card0.countTransitions)
//                default:
//                    return
//                }
//                
//            case (4, 2):
//                let (_, maxInLower) = card0.containsValue(value: card1.maxValue)
//                let (minInUpper, _) = card0.containsValue(value: card1.minValue)
//                switch (maxInLower, minInUpper) {
//                case (false, false), (true, true):
//                    return
//                case (false, true): // minValue of secondCard in upper of firstCard --> first is above, second is below
//                    card0.belongsToPackageMax = findUpperBelongs(belongs: card0.belongsToPackageMax)
//                    card0.belongsToPackageMin = card0.belongsToPackageMax >> UInt8(card0.countTransitions)
//                    card1.belongsToPackageMax = findLowerBelongs(belongs: card1.belongsToPackageMax)
//                    card1.belongsToPackageMin = card1.belongsToPackageMax >> UInt8(card1.countTransitions)
//                case (true, false): // maxValue of secondCard is in lower of firstCard --> second is above, first is below
//                    card1.belongsToPackageMax = findUpperBelongs(belongs: card1.belongsToPackageMax)
//                    card1.belongsToPackageMin = card1.belongsToPackageMax >> UInt8(card1.countTransitions)
//                    card0.belongsToPackageMax = findLowerBelongs(belongs: card0.belongsToPackageMax)
//                    card0.belongsToPackageMin = card0.belongsToPackageMax >> UInt8(card0.countTransitions)
//                }
//            case (4, 3):
//                let card2 = cardsWithTransitions[2]
//                let (_, maxInLower10) = card0.containsValue(value: card1.maxValue)
//                let (minInUpper10, _) = card0.containsValue(value: card1.minValue)
//                let (_, maxInLower20) = card0.containsValue(value: card2.maxValue)
//                let (minInUpper20, _) = card0.containsValue(value: card2.minValue)
//                let (_, maxInLower21) = card1.containsValue(value: card2.maxValue)
//                let (minInUpper21, _) = card1.containsValue(value: card2.minValue)
//                switch (maxInLower10, minInUpper10) {
//                case (false, false), (true, true):
//                    break
//                case (false, true): // minValue of secondCard in upper of firstCard --> first is above, second is below
//                    card0.belongsToPackageMax = findUpperBelongs(belongs: card0.belongsToPackageMax)
//                    card0.belongsToPackageMin = card0.belongsToPackageMax >> UInt8(card0.countTransitions)
//                    card1.belongsToPackageMax = findLowerBelongs(belongs: card1.belongsToPackageMax)
//                    card1.belongsToPackageMin = card1.belongsToPackageMax >> UInt8(card1.countTransitions)
//                case (true, false): // maxValue of secondCard is in lower of firstCard --> second is above, first is below
//                    card1.belongsToPackageMax = findUpperBelongs(belongs: card1.belongsToPackageMax)
//                    card1.belongsToPackageMin = card1.belongsToPackageMax >> UInt8(card1.countTransitions)
//                    card0.belongsToPackageMax = findLowerBelongs(belongs: card0.belongsToPackageMax)
//                    card0.belongsToPackageMin = card0.belongsToPackageMax >> UInt8(card0.countTransitions)
//                }
//                switch (maxInLower20, minInUpper20) {
//                case (false, false), (true, true):
//                    break
//                case (false, true): // minValue of secondCard in upper of firstCard --> first is above, second is below
//                    card0.belongsToPackageMax = findUpperBelongs(belongs: card0.belongsToPackageMax)
//                    card0.belongsToPackageMin = card0.belongsToPackageMax >> UInt8(card0.countTransitions)
//                    card2.belongsToPackageMax = findLowerBelongs(belongs: card2.belongsToPackageMax)
//                    card2.belongsToPackageMin = card2.belongsToPackageMax >> UInt8(card2.countTransitions)
//                case (true, false): // maxValue of secondCard is in lower of firstCard --> second is above, first is below
//                    card2.belongsToPackageMax = findUpperBelongs(belongs: card2.belongsToPackageMax)
//                    card2.belongsToPackageMin = card2.belongsToPackageMax >> UInt8(card2.countTransitions)
//                    card0.belongsToPackageMax = findLowerBelongs(belongs: card0.belongsToPackageMax)
//                    card0.belongsToPackageMin = card0.belongsToPackageMax >> UInt8(card0.countTransitions)
//                }
//                switch (maxInLower21, minInUpper21) {
//                case (false, false), (true, true):
//                    break
//                case (false, true): // minValue of secondCard in upper of firstCard --> first is above, second is below
//                    card1.belongsToPackageMax = findUpperBelongs(belongs: card1.belongsToPackageMax)
//                    card1.belongsToPackageMin = card1.belongsToPackageMax >> UInt8(card1.countTransitions)
//                    card2.belongsToPackageMax = findLowerBelongs(belongs: card2.belongsToPackageMax)
//                    card2.belongsToPackageMin = card2.belongsToPackageMax >> UInt8(card2.countTransitions)
//                case (true, false): // maxValue of secondCard is in lower of firstCard --> second is above, first is below
//                    card2.belongsToPackageMax = findUpperBelongs(belongs: card2.belongsToPackageMax)
//                    card2.belongsToPackageMin = card2.belongsToPackageMax >> UInt8(card2.countTransitions)
//                    card1.belongsToPackageMax = findLowerBelongs(belongs: card1.belongsToPackageMax)
//                    card1.belongsToPackageMin = card1.belongsToPackageMax >> UInt8(card1.countTransitions)
//                }
//           default:
//                return
//            }
        }
        
        func doAction(masterCard: MySKCard, otherCard: MySKCard)->Int {
            func createMask(withMinPackage: Bool = true)->UInt8 {
                var bit = masterCard.belongsToPackageMax
                var mask = masterCard.belongsToPackageMax | (withMinPackage ? masterCard.belongsToPackageMin : 0)
                while bit != masterCard.belongsToPackageMin {
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
                    otherCard.belongsToPackageMax &= ~createMask(withMinPackage: false)
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                case 0b1101:
                    otherCard.belongsToPackageMax &= ~createMask(withMinPackage: false)
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
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
        
        

        
        private func setOtherCardBelonging(cardWithTransition: MySKCard)->Int {
            
            var countChanges = 0
            for otherCard in allCards {
                if cardWithTransition != otherCard {
                     if cardWithTransition.belongsToPackageMax.countOnes() == 1 &&
                        cardWithTransition.belongsToPackageMin.countOnes() == 1 &&
                        otherCard.belongsToPackageMax.countOnes() > 1 &&
                        otherCard.belongsToPackageMin.countOnes() > 1
                    {
                        countChanges += doAction(masterCard: cardWithTransition, otherCard: otherCard)
                    } else {
//                        if cardWithTransition.belongsToPackageMax.countOnes() < otherCard.belongsToPackageMax.countOnes() &&
//                            cardWithTransition.belongsToPackageMin.countOnes() < otherCard.belongsToPackageMin.countOnes() {
//                            countChanges += doAction(masterCard: cardWithTransition, otherCard: otherCard)
//                        }
                    }
                }
            }
            return countChanges
        }
        
        

        private func findPair(card: MySKCard)->[ConnectablePair] {
            var foundedPairs: [ConnectablePair] = []
            func saveIfPair(first: MySKCard, second: MySKCard) {
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
                if card != card1 {
                    saveIfPair(first: card, second: card1)
                }
            }
            return foundedPairs
        }

        private func checkPair(index: Int, actPair: ConnectablePair) {
            if actPair.card1.type == .cardType && actPair.card2.type == .cardType &&
                (actPair.card1.minValue == FirstCardValue && actPair.card2.maxValue == LastCardValue ||
                    actPair.card2.minValue == FirstCardValue && actPair.card1.maxValue == LastCardValue) {
                if checkIfNewCardCompatibleWithCWT(pairToCheck: actPair) {
                    if !pairsToRemove.contains(index) {
                        pairsToRemove.append(index)
                    }
                    return
                }
                for (ind, pair) in connectablePairs.enumerated() {
                    if pair != actPair {
                        if pair.card1.type == .cardType && pair.card2.type == .cardType &&
                            (pair.card1.minValue == FirstCardValue && pair.card2.maxValue == LastCardValue ||
                                pair.card2.minValue == FirstCardValue && pair.card1.maxValue == LastCardValue) {
                            let actPairLen = actPair.card1.countCards + actPair.card2.countCards
                            let pairLen = pair.card1.countCards + pair.card2.countCards
                            if actPairLen >= CountCardsInPackage && pairLen < CountCardsInPackage {
                                if !pairsToRemove.contains(ind) {
                                    pairsToRemove.append(ind)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        func checkIfNewCardCompatibleWithCWT(pairToCheck: ConnectablePair)->Bool {
            for cwt in cardsWithTransitions {
                if cwt != pairToCheck.card1 && cwt != pairToCheck.card2 {
                    var upperCardMaxIncwtUpper = false
                    var upperCardMinIncwtLower = false
                    var cwtMaxInUpperCardUpper = false
                    var cwtMinInLowerCardLower = false
                    var upperCard = pairToCheck.card1
                    var lowerCard = pairToCheck.card2
                    if pairToCheck.card1.maxValue == LastCardValue && pairToCheck.card2.minValue == FirstCardValue {
                        upperCard = pairToCheck.card2
                        lowerCard = pairToCheck.card1
                    }
                    (upperCardMaxIncwtUpper, _) = cwt.containsValue(value: upperCard.maxValue)
                    (_, upperCardMinIncwtLower) = cwt.containsValue(value: lowerCard.minValue)
                    (cwtMaxInUpperCardUpper, _) = upperCard.containsValue(value: cwt.maxValue)
                    (_, cwtMinInLowerCardLower) = lowerCard.containsValue(value: cwt.minValue)
                    if (upperCardMaxIncwtUpper && upperCardMinIncwtLower) || (cwtMaxInUpperCardUpper && cwtMinInLowerCardLower) {
                        return true
                    }
                }
            }
            return false
        }

        private func findContainer() {
            for container in containers {
                if container.colorIndex == colorIndex {
                    container.belongsToPackageMax = maxPackage
                    container.belongsToPackageMin = container.belongsToPackageMax >> UInt8(container.countTransitions)
                    self.container = container
                    countTransitions += container.countTransitions
                    addCardToUsedCards(card: container)
                }
            }
        }

        private func fillAllCards() {
            allCards.removeAll()
            for cardColumn in gameArray {
                for card in cardColumn {
                    if card.used && card.card.colorIndex == colorIndex {
                        addCardToUsedCards(card: card.card)
                        allCards.append(card.card)
                        if card.card.countTransitions > 0 {
                            countTransitions += card.card.countTransitions
                            cardsWithTransitions.append(card.card)
                            switch (countPackages, card.card.countTransitions) {
                            case (2, 1), (3, 2), (4, 3):
                                card.card.belongsToPackageMax = maxPackage
                                card.card.belongsToPackageMin = minPackage
                            case (3, 1), (4, 1):
                                card.card.belongsToPackageMax = allPackages & ~minPackage
                                card.card.belongsToPackageMin = allPackages & ~maxPackage
                            case (4, 2):
                                card.card.belongsToPackageMax = maxPackage + maxPackage >> 1
                                card.card.belongsToPackageMin = minPackage + minPackage << 1
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


    }
}
