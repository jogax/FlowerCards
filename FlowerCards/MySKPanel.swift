//
//  MySKPanel.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 18/03/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import SpriteKit
enum PanelTypes: Int {
    case settings = 0, menu
}
class MySKPanel: SKSpriteNode {
    var view: UIView
    override var size: CGSize {
        didSet {
            if oldValue != size {
                for index in 0..<self.children.count {
                    if self.children[index] is SKLabelNode {
//                        print("Label:",  self.children[index].name)
                    }
                }
            }
        }
    }
    
    let noTouchFunc = "noTouch"
    let setPlayerFunc = "setPlayer"
    let setSoundFunc = "setSoundVolume"
    let setMusicFunc = "setMusicVolume"
    let setLanguageFunc = "setLanguage"
    let setPlayerStatisticFunc = "setPlayerStatistics"
    let setReturnFunc = "setReturn"
    var sizeMultiplier = CGSize(width: 0, height: 0)
    var fontSize:CGFloat = 0
    var callBack: (Bool, Bool, Int, Int)->()
    var parentScene: SKScene?
    
    let playerLabel = SKLabelNode()
    let nameLabel = SKLabelNode()
    let soundLabel = SKLabelNode()
    let musicLabel = SKLabelNode()
    let languageLabel = SKLabelNode()
    let playerStatisticLabel = SKLabelNode()
    let returnLabel = SKLabelNode()
    let callbackName = "SettingsCallbackName"
    var oldPlayerID = 0

