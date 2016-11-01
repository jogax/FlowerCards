//
//  MySKContainer.swift
//  JLines
//
//  Created by Jozsef Romhanyi on 13.07.15.
//  Copyright (c) 2015 Jozsef Romhanyi. All rights reserved.
//

enum MySKNodeType: Int {
    case spriteType = 0, containerType, buttonType, emptyCardType, showCardType
}

enum TremblingType: Int {
    case noTrembling = 0, changeSize, changeSizeOnce, changePos, changeDirection
}
let NoValue = -1
let NoColor = 1000
let MaxCardValue = 13
let LastCardValue = MaxCardValue - 1
let FirstCardValue = 0
import SpriteKit

class MySKNode: SKSpriteNode {
    
    override var size: CGSize {
        didSet {
            if oldValue != CGSize(width: 0,height: 0) && (type != .buttonType) {
                minValueLabel.fontSize = size.width * fontSizeMultiplier
                maxValueLabel.fontSize = size.width * fontSizeMultiplier
                let positionOffset = CGPoint(x: self.size.width * offsetMultiplier.x,  y: self.size.height * offsetMultiplier.y)
                minValueLabel.position = positionOffset
                maxValueLabel.position = positionOffset
                if BGPictureAdded {
                    BGPicture.size = size
                }
//              print("name: \(name), type: \(type), size: \(size), self.position: \(position), minValueLabel.position: \(minValueLabel.position)")
            }
        }
    }
    var column = 0
    var row = 0
    var colorIndex = 0
    var startPosition = CGPoint.zero
    var minValue: Int
    var maxValue: Int
    var countPackages = 1
    var countScore: Int {
        get {
            return(calculateScore())
//            let midValue = Double(minValue + maxValue + 2) / Double(2)
//            return Int(midValue * Double((maxValue - minValue + 1)))
        }
    }
    var mirrored: Int
    let device = GV.deviceType
    let modelConstantLocal = UIDevice.current.modelName

    var origSize = CGSize(width: 0, height: 0)

    var trembling: CGFloat = 0
    var tremblingType: TremblingType = .noTrembling {
        didSet {
            if oldValue != tremblingType {
                if tremblingType == .noTrembling {
                    self.size = self.origSize
                    trembling = 0
                } else {
                    self.origSize = self.size
                }
            }
        }
    }
    
    var isCard = false
    

    var hitCounter: Int = 0

    var type: MySKNodeType
    var hitLabel = SKLabelNode()
    var maxValueLabel = SKLabelNode()
    var minValueLabel = SKLabelNode()
    var packageLabel = SKLabelNode()
    var BGPicture = SKSpriteNode()
    var BGPictureAdded = false
    
    let cardLib: [Int:String] = [
        0:"A", 1:"2", 2:"3", 3:"4", 4:"5", 5:"6", 6:"7", 7:"8", 8:"9", 9:"10", 10: GV.language.getText(.tcj), 11: GV.language.getText(.tcd), 12: GV.language.getText(.tck), NoColor: ""]
    
    let fontSizeMultiplier: CGFloat = 0.35
    let offsetMultiplier = CGPoint(x: -0.48, y: 0.48)
    let BGOffsetMultiplier = CGPoint(x: -0.10, y: 0.25)
    

    init(texture: SKTexture, type:MySKNodeType, value: Int) {
        //let modelMultiplier: CGFloat = 0.5 //UIDevice.currentDevice().modelSizeConstant
        self.type = type
        self.minValue = value
        self.maxValue = value
        self.mirrored = 0
        
        if value > NoValue {
            isCard = true
        }
        
        switch type {
        case .containerType, .emptyCardType, .showCardType:
            hitCounter = 0
        case .buttonType:
            hitCounter = 0
        case .spriteType:
            hitCounter = 1
        }
        
        

        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        if type == .buttonType {
            hitLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
            hitLabel.fontSize = 20;
            hitLabel.zPosition = self.zPosition + 1
        } else {
            
            hitLabel.position = CGPoint(x: self.position.x, y: self.position.y + self.size.width * 0.08)
            hitLabel.fontSize = 15;
            hitLabel.text = "\(hitCounter)"
            
            //print(minValue, text)
            setLabelText(minValueLabel, value: minValue, dotCount: countPackages == 1 ? 0 : countPackages - 1)
            minValueLabel.zPosition = self.zPosition + 1
            
            
        }
        
        setLabel(hitLabel, fontSize: 15)
        setLabel(maxValueLabel, fontSize: size.width * fontSizeMultiplier)
        setLabel(minValueLabel, fontSize: size.width * fontSizeMultiplier)
        

        
        if isCard {
            if minValue == NoColor {
                switch type {
                    case .containerType: alpha = 0.5
                    case .emptyCardType: alpha = 0.1
                    default: alpha = 1.0
                }
            }
            self.addChild(minValueLabel)
        } else {
            self.addChild(hitLabel)
        }

    }
    
