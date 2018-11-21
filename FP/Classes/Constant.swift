//
//  Constant.swift
//  FP
//
//  Created by Bajrang on 13/08/18.
//  Copyright © 2017 Bajrang. All rights reserved.
///

import Foundation
import UIKit

let screenHeight: CGFloat = UIScreen.main.bounds.size.height
let screenWidth: CGFloat = UIScreen.main.bounds.size.width
let USER_DEFAULT = UserDefaults.standard


let appDelegate = UIApplication.shared.delegate as! AppDelegate

let APP_DEEP_MAROON_COLOR = UIColor(red: 240.0/255.0, green: 116.0/255.0, blue: 66.0/255.0, alpha: 1.0)
let APP_LIGHT_GRAY_COLOR = UIColor(red: 161.0/255.0, green: 161.0/255.0, blue: 161.0/255.0, alpha: 1.0)
let APP_LIGHT_TEXT_COLOR = UIColor(red: 163.0/255.0, green: 163.0/255.0, blue: 163.0/255.0, alpha: 1.0)


let dataTaskModel = FPDataTaskModel.sharedInstance
let BASE_URL = "http://techzuke.com/company/"

let FIREBASE_LEGACY_SERVER_KEY = "AIzaSyDmxya20OYE9X9VlNc7s_QY0rvIPBgyCLI" //"AAAAUN79qlE:APA91bEaPL0nQ6Arivkse95G-vGR1Nfo3GTiUkhGyDVtAqRb8BQ3VIlnxPonnUd_2r_wI78VgTD3J7Nzkjf3RJc03Rz01PF10gRrlXDDSU1IVftjRiEtGZVpe4-7ScNspcS8jDGj0rDGya1COK-rnyEC1balqkDnIg"//


// User constant

let USER_INFO = "userInfo"
let FCM_TOKEN = "fcmToken"
let USER_ID = "userId"
let CHAT_COUNT = "chatCount"

// Server response constant

let MESSAGE = "msg";
let ERROR_MESSAGE = "error"


// Error messages constant
let ERROR_CODE = "error_code"


// Server response code

let SUCCESS_RESPONSE = 200
let ERROR = 400
let SERVER_ERROR = 500
let INTERNET_OFF_ERROR = 600


//MARK: HTTP Request enum

enum RequestType : String{
    case GET = "GET"
    case POST = "POST"
}



//MARK: HTTP Request API enum

enum RequestAPI : String
{
    case PUSH_NOTIFICATION = "push_notification/index2.php?"
}
