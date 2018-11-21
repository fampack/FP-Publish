//
//  FPHandler.swift
//  FP
//
//  Created by Bajrang on 03/09/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//

import Foundation
import UIKit


class FPHandler {
    
    static let sharedInstance = FPHandler()
    
    /**
     Server request and response handler method.
     
     
     - Parameter requestType: The HTTP request type string.
     - Parameter requestAPI: The request API string.
     - Parameter parameter: The parameter dictionary .
     
     - Parameter success: The success handler closure.
     - Parameter failure: The failure handler closure.
     
     - Parameter json: The sucess json dictionary.
     - Parameter error: The error json dictionary.
     
     
     - Returns: Get Server response whether its success or not and send back to the model.
     
     */
    
    
    public func requestServer(requestType : String, requestAPI: String, parameter: NSMutableDictionary, success: @escaping ( _ json: NSMutableDictionary) -> () , failure: @escaping (_ error: NSDictionary) -> () )
    {
        
       
        
        FPService.sharedInstance.getServerResponse(requestType: requestType, requestAPI: requestAPI, parameter: parameter, completion: { json in

            
            success(json )
            
        }, failure: {  error in
            
         
            
            failure(error )
            
            
        })
        
        
    }
    
}
