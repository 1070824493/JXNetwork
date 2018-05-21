//
//  HashUtil.swift
//  JXNetworkKit
//
//  Created by Leo on 26/04/2017.
//  Copyright © 2017 Juxin. All rights reserved.
//

import UIKit
import Foundation
import CommonCrypto

public class HashUtil {
  
  @available(*, deprecated: 3.0, message: "🈲🚫❌⛔️禁止使用了哦，JXRequestConfig.hashUrl(query:body:)")
  public static func hashUrl(with config: JXRequestConfig,
                      urlParam: [String: Any],
                      postParam: [String: Any]) -> String {
    
    return config.get(urlParam).post(postParam).hashUrl
  }
  
}

//MARK:- HASH
extension JXRequestConfig {
  
  public var hashUrl: String {
    
    //如果 hashMethod == .none，只是返回requestURL，其他参数会在请求时候alamofire添加
    guard hashMethod != .none else { return requestURL }
    
    var _query = query
    _query["ts"] = Int(Date().timeIntervalSince1970)
    
    if hashMethod == .dictionary {
      _query["hash"] = hashParams(_query, body: body)
    } else {
      let data = try? JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions())
      let string = String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? ""
      _query["hash"] = hashParams(_query, body: ["post": string])
    }
    
    var ret = _query.map{ $0.0 + ("=\($0.1)").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! }
              .joined(separator: "&")
    ret = requestURL + "?" + ret
    
    return ret
    
  }
  
  private func hashParams(_ query: Param, body: Param) -> String {
    var result = "yuafenba(&^%_=>yuafenba|"
    
    // 如果请求加密，body不参与hash计算
    let needHashBody = encryptMethod == .none || encryptMethod == .responseOnly
    
    // 这里有个坑就是如果没有body的参数依然还是拼接一个"|"的
    result = result + dictionaryToOrderedString(query) + "|" + dictionaryToOrderedString(needHashBody ? body : [:])
    
    return result.jxn_md5?.lowercased() ?? ""
  }
  
  private func dictionaryToOrderedString(_ params: Param) -> String {
    
    if params.isEmpty { return "" }
    
    let ret = params.sorted(by: { $0.0 < $1.0 }).flatMap({toStringValue($0.1)}).joined(separator: "|")
    
    return ret
  }
  
  private func toStringValue(_ aValue: Any) -> String {
    if let value = aValue as? NSNumber {
      return "\(value)"
    }
    return "\(aValue)"
  }
  
}

extension String {
  
  fileprivate var jxn_md5: String? {
    let data = (self as NSString).data(using: String.Encoding.utf8.rawValue)
    
    if data == nil {
      return nil
    }
    
    let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))
    
    if result == nil {
      return nil
    }
    
    let resultBytes = UnsafeMutablePointer<CUnsignedChar>(mutating: result!.bytes.bindMemory(to: CUnsignedChar.self,
                                                                                             capacity: result!.length))
    CC_MD5((data! as NSData).bytes, CC_LONG(data!.count), resultBytes)
    
    let a = UnsafeBufferPointer<CUnsignedChar>(start: resultBytes, count: result!.length)
    let hash = NSMutableString()
    
    for i in a {
      hash.appendFormat("%02x", i)
    }
    
    return hash as String
  }
  
  func jxn_subString(before str: String) -> String? {
    guard let range = self.range(of: str) else { return nil }
    
    return self.substring(to: range.lowerBound)
  }
  
  func jxn_subString(after str: String) -> String? {
    guard let range = self.range(of: str) else { return nil }
    
    return self.substring(from: range.upperBound)
  }
  
}
