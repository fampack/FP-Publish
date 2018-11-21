//
//  FPRequestModel.swift
//  FP
//
//  Created by Bajrang on 03/09/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//

import Foundation
import UIKit

class FPRequestModel {
    
    
    
    static let sharedInstance = FPRequestModel()
    
    
    
    //MARK: Make HTTP request
    
    /**
     Make HTTP request method..
     
     
     - Parameter requestType: The HTTP request type string.
     - Parameter requestAPI: The request API string.
     - Parameter parameter: The parameter dictionary .
     
     - Returns: It will return NSMutableURLRequest.
     
     */
    
    
    
    func makeRequest(requestType: RequestType, requestAPI: String, parameter : NSMutableDictionary) -> NSMutableURLRequest
    {
        
        switch requestType {
        case .GET:
            return  getRequest(requestAPI: requestAPI, parameter : parameter )
            
        case .POST:
            return postRequest(requestAPI: requestAPI, parameter : parameter)

        default:
            return NSMutableURLRequest()
            
        }
    }
    
    //MARK GET Request
    
    /**
     Make HTTP GET request method.
     
     - Parameter requestAPI: The request API string.
     - Parameter parameter: The parameter dictionary .
     
     - Returns: It will return NSMutableURLRequest.
     
     */
    
    func getRequest(requestAPI: String ,parameter : NSMutableDictionary) ->
        NSMutableURLRequest{
            
            var request = NSMutableURLRequest()
            
            let parameter = makeParam(requestAPI: requestAPI,parameter : parameter)
            let paramUrl = String(format:"%@%@",BASE_URL,parameter)
            
            if let encoded = paramUrl.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
                let url = URL(string: encoded)
            {
                request = NSMutableURLRequest(url: url)
            }
            
            
            request.httpMethod = RequestType.GET.rawValue
            return request
    }
    
    
    //MARK: POST Request
    
    /**
     Make HTTP POST request method.
     
     - Parameter requestAPI: The request API string.
     - Parameter parameter: The parameter dictionary .
     
     - Returns: It will return NSMutableURLRequest.
     
     */
    
    func postRequest(requestAPI: String , parameter : NSMutableDictionary) -> NSMutableURLRequest{
        
        let request = NSMutableURLRequest(url: NSURL(string: BASE_URL + requestAPI )! as URL)
        
//        var param = String()
//
        //let param =  makeJSONParam(parameter : parameter)
        request.httpBody = makeJSONParam(parameter : parameter) //param.data(using: .utf8)//
        request.httpMethod = RequestType.POST.rawValue
        //request.addValue("multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW", forHTTPHeaderField: "content-type")
        //request.addValue("application/json", forHTTPHeaderField: "Accept")
//        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        return request
        
    }
    
    
    
    //MARK: Make JSON Parameter
    
    /**
     Make JSON data.
     
     - Parameter parameter: The parameter dictionary for making valid json data .
     
     - Returns: It will return JSON data.
     
     */
    
    func makeJSONParam(parameter : NSMutableDictionary) -> Data {
        
        let jsonData = try? JSONSerialization.data(withJSONObject: parameter, options: .prettyPrinted)

        return jsonData! as Data
        
//        let param = (parameter.flatMap({ (key, value) -> String in
//            return "\(key)=\(value)"
//        }) as Array).joined(separator: "&")
//
//
//        return param
        

        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    //MARK: Make String Parameter
    
    /**
     Make JSON string.
     
     - Parameter requestAPI: The request API string.
     - Parameter parameter: The parameter dictionary for making json string .
     
     - Returns: It will return JSON string.
     
     */
    
    func makeParam(requestAPI: String , parameter : NSMutableDictionary) -> String {
        
        let param = (parameter.compactMap({ (key, value) -> String in
            return "\(key)=\(value)"
        }) as Array).joined(separator: "&")
        
        return requestAPI + param
        
    }
    
    
    
}
