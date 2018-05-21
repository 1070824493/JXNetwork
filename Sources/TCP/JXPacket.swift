//
//  JXPacket.swift
//  JXNetworkKit
//
//  Created by Leo on 21/04/2017.
//  Copyright © 2017 Juxin. All rights reserved.
//

import Foundation

enum SocketTag {
  
  static let loginHeader = 101
  static let loginBody = 102
  
  static let otherHeader = 200
  static let otherBody = 201
  
  static let login = 1
  static let message = 100
  static let heartbeat = 65535
  
}

enum PacketType: UInt16 {
  
  case login = 1
  case heartbeat = 65535

}


class JXPacket : JTSerializable {
  
  static let headerLength = MemoryLayout<UInt32>.size + MemoryLayout<UInt32>.size + MemoryLayout<UInt16>.size
  
  // length(4)/uid(4)/type(2)/content(n)
  var packetBodyLength : UInt32 = 0 // not include the packet header
  var senderId : UInt32 = 0
  var packetType : UInt16 = 0
  
  @discardableResult
  func serialize(_ archive: JTArchiveProtocol) -> Int {
    var count = archive.serialize(&packetBodyLength)
    count += archive.serialize(&senderId)
    count += archive.serialize(&packetType)
    return count
  }
  
  func bytesSwappedObject() {
    packetBodyLength = packetBodyLength.byteSwapped
    senderId = senderId.byteSwapped
    packetType = packetType.byteSwapped
  }
}
