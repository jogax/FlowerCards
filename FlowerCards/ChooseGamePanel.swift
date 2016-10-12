//
//  ChooseGamePanel.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 11/07/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

//
//  MySKPanel.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 18/03/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

//import SpriteKit
//import RealmSwift
//
//class ChooseGamePanel: SKSpriteNode {
//    let levelName = "Level"
//    let groupName = "Group"
//    let gameName = "Game"
//    let gamesBackGroundName = "gamesBackGround"
//    let backGroundShapeName = "backGroundShape"
//    let dot = "."
//    let myFontName = "TimesNewRomanBold"
//    let newLine = "\r\n"
//    let gamesPerGroup = 100
//    var deleteIndex: Int = 0
//    var touchStartTime: Date?
//
//    
//    var view: UIView
//    var sizeMultiplier = CGSize(width: 0, height: 0)
//    var fontSize:CGFloat = 0
//    var callBack: (Int)->()
//    var parentScene: SKScene?
//    
//    var levels = [SKLabelNode]()
//    var levelButtons = [SKShapeNode]()
//    var gameButtons = [SKShapeNode]()
//    var levelLabel: SKLabelNode?
//    var showGames = false
//    var gamesBackground = SKShapeNode()
//    var gamesBackgroundStartPosition = CGPoint.zero
//    var gamesBackgroundLastPosition = CGPoint.zero
//    var touchLastLocation = CGPoint.zero
//    var touchStartLocation = CGPoint.zero
//    
//    
//    
//    var playerChanged = false
//    var touchesBeganWithNode: SKNode?
//    var shadow: SKSpriteNode?
//    
//    struct touchMoving {
//        var position: CGPoint
//        var time: Date
//        var movedBy: CGVector
//        var movingSpeed: CGVector
//        init(position: CGPoint = CGPoint.zero, time:Date = Date(), movedBy: CGVector = CGVector(dx: 0, dy: 0), movingSpeed:CGVector = CGVector(dx: 0,dy: 0)) {
//            self.position = position
//            self.time = time
//            self.movedBy = movedBy
//            self.movingSpeed = movingSpeed
//        }
//    }
//    
//    var moving = [touchMoving]()
//    init(view: UIView, frame: CGRect, parent: SKScene, callBack: @escaping (Int)->()) {
//        let size = parent.size // 1.5 //CGSizeMake(parent.size.width / 2, parent.s)
//        //        let texture: SKTexture = SKTexture(imageNamed: "panel")
//        let texture: SKTexture = SKTexture()
//        
//        sizeMultiplier = size / 10
//        
//        self.callBack = callBack
//        self.view = view
//        self.parentScene = parent
//        super.init(texture: texture, color: UIColor.clear, size: size)
//        
//        let countLevels = LevelsForPlayWithCards().count()
//        self.texture = SKTexture(image: getPanelImage(size))
//        setMyDeviceConstants()
//        let startPosition = CGPoint(x: parent.size.width, y: parent.size.height / 2)
//        let zielPosition = CGPoint(x: parent.size.width / 2, y: parent.size.height / 2)
//        self.size = size
//        self.position = startPosition
//        self.color = UIColor.yellow
//        self.zPosition = 100
//        self.alpha = 1.0
//        self.name = "ChooseGamePanel"
//        self.isUserInteractionEnabled = true
//        parentScene!.isUserInteractionEnabled = false
//        parentScene!.addChild(self)
//        
//        addSwipe()
//        let backGroundShape = SKShapeNode(rect: CGRect(x: 0,y: 0, width: self.size.width, height: self.size.height * 0.3))
//        backGroundShape.position = CGPoint(x: -self.size.width / 2 , y: self.size.height * 0.3)
//        backGroundShape.fillColor = UIColor.white //(red: 0xcc/0xff, green: 0xff/0xff, blue: 0xe5/0xff, alpha: 1.0)
//        backGroundShape.zPosition = self.zPosition + 10
//        backGroundShape.name = backGroundShapeName
//        self.addChild(backGroundShape)
//        
//        let backGroundSize = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height * 1.5 ) //CGFloat(countGroups) / countHor * (buttonSize.height + gDistance) + gDistance)
//        gamesBackground = SKShapeNode(rect: backGroundSize)
//        gamesBackground.fillColor = UIColor.white // red: 0xe5/0xff, green: 0xff/0xff, blue: 0xcc/0xff, alpha: 1.0)
//        gamesBackground.position = CGPoint(x: -self.size.width / 2 , y: -backGroundSize.height * 0.8)
//        gamesBackground.zPosition = 10
//        gamesBackground.name = gamesBackGroundName
//        gamesBackgroundStartPosition = gamesBackground.position
//        gamesBackgroundLastPosition = gamesBackgroundStartPosition
//
//        self.addChild(gamesBackground)
//
//        
//        let rDistance = size.width / (CGFloat(countLevels) + 1)
//        let radius = rDistance / 4
//        
//        for levelIndex in 0..<countLevels {
//            levelButtons.append(
//                createRadioButton(
//                    CGPoint(x: (CGFloat(levelIndex) + 1) * rDistance - size.width / 2, y: size.height * 0.34),
//                    radius: radius,
//                    labelText: String(levelIndex + 1)
//                )
//            )
//            self.addChild(levelButtons[levelIndex])
//        }
//        
//        
//        
//        levelLabel = SKLabelNode()
//        levelLabel!.position = CGPoint(x: 0, y: size.height * 0.43)
//        levelLabel!.fontColor = UIColor.black
//        levelLabel!.fontName = myFontName
//        levelLabel!.text = GV.language.getText(.tcLevel, values: ": " + String(GV.player!.levelID + 1))
//        levelLabel!.zPosition = self.zPosition + 10
//        levelLabel!.horizontalAlignmentMode = .center
//        self.addChild(levelLabel!)
//        deleteIndex = children.count
//        showGroups()
//
//        let moveAction = SKAction.move(to: zielPosition, duration: 0.5)
//        self.run(moveAction)
//        
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func showGroups() {
//        showGames = false
//        var groupButtons = [SKShapeNode]()
//        let countGroups = GV.freeGameCount / gamesPerGroup //Predefinitions.gameArray.count / gamesPerGroup
//        let countFreeGroups = GV.freeGameCount / gamesPerGroup
//        let countHor = 4
//        let gDistance = size.width / (CGFloat(countHor) + 1)
//        let width = gDistance * 0.75
//        deleteAllButtons()
//        var gameNumbers = [Int]()
//        
//        for groupIndex in 0..<countGroups {
//            let groupIndexHor = groupIndex % countHor
//            let groupIndexVert: Int = groupIndex / countHor
//            let minGameNrInGroup = groupIndex * gamesPerGroup + 1
//            let maxGameNrInGroup = minGameNrInGroup + gamesPerGroup - 1
//            let filter = "levelID = %d and gameNumber >= %d and gameNumber <= %d and played = true"
//            let gamesInGroup = realm.objects(GameModel.self).filter(filter, GV.player!.levelID, minGameNrInGroup - 1, maxGameNrInGroup - 1)
//            gameNumbers.removeAll()
//            for game in gamesInGroup {
//                if !gameNumbers.contains(game.gameNumber) {
//                    gameNumbers.append(game.gameNumber)
//                }
//            }
//            let groupText = [String(minGameNrInGroup), "...", String(maxGameNrInGroup)]
//            let myX = (CGFloat(groupIndexHor) + 1) * gDistance - size.width / 2 - width / 2
//            let myY = size.height * (0.04 - CGFloat(groupIndexVert) * 0.23)
//            let myPoint = CGPoint(x: myX, y: myY)
//            let button = createGroupButton(
//                myPoint,
//                width: width,
//                buttonIndex: groupIndex,
//                labelText: groupText,
//                freeGroup: groupIndex < countFreeGroups
//            )
//
//            groupButtons.append(button)
////            while self.childNodeWithName(groupButtons[groupIndex].name!) != nil {
////                self.childNodeWithName(groupButtons[groupIndex].name!)!.removeFromParent()
////            }
//
//            self.addChild(groupButtons[groupIndex])
//        }
//    }
//    
//    func showGamesInGroup(_ group: Int) {
//        showGames = true
//        var gameButtons = [SKShapeNode]()
////        let countGroups = GV.freeGameCount / gamesPerGroup //Predefinitions.gameArray.count / gamesPerGroup
//        let countHor: CGFloat = 2
//        let buttonSize = CGSize(
//            width: 0.8 * size.width / countHor,
//            height: (0.8 * size.width / countHor) * 1.2
//        )
//        let gDistance = (size.width - (countHor * buttonSize.width)) / (countHor + 1)
//        let startPosition = CGPoint(
//            x: gDistance, // - gamesBackground.frame.width / 2,
//            y: gamesBackground.frame.height * 0.7
//        )
//        
//        gamesBackgroundLastPosition.y = gamesBackgroundStartPosition.y + CGFloat(gamesPerGroup) / countHor * (gDistance + buttonSize.height)
//
//        deleteAllButtons()
////        let adder = (group * gamesPerGroup).isOdd() ? 0 : 1
//        for index in 0..<gamesPerGroup {
//            var players = [Int]()
//            let gameNumber =  group * gamesPerGroup + index
//            let gameIndexHor = index % Int(countHor)
//            let gameIndexVert: Int = index / Int(countHor)
//            let filter = "levelID = %d and gameNumber == %d and played = true"
//            let gamesWithNumber = realm.objects(GameModel.self).filter(filter, GV.player!.levelID, gameNumber).sorted(byProperty: "playerScore", ascending: false)
//            var gameText = ["#" + String(gameNumber + 1)]
//            for index in 0..<gamesWithNumber.count {
//                let playerID = gamesWithNumber[index].playerID
//                if !players.contains(playerID) {
//                    players.append(playerID)
//                    let gamesCountForPlayer = gamesWithNumber.filter("playerID = %d", playerID).count
//                    let score = gamesWithNumber[index].playerScore
//                    let time = gamesWithNumber[index].time
//                    let playerName = realm.objects(PlayerModel.self).filter("ID = %d", playerID).first!.name
//                    var appendString = playerName
//                    appendString += "("
//                    appendString += String(gamesCountForPlayer)
//                    appendString += "): "
//                    appendString += String(score)
//                    appendString += " / "
//                    appendString += String(time.dayHourMinSec)
//                    gameText.append(appendString)
//                }
//            }
//            gameButtons.append(
//                createGameButton(
//                    CGPoint(
//                        x: startPosition.x + gameIndexHor.toCGFloat() * (buttonSize.width + gDistance),
//                        y: startPosition.y - gameIndexVert.toCGFloat() * (buttonSize.height + gDistance)
//                    ),
//                    size: buttonSize,
//                    buttonIndex: gameNumber,
//                    labelText: gameText
//                )
//            )
//            gamesBackground.addChild(gameButtons[index])
//        }
//        
//    }
//    
//    func deleteAllButtons() {
//        let index = deleteIndex
//        while index<self.children.count {
//            self.children[children.count - 1].removeFromParent()
//        }
//        for _ in 0..<gamesBackground.children.count {
//            gamesBackground.children.last!.removeFromParent()
//        }
//    }
//    
//    func createGroupButton(_ position: CGPoint, width: CGFloat, buttonIndex: Int, labelText: [String], freeGroup: Bool = false)->SKShapeNode {
//        
//        let button = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: width * 1.5), cornerRadius: width / 10)
//        
//        button.position = position
//        
//        if freeGroup {
//            button.fillColor = UIColor(red: 127/255, green: 255/255, blue: 0/255, alpha: 1.0)
//        } else {
//            button.fillColor = UIColor(red: 250/255, green: 160/255, blue: 122/255, alpha: 1.0)
//        }
//        button.strokeColor = UIColor.black
//        button.lineWidth = 3
//        button.zPosition = self.zPosition + 10
//        
//        button.name = groupName + dot + String(buttonIndex)
//        button.addChild(createLabel(CGPoint(x: width * 0.5, y: width * 1.1), text: labelText[0], name: button.name!, fontSize: width * 0.3))
//        button.addChild(createLabel(CGPoint(x: width * 0.5, y: width * 0.95), text: labelText[1], name: button.name!, fontSize: width * 0.3))
//        button.addChild(createLabel(CGPoint(x: width * 0.5, y: width * 0.6), text: labelText[2], name: button.name!, fontSize: width * 0.3))
////        button.addChild(createLabel(CGPointMake(width * 0.5, width * 0.3), text: labelText[3], name: button.name!, fontSize: width * 0.25))
//        return button
//    }
//    
//    func createGameButton(_ position: CGPoint, size: CGSize, buttonIndex: Int, labelText: [String])->SKShapeNode {
//        
//        let button = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: size.width / 10)
//        gamesBackground.position = gamesBackgroundStartPosition
//        
//        button.position = position
//        button.strokeColor = UIColor.black
//        button.lineWidth = 3
//        button.zPosition = gamesBackground.zPosition + 1
//        button.fillColor = UIColor(red: 127/255, green: 255/255, blue: 0/255, alpha: 1.0)
//
//        
//        button.name = gameName + dot + String(buttonIndex)
//        button.addChild(createLabel(CGPoint(x: size.width * 0.5, y: size.height * 0.85), text: labelText[0], name: button.name!, fontSize: size.width * 0.12))
//        for textIndex in 1..<labelText.count {
//            button.addChild(createLabel(
//                CGPoint(x: size.width * 0.5, y: size.height * (0.85 - CGFloat(textIndex) * 0.10)),
//                text: labelText[textIndex],
//                name: button.name!,
//                fontSize: size.width * 0.08))
//        }
//        return button
//    }
//    
//    func createLabel(_ position: CGPoint, text: String, name: String, fontSize: CGFloat)->SKLabelNode {
//        let label = SKLabelNode()
//        
//        label.position = position
//        label.text = text
//        label.color = UIColor.black
//        label.fontSize = fontSize
//        label.fontName = myFontName
//        label.fontColor = UIColor.black
//        label.name = name
//        return label
//    }
//    
//    func createRadioButton(_ position: CGPoint, radius: CGFloat, labelText: String)->SKShapeNode {
//        let button = SKShapeNode(circleOfRadius: radius)
//        
//        button.position = position
//        button.fillColor = UIColor.white
//        if Int(labelText) == GV.player!.levelID + 1 {
//            button.fillColor = UIColor.black
//        }
//        
//        button.strokeColor = UIColor.black
//        button.zPosition = self.zPosition + 10
//        button.name = levelName + dot + labelText
//        let label = SKLabelNode()
//        label.position = CGPoint(x: 0, y: radius * 1.1)
//        label.text = labelText
//        label.color = UIColor.black
//        label.fontSize = 2 * radius
//        label.fontName = myFontName
//        label.fontColor = UIColor.black
//        label.name = button.name
//        button.addChild(label)
//        return button
//    }
//    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touchLocation = touches.first!.location(in: self)
//        let node = atPoint(touchLocation)
//        touchLastLocation = touchLocation
//        touchStartLocation = touchLocation
//        touchStartTime = Date()
//        touchesBeganWithNode = node
//        if showGames {
//            moving.removeAll()
//            moving.append(touchMoving(position: touchLocation))
//        }
//        
//    }
//    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touchLocation = touches.first!.location(in: self)
//        let node = atPoint(touchLocation)
//        if showGames {
//            if node.name != nil && (node.name! == gamesBackGroundName || node.name!.components(separatedBy: dot)[0] == gameName) {
//                let distanceToMove = touchLocation.y - touchLastLocation.y
//                if CGFloat(gamesBackground.position.y + distanceToMove).between(gamesBackgroundStartPosition.y, max: gamesBackgroundLastPosition.y) {
//                    gamesBackground.position.y += distanceToMove
//                    touchLastLocation = touchLocation
//                }
//            }
//            let newDelta = CGVector(dx: moving.last!.position.x - touchLocation.x, dy: moving.last!.position.y - touchLocation.y)
//            if moving.last!.movedBy.dy.isPositiv() != newDelta.dy.isPositiv() {
//                let tempMovingLast = moving.last!
//                moving.removeAll()
//                moving.append(tempMovingLast)
//                moving[0].movingSpeed = CGVector(dx: 0, dy: 0)
//                moving[0].movedBy = CGVector(dx: 0, dy: 0)
//                let actTime = Date()
//                let timeDelta = CGFloat(actTime.timeIntervalSince(moving.last!.time))
//                let speed = CGVector(dx: newDelta.dx / timeDelta, dy: newDelta.dy / timeDelta)
//                moving.append(touchMoving(position: touchLocation, time: actTime, movedBy: newDelta, movingSpeed: speed))
//            } else {
//                let actTime = Date()
//                let timeDelta = CGFloat(actTime.timeIntervalSince(moving.last!.time))
//                let speed = CGVector(dx: newDelta.dx / timeDelta, dy: newDelta.dy / timeDelta)
//                moving.append(touchMoving(position: touchLocation, time: actTime, movedBy: newDelta, movingSpeed: speed))
//            }
//        }
//    }
//    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touchLocation = touches.first!.location(in: self)
//        let node = atPoint(touchLocation)
//        if showGames {
//            if abs(moving.last!.position.y - moving.first!.position.y) > 20 {
//                
//                let touchDuration = CGFloat(Date().timeIntervalSince(moving.first!.time))
//                let touchDistance = touchLocation.y - moving.first!.position.y
//                var distanceToMove = touchDistance / touchDuration
//                
//                if CGFloat(gamesBackground.position.y + distanceToMove) < gamesBackgroundStartPosition.y {
//                    distanceToMove = gamesBackgroundStartPosition.y - gamesBackground.position.y
//                }
//                if CGFloat(gamesBackground.position.y + distanceToMove) > gamesBackgroundLastPosition.y {
//                    distanceToMove = gamesBackgroundLastPosition.y + gamesBackground.position.y
//                }
//               
//                if CGFloat(gamesBackground.position.y + distanceToMove).between(gamesBackgroundStartPosition.y, max: gamesBackgroundLastPosition.y) {
//                    let moveAction = SKAction.move(by: CGVector(dx: 0, dy: distanceToMove), duration: 0.3)
//                    gamesBackground.run(moveAction)
//                } else {
//                    
//                }
//                return
//            }
//        }
//
//     
//        if node.name != nil {
//            let components = node.name!.components(separatedBy: dot)
//            if touchLastLocation.y - touchStartLocation.y < 12 {
//                switch components[0] {
//                    case levelName:
//                        setLevel(Int(components[1])!)
//                    case groupName:
//                        goToGroup(Int(components[1])!)
//                case gameName:
//                        goToGame(Int(components[1])!)
//                    default: break
//                }
//            }
//        }
//     }
//    
//    func setLevel(_ number: Int) {
//        let oldLevel = GV.player!.levelID
//        levelButtons[oldLevel].fillColor = UIColor.white
//        levelButtons[number - 1].fillColor = UIColor.black
//        try! realm.write({
//            GV.player!.levelID = number - 1
//        })
//        levelLabel!.text = GV.language.getText(.tcLevel, values: ": " + String(number))
//        showGroups()
//    }
//    
//    func goToGroup(_ number: Int) {
//        showGamesInGroup(number)
//    }
//    
//    func goToGame(_ gameNumber: Int) {
//        self.removeAllChildren()
//        self.removeFromParent()
//        callBack(gameNumber)
//    }
//    
//    func setMyDeviceConstants() {
//        
//        switch GV.deviceConstants.type {
//        case .iPadPro12_9:
//            fontSize = CGFloat(20)
//        case .iPadPro9_7:
//            fontSize = CGFloat(20)
//        case .iPad2:
//            fontSize = CGFloat(20)
//        case .iPadMini:
//            fontSize = CGFloat(20)
//        case .iPhone6Plus:
//            fontSize = CGFloat(15)
//        case .iPhone6:
//            fontSize = CGFloat(15)
//        case .iPhone5:
//            fontSize = CGFloat(13)
//        case .iPhone4:
//            fontSize = CGFloat(12)
//        default:
//            break
//        }
//        
//    }
//    
//    func getPanelImage (_ size: CGSize) -> UIImage {
//        let opaque = false
//        let scale: CGFloat = 1
//        
//        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
//        let ctx = UIGraphicsGetCurrentContext()
//        //        CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
//        
//        //        CGContextBeginPath(ctx)
//        let roundRect = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), byRoundingCorners:.allCorners, cornerRadii: CGSize(width: 0, height: 0)).cgPath
//        ctx?.addPath(roundRect)
//        ctx?.setFillColor(UIColor.white.cgColor);
//        ctx?.fillPath()
//        
//        
//        let points = [
//            CGPoint(x: size.width * 0.08, y: size.height * 0.20),
//            CGPoint(x: size.width * 0.92, y: size.height * 0.20)
//        ]
////        CGContextAddLines(ctx, points, points.count)
//        ctx?.addLines(between: points)
//        ctx?.strokePath()
//        
//        
//        
//        
//        //        CGContextSetShadow(ctx, CGSizeMake(10,10), 1.0)
//        //        CGContextStrokePath(ctx)
//        
//        
//        
//        ctx?.closePath()
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        
//        return image!
//    }
//    
//    func addSwipe() {
////        let directions: [UISwipeGestureRecognizerDirection] = [.Up, .Down, .Left, .Right]
////        for direction in directions {
////            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(ChooseGamePanel.handleSwipe(_:)))
////            gesture.direction = direction
////            gesture.cancelsTouchesInView = true
////            gesture.delaysTouchesBegan = true
////            self.view.addGestureRecognizer(gesture)
////        }
//    }
//    
//    func handleSwipe(_ sender: UISwipeGestureRecognizer) {
//        switch sender.direction {
//        case UISwipeGestureRecognizerDirection.right:
//            print("Swiped right")
//        case UISwipeGestureRecognizerDirection.down:
//            _ = Date().timeIntervalSince(touchStartTime!)
//            let moveAction = SKAction.move(by: CGVector(dx: 0, dy: -1000), duration: 0.3)
//            gamesBackground.run(moveAction)
//        case UISwipeGestureRecognizerDirection.left:
//            print("Swiped left")
//        case UISwipeGestureRecognizerDirection.up:
//            _ = Date().timeIntervalSince(touchStartTime!)
//            let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 1000), duration: 0.3)
//            gamesBackground.run(moveAction)
//        default:
//            break
//        }
//    }
//
//    deinit {
//    }
//    
//}
//
