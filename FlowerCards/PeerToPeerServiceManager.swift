
//
//  PeerToPeerManager.swift
//  Flowers
//
//  Created by Jozsef Romhanyi on 20/07/2016.
//  Copyright © 2016 Jozsef Romhanyi. All rights reserved.
//

import Foundation
import MultipeerConnectivity


class PeerToPeerServiceManager: NSObject {

    let separator = "°"
    var identifier: String
    struct MessageContent {
        var command: PeerToPeerCommands
        var messages: [String]
        var answers: [String]
        var fromPeerIndex: Int
        var closed: Bool
        var timeStamp: Date
   }
    fileprivate let peerToPeerType: String
//    static private let CardFootballName:String = "CardFootball on "
    
    fileprivate let myPeerId = MCPeerID(displayName: UIDevice.current.identifierForVendor!.uuidString)//.name)
    
    fileprivate let serviceBrowser : MCNearbyServiceBrowser
    fileprivate let serviceAdvertiser : MCNearbyServiceAdvertiser
    var delegate : PeerToPeerServiceManagerDelegate?
    
    var messageArray = [Int:MessageContent]()
    var answerArray = [Int:MessageContent]()
    var messageNr = 0

    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.required)
        session.delegate = self
        return session
    }()

    init(peerType: String, identifier: String, deviceName: String) {
        peerToPeerType = peerType
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: peerToPeerType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: peerToPeerType)
        self.identifier = identifier
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
    
    func getPartnerName()->([String]) {  // partnerName, deviceName
        var names = [String]()
        for index in 0..<session.connectedPeers.count {
            names.append((session.connectedPeers[index].name!))
        }
        return names
    }
    
    func changeIdentifier(_ newIdentifier: String) {
        self.identifier = newIdentifier
        for index in 0..<session.connectedPeers.count {
            sendInfo(.myNameIs, message: [identifier], toPeer: session.connectedPeers[index])
        }
    }
    
    func sendData(_ command: PeerToPeerCommands, messageNr: Int, message : [String], new: Bool = true, toPeer: MCPeerID? = nil, toPeerIndex: Int = 0, answer: Bool = false) {
        var peer = toPeer
        if toPeer == nil {
            peer = session.connectedPeers[toPeerIndex]
        }
        if session.connectedPeers.count > 0 {
            do {
                var stringToSend = (command.commandName + separator + String(messageNr) + separator + String(new))
                for index in 0..<message.count {
                    stringToSend += separator + message[index]
                }
                messageArray[messageNr] = MessageContent(command: command, messages: message, answers: [String](), fromPeerIndex: 0, closed: false, timeStamp: Date())
                let myNSData = (stringToSend as NSString).data(using: String.Encoding.utf8.rawValue)!
//                print("sendMessage: \(stringToSend) to \(peer!.displayName)")
                
                try self.session.send(myNSData, toPeers: [peer!], with: MCSessionSendDataMode.reliable)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
        }
    }
    
    func sendInfo(_ command: PeerToPeerCommands, message : [String], new: Bool = true, toPeer: MCPeerID? = nil, toPeerIndex: Int = 0) {
        sendData(command, messageNr: messageNr, message: message, new: true, toPeer: toPeer, toPeerIndex: toPeerIndex, answer: false)
        messageArray.removeValue(forKey: messageNr)
        messageNr += 1
    }

    func sendMessage(_ command: PeerToPeerCommands, message : [String], toPeer: MCPeerID? = nil, toPeerIndex: Int = 0)->[String] {
        let myMessageNr = messageNr
        messageNr += 1
        sendData(command, messageNr: myMessageNr, message: message, new: true, toPeer: toPeer, toPeerIndex: toPeerIndex, answer: false)
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

    func sendAnswer(_ messageNr: Int, answer : [String]) {
        
        let command = answerArray[messageNr]!.command
        let toPeerIndex = answerArray[messageNr]!.fromPeerIndex
        sendData(command, messageNr: messageNr, message: answer, new: false, toPeerIndex: toPeerIndex, answer: true)
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


extension PeerToPeerServiceManager : MCNearbyServiceAdvertiserDelegate {
    @available(iOS 7.0, *)
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }

    @available(iOS 7.0, *)
//    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
//        
//    }

    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, error: NSError) {
//        print("didNotStartAdvertisingPeer: \(error)")
    }
    
//    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?,  invitationHandler: (Bool, MCSession) -> Void) {
//        invitationHandler(true, self.session)
////        print("from \(myPeerId.displayName): in PeerToPeerServiceManager")
//    }

}

extension PeerToPeerServiceManager : MCNearbyServiceBrowserDelegate {

    private func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
//        print("didNotStartBrowsingForPeers: \(error)")
    }

    

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
//        if peerID.displayName.containsString(PeerToPeerServiceManager.CardFootballName) {
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
//            print("new connection found: \(peerID.displayName), countConnections: \(self.session.connectedPeers.count)")
//        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
//        connectionLost(
        print("connections lost: \(peerID.displayName), count connections: \(self.session.connectedPeers.count)")
    }
}

extension PeerToPeerServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        //        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
        if state == .connected {
            sendInfo(.myNameIs, message:  [identifier], toPeer: peerID)
        }
//        print("peer \(peerID.displayName) didChangeState: \(state.stringValue())")
        
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let receivedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
        let stringTable = receivedString.components(separatedBy: separator)
        let command = PeerToPeerCommands.decodeCommand(stringTable[0])
        let messageNr = Int(stringTable[1])
        let new = stringTable[2] == "true" ? true : false
        var parameterString = [String]()
        for index in 3..<stringTable.count {
            parameterString.append(stringTable[index])
        }
        
        var fromPeerIndex = -1
        for index in 0..<session.connectedPeers.count {
            if session.connectedPeers[index] == peerID {
                fromPeerIndex = index
                break
            }
        }
        if fromPeerIndex != -1 {
            if command == .myNameIs {
                peerID.name = parameterString[0]
//                self.delegate!.messageReceived(fromPeerIndex, command: command, message: parameterString, messageNr: messageNr!)
            } else {
                if new { // new message from Partner
                    answerArray[messageNr!] = MessageContent(command: command, messages: parameterString, answers: [String](), fromPeerIndex: fromPeerIndex, closed: false, timeStamp: Date())
                    self.delegate!.messageReceived(fromPeerIndex, command: command, message: parameterString, messageNr: messageNr!)
                } else { // answer to my Message
                    messageArray[messageNr!]!.answers = parameterString
//                    print("used time: \(Date().timeIntervalSince(messageArray[messageNr!]!.timeStamp)), \(parameterString)")
                    messageArray[messageNr!]!.closed = true
                }
            }
        }
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
//        print("from \(myPeerId.displayName):didStartReceivingResourceWithName")
    }
    
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL , withError error: Error?) {
//        print("from \(myPeerId.displayName):didFinishReceivingResourceWithName")
    }
    
   func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
//        print("from \(myPeerId.displayName):didReceiveStream")
    }
    
    
}

extension MCPeerID {

    fileprivate struct AssociatedKeys {
        static var partnerName:String?
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

    
}

protocol PeerToPeerServiceManagerDelegate {
    
    func connectedDevicesChanged(_ manager : PeerToPeerServiceManager, connectedDevices: [String])
    func messageReceived(_ fromPeerIndex : Int, command: PeerToPeerCommands, message: [String], messageNr: Int)
    
}

