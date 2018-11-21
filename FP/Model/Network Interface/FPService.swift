//
//  FPService.swift
//  FP
//
//  Created by Bajrang on 03/09/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//

import Foundation
import UIKit

class FPService {
    
    static let sharedInstance = FPService()
    
    let errorDict = NSMutableDictionary()
    
    /**
     Server request and response method.
     
     
     - Parameter requestType: The HTTP request type string.
     - Parameter requestAPI: The request API string.
     - Parameter parameter: The parameter dictionary .
     
     - Parameter completion: The success handler closure.
     - Parameter failure: The failure handler closure.
     
     - Parameter json: The sucess json dictionary.
     - Parameter error: The error json dictionary.
     
     
     - Returns: Pass server response whether its success or not.
     
     */
    
    func getServerResponse(requestType : String, requestAPI: String, parameter: NSMutableDictionary, completion: @escaping ( _ json: NSMutableDictionary) -> () , failure: @escaping (_ error:   NSMutableDictionary) -> ())
    {

        let request = FPRequestModel.sharedInstance.makeRequest(requestType: RequestType(rawValue: requestType)!, requestAPI: requestAPI, parameter : parameter)
        request.timeoutInterval = 40.0
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
           
        
            if let httpResponse = response as? HTTPURLResponse
            {
                if httpResponse.statusCode == SUCCESS_RESPONSE
                {
                    guard error == nil else
                    {
                        DispatchQueue.main.async {
                            
                           self.errorDict[ERROR_MESSAGE] = error?.localizedDescription
                            self.errorDict[ERROR_CODE] = SERVER_ERROR
                           failure(self.errorDict)
                            
                        }
                        return
                    }
                    
                    guard let data = data else {
                        
                        DispatchQueue.main.async {
                            
                           self.errorDict[ERROR_MESSAGE] = error?.localizedDescription
                            self.errorDict[ERROR_CODE] = SERVER_ERROR
                            failure(self.errorDict)
                            
                        }
                        return
                    }
                    
                    do {
                        
                        if data.count == 0 // Check only status code
                        {
                            DispatchQueue.main.async {
                                
                                let responseDict = NSMutableDictionary()
                          
                                completion(responseDict)
                                
                            }
                            
                        }
                            
                        else if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
                        {
                            DispatchQueue.main.async {
                                
                                var responseDict: NSMutableDictionary = NSMutableDictionary(dictionary: json)
                                
                                responseDict = responseDict.mutableCopy() as! NSMutableDictionary

                                
                                completion(responseDict)
                            }
                        }
                    } catch let error {
                        
                        DispatchQueue.main.async {

                            self.errorDict[ERROR_MESSAGE] = error.localizedDescription
                            self.errorDict[ERROR_CODE] = SERVER_ERROR
                            failure(self.errorDict)
                            
                        }
                    }
                    
                }
                else if (httpResponse.statusCode == SERVER_ERROR){
                    
                    DispatchQueue.main.async {
                   self.errorDict[ERROR_CODE] = SERVER_ERROR
                   self.errorDict[ERROR_MESSAGE] = error?.localizedDescription
                    
                    failure(self.errorDict)
                    }
                }
                else
                {
                    DispatchQueue.main.async {
                        

                    self.errorDict[ERROR_CODE] = SERVER_ERROR
                    self.errorDict[ERROR_MESSAGE] = error?.localizedDescription
                        failure(self.errorDict)
                        
                    }
                }
                
            }
            else
            {
                
                DispatchQueue.main.async {
                    

                  self.errorDict[ERROR_CODE] = INTERNET_OFF_ERROR
                  self.errorDict[ERROR_MESSAGE] = error?.localizedDescription
                    failure(self.errorDict)
                    
                }
            }
            
            
            
        })
        
        dataTask.resume()
        
    }
}
