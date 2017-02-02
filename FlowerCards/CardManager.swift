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
    private let colorNames = ["Purple", "Blue", "Green", "Red"]
    private let purple = 0
    private let blue = 1
    private let green = 2
    private let red = 3
    private var colorArray: [DataForColor] = []
    

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

    func check(card: MySKCard) {
        analyzeColor(data: &colorArray[card.colorIndex])
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
//        let OK1 = ((first.minValue == second.maxValue + 1 && first.belongsToPackageMin & second.belongsToPackageMax != 0 && second.type != .containerType) ||
//            (first.maxValue == second.minValue - 1 && first.belongsToPackageMax & second.belongsToPackageMin != 0) ||
//            (countPackages > 1 &&
//                first.maxValue == LastCardValue &&
//                second.minValue == FirstCardValue &&
//                second.belongsToPackageMin & ~minPackage != 0 &&
//                first.belongsToPackageMax & ~maxPackage != 0 &&
//                first.countTransitions + second.countTransitions + 1 <= countPackages - 1) ||
//            (countPackages > 1 &&
//                first.minValue == FirstCardValue &&
//                second.maxValue == LastCardValue &&
//                first.belongsToPackageMin & ~minPackage != 0 &&
//                second.belongsToPackageMax & ~maxPackage != 0 &&
//                first.countTransitions + second.countTransitions + 1 <= countPackages - 1 &&
//                countTransitionsForColor <= countPackages - 1 &&
//                second.type != .containerType))
        if OK
        {
//            if !OK1 {
//                print ("calculated result (false) is false")
//            }
            return true
        }
//        if OK1 {
//            print ("calculated result (true) is false")
//        }
        
        return false
    }
    
