//
//  JXHTTP+Cookie.swift
//  JXNetworkKit
//
//  Created by LeoWei on 2017/8/29.
//  Copyright © 2017年 Juxin. All rights reserved.
//

import Foundation

public extension HTTPCookieStorage {
  
  public static func jx_removeCookies() {
    
    shared.cookies?.forEach{ (item) in
      shared.deleteCookie(item)
    }
  }
  
  public static func jx_setCookie(domain: String, name: String, value: String) {
    
    DDLogVerbose("setCookie: domain=\(domain), \(name)=\(value)")
    
    var properties = [HTTPCookiePropertyKey : Any]()
    properties[HTTPCookiePropertyKey.name] = name
    properties[HTTPCookiePropertyKey.value] = value
    properties[HTTPCookiePropertyKey.domain] = domain
    properties[HTTPCookiePropertyKey.originURL] = ""
    properties[HTTPCookiePropertyKey.path] = "/"
    properties[HTTPCookiePropertyKey.version] = ""
    
    if let cookie = HTTPCookie(properties: properties) {
      shared.setCookie(cookie)
    }
  }
  
}
