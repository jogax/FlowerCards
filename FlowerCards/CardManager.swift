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
                            card.card.belongsToPackageMax = allPackages & ~minPackage
                            card.card.belongsToPackageMin = allPackages & ~maxPackage
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
                    if card.minValue == card1.maxValue + 1 && card.belongsToPackageMin & card1.belongsToPackageMax != 0
                    ||
                        card.maxValue == card1.minValue - 1 && card.belongsToPackageMax & card1.belongsToPackageMin != 0
                    ||
                        card.minValue == FirstCardValue &&
                        card1.maxValue == LastCardValue &&
                        card.belongsToPackageMin & ~minPackage != 0 &&
                        card1.belongsToPackageMax & ~maxPackage != 0 &&
                        data.countTransitions < countPackages - 1
                    ||
                        card.maxValue == LastCardValue &&
                        card1.minValue == FirstCardValue &&
                        card1.belongsToPackageMax & ~minPackage != 0 &&
                        data.countTransitions < countPackages - 1
                    ||
                        card.type == .containerType && card.colorIndex == NoValue && card1.maxValue == LastCardValue
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
            var switchValue = 0
            var index = 0
            for (ind, otherCard) in data.allCards.enumerated() {
                index = ind
                let maxInUpper = 16
                let minInUpper = 8
                let allCountTransitions = 4
                let maxInLower = 2
                let minInLower = 1
                if cardWithTransition != otherCard && otherCard.belongsToPackageMax.countOnes() > 1 && otherCard.belongsToPackageMin.countOnes() > 1 {
                    let a1 = upperValues.contains(otherCard.maxValue) ? maxInUpper : 0
                    let a2 = upperValues.contains(otherCard.minValue) ? minInUpper : 0
                    let a3 = data.countTransitions == countPackages - 1 ? allCountTransitions : 0
                    let a4 = lowerValues.contains(otherCard.maxValue) ? maxInLower : 0
                    let a5 = lowerValues.contains(otherCard.minValue) ? minInLower : 0
                    switchValue = a1 + a2 + a3 + a4 + a5
                    switch switchValue
//                        (upperValues.contains(otherCard.maxValue),
//                        upperValues.contains(otherCard.minValue),
//                        data.countTransitions == countPackages - 1,
//                        lowerValues.contains(otherCard.maxValue),
//                        lowerValues.contains(otherCard.minValue))
                    {
                    case 31: // 11111
                        otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin | cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        countChanges += 1
                    case 30: // 11110
                        otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin | cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        countChanges += 1
                    case 28: // 11100 -> maxInUpper + minInUpper + allCountTransitions + 0 + 0: // (true, true, true, false, false): #28
                        if cardWithTransition.belongsToPackageMax == maxPackage {
                            otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMax >> 1 | cardWithTransition.belongsToPackageMax >> 2 | cardWithTransition.belongsToPackageMax >> 3
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        } else if cardWithTransition.belongsToPackageMax == minPackage {
                            otherCard.belongsToPackageMin &= (cardWithTransition.belongsToPackageMax << 1 | cardWithTransition.belongsToPackageMax << 2 | cardWithTransition.belongsToPackageMax << 3) & allPackages
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                        }
                        countChanges += 1
                    case 27: // 11011 -> (true, true, false, true, true)
                        if cardWithTransition.belongsToPackageMax < maxPackage {
                            otherCard.belongsToPackageMin &= cardWithTransition.belongsToPackageMax << 1 |
                                                             cardWithTransition.belongsToPackageMax << 2
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                        } else {
                            otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        }
                        countChanges += 1
                    case 26: //11010 -> (true, true, false, true, false)
                        otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        countChanges += 1
                    case 25: //11001 -> (true, true, false, false, true):
                        otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        countChanges += 1
                    case 24: //11000 -> maxInUpper + minInUpper + 0 + 0 + 0: //(true, true, false, false, false): #24
                        if cardWithTransition.belongsToPackageMax == maxPackage {
                            otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMax >> 1 | cardWithTransition.belongsToPackageMax >> 2 | cardWithTransition.belongsToPackageMax >> 3
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                            if otherCard.belongsToPackageMin.countOnes() == 1 {
                                otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << 1
                            }
                            countChanges += 1
                        } else if cardWithTransition.belongsToPackageMax == minPackage {
                            otherCard.belongsToPackageMin &= (cardWithTransition.belongsToPackageMax << 1 | cardWithTransition.belongsToPackageMax << 2 | cardWithTransition.belongsToPackageMax << 3) & allPackages
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                            countChanges += 1
                        }
                    case 23: // 10111
                        otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin | cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        countChanges += 1
                    case 22: // 10110
                        otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin | cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        countChanges += 1
                    case 20: // 10100  -> maxInUpper + 0 + allCountTransitions + 0 + 0: // (true, false, true, false, false): #20
                        if cardWithTransition.belongsToPackageMax == maxPackage {
                            otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMax >> 1 | cardWithTransition.belongsToPackageMax >> 2 | cardWithTransition.belongsToPackageMax >> 3
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        } else if cardWithTransition.belongsToPackageMax == minPackage {
                            otherCard.belongsToPackageMin &= (cardWithTransition.belongsToPackageMax << 1 | cardWithTransition.belongsToPackageMax << 2 | cardWithTransition.belongsToPackageMax << 3) & allPackages
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                        }
                        countChanges += 1
                    case 19: // 01011
                        otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        countChanges += 1
                    case 18: // 01010
                        otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        countChanges += 1
                    case 17: //10001 -> (true, false, false, false, true)
                        otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        countChanges += 1
                    case 16: // 10000 -> maxInUpper + 0 + 0 + 0 + 0: //(true, false, false, false, false): #16
                        if cardWithTransition.type == .containerType {
                            otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        } else if cardWithTransition.belongsToPackageMax == maxPackage && cardWithTransition.countTransitions == 0 {
                            otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        } else if cardWithTransition.belongsToPackageMax == maxPackage && cardWithTransition.countTransitions > 0 {
                            otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin | cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2
                            otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        } else {
                            otherCard.belongsToPackageMin &= (cardWithTransition.belongsToPackageMax << 1 | cardWithTransition.belongsToPackageMax << 2 | cardWithTransition.belongsToPackageMax << 3) & allPackages
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                        }
                        countChanges += 1
                    case 14: // 01110
                        if cardWithTransition.belongsToPackageMax == maxPackage {
                            if cardWithTransition.countTransitions > 0 {
                                otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin | cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2
                                otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                            } else {
                                otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                                otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                            }
                        } else if cardWithTransition.belongsToPackageMax == minPackage {
                            otherCard.belongsToPackageMin &= (cardWithTransition.belongsToPackageMax << 1 | cardWithTransition.belongsToPackageMax << 2 | cardWithTransition.belongsToPackageMax << 3) & allPackages
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                        }
                        countChanges += 1
                        
                    case 13, 12: // 01101
                        if cardWithTransition.belongsToPackageMax == maxPackage {
                            if cardWithTransition.countTransitions > 0 {
                                otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin | cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2
                                otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                            } else {
                                otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMin >> 1 | cardWithTransition.belongsToPackageMin >> 2 | cardWithTransition.belongsToPackageMin >> 3
                                otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                            }
                        } else if cardWithTransition.belongsToPackageMax == minPackage {
                            otherCard.belongsToPackageMin &= (cardWithTransition.belongsToPackageMax << 1 | cardWithTransition.belongsToPackageMax << 2 | cardWithTransition.belongsToPackageMax << 3) & allPackages
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                        }
                        countChanges += 1
                    case 9, 8: // 01001, 01000
                        otherCard.belongsToPackageMin &= allPackages & ~cardWithTransition.belongsToPackageMax
                        otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                        countChanges += 1
                    case 7, 6, 5: //00111, 00110, 00101
                        if cardWithTransition.countTransitions > 0 {
                            otherCard.belongsToPackageMin &= (cardWithTransition.belongsToPackageMax | cardWithTransition.belongsToPackageMax << 1 | cardWithTransition.belongsToPackageMax << 2 | cardWithTransition.belongsToPackageMax << 3) & allPackages
                            otherCard.belongsToPackageMax = otherCard.belongsToPackageMin << UInt8(otherCard.countTransitions)
                        }
                        countChanges += 1
                    case 2: // 00010
                        otherCard.belongsToPackageMax &= cardWithTransition.belongsToPackageMax
                        otherCard.belongsToPackageMin = otherCard.belongsToPackageMax >> UInt8(otherCard.countTransitions)
                        countChanges += 1
                    default:
                        break
                    }
                    if otherCard.belongsToPackageMax == 0 {
                        print ("\(otherCard.printValue)")
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
                    print(data.connectablePairs[index].printValue)
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
