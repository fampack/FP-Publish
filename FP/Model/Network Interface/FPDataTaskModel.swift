//
//  FPDataTaskModel.swift
//  FP
//
//  Created by Bajrang on 03/09/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//

import Foundation

@objc protocol FPDataTaskModelDelegate: class {
    
    @objc optional func didRecieveResponseOfPushNotification(json: NSMutableDictionary)
    @objc optional func didRecieveErrorOfPushNotification(error: NSMutableDictionary)
}



class FPDataTaskModel {
    
    static let sharedInstance = FPDataTaskModel()

    
    weak var delegate: FPDataTaskModelDelegate?



    
    public func sendPUSHNotification(parameter: NSMutableDictionary) {

        FPHandler.sharedInstance.requestServer(requestType: RequestType.POST.rawValue , requestAPI: RequestAPI.PUSH_NOTIFICATION.rawValue , parameter: parameter, success: { json  in
            FPSingleton.sharedInstance.hideActivityIndicator()
            if(self.delegate?.didRecieveResponseOfPushNotification != nil){
                
                self.delegate?.didRecieveResponseOfPushNotification!(json: json)
            }
            
        }, failure: {  error in
            FPSingleton.sharedInstance.hideActivityIndicator()
            if(self.delegate?.didRecieveErrorOfPushNotification != nil){
                self.delegate?.didRecieveErrorOfPushNotification!(error: error as! NSMutableDictionary)
            }
        })
        
    }
    
}
