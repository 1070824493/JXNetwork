//
//  JXResponse.swift
//  JXNetworkKit
//
//  Created by Leo on 25/04/2017.
//  Copyright © 2017 Juxin. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum ResponseKey {
  
  public static let res = "res"
  public static let result = "result"
  public static let status = "status"
  
  public static let ok = "ok"
  public static let success = "success"
  
  // JXResponse key
  public static let msg = "msg"
  public static let detail = "detail"
  public static let code = "code"
}

public struct JXResponse {
  
  public var status = "" // "success" / "fail", 成功／失败
  public var code = 0  // 预定义状态码
  public var msg = "" // 错误信息
  public var error: Error?
  
  public var isSuccess: Bool {
    return error == nil && (status == ResponseKey.ok || status == ResponseKey.success)
  }
  
  public static func parse(_ value: Any?) -> JXResponse {
    
    if let dictionary = value as? NSDictionary {
      return parse(dictionary: dictionary)
    }
    
    return JXResponse()
    
  }
  
  private static func parse(dictionary: NSDictionary) -> JXResponse {
    
    var response = JXResponse()
    response.msg = dictionary[ResponseKey.msg] as? String ?? ""
    
    // 防止上层错误信息被覆盖
    let msg = dictionary[ResponseKey.detail] as? String ?? ""
    if response.msg.isEmpty || !msg.isEmpty {
      response.msg = msg
    }
    
    response.code = dictionary[ResponseKey.code] as? Int ?? 0
    response.status = dictionary[ResponseKey.status] as? String ?? ""
    
    return response
    
  }
  
}