//    private func deleteCard(card: MySKCard) {
//        for (index, cardInCycle) in colorArray[card.colorIndex].allCards.enumerated() {
//            if card.column == cardInCycle.column && card.row == cardInCycle.row {
//                colorArray[card.colorIndex].allCards.remove(at: index)
//                break
//            }
//        }
//    }
//    
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
            var switchValue: UInt16 = 0
            var switchValue1: UInt16 = 0
            var index = 0
            for (ind, otherCard) in data.allCards.enumerated() {
                index = ind
                let maxInUpper = 16
                let minInUpper = 8
                let allCountTransitions = 4
                let maxInLower = 2
                let minInLower = 1
                if cardWithTransition != otherCard && otherCard.belongsToPackageMax.countOnes() > 1 && otherCard.belongsToPackageMin.countOnes() > 1 {
                    
                    let b1 = UInt16(countPackages - 1) << 8
                    let b2 = UInt16(cardWithTransition.countTransitions) << 6
                    let b3 = UInt16(otherCard.countTransitions) << 4
                    
                    let c1: UInt16 = UInt16(upperValues.contains(otherCard.maxValue) ? 8 : 0)
                    let c2: UInt16 = UInt16(upperValues.contains(otherCard.minValue) ? 4 : 0)
                    let c3: UInt16 = UInt16(lowerValues.contains(otherCard.maxValue) ? 2 : 0)
                    let c4: UInt16 = UInt16(lowerValues.contains(otherCard.minValue) ? 1 : 0)

                    switchValue = b1 + b2 + b3
                    switchValue += c1 + c2 + c3 + c4
                    if !setOfBinarys.contains(switchValue1.toBinary(len:12)) {
                        setOfBinarys.append(switchValue1.toBinary(len:12))
                    }
                    if cardWithTransition.belongsToPackageMax.countOnes() == 1 { // check only if belongs to 1 concrete Package
                        switch switchValue {
                        case 0b0100000000, 0b1000000000, 0b1100000000:
                            break
                        case 0b0100001000: // 2 Packages, e.g. cwt: K-0-K (2/2) other: K-0-Q
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b0100000100: // 2 Packages, e.g. cwt: 6-0-A (1/1) other: 8-0-4
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b0100001100: // 2 Packages, e.g. cwt: K-0-10, other: Q-0-Q
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b0101000000: // 2 Packages, e.g. cwt: A-1-K, other: 9-0-9 --> break, nothing to do
                            break
                        case 0b0101000010: // 2 Packages, e.g. cwt: 2-1-Q, other: Q-0-9
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMin
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b0101000011: // 2 Packages, e.g. cwt: A-1-K, other: K-0-K
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMin
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b0101000100: // 2 Packages, e.g. cwt: A-1-K, other: 2-0-A
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b0101001100: // 2 Packages, e.g. cwt: A-1-K, other: A-0-A
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                            
                            
                            
                        case 0b1001000000: // 2 Packages, e.g. cwt: A-1-K, other: 9-0-9 --> break, nothing to do
                            break
                        case 0b1000000100: // 3 Packages, e.g. cwt: 7-0-2 (1/1) other: 8-0-7 (3/3)
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b1000001100: // 3 Packages, e.g. cwt: K-0-Q (4/4, container) other: K-0-K
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b1000001000: // 3 Packages, e.g. cwt: K-0-Q (4/4, container) other: Q-0-J
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b1000010100: // 3 Packages, e.g. cwt: K-0-Q (4/4, container) other: 3-1-Q
                            otherCard.belongsToPackageMin &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << 1
                            countChanges += 1
                        case 0b1000011000: // 3 Packages, e.g. cwt: K-0-K (4/4, container) other: K-1-J (6/3)
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> 1
                            countChanges += 1
                        case 0b1000011100: // 3 Packages, e.g. cwt: K-0-4 (4/4, container) other: 8-1-10 (6/3)
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMin >> 1
                            countChanges += 1
                        case 0b1001000011: // 3 Packages, e.g. cwt: A-1-Q (6/3) other: K-0-K (7/7) nothing to do
                            otherCard.belongsToPackageMin &= ~cardWithTransition.belongsToPackageMin
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin
                            countChanges += 1
                        case 0b1001000100: // 3 Packages, e.g. cwt: 6-1-K (2/1) other: 7-0-2 (3/3)
                            otherCard.belongsToPackageMin &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin
                            countChanges += 1
                        case 0b1001001100: // 3 Packages, e.g. cwt: A-1-K (6/3) other: A-0-A (7/7)
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b1001001110: // 3 Packages, e.g. cwt: K-1-3 (4/2, container) other: 3-0-2 (7/7)
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax & ~cardWithTransition.belongsToPackageMin
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b1001001111: // 3 Packages, e.g. cwt: K-1-10 (4/2) other: 10-0-10 (7/7)
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax & ~cardWithTransition.belongsToPackageMin
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b1001011100: // 3 Packages, e.g. cwt: K-1-10 (4/2) other: 5-1-9 (6/3)
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> 1
                            countChanges += 1
                        case 0b1001011101: // 3 Packages, e.g. cwt: K-1-10 (4/2) other: 6-1-K (6/3)
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> 1
                            countChanges += 1
                        case 0b1010000000: // 3 Packages, e.g. cwt: 2-2-Q (4/1) other: 6-0-6 (7/7) --> nothing to do
                            break
                        case 0b1010000010: // 3 Packages, e.g. cwt: 4-2-Q (4/1) other: Q-0-6 (7/7)
                            otherCard.belongsToPackageMax = maxPackage
                            otherCard.belongsToPackageMin = maxPackage
                            countChanges += 1                            
                        case 0b1010000011: // 3 Packages, e.g. cwt: 2-2-Q (4/1) other: K-0-Q (7/7)
                            otherCard.belongsToPackageMax = maxPackage
                            otherCard.belongsToPackageMin = maxPackage
                            countChanges += 1
                        case 0b1010001100: // 3 Packages, e.g. cwt: 2-2-Q (4/1) other: 2-0-2 (7/7)
                            otherCard.belongsToPackageMax = minPackage
                            otherCard.belongsToPackageMin = minPackage
                            countChanges += 1
                        case 0b1000010000: // 3 Packages, e.g. cwt: K-0-K (6/3) other: K-0-K (7/7) --> nothing to do
                            break
                            
                            
                        case 0b1100001000: // 4 Packages, e.g. cwt: 8-0-2 other: 5-0-1
                            otherCard.belongsToPackageMax &= ~cardWithTransition.belongsToPackageMax
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax
                            countChanges += 1
                        case 0b1100010000: // 4 Packages, e.g. cwt: K-0-5 other: 3-1-J
                            break
                        case 0b1100011000: // 4 Packages, e.g. cwt: K-0-10 other: 8-1-J
                            break
                        default:
                            
                            print("not implemented: \(switchValue1.toBinary(len:12))")
                            break
                        }
                    }
                    if otherCard.belongsToPackageMax == 0 {
//                        print ("\(otherCard.printValue)")
                    }
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
        if data.allCards.count > 0 {
//            print("foundedPairs: \(data.connectablePairs.count) for color: \(colorNames[data.allCards[0].colorIndex])")
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
