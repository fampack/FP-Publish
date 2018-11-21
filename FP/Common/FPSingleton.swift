//
//  FPSingleton.swift
//  FP
//
//  Created by Bajrang on 21/09/18.
//  Copyright © 2017 Bajrang. All rights reserved.
//

import UIKit
import UserNotifications
import Photos

@objc protocol FPSingletonDelegate: class {
    
    @objc optional func userDidAuthorisedPhotoGallaryPermission()
    @objc optional func userDidDeniedPhotoGallaryPermission()
    
    @objc optional func userDidAuthorisedCameraPermission()
    @objc optional func userDidDeniedCameraPermission()
    
}


//import SDWebImage

//import SwiftKeychainWrapper

class FPSingleton: NSObject {
    
    var container: UIView = UIView()
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    weak var delegate: FPSingletonDelegate?
    
    var currentViewController: UIViewController?
    
    var fourDigitNumber: String {
        var result = ""
        repeat {
            // Create a string with a random number 0...9999
            result = String(format:"%04d", arc4random_uniform(10000) )
        } while Set<Character>(result).count < 4
        return result
    }
    
    //var obj_noInternetConnectionView : NoInternetConnectionView?
    
  // fileprivate let keychainWrapper = KeychainWrapper(serviceName: KeychainWrapper.standard.serviceName, accessGroup: "group.deviceGroup")
    
   fileprivate let transition = CATransition()
    
    //MARK: Shared Instance
    
    static let sharedInstance : FPSingleton =
    {
        let instance = FPSingleton(array: [])
        return instance
    }()
    
    //MARK: Local Variable
    
    var emptyStringArray : [String]
    
    //MARK: Init
    
    init( array : [String]) {
        emptyStringArray = array
    }
    
    
    let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil) as UIStoryboard?
    
    var label: UILabel?
    
    fileprivate let toastLabel = UILabel()
    
    
    
    
    //MARK: Get device id
    
