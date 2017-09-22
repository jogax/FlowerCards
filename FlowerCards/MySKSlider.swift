//
//  MySKSlider.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 13/05/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import SpriteKit
import AVFoundation

enum SoundType: Int {
    case music = 0, sound
}
class MySKSlider: MySKTable, AVAudioPlayerDelegate {
    var callBack: ()->()
    let myColumnWidths: [CGFloat] = [10,80,10]  // in %
    //    let myDetailedColumnWidths = [20, 20, 20, 20, 20] // in %
//    let myName = "MySKSlider"
    let countLines = 1
    var volumeValue = CGFloat(50)
    var startLocation = CGPoint.zero
    var sliderMinMaxXPosition = CGFloat(0)
    var soundType: SoundType
    var soundEffects: AVAudioPlayer?
    var url: URL?
    var timer: Timer?
    var fileName = ""
    

    
    init (parent: SKSpriteNode, callBack: @escaping ()->(), soundType: SoundType) {
        let headLines: [String] = [
            GV.language.getText(.tcPlayer, values: GV.player!.name),
            soundType == .music ? GV.language.getText(.tcMusicVolume) : GV.language.getText(.tcSoundVolume),
//            "Testline 3",
//            "Testline 4",
        ]
        self.callBack = callBack
        self.soundType = soundType
        self.volumeValue = CGFloat((soundType == .music ? GV.player!.musicVolume : GV.player!.soundVolume))
        super.init(columnWidths: myColumnWidths, countRows:countLines, headLines: headLines, parent: parent, myName: "MySKSlider", width: parent.parent!.frame.width * 0.9)
        sliderMinMaxXPosition = self.size.width * myColumnWidths[1] / 2 / 100
        fileName = soundType == .music ? "MyMusic" : "OK"
        playSound(fileName, volume: Float(volumeValue), loops: -1)
        showMe(showSlider)
    }
    
    func showSlider() {
        let sliderImage = DrawImages.getSetVolumeImage(CGSize(width: self.size.width * 0.8, height: heightOfLabelRow), volumeValue: volumeValue)
        let elements: [MultiVar] = [
            MultiVar(string: ""),
            MultiVar(texture: SKTexture(image: sliderImage)),
            MultiVar(string: "\(volumeValue)")
        ]
        showRowOfTable(rowOfTable: RowOfTable(elements: elements, selected: true), row:  0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first!.location(in: self)
        startLocation = touchLocation
        touchesBeganAtNode = atPoint(touchLocation)
        if !(touchesBeganAtNode is SKLabelNode || (touchesBeganAtNode is SKSpriteNode && touchesBeganAtNode!.name != self.name)) {
            touchesBeganAtNode = nil
        }
        if soundType == .sound {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                                                 selector: #selector(MySKSlider.reStart), userInfo: nil, repeats:true)
        }
        soundEffects!.play()
    }
    
    @objc func reStart() {
        playSound(fileName, volume: Float(volumeValue), loops: -1)
        soundEffects!.play()
        print(Date())
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let sliderNode = self.childNode(withName: "1-0") {
            volumeValue = round((touches.first!.location(in: sliderNode).x + self.sliderMinMaxXPosition) / (2 * self.sliderMinMaxXPosition) * 100)
            volumeValue = volumeValue < 0 ? 0 : volumeValue > 100 ? 100 : volumeValue
            showSlider()
            soundEffects!.volume = Float(volumeValue) * 0.001
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touchLocation = touches.first!.locationInNode(self)
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        let (touch, _, _, _) = checkTouches(touches, withEvent: event)
        switch touch {
        case MyEvents.goBackEvent:
            let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
            myParent.run(fadeInAction)
            removeFromParent()
            callBack()
        case .noEvent:
            soundEffects!.stop()
            if let sliderNode = self.childNode(withName: "1-0") {
                volumeValue = round((touches.first!.location(in: sliderNode).x + self.sliderMinMaxXPosition) / (2 * self.sliderMinMaxXPosition) * 100)
                volumeValue = volumeValue < 0 ? 0 : volumeValue > 100 ? 100 : volumeValue
                showSlider()
                try! realm.write({
                    switch self.soundType {
                    case .music:
                        GV.player!.musicVolume = Float(volumeValue)
                    case .sound:
                        GV.player!.soundVolume = Float(volumeValue)
                    }
                })
            }
        }
        
//        }
        
    }
    
//    override func setMyDeviceSpecialConstants() {
//        fontSize = GV.onIpad ? 20 : 15
//        heightOfLabelRow =  GV.onIpad ? 40 : 35
//    }
    
    func playSound(_ fileName: String, volume: Float, loops: Int) {
        //levelArray = GV.cloudData.readLevelDataArray()
        let url = URL(
            fileURLWithPath: Bundle.main.path(forResource: fileName, ofType: "m4a")!)
        //backgroundColor = SKColor(patternImage: UIImage(named: "aquarium.png")!)
        
        do {
            try soundEffects = AVAudioPlayer(contentsOf: url)
            soundEffects?.delegate = self
            soundEffects?.prepareToPlay()
            soundEffects?.volume = 0.001 * volume
            soundEffects?.numberOfLoops = loops
//            soundEffects?.play()
        } catch {
            print("audioPlayer error")
        }
    }

}

