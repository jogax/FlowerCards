
//
//  PeerToPeerManager.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 20/07/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol PeerToPeerServiceManagerDelegate {
    
    func connectedDevicesChanged(_ manager : P2PHelper, connectedDevices: [String])
    func messageReceived(_ fromPeer : MCPeerID, command: CommunicationCommands, message: [String], messageNr: Int)
    
}



class P2PHelper: NSObject {

    let separator = "°"
    let Nobody = ""
    var identifier: String
    var iAmPlayingWith: String
    struct MessageContent {
        var command: CommunicationCommands
        var messages: [String]
        var answers: [String]
        var fromPeer: MCPeerID
        var closed: Bool
        var timeStamp: Date
   }
    fileprivate let peerToPeerType: String
//    static private let CardFootballName:String = "CardFootball on "
    fileprivate let myPeerID = MCPeerID(displayName: GV.deviceSessionID)
//    fileprivate let myPeerID = MCPeerID(displayName: UIDevice.current.identifierForVendor!.uuidString)//.name)
    
    fileprivate let serviceBrowser : MCNearbyServiceBrowser
    fileprivate let serviceAdvertiser : MCNearbyServiceAdvertiser
    var delegate : PeerToPeerServiceManagerDelegate?
    
    var messageArray = [Int:MessageContent]()
    var answerArray = [Int:MessageContent]()
    var messageNr = 0
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.required)
        session.delegate = self
        return session
    }()

    init(peerType: String, identifier: String, deviceName: String) {
        peerToPeerType = peerType
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: peerToPeerType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: peerToPeerType)
        self.identifier = identifier
        self.iAmPlayingWith = Nobody
        super.init()
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    func hasOtherPlayers() -> Bool {
        return self.session.connectedPeers.count != 0
    }
    
    func countPartners() -> Int {
        return session.connectedPeers.count
    }
    
    func getPartners()->[MCPeerID] {  // [peerID]
        return session.connectedPeers
    }
    
    func changeIdentifier(_ newIdentifier: String) {
        self.identifier = newIdentifier
        for index in 0..<session.connectedPeers.count {
            sendInfo(command: .myNameIs, message: [identifier, iAmPlayingWith], toPeer: session.connectedPeers[index])
        }
    }
    
    func changeStatusToFree() {
        for index in 0..<session.connectedPeers.count {
            iAmPlayingWith = Nobody
            sendInfo(command: .myStatusIsFree, message: [], toPeer: session.connectedPeers[index])
        }
    }
    
    func changeStatusToIsPlaying(isPlayingWith: String) {
        iAmPlayingWith = isPlayingWith
        for index in 0..<session.connectedPeers.count {
            sendInfo(command: .myStatusIsPlaying, message: [isPlayingWith], toPeer: session.connectedPeers[index])
        }
    }
    
    func sendData(command: CommunicationCommands, messageNr: Int, message : [String], new: Bool = true, toPeer: MCPeerID, answer: Bool = false) {
        var founded = false
        var peer: MCPeerID? = nil
        for actPeer in session.connectedPeers {
            if actPeer.displayName == toPeer.displayName {
                founded = true
                peer = actPeer
            }
        }
        if !founded {
            return
        }
        do {
            var stringToSend = (command.commandName + separator + String(messageNr) + separator + String(new))
            for index in 0..<message.count {
                stringToSend += separator + message[index]
            }
            messageArray[messageNr] = MessageContent(command: command, messages: message, answers: [String](), fromPeer: myPeerID, closed: false, timeStamp: Date())
            let myNSData = (stringToSend as NSString).data(using: String.Encoding.utf8.rawValue)!
            
            try self.session.send(myNSData, toPeers: [peer!], with: MCSessionSendDataMode.reliable)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
            
    }
    
    func sendInfo(command: CommunicationCommands, message : [String], new: Bool = true, toPeer: MCPeerID) {
        sendData(command: command, messageNr: messageNr, message: message, new: true, toPeer: toPeer, answer: false)
        messageArray.removeValue(forKey: messageNr)
        messageNr += 1
    }

    func sendMessage(command: CommunicationCommands, message : [String], toPeer: MCPeerID)->[String] {
        let myMessageNr = messageNr
        messageNr += 1
        sendData(command: command, messageNr: myMessageNr, message: message, new: true, toPeer: toPeer, answer: false)
        var counter = 0
        let maxTime: Double = 20 // sec
        let startAt = Date()
        var answersToReturn: [String]
        while !messageArray[myMessageNr]!.closed && Date().timeIntervalSince(startAt) < maxTime {
            sleep(UInt32(0.1))
            counter += 1
        }
        if Date().timeIntervalSince(startAt) < maxTime {
            answersToReturn = messageArray[myMessageNr]!.answers
        } else {
            answersToReturn = [GV.timeOut]
        }
        messageArray.removeValue(forKey: myMessageNr)
        
        return answersToReturn
    }

    func sendAnswer(messageNr: Int, answer : [String]) {
        
        let command = answerArray[messageNr]!.command
        let toPeer = answerArray[messageNr]!.fromPeer
        sendData(command: command, messageNr: messageNr, message: answer, new: false, toPeer: toPeer, answer: true)
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
    
    
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
        case .notConnected: return "NotConnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        }
    }
    
    
    
}


