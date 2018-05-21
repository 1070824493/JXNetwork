//
//  JXTCPMessageHandler.swift
//  JXNetworkKit
//
//  Created by Leo on 25/04/2017.
//  Copyright © 2017 Juxin. All rights reserved.
//

import Foundation
import SwiftyJSON

public typealias JXMessageCallback = (_ code: Int, _ json: JSON?) -> Void

class JXTCPMessageHandler {
  var messageId = 0
  var sendTime: Int64 = 0
  var callback: JXMessageCallback?
  
  init(messageId: Int, callback: JXMessageCallback?) {
    self.messageId = messageId
    self.callback = callback
    self.sendTime = JXTCPManager.serverTime
  }
}
