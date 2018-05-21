//
//  JXHTTPManager.swift
//  JXNetworkKit
//
//  Created by Leo on 25/04/2017.
//  Copyright © 2017 Juxin. All rights reserved.
//

import Foundation
import EVReflection
import MBProgressHUD
import SwiftyJSON
import Alamofire

public typealias Param = [String: Any]

func +=(l: inout Param, r: Param) {
  for (k, v) in r {
    l[k] = v
  }
}

public protocol JXHTTPManagerDelegate: NSObjectProtocol {
  func jx_HTTPDidParsedAuth(auth: String)
  func jx_HTTPCacheVersion() -> String
}

public class JXHTTPManager: NSObject {
  
  
  public static weak var delegate: JXHTTPManagerDelegate?
  
  private static let sessionManager: Alamofire.SessionManager = initSessionManager()
  private static let queue = DispatchQueue(label: "com.juxin.yuanfenba", qos: .utility, attributes: .concurrent)
  
  private static func initSessionManager() -> Alamofire.SessionManager {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForResource = 7
    return Alamofire.SessionManager(configuration: configuration)
  }
  
  public static func requestResObject<T: EVObject>(config: JXRequestConfig, queue: DispatchQueue? = nil,
                                      mapTo object: T? = nil, showHud: Bool = false,
                                      callback : @escaping ([T]?, JXResponse) -> Void){
    self.requestObject(config: config, queue: queue, keyPath: "res", mapTo: object, showHud: showHud, callback: callback)
  }
  
  public static func requestObject<T: EVObject>(config: JXRequestConfig, queue: DispatchQueue? = nil,
                                   keyPath: String? = nil, mapTo object: T? = nil, showHud: Bool = false,
                                   callback : @escaping ([T]?, JXResponse) -> Void) {
    
    // 如果queue给了然后showHud还给了true，后果自负哦
    let hud = showHudIfNeeded(showHud)
    
    JXHTTPManager.queue.async {
      let request = JXHTTPManager.getRequest(with: config)
      request.responseArray(queue: queue, keyPath: keyPath, mapTo: object) { (response) in
        
        DDLogVerbose("response: \(response.value?.description ?? ""), "
          + "error: \(response.error?.localizedDescription ?? "")")
        request.jxResponse.error = response.error as NSError?
        
        (queue ?? DispatchQueue.main).async {
          if Thread.isMainThread {
            hud?.hide(animated: false)
          } else {
            DispatchQueue.main.async {
              hud?.hide(animated: false)
            }
          }
          callback(response.result.value, request.jxResponse)
        }
      }
    }
  }
  
  public static func requestResObject<T: EVObject>(config: JXRequestConfig, queue: DispatchQueue? = nil,
                                      mapTo object: T? = nil, showHud: Bool = false,
                                      callback : @escaping (T?, JXResponse) -> Void){
    requestObject(config: config, queue: queue, keyPath: "res", mapTo: object, showHud: showHud, callback: callback)
  }
  
  public static func requestObject<T: EVObject>(config: JXRequestConfig, queue: DispatchQueue? = nil,
                                   keyPath: String? = nil,mapTo object: T? = nil, showHud: Bool = false,
                                   callback : @escaping (T?, JXResponse) -> Void) {
    
    // 如果queue给了然后showHud还给了true，后果自负哦
    let hud = showHudIfNeeded(showHud)
    
    JXHTTPManager.queue.async {
      let request = JXHTTPManager.getRequest(with: config)
      request.responseObject(queue: queue, keyPath: keyPath, mapTo: object) { (response) in
        
        DDLogVerbose("response: \(response.value?.description ?? ""), "
          + "error: \(response.error?.localizedDescription ?? "")")
        request.jxResponse.error = response.error as NSError?
        
        (queue ?? DispatchQueue.main).async {
          if Thread.isMainThread {
            hud?.hide(animated: false)
          } else {
            DispatchQueue.main.async {
              hud?.hide(animated: false)
            }
          }
          callback(response.result.value, request.jxResponse)
        }
        
      }
      
    }
  }
  
  public static func requestResJSON(config: JXRequestConfig, queue: DispatchQueue? = nil, showHud: Bool = false,
                                    callback: @escaping (JSON?, JXResponse) -> Void) {
    requestJSON(config: config, queue: queue, keyPath: "res", showHud: showHud, callback: callback)
  }
  
  
  public static func requestJSON(config: JXRequestConfig, queue: DispatchQueue? = nil, keyPath: String? = nil,
                                 showHud: Bool = false, callback: @escaping (JSON?, JXResponse) -> Void) {
    
    let hud = showHudIfNeeded(showHud)
    
    JXHTTPManager.queue.async {
      let request = JXHTTPManager.getRequest(with: config)
      request.responseSwiftyJSON(queue: queue, keyPath: keyPath) { (response) in
        
        DDLogVerbose("response: \(response.value?.description ?? ""), "
          + "error: \(response.error?.localizedDescription ?? "")")
        request.jxResponse.error = response.error
        // 等注册接口重构
        if let auth = response.response?.allHeaderFields["Set-Cookie"] as? String {
          if let authString = auth.jxn_subString(after: "auth=")?.jxn_subString(before: ";"), !authString.isEmpty {
            JXHTTPManager.delegate?.jx_HTTPDidParsedAuth(auth: authString)
          }
        }
        // 等注册接口重构
        
        (queue ?? DispatchQueue.main).async {
          if Thread.isMainThread {
            hud?.hide(animated: false)
          } else {
            DispatchQueue.main.async {
              hud?.hide(animated: false)
            }
          }
          callback(response.result.value, request.jxResponse)
        }
      }
    }
  }
  
  private static func getRequest(with config: JXRequestConfig) -> DataRequest {
    
    let url = config.hashUrl
    DDLogVerbose("HTTPManager: sendRequest \(config.method.rawValue) \(url)")
    
    let request = sessionManager.request(url, method: config.method, parameters: config.parameters,
                                         encoding: config.parameterEncoding, headers: config.headers)
    request.config = config
    return request
    
  }
  
  //MARK:- HUD
  
  private static func showHudIfNeeded(_ show: Bool) -> MBProgressHUD? {
    
    guard show else {
      return nil
    }
    
    if let key = UIApplication.shared.keyWindow {
      let hud = MBProgressHUD(view: key)
      hud.removeFromSuperViewOnHide = true
      key.addSubview(hud)
      if Thread.isMainThread {
        hud.show(animated: true)
      } else {
        DispatchQueue.main.async {
          hud.show(animated: true)
        }
      }
      return hud
    }
    
    return nil
  }
  
}