//    func getDeviceID() -> String {
//        
//        
//      var deviceId = keychainWrapper.string(forKey: DEVICE_ID)
//        
//        
//        if(deviceId.characters.count == 0){
//  
//            deviceId = createDeviceID()
//            if(keychainWrapper.set(deviceId, forKey: DEVICE_ID)){
//                
//            }
//            else{
//                
//            }
//        }
//        
//    return deviceId
//        
//    }
    
   private func createDeviceID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)
        
        let swiftString: String = cfStr as String
        return swiftString
    }
    
    func sendPUSHNotification(to devices: [String], title: String, subtitle: String, body: String, data: [String : Any]?)
    {
        let paramDict = NSMutableDictionary()
        paramDict["tokens"] = devices
        paramDict["title"] = title
        paramDict["subtitle"] = subtitle
        paramDict["body"] = body
        if data != nil {
            paramDict["data"] = data
        }
        paramDict["access_key"] = FIREBASE_LEGACY_SERVER_KEY
        
        dataTaskModel.delegate = self
        
        dataTaskModel.sendPUSHNotification(parameter: paramDict)
    }
    
    
    func showAlertWithMultipleButtons(title: String?, message: String,inViewController: UIViewController, buttonOneCaption: String, buttonTwoCaption: String, multipleButtons: Bool, completion: (( _ buttonClick: Bool) -> ())?){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if multipleButtons
        {
            let cancelButton = UIAlertAction(title: buttonTwoCaption, style: UIAlertAction.Style.cancel)
            { _ in
                completion?(false)
                
            }
            
            let okButton = UIAlertAction(title: buttonOneCaption, style: .default, handler:{ (alert: UIAlertAction!) in
                
                completion?(true)
                
            })
            
            alert.addAction(cancelButton)
            alert.addAction(okButton)
        }
        else
        {
            let okButton = UIAlertAction(title: buttonOneCaption, style: .default, handler:{ (alert: UIAlertAction!) in
                
                completion?(true)
                
            })
            
            alert.addAction(okButton)
        }
        

        
        
        inViewController.present(alert, animated: true, completion: nil)
        
    }
    
    func showAlertController(message: String,inViewController: UIViewController, completion: @escaping ( _ SelectedButton: NSString) -> ())
    {
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        
        let photoLibrary = UIAlertAction(title: "Photo Library", style: UIAlertAction.Style.default)
        { _ in
            completion("Photo Library")
            
        }
        
        let camera = UIAlertAction(title: "Capture Photo", style: .default, handler:{ (alert: UIAlertAction!) in
            
            completion("Capture Photo")
            
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel)
        { _ in
            completion("Cancel")
            
        }
        
        alert.addAction(photoLibrary)
        alert.addAction(camera)
        alert.addAction(cancelButton)
        
        inViewController.present(alert, animated: true, completion: nil)
        
    }
    
    func showAlert(style inStyle:UIAlertController.Style, title titleText: String?, message messageText: String?, firstButtonText firstButtonTitle: String?, secondButtonText secondButtonTitle: String?, parentVC inViewController: UIViewController, completion: (( _ selectedButton: String) -> ())?)
    {
        let alert = UIAlertController(title: titleText, message: messageText, preferredStyle: inStyle)
        
        let firstAlertButton = UIAlertAction(title: firstButtonTitle, style: UIAlertAction.Style.default)
        { _ in
            completion?(firstButtonTitle ?? "")
            
        }
        alert.addAction(firstAlertButton)
        if let secondButton = secondButtonTitle {
            let secondAlertButton = UIAlertAction(title: secondButton, style: .default, handler:{ (alert: UIAlertAction!) in
                
                completion?(secondButton)
                
            })
            alert.addAction(secondAlertButton)
        }
        
        
        let cancelButton = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel)
        { _ in
            completion?("Cancel")
            
        }
        
        alert.addAction(cancelButton)
        
        inViewController.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Show Toast on current view controller
    
    /**
     Show toast in a view.
     
     - Parameter message:  It's a string to be used for message.
     - Parameter inView: It's an UIView where toast to be shown.
     
     */
    
    func showToast(message : String) {
        
        toastLabel.frame = CGRect(x: 0, y: screenHeight-49, width: screenWidth, height: 49)
        
        toastLabel.backgroundColor = APP_DEEP_MAROON_COLOR //UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = UIColor.white
        toastLabel.numberOfLines = 2
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont.systemFont(ofSize: 15.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        
        toastLabel.layer.zPosition = 1
        
        toastLabel.clipsToBounds  =  true
        
        appDelegate.window!.addSubview(toastLabel)
        UIView.animate(withDuration: 1.0, delay: 3.0, options: .curveEaseOut, animations: {
            
            self.toastLabel.alpha = 0.0
            
        }, completion: {(isCompleted) in
            
            self.toastLabel.removeFromSuperview()
            
        })
        
    }

    
    
    
    
    //MARK: Show time ago
    
    
    func getTimeAgo(timeStamp: String) -> String {
    
        var timeStamp = timeStamp
        timeStamp = timeStamp.replacingOccurrences(of: "-", with: "")
        var time: String = ""
        let postTime:Int = Int(timeStamp)!
        var timeBefore = Int(postTime / 3600)
       
        if(timeBefore <= 0) {
            timeBefore = postTime / 60
            
            if(timeBefore <= 0){
                time = String(format: "%d sec", timeBefore)
            }
            else{
                if(timeBefore == 1){
                    time = String(format: "%d min", timeBefore)
                }
                else{
                   time = String(format: "%d mins", timeBefore)
                }
                
            }
            
        }
        else if(timeBefore<24){
            
            if(timeBefore==1){
               time = String(format: "%d hr", timeBefore)
                
            }
            else{
                time = String(format: "%d hrs", timeBefore)
                
            }
            
        }
        else{
            if(timeBefore % 24 == 0 && timeBefore / 24 == 1){
                time="Yesterday";
            }
            else if(timeBefore>24 && timeBefore<48){
                time="1 day ago";
            }
            else{
               
                if(timeBefore / 24 >= 30){
                    
                    if(timeBefore/24==30)
                    {
                        time="1 month ago";
                    }
                    else{
                        
                        if(((timeBefore / 24) / 30) < 12){
                            
                              time = String(format: "%d month ago", (timeBefore / 24) / 30)

                        }
                        else{
                            
                            if(((timeBefore / 24) / 30) == 12)
                            {
                                time="1 year ago";
                            }
                            else
                            {
                                if(((timeBefore / 24) / 30) / 12 == 1)
                                {
                                    time="1 year ago";
                                }
                                else{
                                    
                                     time = String(format: "%d years ago", (((timeBefore / 24) / 30) / 12))
                                }
                               
                            }
                        }
                    }
                }
                else
                {
                    time = String(format: "%d days ago", timeBefore / 24)
                }
            }
        }

        return time;
    
    }
    
    
    func addCornerRadiusWithBorder(button : Any, cornerRadius : CGFloat,borderWidth : CGFloat, borderColor : UIColor?) -> Void
    {
        
        let receivedView : UIView = button as! UIView
        receivedView.layer.cornerRadius = cornerRadius
        receivedView.clipsToBounds = true
        
        if borderColor != nil
        {
            receivedView.layer.borderWidth = borderWidth
            receivedView.layer.borderColor = borderColor?.cgColor
        }
    }
    
    // MARK: - Draw Bottom Line To UIView
    
    func drawBottomLine(optionView:UIView)
    {
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0.0, y: optionView.frame.height-0.5, width: optionView.frame.width, height: 0.5)
        bottomBorder.backgroundColor = UIColor.lightGray.cgColor
        optionView.layer.addSublayer(bottomBorder)
        
    }
    
    func validateEmail(email: NSString) -> Bool
    {
        let regex1 = "\\A[a-z0-9]+([-._][a-z0-9]+)*@([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,3}\\z"
        let regex2 = "^(?=.{1,64}@.{4,64}$)(?=.{6,100}$).*"
        
        let predicate1 = NSPredicate(format: "SELF MATCHES %@",regex1)
        let predicate2 = NSPredicate(format: "SELF MATCHES %@",regex2)
        
        return (predicate1.evaluate(with: email) && predicate2.evaluate(with: email))
    }
    
    //MARK: Set Card view corner radious--->
    func setCardView(view : UIView, cornerRadius: Float)
    {
        
        DispatchQueue.main.async  {
            view.layer.masksToBounds = false
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOpacity = 0.3
            view.layer.shadowOffset = CGSize(width: -1, height: 1)
            view.layer.shadowRadius = 1.5
            view.layer.cornerRadius = CGFloat(cornerRadius);
        }
    }

    
    func showActivityIndicator()
    {
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        //let container: UIView = UIView()
        container.frame = UIScreen.main.bounds
        container.backgroundColor = UIColor.clear //UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.3)
        
        let loadingView: UIView = UIView()
        loadingView.frame = CGRect(x: (screenWidth - 80)/2.0, y: (screenHeight - 80)/2.0, width: 80, height: 80)
        loadingView.backgroundColor = UIColor(red:0.27, green:0.27, blue:0.27, alpha:0.8)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        //let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.style =
            UIActivityIndicatorView.Style.whiteLarge
        activityIndicator.center = CGPoint(x: loadingView.frame.size.width / 2, y:
            loadingView.frame.size.height / 2)
        loadingView.addSubview(activityIndicator)
        container.addSubview(loadingView)
        UIApplication.shared.keyWindow?.addSubview(container)
        activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator()
    {
        if(UIApplication.shared.isIgnoringInteractionEvents)
        {
              UIApplication.shared.endIgnoringInteractionEvents()
        }
      
        activityIndicator.stopAnimating()
        container.removeFromSuperview()
    }
    
    func getDays(startDay: String, endDay: String) -> String
    {
        var diff = 0
        
        if let startDay = startDay.date()
        {
            if let endDay = endDay.date()
            {
                diff = endDay.interval(ofComponent: .day, fromDate: startDay)
            }
        }

        return String(format: "%d",(diff+1))
    }

    func getCurrentTimeStamp(withRandom random: Bool = false) -> u_long
    {
        let timeInSeconds = Date().timeIntervalSince1970
        var milliseconds = timeInSeconds*1000
        
        if random {
            milliseconds = Double(String(format: "%lu", u_long(milliseconds)).appending(fourDigitNumber))!
        }
        
        return u_long(milliseconds)
    }
    
    public func getUniqueId() -> String {
        if let userId = FPDataModel.userId {
            let timeStampWithRandom = getCurrentTimeStamp(withRandom: true)
            return String(format: "%lu_%@",timeStampWithRandom, userId)
        }
        return ""
    }
    
    func getConversationID(otherUserID: String, meID: String) -> String {
      
        let otherUserIdInt:Int = Int(otherUserID)!
        let meIdInt:Int = Int(meID)!
        
        if( otherUserIdInt > meIdInt) {
            
            return "\(meID)_\(otherUserID)"
        }
        return "\(otherUserID)_\(meID)"
        
        
    }
    
    func getChatID(length: Int) -> String
    {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func dateDiff(origDate:  Date) -> String
    {
        let df = DateFormatter()
        df.formatterBehavior = .behavior10_4
        df.dateFormat = "dd/MM/yyyy"
        
        let todayDate = Date()
        var ti = origDate.timeIntervalSince(todayDate)
        ti = ti * -1
        
        if ti < 1
        {
            return getChatTime(chatDate: origDate, isTimeWithDate: false)
        }
        else if ti < 60
        {
            let diff = round(ti as Double)
            if diff == 1
            {
                return getChatTime(chatDate: origDate, isTimeWithDate: false)
            }
        }
        else if (ti < 3600)
        {
            return getChatTime(chatDate: origDate, isTimeWithDate: false)
        }
        else if (ti < 86400)
        {
            let diff = round(ti / 3600.0)
            
            if diff > 1
            {
                return getChatTime(chatDate: origDate, isTimeWithDate: false)
            }
            return getChatTime(chatDate: origDate, isTimeWithDate: false)
        }
        else if (ti < 2629743)
        {
            let diff = round(ti / 60 / 60 / 24)
            if (diff <= 6 )
            {
                if (diff > 1)
                {
                    return String(format: "%d Days", diff)
                }
                return String(format: "%d Day", diff)
            }
            else
            {
                return getChatTime(chatDate: origDate, isTimeWithDate: true)
            }
        }
        else{
            return getChatTime(chatDate: origDate, isTimeWithDate: true)
        }
        return getChatTime(chatDate: origDate, isTimeWithDate: false)
        
    }
    
    func getChatTime(chatDate: Date, isTimeWithDate: Bool) -> String
    {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        
        if isTimeWithDate
        {
            dateFormatter.dateFormat = "MMM d,hh:mm a"
        }
        else
        {
            dateFormatter.dateFormat = "hh:mm a"
        }
        
        return dateFormatter.string(from: chatDate)
    }
    
    func getWeekDayFromTimeStamp( timeStamp:Double) -> String  {
       
        let todayDate = Date(timeIntervalSince1970: timeStamp)
       
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let todayDayName = dateFormatter.string(from: todayDate)
              
        return todayDayName
    }

    func getDateFromTimeStamp( timeStamp:Double) -> String  {
        
        let todayDate = Date(timeIntervalSince1970: timeStamp)
        //dd MMM yyyy
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MM/dd/YYYY"
        let todayDayName = dateFormatter.string(from: todayDate)
        
        return todayDayName
    }

    
    
    public func hideTint(from textField: UITextField)
    {
        textField.tintColor = UIColor.clear
    }

    func setBadgeInTabBar(badgeCount: String)
    {
        DispatchQueue.main.async {
            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let window =  appDelegate.window
            if let tabBarController = (window?.rootViewController as? UITabBarController)
            {
                if Int(badgeCount)! <= 0
                {
                    tabBarController.tabBar.items?[1].badgeValue = nil
                }
                else
                {
                    tabBarController.tabBar.items?[1].badgeValue = badgeCount
                }
            }
        }
        
    }
    
    func checkPhotoLibraryPermission()
    {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            //handle authorized status
            if(self.delegate?.userDidAuthorisedPhotoGallaryPermission != nil){
                self.delegate?.userDidAuthorisedPhotoGallaryPermission!()
            }
            break
        case .denied, .restricted :
            //handle denied status
            if(self.delegate?.userDidDeniedPhotoGallaryPermission != nil){
                self.delegate?.userDidDeniedPhotoGallaryPermission!()
            }
            break
        case .notDetermined:
            // ask for permissions
            PHPhotoLibrary.requestAuthorization() { status in
                switch status {
                case .authorized:
                    // as above
                    if(self.delegate?.userDidAuthorisedPhotoGallaryPermission != nil){
                        DispatchQueue.main.async {
                            self.delegate?.userDidAuthorisedPhotoGallaryPermission!()
                        }
                    }
                    break
                case .denied, .restricted:
                    // as above
                    
                    break
                case .notDetermined:
                    // won't happen but still
                    
                    break
                }
            }
            break
        }
    }
    
    func checkCameraPermission()
    {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .authorized:
            if(self.delegate?.userDidAuthorisedCameraPermission != nil){
                self.delegate?.userDidAuthorisedCameraPermission!()
            }
            break
        case .denied:
            if(self.delegate?.userDidDeniedCameraPermission != nil){
                self.delegate?.userDidDeniedCameraPermission!()
            }
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
                if granted == true {
                    // User granted
                    
                    if(self.delegate?.userDidAuthorisedCameraPermission != nil){
                        DispatchQueue.main.async {
                            self.delegate?.userDidAuthorisedCameraPermission!()
                        }
                    }
                } else {
                    // User Rejected
                }
            })
            break
        default:
            break
        }
    }
    
    func getSortedFeeds (_ feedsArray: [[String: Any]]) -> [[String : Any]] {
        let sortedArray = feedsArray.sorted(by: { (obj1, obj2) -> Bool in
            
            let str1  = ((obj1["feedInfo"] as! [String : Any])["created"])!
            let str2 = ((obj2["feedInfo"] as! [String : Any])["created"])!
            
            let resultString1 = String(describing: str1)
            let resultString2 = String(describing: str2)
            
            let dbl1 = (resultString1 as NSString).doubleValue
            let dbl2 = (resultString2 as NSString).doubleValue
            
            
            return dbl1 > dbl2
        })
        return sortedArray
    }
}

