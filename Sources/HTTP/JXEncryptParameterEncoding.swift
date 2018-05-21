//
//  JXEncryptParameterEncoding.swift
//  JXNetworkKit
//
//  Created by LeoWei on 2017/8/24.
//  Copyright © 2017年 Juxin. All rights reserved.
//

import Foundation
import Alamofire
import JXEncrypt
import SwiftyJSON

struct JXEncryptParameterEncoding: ParameterEncoding {
  
  /// Returns a default `URLEncoding` instance.
  public static var `default`: JXEncryptParameterEncoding { return JXEncryptParameterEncoding() }
  
  func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
    var request = urlRequest.urlRequest!
    
    request.setValue("application/jx-json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/jx-json", forHTTPHeaderField: "Accept")
    
    guard let parameters = parameters else {
      return request
    }
    
    let options = JSONSerialization.WritingOptions()
    guard let jsonString = JSON(parameters).rawString(options: options) else {
      return request
    }
    request.httpBody = Encrypt.encrypt(jsonString).data(using:.utf8)
    return request
  }
}
