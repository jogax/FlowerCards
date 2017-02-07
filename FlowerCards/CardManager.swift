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

    func check(color: Int) {
        _ = analyzeColor(data: &colorArray[color])
    }
    
    func checkIfCardUsable(card: MySKCard)->Bool {
        return analyzeColor(data: &colorArray[card.colorIndex], cardToCheck: card)
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
        
    private func analyzeColor(data: inout DataForColor, cardToCheck: MySKCard? = nil)->Bool {
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
        
        if let checkCard = cardToCheck {
            if data.container != nil {
                
            }
            return true
        } else {
            data.connectablePairs.removeAll()
            data.cardsWithTransitions.removeAll()
            data.countTransitions = 0

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
        return true
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
