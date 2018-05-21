//
//  JXReachabilityManager.swift
//  JXNetworkKit
//
//  Created by Leo on 21/04/2017.
//  Copyright © 2017 Juxin. All rights reserved.
//

import Foundation
import Alamofire

public enum JXReachabilityStatus {
  case wifi
  case cellular
  case none
  case unknown
}

public extension Notification.Name {
  static let jx_reachabilityDidChange = Notification.Name(rawValue: "com.juxin.reachabilityDidChange")
}

extension NetworkReachabilityManager.NetworkReachabilityStatus {
  
  func convert() -> JXReachabilityStatus {
    
    switch self {
      
    case NetworkReachabilityManager.NetworkReachabilityStatus.notReachable:
      return .none
      
    case NetworkReachabilityManager.NetworkReachabilityStatus.reachable(ConnectionType: let type):
      return type == NetworkReachabilityManager.ConnectionType.ethernetOrWiFi ? .wifi : .cellular
      
    default:
      return .unknown
    }
    
  }
  
}

protocol JXReachabilityManagerDelegate: NSObjectProtocol {
  
  func jx_reachabilityDidChanged(currentStatus: JXReachabilityStatus)
  
}

public class JXReachabilityManager: NSObject {
  
  public static let shared = JXReachabilityManager()
  
  private var manager: NetworkReachabilityManager?
  weak var delegate: JXReachabilityManagerDelegate?
  
  public var currentStatus: JXReachabilityStatus = .unknown {
    didSet{
      NotificationCenter.default.post(name: .jx_reachabilityDidChange, object: nil)
    }
  }
  
  var isReachable: Bool {
    return currentStatus != .unknown && currentStatus != .none
  }
  
  private override init() {
    
    super.init()
    
    manager = NetworkReachabilityManager()
    manager?.listener = { state in
      self.currentStatus = state.convert()
      self.delegate?.jx_reachabilityDidChanged(currentStatus: self.currentStatus)
    }
    manager?.startListening()
  }
  
}

