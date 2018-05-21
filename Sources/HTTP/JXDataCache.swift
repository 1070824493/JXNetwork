//
//  JXDataCache.swift
//  JXNetworkKit
//
//  Created by LeoWei on 2017/8/30.
//  Copyright © 2017年 Juxin. All rights reserved.
//

import Foundation
import YYCache

class JXDataCache {
  
  static let cache = YYCache(name: "jx_network")
  
  static var versionString: String {
    return JXHTTPManager.delegate?.jx_HTTPCacheVersion() ?? "0"
  }
  
  static func loadDataIfCached(with config: JXRequestConfig) -> Data? {
    
    guard config.shouldCache else { return nil }
    
    if let dataFromCache = cache?.object(forKey: config.requestURL + versionString) as? Data {
      return dataFromCache
    }
    
    if case .file(let fileName) = config.cacheType {
      return NSData(contentsOfFile: fileName) as Data?
    }
    
    return nil
  }
  
  static func cacheDataIfNeeded(with config:JXRequestConfig, data: Data) {
    
    guard config.shouldCache else { return }
    
    cache?.setObject(data as NSCoding, forKey: config.requestURL + versionString)
  }
  
}