    func setLabel(_ label: SKLabelNode, fontSize: CGFloat) {
        label.fontName = "ArielItalic"
        label.fontColor = SKColor.black
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top
        label.isUserInteractionEnabled = false
    }
    
    func reload() {
        if isCard {
            setLabelText(minValueLabel, value: minValue, dotCount: countPackages == 1 ? 0 : countPackages - 1)
            setLabelText(maxValueLabel, value: maxValue, dotCount: countPackages == 1 ? 0 : countPackages)
            if minValue != NoColor {
                self.alpha = 1.0
            } else {
                switch type {
                    case .containerType: alpha = 0.5
                    case .emptyCardType: alpha = 0.1
                    default: alpha = 1.0
                }
            }
            let BGPicturePosition = CGPoint(x: self.size.width * BGOffsetMultiplier.x, y: self.size.height * BGOffsetMultiplier.y)
            let bgPictureName = "BGPicture"
            if minValue != maxValue  || countPackages > 1 {
                if !BGPictureAdded {
                    if self.childNode(withName: bgPictureName) == nil {
                        self.addChild(BGPicture)
                        BGPicture.addChild(maxValueLabel)
                        BGPicture.name = bgPictureName
                        BGPicture.alpha = 1.0
                    }
                    BGPicture.texture = self.texture
                    BGPictureAdded = true
                    BGPicture.position = BGPicturePosition // CGPointMake(-3, 25)
                    BGPicture.size = size
                    self.zPosition = 0
                    BGPicture.zPosition = self.zPosition - 1
                    BGPicture.isUserInteractionEnabled = false
                    //maxValueLabel.position = positionOffset //CGPointMake(-20, 35)
                    maxValueLabel.zPosition = self.zPosition + 1
                    //minValueLabel.zPosition = maxValueLabel.zPosition + 1
                }
            } else {
                if BGPictureAdded || self.childNode(withName: bgPictureName) != nil {
                    maxValueLabel.removeFromParent()
                    BGPicture.removeFromParent()
                    BGPictureAdded = false
                    if type == .containerType && minValue == NoValue {
                        self.alpha = 0.5
                    }
                } else {
                    if colorIndex == NoColor {
                        self.texture = atlas.textureNamed("emptycard")
                    }
                }
            }
        } else {
            hitLabel.text = "\(hitCounter)"
        }

    }

    func setLabelText(_ label: SKLabelNode, value: Int, dotCount: Int) {
        guard let text = cardLib[minValue == NoColor ? NoColor : value % MaxCardValue] else {
            return
        }
        let starString = " " + String(repeating: "*", count: dotCount)
        label.text = "\(value == 10 ? " " : "")\(text + starString)"
    }
    
    func getMirroredScore() -> Int {
        return countScore * mirrored
    }
    
    func calculateScore()->Int {
        var actValue: Int
        switch countPackages {
        case 1:
            let midValue = Double(minValue + maxValue + 2) / Double(2)
            actValue = Int(midValue * Double((maxValue - minValue + 1)))
        case 2, 3:
            var midValue = Double(minValue + LastCardValue + 2) / Double(2)
            actValue = Int(midValue * Double((LastCardValue - minValue + 1)))
            midValue = Double(maxValue + 2) / Double(2)
            actValue += Int(midValue * Double((maxValue + 1)))
            actValue += countPackages < 3 ? 0 : 91 * (countPackages - 2)
        default: actValue = 0
        }
        return actValue
    }
    
    func connectWith(otherSprite: MySKNode) {
        if otherSprite.countPackages > 1 {
            self.countPackages += otherSprite.countPackages - 1
        }
        if self.minValue == otherSprite.maxValue + 1 {
            self.minValue = otherSprite.minValue
        } else if self.maxValue == otherSprite.minValue - 1 {
            self.maxValue = otherSprite.maxValue
        } else if self.minValue == FirstCardValue && otherSprite.maxValue == LastCardValue {
            self.minValue = otherSprite.minValue
            countPackages += 1
        } else if self.maxValue == LastCardValue && otherSprite.minValue == FirstCardValue {
            self.maxValue = otherSprite.maxValue
            countPackages += 1
        } else if self.maxValue == NoColor {  // empty Container
            self.maxValue = otherSprite.maxValue
            self.minValue = otherSprite.minValue
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