extension FPSingleton: FPDataTaskModelDelegate {
    func didRecieveResponseOfPushNotification(json: NSMutableDictionary) {
        print(json)
    }
    
    func didRecieveErrorOfPushNotification(error: NSMutableDictionary) {
        print(error)
    }
}


extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

extension String
{
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
    
}

extension Int{
    
    var fontSize : CGFloat {
        
        var deltaSize : CGFloat = 0;
        switch (UIDevice.deviceType) {
        case .iPhone4_4s,
             .iPhone5_5s :
            deltaSize = -1;
        case .iPhone6_6s :
            deltaSize = 2;
        case .iPhone6p_6ps :
            deltaSize = 2;
        default:
            deltaSize = 0;
        }
        
        let selfValue = self;
        return CGFloat(selfValue) + deltaSize;
    }
}

extension UIDevice {
    enum DeviceTypes {
        case iPhone4_4s
        case iPhone5_5s
        case iPhone6_6s
        case iPhone6p_6ps
        case after_iPhone6p_6ps
    }
    
    static var deviceType : DeviceTypes {
        switch UIScreen.main.bounds.height {
        case 480.0:
            return .iPhone4_4s
        case 568.0:
            return .iPhone5_5s
        case 667.0:
            return .iPhone6_6s
        case 736.0:
            return .iPhone6p_6ps
        default:
            return .after_iPhone6p_6ps
        }
    }
}

extension UIFont {
    class func font_medium(_ size : CGFloat) -> UIFont {
        return UIFont(name: "Helvetica Neue", size: size)!;
    }
}

