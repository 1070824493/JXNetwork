//
//  JXTCPManager.swift
//  JXNetworkKit
//
//  Created by Leo on 21/04/2017.
//  Copyright © 2017 Juxin. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import SwiftyJSON
import JXEncrypt

let reconnectTimeInterval   = 3.0
let reconnectMaxCount       = 3
let loginTimeOut            = 10.0
let sendTimeOutTime         = 6.0

let readTimeOutTime         = 5.0
let heartBeatInterval       = 30.0

public enum ConnectStatus {
  case unconnected, connected, reconnecting, connecting, reconnectFailed
}

public protocol JXTCPManagerDelegate: NSObjectProtocol {
  func jx_TCPAddress() -> (host: String, port: UInt16)
  func jx_TCPLoginBody() -> String
  func jx_TCPDidRecieve(message: JSON)
}

open class JXTCPManager: NSObject, GCDAsyncSocketDelegate {
  
  public static let shared = JXTCPManager()
  public static let connectTimeoutTimeInterval: TimeInterval = 5
//  public static var host = "123.59.187.33" //"sc.app.yuanfenba.net"
//  public static var port: UInt16 = 8823
  
  public weak var delegate: JXTCPManagerDelegate?
  
  public private(set) static var serverTime: Int64 {
    
    get { return Int64(Date().timeIntervalSince1970) + serverOffsetTime }
    
    set {
      if newValue == 0 { return }
      serverOffsetTime = serverTime - Int64(Date().timeIntervalSince1970)
    }
  }
  
  public private(set) var currentStatus: ConnectStatus = .unconnected {
    willSet {
      DDLogInfo("TCPManager------- currentStatus will change from \(currentStatus) to \(newValue)")
    }
    
    didSet{
      NotificationCenter.default.post(name: .tcpStatusDidChangedNotification, object: currentStatus)
    }
  }
  
  public func login(uid: Int, completionHandler: @escaping (_ result: Bool) -> Void) {
    
    logout()
    self.uid = uid
    
    currentStatus = .connecting
    loginHandler = completionHandler
    connect()
  }
  
  public func logout() {
    
    DDLogInfo("TCPManager------- logout")
    
    if timer != nil {
      timer!.invalidate()
      timer = nil
    }
    
    socket?.disconnect()
    
    currentStatus = .unconnected
    
  }
  
  public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
    
    DDLogInfo("TCPManager------- connected!")
    
