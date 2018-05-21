//
//  JXDataRequest.swift
//  JXNetworkKit
//
//  Created by LeoWei on 2017/8/23.
//  Copyright © 2017年 Juxin. All rights reserved.
//

import Foundation
import Alamofire
import EVReflection
import SwiftyJSON
import JXEncrypt
import YYCache

extension DataRequest {
  
  static var configKey: Void?
  static var jxResponseKey: Void?
  
  var config: JXRequestConfig! {
    get {
      return objc_getAssociatedObject(self, &DataRequest.configKey) as? JXRequestConfig
    }
    set {
      objc_setAssociatedObject(self, &DataRequest.configKey, newValue , .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
  
  var jxResponse: JXResponse! {
    get {
      return objc_getAssociatedObject(self, &DataRequest.jxResponseKey) as? JXResponse ?? JXResponse()
    }
    set {
      objc_setAssociatedObject(self, &DataRequest.jxResponseKey, newValue , .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
  }
  
}

// https://github.com/evermeer/EVReflection/tree/master/Source/Alamofire

public extension DataRequest {
  
  enum ErrorCode: Int {
    case noData = 1
  }
  
  func newError(_ code: ErrorCode, failureReason: String) -> NSError {
    let errorDomain = "com.alamofirejsontoobjects.error"
    
    let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
    let returnError = NSError(domain: errorDomain, code: code.rawValue, userInfo: userInfo)
    
    return returnError
  }
  
  @discardableResult
  public func responseObject<T: EVObject>(queue: DispatchQueue? = nil, keyPath: String? = nil, mapTo object: T? = nil,
                             completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
    
    let serializer = self.reflectionSerializer(keyPath, mapTo: object)
    return response(queue: queue, responseSerializer: serializer, completionHandler: completionHandler)
  }
  
  func reflectionSerializer<T: EVObject>(_ keyPath: String?, mapTo object: T? = nil) -> DataResponseSerializer<T> {
    return DataResponseSerializer<T> { request, response, data, error in

      let responseSerializer = self.jxJSONSerializer(keyPath)
      let result = responseSerializer.serializeResponse(request, response, data, error)
      
      guard result.error == nil else { return .failure(result.error!) }
      
      var JSONToMap: NSDictionary?
      if let keyPath = keyPath , keyPath.isEmpty == false {
        JSONToMap = (result.value as AnyObject?)?.value(forKeyPath: keyPath) as? NSDictionary
      } else if let dict = result.value as? NSDictionary {
        JSONToMap = dict
      } else if let array = result.value as? NSArray {
        JSONToMap = NSDictionary.init(dictionary: ["": array])
      }
      
      if JSONToMap == nil {
        JSONToMap = NSDictionary()
      }
      
      if object == nil {
        let instance: T = T()
        let parsedObject: T = ((instance.getSpecificType(JSONToMap!) as? T) ?? instance)
        let _ = EVReflection.setPropertiesfromDictionary(JSONToMap!, anyObject: parsedObject)
        return .success(parsedObject)
      } else {
        let _ = EVReflection.setPropertiesfromDictionary(JSONToMap!, anyObject: object!)
        return .success(object!)
      }
    }
  }
  
  /**
   Adds a handler to be called once the request has finished.
   
   - parameter queue: The queue on which the completion handler is dispatched.
   - parameter keyPath: The key path where EVReflection mapping should be performed
   - parameter object:  ⚠️(parameter is not used, only here to make the generics work)⚠️
   - parameter completionHandler: A closure to be executed once the request has finished and
     the data has been mapped by EVReflection.
   
   - returns: The request.
   */
  
  @discardableResult
  public func responseArray<T: EVObject>(queue: DispatchQueue? = nil, keyPath: String? = nil, mapTo object: T? = nil,
                            completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
    let serializer = self.reflectionArraySerializer(keyPath, mapTo: object)
    return response(queue: queue, responseSerializer: serializer, completionHandler: completionHandler)
  }
  
  
  func reflectionArraySerializer<T: EVObject>(_ keyPath: String?, mapTo object: T? = nil)
    -> DataResponseSerializer<[T]> {
    return DataResponseSerializer { request, response, data, error in

      let responseSerializer = self.jxJSONSerializer(keyPath)
      let result = responseSerializer.serializeResponse(request, response, data, error)
      
      guard result.error == nil else { return .failure(result.error!) }
      
      var JSONToMap: NSArray?
      if let keyPath = keyPath, keyPath.isEmpty == false {
        JSONToMap = (result.value as AnyObject?)?.value(forKeyPath: keyPath) as? NSArray
      } else if let array = result.value as? NSArray {
        JSONToMap = array
      } else if let dict = result.value as? NSDictionary {
        JSONToMap = [dict]
      }
      
      if JSONToMap == nil {
        let failureReason = "Data could not be serialized. Empty array."
        let error = self.newError(.noData, failureReason: failureReason)
        return .failure(error)
      }
      
      let parsedObject:[T] = (JSONToMap!).map {
        let instance: T = T()
        let _ = EVReflection.setPropertiesfromDictionary($0 as? NSDictionary ?? NSDictionary(), anyObject: instance)
        return instance
        } as [T]
      
      return .success(parsedObject)
    }
  }

}

public extension DataRequest {
  
  @discardableResult
  public func responseSwiftyJSON(queue: DispatchQueue? = nil, keyPath: String? = nil,
                                 completionHandler: @escaping (DataResponse<JSON>) -> Void) -> Self {
    let serializer = self.swiftyJSONSerializer(keyPath)
    return response(queue: queue, responseSerializer: serializer, completionHandler: completionHandler)
  }
  
  
  func swiftyJSONSerializer(_ keyPath: String?) -> DataResponseSerializer<JSON> {
    return DataResponseSerializer { request, response, data, error in
      
      let responseSerializer = self.jxJSONSerializer(keyPath)
      let result = responseSerializer.serializeResponse(request, response, data, error)
      
      guard result.error == nil else { return .failure(result.error!) }
      
      var JSONToMap: NSDictionary?
      if let keyPath = keyPath , keyPath.isEmpty == false {
        JSONToMap = (result.value as AnyObject?)?.value(forKeyPath: keyPath) as? NSDictionary
      } else if let dict = result.value as? NSDictionary {
        JSONToMap = dict
      } else if let array = result.value as? NSArray {
        JSONToMap = NSDictionary.init(dictionary: ["": array])
      }
      
      if JSONToMap == nil {
        let failureReason = "Data could not be serialized. Empty dictionary."
        let error = self.newError(.noData, failureReason: failureReason)
        return .failure(error)
      }
      
      return .success(JSON(JSONToMap!))
      
    }
  }
}

private let emptyDataStatusCodes: Set<Int> = [204, 205]

public extension DataRequest {
  
  func jxJSONSerializer(_ keyPath: String?) -> DataResponseSerializer<Any> {
    return DataResponseSerializer { request, response, data, error in
      var dataToSerialize = data
      
      if data == nil || data!.isEmpty || !(200...300).contains(response?.statusCode ?? 0) {
        dataToSerialize = JXDataCache.loadDataIfCached(with: self.config)
      } else {
        JXDataCache.cacheDataIfNeeded(with: self.config, data: data!)
      }
      
      if error != nil && (dataToSerialize == nil || dataToSerialize!.isEmpty) {
        return .failure(error!)
      }
      
      if self.config.needDecryptResponse {
        dataToSerialize = Encrypt.decryptData(dataToSerialize)
      }
      
      guard dataToSerialize != nil else {
        let failureReason = "Data could not be serialized. Input data was nil."
        let error = self.newError(.noData, failureReason: failureReason)
        return .failure(error)
      }
      
      if let response = response, emptyDataStatusCodes.contains(response.statusCode) { return .success(NSNull()) }
      
      guard let validData = dataToSerialize, validData.count > 0 else {
        return .failure(AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength))
      }
      
      do {
        let json = try JSONSerialization.jsonObject(with: validData, options: .allowFragments)
        self.jxResponse = JXResponse.parse(json)
        return .success(json)
      } catch {
        return .failure(AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error)))
      }
      
    }
  }
}
