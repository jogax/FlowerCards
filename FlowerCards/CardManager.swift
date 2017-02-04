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



// for managing of connectibility of gameArray members
class CardManager {
    
    var setOfBinarys: [String] = []


    struct ConnectablePair {
        var card1: MySKCard
        var card2: MySKCard
        func convertCard(card: MySKCard)->String {
            return "\(card.countTransitions)-\(card.minValue)-\(card.maxValue)-\(card.column)-\(card.row)-\(card.type)"
        }
        var printValue: String {
            get {
                let value = "\(card1.printValue) - \(card2.printValue)"
                return value
            }
        }
        var hashValue : String {
            get {
                return  convertCard(card: card1) + "-" + convertCard(card: card2)
            }
        }
        var hashValue1 : String {
            get {
                return convertCard(card: card2) + "-" + convertCard(card: card1)
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
//    enum ToDoValues: Int {
//        case NothingToDo = 0,
//        MaxInUpper,
//        MaxInLower,
//        MinInUpper,
//        MinInLower,
//        MinInUpperLower,
//        SecondMinMaxToMaxPackage,
//        SecondMinMaxToMinPackage
//    }
    private let colorNames = ["Purple", "Blue", "Green", "Red"]
    private let purple = 0
    private let blue = 1
    private let green = 2
    private let red = 3
    private var colorArray: [DataForColor] = []
//    let ToDoTable: [UInt16:ToDoValues] = [
//        0b0100000000: .NothingToDo,
//        0b1000000000: .NothingToDo,
//        0b0100000100: .SecondMaxInFirstMax,         // 2 Packages, e.g. cwt: 6-0-A (1/1) other: 8-0-4
//        0b0100001000: .SecondMaxInFirstMax,         // 2 Packages, e.g. cwt: K-0-K (2/2) other: K-0-Q
//        0b0100001100: .SecondMaxInFirstMax,         // 2 Packages, e.g. cwt: K-0-10, other: Q-0-Q
//        0b0101000000: .NothingToDo,                 // 2 Packages, e.g. cwt: A-1-K, other: 9-0-9 --> break, nothing to do
//        0b0101000010: .SecondMaxInFirstMin,         // 2 Packages, e.g. cwt: 2-1-Q, other: Q-0-9
//        0b0101000011: .SecondMaxInFirstMin,         // 2 Packages, e.g. cwt: A-1-K, other: K-0-K
//        0b0101000100: .SecondMaxInFirstMax,         // 2 Packages, e.g. cwt: A-1-K, other: 2-0-A
//        0b0101001100: .SecondMaxInFirstMax,         // 2 Packages, e.g. cwt: A-1-K, other: A-0-A
//
//        0b1001000000: .NothingToDo,                 // 2 Packages, e.g. cwt: A-1-K, other: 9-0-9 --> break, nothing to do
//        0b1000000100: .SecondMaxInFirstMax,         // 3 Packages, e.g. cwt: 7-0-2 (1/1) other: 8-0-7 (3/3)
//        0b1000001100: .SecondMaxInFirstMax,         // 3 Packages, e.g. cwt: K-0-Q (4/4, container) other: K-0-K
//        0b1000001000: .SecondMaxInFirstMax,         // 3 Packages, e.g. cwt: K-0-Q (4/4, container) other: Q-0-J
//        0b1000010100: .SecondMinInFirstMaxShift1,   // 3 Packages, e.g. cwt: K-0-Q (4/4, container) other: 3-1-Q
//        0b1000011000: .SecondMaxInFirstMaxShift1,   // 3 Packages, e.g. cwt: K-0-K (4/4, container) other: K-1-J (6/3)
//        0b1000011100: .SecondMaxInFirstMaxShift1,   // 3 Packages, e.g. cwt: K-0-4 (4/4, container) other: 8-1-10 (6/3)
//        0b1001000011: .SecondMinInFirstMin,         // 3 Packages, e.g. cwt: A-1-Q (6/3) other: K-0-K (7/7) nothing to do
//        0b1001000100: .SecondMinInFirstMax,         // 3 Packages, e.g. cwt: 6-1-K (2/1) other: 7-0-2 (3/3)
//        0b1001001100: .SecondMaxInFirstMax,         // 3 Packages, e.g. cwt: A-1-K (6/3) other: A-0-A (7/7)
//        0b1001001110: .SecondMaxInFirstMaxAndFirstMin, // 3 Packages, e.g. cwt: K-1-3 (4/2, container) other: 3-0-2 (7/7)
//        0b1001001111: .SecondMaxInFirstMaxAndFirstMin, // 3 Packages, e.g. cwt: K-1-10 (4/2) other: 10-0-10 (7/7)
//        0b1001011100: .SecondMaxInFirstMaxShift1,   // 3 Packages, e.g. cwt: K-1-10 (4/2) other: 5-1-9 (6/3)
//        0b1001011101: .SecondMaxInFirstMaxShift1,   // 3 Packages, e.g. cwt: K-1-10 (4/2) other: 6-1-K (6/3)
//        0b1010000000: .NothingToDo,                 // 3 Packages, e.g. cwt: 2-2-Q (4/1) other: 6-0-6 (7/7) --> nothing to do
//        0b1010000010: .SecondMinMaxToMaxPackage,    // 3 Packages, e.g. cwt: 4-2-Q (4/1) other: Q-0-6 (7/7)
//        0b1010000011: .SecondMinMaxToMaxPackage,    // 3 Packages, e.g. cwt: 2-2-Q (4/1) other: K-0-Q (7/7)
//        0b1010001100: .SecondMinMaxToMinPackage,    // 3 Packages, e.g. cwt: 2-2-Q (4/1) other: 2-0-2 (7/7)
//        0b1000010000: .NothingToDo,                 // 3 Packages, e.g. cwt: K-0-K (6/3) other: K-0-K (7/7) --> nothing to do
//        0b1100000000: .NothingToDo,
//        0b1100001000: .SecondMaxInFirstMax,         // 4 Packages, e.g. cwt: 8-0-2 other: 5-0-1
//        0b1100010000: .NothingToDo,                 // 4 Packages, e.g. cwt: K-0-5 other: 3-1-J
//        0b1100011000: .NothingToDo,                 // 4 Packages, e.g. cwt: K-0-10 other: 8-1-J
//    ]
//
//    private let toDoTable: [UInt16:ToDoValues] = [:]
//    

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
//        fillToDoTable()
    }

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
                        (card.type == .containerType && card.colorIndex == NoValue && card1.maxValue == LastCardValue)
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
            func findCardValues(card: MySKCard)->(upper:[Int], mid: [Int], lower: [Int]) {
                var upperValues: [Int] = []
                var midValues: [Int] = []
                var lowerValues: [Int] = []
                var value = card.maxValue
                var countUpperValues = 0
                var countMidValues = 0
                var countLowerValues = 0
                if card.countTransitions == 0 {
                    countUpperValues = card.maxValue - card.minValue + 1
                } else {
                    countUpperValues = card.maxValue + 1
                    countMidValues = (card.countTransitions - 1) * MaxCardValue
                    countLowerValues = LastCardValue - card.minValue + 1
                }
                for _ in 0..<countUpperValues {
                    upperValues.append(value)
                    value -= 1
                }
                value = LastCardValue
                for _ in 0..<countMidValues {
                    midValues.append(value)
                    value -= 1
                }
                value = LastCardValue
                for _ in 0..<countLowerValues {
                    lowerValues.append(value)
                    value -= 1
                }
                return (upper: upperValues, mid: midValues, lower: lowerValues)
            }
            
            
            let (upperValues, _, lowerValues) = findCardValues(card: cardWithTransition)
            var countChanges = 0
            var switchValue: UInt8 = 0
            var index = 0
            for (ind, otherCard) in data.allCards.enumerated() {
                func doAction(toDo: UInt8) {
                    let savedBelongsToPackageMin = otherCard.belongsToPackageMin
                    let savedBelongsToPackageMax = otherCard.belongsToPackageMax
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
                    otherCard.belongsToPackageMin &= ~cardWithTransition.belongsToPackageMax & ~cardWithTransition.belongsToPackageMin
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
                    otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax & ~cardWithTransition.belongsToPackageMin
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1011() {
                    otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax & ~cardWithTransition.belongsToPackageMin
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1100() {
                    otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1101() {
                    otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1110() {
                    otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax & ~cardWithTransition.belongsToPackageMin
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
                func set0b1111() {
                    otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax & ~cardWithTransition.belongsToPackageMin
                    otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                }
//                func setSecondMinMaxToMaxPackage() {
//                    otherCard.belongsToPackageMax = maxPackage
//                    otherCard.belongsToPackageMin = maxPackage
//                }
//                func setSecondMinMaxToMinPackage() {
//                    otherCard.belongsToPackageMax = minPackage
//                    otherCard.belongsToPackageMin = minPackage
//                }
                index = ind
                if cardWithTransition != otherCard &&
                    cardWithTransition.belongsToPackageMax.countOnes() == 1 &&
                    cardWithTransition.belongsToPackageMin.countOnes() == 1 &&
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
//                    if !setOfBinarys.contains(switchValue.toBinary(len:12)) {
//                        setOfBinarys.append(switchValue.toBinary(len:12))
//                    }
//                    if cardWithTransition.belongsToPackageMax.countOnes() == 1 { // check only if belongs to 1 concrete Package
//                        if let toDoValue = ToDoTable[switchValue] {
//                            doAction(toDo: toDoValue)
//                        } else {
//                            print("not Implemented: \(switchValue)")
//                        }
//                    }
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
                    data.connectablePairs.remove(at: index)
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

}
