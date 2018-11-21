//
//  FPDataModel.swift
//  FP
//
//  Created by Bajrang on 15/08/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//

import Foundation

class FPDataModel {
    
    static var userId: String? {
        get {
            return USER_DEFAULT.string(forKey: USER_ID)
        }
        set {
            USER_DEFAULT.setValue(newValue, forKey: USER_ID)
        }
    }
    
    static var userInfo: [String : Any]? {
        get {
            return USER_DEFAULT.value(forKey: USER_INFO) as? [String : Any]
        }
        set {
            USER_DEFAULT.setValue(newValue, forKey: USER_INFO)
        }
    }
    
    static var fcmToken: String? {
        get {
            return USER_DEFAULT.string(forKey: FCM_TOKEN)
        }
        set {
            USER_DEFAULT.setValue(newValue, forKey: FCM_TOKEN)
        }
    }
}