extension P2PHelper : MCNearbyServiceAdvertiserDelegate {
    @available(iOS 7.0, *)
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }

    @available(iOS 7.0, *)
//    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
//        
//    }

    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, error: NSError) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
//    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?,  invitationHandler: (Bool, MCSession) -> Void) {
//        invitationHandler(true, self.session)
////        print("from \(myPeerID.displayName): in PeerToPeerServiceManager")
//    }

}

extension P2PHelper : MCNearbyServiceBrowserDelegate {

    private func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("didNotStartBrowsingForPeers: \(error)")
    }

    

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
//        if peerID.displayName.containsString(PeerToPeerServiceManager.CardFootballName) {
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
            print("new connection found: \(String(describing: peerID.displayName)), countConnections: \(self.session.connectedPeers.count)")
//        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
//        connectionLost(
        print("connections lost: \(String(describing: peerID.displayName)), count connections: \(self.session.connectedPeers.count)")
    }
}

extension P2PHelper : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        //        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
        if state == .connected {
            sendInfo(command: .myNameIs, message:  [identifier, iAmPlayingWith], toPeer: peerID)
            print ("connected to \(peerID.displayName), countConnections: \(self.session.connectedPeers.count)")
        }
//        print("peer \(String(describing: peerID.displayName)) didChangeState: \(state.stringValue())")
        
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let receivedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        let stringTable = receivedString.components(separatedBy: separator)
        let command = CommunicationCommands.decodeCommand(stringTable[0])
        let messageNr = Int(stringTable[1])
        let new = stringTable[2] == "true" ? true : false
        var parameterString = [String]()
        for index in 3..<stringTable.count {
            parameterString.append(stringTable[index])
        }
        
        for index in 0..<session.connectedPeers.count {
            if session.connectedPeers[index] == peerID {
                if command == .myNameIs {
                    peerID.name = parameterString[0]
                    if parameterString.count > 1 { // older versions send only the 1-st param
                        peerID.playingWith = parameterString[1]
                    }
                    //                self.delegate!.messageReceived(fromPeerIndex, command: command, message: parameterString, messageNr: messageNr!)
                } else if command == .myStatusIsFree {
                    peerID.playingWith = ""
                } else if command == .myStatusIsPlaying {
                    peerID.playingWith = parameterString[0]
                } else {
                    if new { // new message from Partner
                        answerArray[messageNr!] = MessageContent(command: command, messages: parameterString, answers: [String](), fromPeer: peerID, closed: false, timeStamp: Date())
                        self.delegate!.messageReceived(peerID, command: command, message: parameterString, messageNr: messageNr!)
                    } else { // answer to my Message
                        messageArray[messageNr!]!.answers = parameterString
                        //                    print("used time: \(Date().timeIntervalSince(messageArray[messageNr!]!.timeStamp)), \(parameterString)")
                        messageArray[messageNr!]!.closed = true
                    }
                }
                break
            }
        }
//        if fromPeerIndex != -1 {
//            if command == .myNameIs {
//                peerID.name = parameterString[0]
////                self.delegate!.messageReceived(fromPeerIndex, command: command, message: parameterString, messageNr: messageNr!)
//            } else {
//                if new { // new message from Partner
//                    answerArray[messageNr!] = MessageContent(command: command, messages: parameterString, answers: [String](), fromPeer: fromPeerIndex, closed: false, timeStamp: Date())
//                    self.delegate!.messageReceived(fromPeerIndex, command: command, message: parameterString, messageNr: messageNr!)
//                } else { // answer to my Message
//                    messageArray[messageNr!]!.answers = parameterString
////                    print("used time: \(Date().timeIntervalSince(messageArray[messageNr!]!.timeStamp)), \(parameterString)")
//                    messageArray[messageNr!]!.closed = true
//                }
//            }
//        }
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
//        print("from \(myPeerID.displayName):didStartReceivingResourceWithName")
    }
    
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL? , withError error: Error?) {
//        print("from \(myPeerID.displayName):didFinishReceivingResourceWithName")
    }
    
   func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
//        print("from \(myPeerId.displayName):didReceiveStream")
    }
    
    
}

extension MCPeerID {

    fileprivate struct AssociatedKeys {
        static var partnerName:String?
        static var opponentName:String?
        static var index: Int?
    }
    
    var name: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.partnerName) as? String
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.partnerName, newValue as String?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    var playingWith: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.opponentName) as? String
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.opponentName, newValue as String?, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}


