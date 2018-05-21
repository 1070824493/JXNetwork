//
//  JXRequestConfig.swift
//  JXNetworkKit
//
//  Created by Leo on 25/04/2017.
//  Copyright © 2017 Juxin. All rights reserved.
//

import Foundation
import Alamofire
import JXEncrypt
import SwiftyJSON
import EVReflection

public protocol JXHostConvertible {
  func asHost() -> String
}

public enum JXEncryptType {
  case none           // 不加密
  case all            // 请求加密 & 返回也是加密的
  case requestOnly    // 请求加密 & 返回内容不是加密的
  case responseOnly   // 请求不是加密的 & 返回内容是加密的
}

public enum JXHashMethod {
  
  @available(*, deprecated: 3.0, message: "⚠️这个应该用dictionary了")
  public static let form = JXHashMethod.dictionary
  case none        // 不加密
  case dictionary  // 当做字典排序加密
  
  @available(*, deprecated: 3.0, message: "⚠️这个应该没用了，如果你用到了，也许就是你用错了哦")
  case jsonString      // jsonString形式的hash计算方式
}

public enum JXRequestEncoding {
  case url      // 对应Alamofire的url encoding, 代表： GET 或 POST表单上传
  case json     // 对应Alamofire的json encoding, 代表： POST 传JSON
  case encrypt   // 对应Alamofire的自定义encoding，目前我们是自己用来加密🔐使用
}

public enum JXCacheType {
  case none                   // 不缓存
  case cache                  // 仅用YYCache缓存
  case file(path: String)  // 不仅cache，还有文件备份
}

public class JXRequestConfig {
  
  var host: JXHostConvertible
  var path: String
  var method: HTTPMethod = .post
  var encryptMethod: JXEncryptType = .none
  var encoding: JXRequestEncoding = .url
  var hashMethod: JXHashMethod = .none
  
  var requestURL: String {
    return host.asHost() + path
  }
  
  var needDecryptResponse: Bool {
    return encryptMethod == .responseOnly || encryptMethod == .all
  }
  
  var parameterEncoding: ParameterEncoding {
    switch encoding {
    case .url:
      return URLEncoding.default
    case .json:
      return JSONEncoding.default
    case .encrypt:
      return JXEncryptParameterEncoding.default
    }
  }
  
  public init(host: JXHostConvertible, path: String, method: HTTPMethod = .post, encryptMethod: JXEncryptType = .none,
              encoding: JXRequestEncoding = .url, hashMethod: JXHashMethod = .none, cacheType: JXCacheType = .none) {
    self.host = host
    self.path = path
    self.method = method
    self.encryptMethod = encryptMethod
    self.encoding = encoding
    self.hashMethod = hashMethod
    self.cacheType = cacheType
  }
  
  public func get(_ param: Param) -> Self {
    query += param
    return self
  }
  public func post(_ param: Param) -> Self {
    body += param
    return self
  }
  public func header(_ param: HTTPHeaders?) -> Self {
    headers = param
    return self
  }
  public func param(_ param: Param) -> Self {
    return method == .post ? post(param) : get(param)
  }

  var query: Param = [:]
  var body: Param = [:]
  var headers: HTTPHeaders? = nil
  
  var parameters: Param? {
    
    if method == .post {
      return body
    }
    
    if hashMethod == .none {
      return query
    }
    
    return nil
    
  }
  
  // MARK: - CACHE
  
  public var cacheType: JXCacheType = .none
  public var shouldCache: Bool {
    
    if case .none = cacheType {
      return false
    }
    return true
  }
  
}







