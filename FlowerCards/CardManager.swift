//
//  GameArrayManager.swift
//  FlowerCards
//
//  Created by Jozsef Romhanyi on 30/12/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import SpriteKit

var allPackages: UInt8 = 0
var maxPackage: UInt8 = 0
var minPackage: UInt8 = 0
let bitMaskForPackages: [UInt8] = [1, 2, 4, 8]
let maxPackageCount = 4

var stopCreateTippsInBackground = false
var tippArray = [Tipps]()
var showHelpLines: ShowHelpLine = .green
var cardSize:CGSize = CGSize(width: 0, height: 0)

let myLineName = "myLine"

var lineWidthMultiplierNormal = CGFloat(0.04) //(0.0625)
let lineWidthMultiplierSpecial = CGFloat(0.125)
var lineWidthMultiplier: CGFloat?
let fixationTime = 0.1


var lastPair = PairStatus() {
didSet {
    if oldValue.color != lastPair.color {
        lastPair.startTime = Date()
        lastPair.changeTime = lastPair.startTime
    }
}
}




// for managing of connectibility of gameArray members
class CardManager {
    
    var setOfBinarys: [String] = []
    var tremblingCards: [MySKCard] = []

    var tippIndex = 0
    var lastNextPoint: Founded?

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
        var printValue: String {
            get {
                let value = "\(card1.printValue) - \(card2.printValue)"
                return value
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

    struct DataForColor {
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
    
    func check() {
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
    
//    private func fillToDoTable() {
//        for packageIndex in 2...maxPackageCount {
//            for cwtCountTransitions in 0...maxPackageCount - 1 {
//                for otherCountTransitions in 0...maxPackageCount - 1 {
//                    for upperIndex in 0...3 {
//                        for lowerIndex in 0...3 {
//                            if cwtCountTransitions + otherCountTransitions < packageIndex {
//                                if otherCountTransitions > 0 || lowerIndex == 0 {
//                                    var switchValue: UInt16 = UInt16(packageIndex - 1) << 8
//                                        switchValue += UInt16(cwtCountTransitions << 6)
//                                        switchValue += UInt16(otherCountTransitions << 4)
//                                        switchValue += UInt16(upperIndex << 2)
//                                        switchValue += UInt16(lowerIndex)
//                                    var toDo: ToDoValues
//                                    switch upperIndex << 2 + lowerIndex {
////                                    case 0b0001: toDo = .SecondMinInFirstMin
////                                    case 0b0100:
//                                    default: toDo = .NothingToDo
//                                    }
//                                    print("\(switchValue.toBinary(len: 12))")
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    
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
        func findPair(card: MySKCard, startIndex: Int = -1) {
            if data.allCards.count > 0 {
                for index in startIndex + 1..<data.allCards.count {
                    let card1 = data.allCards[index]
//                    checkCardBelonging(data: &data, card: card1)
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
            findPair(card: data.allCards[index], startIndex: index)
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
                        if actPairLen >= MaxCardValue && pairLen < MaxCardValue {
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
//            countValues = card.maxValue + MaxCardValue - card.minValue + 1 + (MaxCardValue * (card.countTransitions - 1))
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
        //        cardManager!.check()
        
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
                                let connectable = areConnectable(first: first, second: second)
                                if (column1 != column2 || row1 != row2) && connectable {
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
                    let cardToCheck = gameArray[column1][row1].card
                    for (index, container) in containers.enumerated() {
                        if cardToCheck.belongsToPackageMax & container.belongsToPackageMin != 0 || cardToCheck.maxValue == LastCardValue && container.minValue == FirstCardValue {
                            if !thisColorHasContainer && container.minValue == NoColor && cardToCheck.maxValue == LastCardValue {
                                let actContainerPair = FromToColumnRow(fromColumnRow: ColumnRow(column: column1, row: row1), toColumnRow: ColumnRow(column: index, row: NoValue))
                                pairsToCheck.append(actContainerPair)
                            } else  if container.colorIndex == cardToCheck.colorIndex &&
                                (container.minValue == cardToCheck.maxValue + 1 ||
                                    (container.minValue ==  FirstCardValue && cardToCheck.maxValue == LastCardValue))   {
                                let actContainerPair = FromToColumnRow(fromColumnRow: ColumnRow(column: column1, row: row1), toColumnRow: ColumnRow(column: index, row: NoValue))
                                pairsToCheck.append(actContainerPair)
                            }
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
                        //                            removeIndex.insert(ind + 1, at: 0)
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
                                //                                removeIndex.insert(ind + index, at: 0)
                            }
                            index += 1
                        }
                        _ = 0
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
        //        if tippArray.count > 0 {
//        tippsButton!.activateButton(true)
        //        } else {
        //            print("No Tipps")
        //        }
        
//        tippIndex = 0  // set tipps to first
        //printFunc(function: "createTipps", start: false)
        return true
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


    private func checkPathToFoundedCards(_ actPair:FromToColumnRow) {
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
            let (foundedPoint, myPoints) = createHelpLines(actPair.fromColumnRow, toPoint: toPoint, inFrame: GV.mainScene!.frame, lineSize: cardSize.width, showLines: false)
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
    
    private func calculateAngle(_ point1: CGPoint, point2: CGPoint) -> (angleRadian:CGFloat, angleDegree: CGFloat) {
        //        let pointOfCircle = CGPoint (x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        let offset = point2 - point1
        let length = offset.length()
        let sinAlpha = offset.y / length
        let angleRadian = asin(sinAlpha);
        let angleDegree = angleRadian * 180.0 / CGFloat(M_PI)
        return (angleRadian, angleDegree)
    }
    
    private func checkForSort(t0: Tipps, t1:Tipps)->Bool {
        let returnValue = gameArray[t0.fromColumn][t0.fromRow].card.colorIndex < gameArray[t1.fromColumn][t1.fromRow].card.colorIndex
            || (gameArray[t0.fromColumn][t0.fromRow].card.colorIndex == gameArray[t1.fromColumn][t1.fromRow].card.colorIndex &&
                (gameArray[t0.fromColumn][t0.fromRow].card.maxValue < gameArray[t1.fromColumn][t1.fromRow].card.minValue
                    || (t0.toRow != NoValue && t1.toRow != NoValue && gameArray[t0.toColumn][t0.toRow].card.maxValue < gameArray[t1.toColumn][t1.toRow].card.minValue)))
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

    private func findEndPoint(_ movedFrom: ColumnRow, fromPoint: CGPoint, toPoint: CGPoint, lineWidth: CGFloat, showLines: Bool)->(pointFounded:Bool, closestPoint: Founded?) {
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
    
//    func findClosestPoint(_ P1: CGPoint, P2: CGPoint, lineWidth: CGFloat, movedFrom: ColumnRow) -> Founded? {
//        
//        /*
//         Ax+By=C  - Equation of a line
//         Line is given with 2 Points (x1, y1) and (x2, y2)
//         A = y2-y1
//         B = x1-x2
//         C = A*x1+B*y1
//         */
//        //let offset = P1 - P2
//        var founded = Founded()
//        for column in 0..<countColumns {
//            for row in 0..<countRows {
//                if gameArray[column][row].used {
//                    let P0 = gameArray[column][row].position
//                    //                    if (P0 - P1).length() > lineWidth { // check all others but not me!!!
//                    if !(movedFrom.column == column && movedFrom.row == row) {
//                        let intersectionPoint = findIntersectionPoint(P1, b:P2, c:P0)
//                        
//                        let distanceToP0 = (intersectionPoint - P0).length()
//                        let distanceToP1 = (intersectionPoint - P1).length()
//                        let distanceToP2 = (intersectionPoint - P2).length()
//                        let lengthOfLineSegment = (P1 - P2).length()
//                        
//                        if distanceToP0 < lineWidth && distanceToP2 < lengthOfLineSegment {
//                            if founded.distanceToP1 > distanceToP1 {
//                                founded.point = intersectionPoint
//                                founded.distanceToP1 = distanceToP1
//                                founded.distanceToP0 = distanceToP0
//                                founded.column = column
//                                founded.row = row
//                                founded.foundContainer = false
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    
//        for index in 0..<countContainers {
//            let P0 = containers[index].position
//            if (P0 - P1).length() > lineWidth { // check all others but not me!!!
//                let intersectionPoint = findIntersectionPoint(P1, b:P2, c:P0)
//                
//                let distanceToP0 = (intersectionPoint - P0).length()
//                let distanceToP1 = (intersectionPoint - P1).length()
//                let distanceToP2 = (intersectionPoint - P2).length()
//                let lengthOfLineSegment = (P1 - P2).length()
//                
//                if distanceToP0 < lineWidth && distanceToP2 < lengthOfLineSegment {
//                    if founded.distanceToP1 > distanceToP1 {
//                        founded.point = intersectionPoint
//                        founded.distanceToP1 = distanceToP1
//                        founded.distanceToP0 = distanceToP0
//                        founded.column = index
//                        founded.row = NoValue
//                        founded.foundContainer = true
//                    }
//                }
//            }
//            
//        }
//        if founded.distanceToP1 != founded.maxDistance {
//            return founded
//        } else {
//            return nil
//        }
//    }
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


    
}
