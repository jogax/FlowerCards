//
//  ViewController.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 20.09.15.
//  Copyright © 2015 Jozsef Romhanyi. All rights reserved.
//

import UIKit
import SpriteKit
import RealmSwift
import GameplayKit

var Pi = Double.pi
let DegreesToRadians = Pi / 180
let RadiansToDegrees = 180 / Pi
let countGames = 10000
let appName = "FlowerCards"


class GameViewController: UIViewController,/* SettingsDelegate,*/ UIApplicationDelegate {
    var aktName = ""
//    var aktModus = GameModusFlowers
    var skView: SKView?
    var cardsScene: CardGameScene?
//    var flowersScene: FlowerGameScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GV.mainViewController = self
        let actDate = getTodayString()
        GV.deviceSessionID = UIDevice.current.identifierForVendor!.uuidString + "-" + actDate
        if let strAppName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") {
            GV.appName = strAppName as! String
        }
        if let strVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") {
            GV.versionsNumber = strVersion as! String
        }
        if let strBuildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") {
            GV.buildNumber = strBuildNumber as! String
        }

//        self.importGamePredefinitions()
        startScene()

//        _ = CreateGamePredefinition(countGames: countGames)
//        exportGames(1000)
        
//        let _ = ImportGamePredefinitions(countGames: countGames)
//        backgroundThread(background: {
//            self.loadGamePredefinitionIfvaressary(countGames)
//        })
//        sleep(Double(1)) // wait for a second

//        copyDefaultRealmFileIfNotExistsYet()
//        printFonts()
        // Do any additional setup after loading the view, typically from a nib.
     }
    
    func getTodayString() -> String{
        
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let year = String(components.year!)
        let month = (components.month! > 9 ? "" : "0") + String(describing: components.month!)
        let day = (components.day! > 9 ? "" : "0") + String(describing: components.day!)
        let hour = (components.hour! > 9 ? "" : "0") + String(describing: components.hour!)
        let minute = (components.minute! > 9 ? "" : "0") + String(describing: components.minute!)
        let second = (components.second! > 9 ? "" : "0") + String(describing: components.second!)
        
        let today_string = year + month + day + "-" + hour  + minute + second
        
        return today_string
        
    }

    
    func applicationWillEnterForeground(_ application: UIApplication) {
        _ = 0
    }
    
    func copyDefaultRealmFileIfNotExistsYet() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectory = paths[0] 
        let defaultFilePath = documentDirectory + "/default.realm"
        
        let manager = FileManager.default
        if (manager.fileExists(atPath: defaultFilePath)) {
            print("DB exists, nothing to do")
        } else {
            print("not exists at path: \(documentDirectory), will be copied")
            let myOrigRealmFile = Bundle.main.path(forResource: "MyDB", ofType: "realm")
//            try! manager.moveItemAtPath(myOrigRealmFile!, toPath: defaultFilePath)
            try! manager.copyItem(atPath: myOrigRealmFile!, toPath: defaultFilePath)
//            try! manager.removeItemAtPath(myOrigRealmFile!)
        }
        realm = try! Realm()
    }
    
    func startScene() {
        self.view.isMultipleTouchEnabled = false
        skView = self.view as? SKView
        skView!.showsFPS = true
        skView!.showsNodeCount = true
        cardsScene = nil
//        flowersScene = nil
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView!.ignoresSiblingOrder = true


        
        if realm.objects(PlayerModel.self).count == 0 {
              _ = GV.createNewPlayer(true)
        }
        
        
        GV.player = realm.objects(PlayerModel.self).filter("isActPlayer = TRUE").first!
 
//        if realm.objects(StatisticModel.self).filter("playerID = %d", GV.player!.ID).count == 0 {
//            let statistic = StatisticModel()
//            statistic.ID = GV.createNewRecordID(.statisticModel)
//            statistic.playerID = GV.player!.ID
//            statistic.levelID = GV.player!.levelID
//            try! realm.write({
//                realm.add(statistic)
//            })
//        } else {
////            GV.statistic = GV.realm.objects(StatisticModel).filter("playerID = %d AND levelID = %d", GV.player!.ID, GV.player!.levelID).first!
//        }
        
        GV.language.setLanguage(GV.player!.aktLanguageKey)
        
        let myName = GV.player!.name
        let deviceName = UIDevice.current.name
        GV.peerToPeerService = PeerToPeerServiceManager(peerType: appName, identifier: myName, deviceName: deviceName)  // Start connection

        skView!.showsFPS = true
        skView!.showsNodeCount = true
        skView!.ignoresSiblingOrder = true
        
//        if GV.actGameParam.gameModus == GameModusCards {
            let scene = CardGameScene(size: CGSize(width: view.frame.width, height: view.frame.height))
            GV.language.addCallback(scene.changeLanguage, callbackName: "CardGameCallBack")
            scene.scaleMode = .resizeFill
            skView!.presentScene(scene)
            cardsScene = scene
//            GV.mainScene = scene // global for the whole app
    }
    func printFonts() {
        let fontFamilyNames = UIFont.familyNames
        for familyName in fontFamilyNames {
            print("------------------------------")
            print("Font Family Name = [\(familyName)]")
            let names = UIFont.fontNames(forFamilyName: familyName)
            print("Font Names = [\(names)]")
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}