    sendLoginData()
    
  }
  
  public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    DDLogInfo("TCPManager------- socket disconnected.")
    
    timer?.invalidate()
    timer = nil
    
    if err == nil {
      loginHandlerAndClear(success: false)
    } else {
      reConnect()
    }
    
  }
  
  public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    
    switch tag {
      
    case SocketTag.loginHeader:
      
      guard let packetHeader = readPacketHead(data) else { return }
      
      tryToReadBody(SocketTag.loginBody, length: UInt(packetHeader.packetBodyLength))
      
    case SocketTag.loginBody:
      
      defer { tryToReadHeader(SocketTag.otherHeader) }
      
      guard let body = String(data: data, encoding: String.Encoding.utf8) else {
        loginHandlerAndClear(success: false)
        currentStatus = .unconnected
        return
      }
      
      loginHandle(Encrypt.decrypt(body))
      
    case SocketTag.otherHeader:
      
      guard let packetHeader = readPacketHead(data) else { return }
      
      currentPacket = packetHeader
      
      guard packetHeader.packetBodyLength > 0 else {
        
        DDLogInfo("TCPManager------- did read heartbeat")
        tryToReadHeader(SocketTag.otherHeader)
        return
      }
      
      tryToReadBody(SocketTag.otherBody, length: UInt(currentPacket.packetBodyLength))
      
    case SocketTag.otherBody:
      
      defer { tryToReadHeader(SocketTag.otherHeader) }
      
      if data.count < Int(currentPacket.packetBodyLength) { return }
      
      guard let cryptographBody = String(data: data, encoding: String.Encoding.utf8) else { return }
      
      DDLogInfo("TCPManager------- socket didRead: " + cryptographBody)
      
      var clearTextBody = Encrypt.decrypt(cryptographBody)
      
      guard clearTextBody != nil else { return }
      
      guard !clearTextBody!.isEmpty else { return }
      
      clearTextBody = clearTextBody!.replacingOccurrences(of: "\n", with: "")
      
      let json = JSON(parseJSON: clearTextBody!)
      
      if currentPacket.packetType < 100 {
        
        handleMessage(json: json)
        
      } else {
        
        let content = "{\"d\":\(json["d"].intValue),\"s\":0}"
        sendPacket(ofType: currentPacket.packetType, content: content, tag: 0)
        
        delegate?.jx_TCPDidRecieve(message: json)
        
      }
      
      
    default:
      DDLogInfo("TCPManager------- error read tag=\(tag)")
    }
    
  }
  
  // MARK:- private
  private override init() {
    super.init()
    NotificationCenter.default.addObserver(self, selector: #selector(networkStatusDidChanged), name: .jx_reachabilityDidChange, object: nil)
    callbackTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeoutCallbacks), userInfo: nil, repeats: true)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  private var socket: GCDAsyncSocket?
  private var timer: Timer? = nil
  private var callbackTimer: Timer? = nil
  
  private var uid = 0

  private var failCount = 0
  
  private var currentPacket = JXPacket()
  
  private var loginHandler: ((Bool) -> Void)? = nil {
    didSet {
      if loginHandler != nil {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + loginTimeOut) {
          self.loginHandlerAndClear(success: false)
        }
      }
    }
  }
  
  private static var serverOffsetTime: Int64 = 0
  
  private func connect() {
    
    socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    socket?.isIPv4PreferredOverIPv6 = false
    
    do {
      let address = delegate?.jx_TCPAddress() ?? (host: "sc.app.yuanfenba.net", port: 8823)
      try socket?.connect(toHost: address.host, onPort: address.port, withTimeout: JXTCPManager.connectTimeoutTimeInterval)
    }
    catch _ {
      DDLogInfo("TCPManager------- Connect failed")
      currentStatus = .unconnected
      loginHandlerAndClear(success: false)
    }
  }
  
  fileprivate func reConnect() {
    
    socket?.disconnect()
    currentStatus = .reconnecting
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + reconnectTimeInterval) {
      self.failCount += 1
      if self.failCount >= reconnectMaxCount {
        self.failCount = 0
        self.currentStatus = .reconnectFailed
        return
      }
      
      DDLogInfo("TCPManager------- Socket reconnecting")
      self.connect()
    }
    
  }
  
  private func loginHandle(_ jsonString: String) {
    
    let resultJson = JSON(parseJSON: jsonString)
    
    if resultJson["tm"] != JSON.null {
      JXTCPManager.serverTime = resultJson["tm"].int64Value
    }
    
    if resultJson["status"] != JSON.null && resultJson["status"].intValue == 0 {
      DDLogInfo("TCPManager------- Start timer to send heartbeat")
      
      timer?.invalidate()
      timer = Timer.scheduledTimer(timeInterval: heartBeatInterval, target: self, selector: #selector(sendHeartbeatData), userInfo: nil, repeats: true)
      
      
      self.loginHandlerAndClear(success: true)
      currentStatus = .connected
      return
    }
    
    DDLogInfo("TCPManager------- Login and return the error status")
    logout()
    reConnect()
    
    loginHandlerAndClear(success: false)
    
  }
  
  private func loginHandlerAndClear(success: Bool) {
    loginHandler?(success)
    loginHandler = nil
  }
  
  // MARK:- packet creator
  
  private func createLoginJsonString() -> String {
    return delegate?.jx_TCPLoginBody() ?? ""
  }
  
  private func createPacketData(ofType type: UInt16, content: String) -> Data {
    
    let header = JXPacket()
    
    header.senderId = UInt32(uid)
    let contentData = content.data(using: .utf8)!
    
    header.packetBodyLength = UInt32(contentData.count)
    header.packetType = type
    header.bytesSwappedObject()
    
    var buffer = [Int8](repeating: 0, count: Int(JXPacket.headerLength))
    let archive = JTArchive(buffer: &buffer, processType: .write)
    header.serialize(archive)
    
    let data = NSMutableData(bytes: buffer, length: buffer.count)
    data.append(contentData)
    
    return data as Data
  }
  
  // MARK:- packet sender
  
  private func sendLoginData() {
    
    guard uid > 0 else {
      socket?.disconnect()
      currentStatus = .unconnected
      return
    }
    
    sendPacket(ofType: PacketType.login.rawValue, content: createLoginJsonString(), tag: SocketTag.login)
    tryToReadHeader(SocketTag.loginHeader)
  }
  
  @objc private func sendHeartbeatData() {
    sendPacket(ofType: PacketType.heartbeat.rawValue, content: "", tag: SocketTag.heartbeat, encrypt: false)
  }
  
  private func sendPacket(ofType type: UInt16, content: String, tag: Int, encrypt: Bool = true) {
    
    let data = createPacketData(ofType: type, content: encrypt ? Encrypt.encrypt(content) : content)
    DDLogInfo("TCPManager------- send data, content=\(content), data length = \(data.count)")
    
    socket?.write(data, withTimeout: sendTimeOutTime, tag: tag)
  }
  
  // MARK:- packet parser
  
  private func tryToReadHeader(_ tag: Int) {
    socket?.readData(withTimeout: -1, buffer: nil, bufferOffset: 0, maxLength: UInt(JXPacket.headerLength), tag: tag)
  }
  
  private func tryToReadBody(_ tag: Int, length: UInt) {
    socket?.readData(toLength: length, withTimeout: -1, tag: tag)
  }
  
  private func readPacketHead(_ data: Data) -> JXPacket? {
    
    if data.count != JXPacket.headerLength {
      return nil
    }
    
    var buffer = [Int8](repeating: 0, count: JXPacket.headerLength)
    (data as NSData).getBytes(&buffer, length: Int(JXPacket.headerLength))
    
    let archive = JTArchive(buffer: &buffer, processType: .read)
    
    let header = JXPacket()
    header.serialize(archive)
    
    header.bytesSwappedObject()
    
    return header
  }
  
  // MARK: TCPMessageSender
  
  open func sendMessage(messageId: Int, type: UInt16, content message: String, complete: JXMessageCallback?) {
    if currentStatus != .connected {
      complete?(-1001, nil)
      return
    }
    
    addHandler(messageId: messageId, callback: complete)
    sendPacket(ofType: type, content: message, tag: SocketTag.message, encrypt: true)
  }

  
  private var messageHandlers: [Int: JXTCPMessageHandler] = [:]
  
  private func addHandler(messageId: Int, callback: JXMessageCallback?) {
    
    messageHandlers[messageId] = JXTCPMessageHandler(messageId: messageId, callback: callback)
    
  }
  
  private func removeMessage(messageId: Int) -> JXTCPMessageHandler? {
    
    return messageHandlers.removeValue(forKey: messageId)
    
  }
  
  private func handleMessage(json: JSON) {
    
    guard let handler = removeMessage(messageId: json["d"].intValue) else { return }
    
    handler.callback?(json["s"].intValue, json)
    
  }
  
  @objc private func timeoutCallbacks() {
    messageHandlers.forEach { (id, message) in
      if JXTCPManager.serverTime - message.sendTime > Int64(6) {
        message.callback?(-1002, nil)
        messageHandlers[id] = nil
      }
    }
  }

}

extension JXTCPManager {
  
  @objc func networkStatusDidChanged() {
    if currentStatus == .reconnectFailed && JXReachabilityManager.shared.isReachable {
      reConnect()
    }
  }
  
}

extension NSNotification.Name {
  
  public static let tcpStatusDidChangedNotification = Notification.Name(rawValue: "tcpStatusDidChanged")
}
