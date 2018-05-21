//
//  JTArchive.swift
//  JXNetworkKit
//
//  Created by Leo on 24/04/2017.
//  Copyright © 2017 Juxin. All rights reserved.
//

import Foundation

enum ArchiveProcessType {
  case read, write
}

protocol JTArchiveProtocol {
  func serialize<T>(_ o: inout T) -> Int
}

protocol JTSerializable {
  func serialize(_ archive: JTArchiveProtocol) -> Int
}

class JTArchive : JTArchiveProtocol {
  
  var buffer: Array<Int8>
  var currentPtr: UnsafeMutablePointer<Int8>
  var processType: ArchiveProcessType = ArchiveProcessType.read
  
  init(buffer: inout Array<Int8>, processType: ArchiveProcessType) {
    self.buffer = buffer
    self.currentPtr = UnsafeMutableBufferPointer<Int8>(start: &buffer, count: buffer.count).baseAddress!
    self.processType = processType
  }
  
  func serialize<T>(_ o: inout T) -> Int {
    
    if processType == .read {
      o = currentPtr.withMemoryRebound(to: T.self, capacity: MemoryLayout<T>.size) { (pointer) -> T in
        return pointer.pointee
      }
    }
    else {
      
      _ = currentPtr.withMemoryRebound(to: T.self, capacity: MemoryLayout<T>.size) { (pointer) -> T in
        pointer.pointee = o
        return pointer.pointee
      }
      
    }
    currentPtr = currentPtr.advanced(by: MemoryLayout<T>.size)
    
    return MemoryLayout<T>.size
  }
  
  func serialize<T: JTSerializable>(_ o: inout T) -> Int {
    return o.serialize(self)
  }
}