    var type: PanelTypes
    var playerChanged = false
    var touchesBeganWithNode: SKNode?
    var shadow: SKSpriteNode?
    init(view: UIView, frame: CGRect, type: PanelTypes, parent: SKScene, callBack: @escaping (Bool, Bool, Int, Int)->()) {
        let size = parent.size * 0.75 // / 2 //CGSizeMake(parent.size.width / 2, parent.s)
//        let texture: SKTexture = SKTexture(imageNamed: "panel")
        let texture: SKTexture = SKTexture()
        
        sizeMultiplier = size / 10
        
        self.callBack = callBack
        self.view = view
        self.type = type
        self.parentScene = parent
        super.init(texture: texture, color: UIColor.clear, size: size)
        GV.language.addCallback(changeLanguage, callbackName: callbackName)
        

        self.texture = SKTexture(image: getPanelImage(size))
        setMyDeviceConstants()
        let startPosition = CGPoint(x: parent.size.width, y: parent.size.height / 2)
        let zielPosition = CGPoint(x: parent.size.width / 2, y: parent.size.height / 2)
        self.size = size
        self.position = startPosition
        self.color = UIColor.yellow
        self.zPosition = 100
        self.alpha = 1.0
        self.name = "MySKPanel"
        self.isUserInteractionEnabled = true
        parentScene!.isUserInteractionEnabled = false
        makeSettings()
        parentScene!.addChild(self)
        let moveAction = SKAction.move(to: zielPosition, duration: 0.5)
        self.run(moveAction)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeLanguage()->Bool{
        let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        playerLabel.text = GV.language.getText(.tcPlayer, values: name)
        nameLabel.text = GV.language.getText(.tcChooseName)
        soundLabel.text = GV.language.getText(.tcSoundVolume)
        musicLabel.text = GV.language.getText(.tcMusicVolume)
        languageLabel.text = GV.language.getText(.tcLanguage)
        playerStatisticLabel.text = GV.language.getText(.tcStatistic)
        returnLabel.text = GV.language.getText(.tcReturn)
        return false
    }
    
    
    
    func makeSettings() {
        let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        createLabels(playerLabel, text: GV.language.getText(.tcPlayer, values: name), lineNr: 1, horAlignment: SKLabelHorizontalAlignmentMode.center, name: noTouchFunc)
        playerLabel.fontColor = UIColor.black
        createLabels(nameLabel, text: GV.language.getText(.tcChooseName), lineNr: 2, horAlignment: .left, name: setPlayerFunc)
        createLabels(soundLabel, text: GV.language.getText(.tcSoundVolume), lineNr: 3, horAlignment: .left, name: setSoundFunc )
        createLabels(musicLabel, text: GV.language.getText(.tcMusicVolume), lineNr: 4, horAlignment: .left, name: setMusicFunc )
        createLabels(languageLabel, text: GV.language.getText(.tcLanguage), lineNr: 5, horAlignment: .left, name: setLanguageFunc )
        createLabels(playerStatisticLabel, text: GV.language.getText(.tcStatistic), lineNr: 6, horAlignment: .left, name: setPlayerStatisticFunc )
        createLabels(returnLabel, text: GV.language.getText(.tcReturn), lineNr: 7, horAlignment: .left, name: setReturnFunc )
    }
    func createLabels(_ label: SKLabelNode, text: String, lineNr: Int, horAlignment: SKLabelHorizontalAlignmentMode, name:String) {
        label.text = text
        label.name = name
        
        label.position = CGPoint(x: -CGFloat(size.width / 2) + sizeMultiplier.width ,  y: CGFloat(5 - lineNr) * sizeMultiplier.height )
        label.fontName = "AvenirNext"
//        print (self.frame, label.frame)
        label.fontColor = SKColor.blue
        label.zPosition = self.zPosition + 10
        label.horizontalAlignmentMode = .left
        label.fontSize = fontSize
        self.addChild(label)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first!.location(in: self)
        let node = atPoint(touchLocation)
        touchesBeganWithNode = node
//        print(node.name)
        if node is SKLabelNode && node.name!.isMemberOf (setPlayerFunc, setSoundFunc, setMusicFunc, setLanguageFunc, setPlayerStatisticFunc,setReturnFunc) {
            (node as! SKLabelNode).fontSize += 2
        }

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first!.location(in: self)
        if touchesBeganWithNode is SKLabelNode {
            if touchesBeganWithNode!.name != noTouchFunc {
                (touchesBeganWithNode as! SKLabelNode).fontSize -= 2
            }
            let node = atPoint(touchLocation)
            if node is SKLabelNode && touchesBeganWithNode == node {
                if node.name!.isMemberOf (setPlayerFunc, setSoundFunc, setMusicFunc, setLanguageFunc, setPlayerStatisticFunc,  setReturnFunc) {
    //                (node   as! SKLabelNode).fontSize -= 2
                    switch node.name! {
                    case setPlayerFunc: setPlayer()
                    case setSoundFunc: setSoundVolume()
                    case setMusicFunc: setMusicVolume()
                    case setLanguageFunc: setLanguage()
                    case setPlayerStatisticFunc: setPlayerStatistic()
                    case setReturnFunc: goBack(playerChanged)
                    default: goBack(playerChanged)
                    }
                }
            }
        }
    }
    
    func noTouch() {
        
    }
    
    func setPlayer() {
        isUserInteractionEnabled = false
        oldPlayerID = GV.player!.ID
        let _ = MySKPlayer(parent: self, view: parentScene!.view!, callBack: callIfMySKPlayerEnds)
    }
    func setSoundVolume() {
        _ = MySKSlider(parent: self, callBack: callIfMySKSliderEnds, soundType: .sound)
        
    }
    func setMusicVolume() {
        _ = MySKSlider(parent: self, callBack: callIfMySKSliderEnds, soundType: .music)
    }
    func setLanguage() {
        isUserInteractionEnabled = false
        let _ = MySKLanguages(parent: self, callBack: callIfMySKLanguagesEnds)
    }
    
    func setPlayerStatistic() {
        isUserInteractionEnabled = false
        let _ = MySKStatistic(parent: self, callBack: callIfMySKStatisticEnds)
    }
    
    func goBack(_ restartGame: Bool, gameNumberChoosed: Bool = false, gameNumber: Int = 0, levelIndex: Int = 0) {
        GV.language.removeCallback(callbackName)
        shadow?.removeFromParent()
        self.removeFromParent()
        parentScene!.isUserInteractionEnabled = true
        callBack(restartGame, gameNumberChoosed, gameNumber, levelIndex)
    }
    
    func callIfMySKSliderEnds() {
        
    }
    
    func callIfMySKPlayerEnds () {
        if GV.player!.ID != oldPlayerID {
            playerChanged = true
        }
        GV.peerToPeerService!.changeIdentifier(GV.player!.name)
        let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        playerLabel.text = GV.language.getText(.tcPlayer, values: name)
        self.isUserInteractionEnabled = true
    }
    
    func callIfMySKLanguagesEnds() {
        self.isUserInteractionEnabled = true
        let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        playerLabel.text = GV.language.getText(.tcPlayer, values: name)
        nameLabel.text = GV.language.getText(.tcChooseName)
        soundLabel.text = GV.language.getText(.tcSoundVolume)
        musicLabel.text = GV.language.getText(.tcMusicVolume)
        languageLabel.text = GV.language.getText(.tcLanguage)
        playerStatisticLabel.text = GV.language.getText(.tcStatistic)
        returnLabel.text = GV.language.getText(.tcReturn)
    }
    
    func callIfMySKStatisticEnds(_ startGame: Bool, gameNumber: Int, levelIndex: Int) {
        if startGame {
            goBack(true, gameNumberChoosed: true, gameNumber: gameNumber, levelIndex: levelIndex)
        }
        self.isUserInteractionEnabled = true
        let name = GV.player!.name == GV.language.getText(.tcAnonym) ? GV.language.getText(.tcGuest) : GV.player!.name
        playerLabel.text = GV.language.getText(.tcPlayer, values: name)
        nameLabel.text = GV.language.getText(.tcChooseName)
        soundLabel.text = GV.language.getText(.tcSoundVolume)
        musicLabel.text = GV.language.getText(.tcMusicVolume)
        languageLabel.text = GV.language.getText(.tcLanguage)
        playerStatisticLabel.text = GV.language.getText(.tcStatistic)
        returnLabel.text = GV.language.getText(.tcReturn)
    }
    
    func setMyDeviceConstants() {
        fontSize = GV.onIpad ? 30 : 20       
    }
    
    func getPanelImage (_ size: CGSize) -> UIImage {
        let opaque = false
        let scale: CGFloat = 1

        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let ctx = UIGraphicsGetCurrentContext()
        //        CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
        
        //        CGContextBeginPath(ctx)
        let roundRect = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), byRoundingCorners:.allCorners, cornerRadii: CGSize(width: size.width / 20, height: size.height / 20)).cgPath
        ctx!.addPath(roundRect)
        ctx!.setFillColor(UIColor.white.cgColor);
        ctx!.fillPath()
        
        let points = [
            CGPoint(x: size.width * 0.1, y: size.height * 0.12),
            CGPoint(x: size.width * 0.9, y: size.height * 0.12)
        ]
//        CGContextAddLines(ctx, points, points.count)
        ctx!.addLines(between: points)
        ctx!.strokePath()
        
//        CGContextSetShadow(ctx, CGSizeMake(10,10), 1.0)
        //        CGContextStrokePath(ctx)
        
        
        
        ctx!.closePath()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        return image!
    }
    



    deinit {
    }

}

