//
//  SearchViewController.swift
//  FP
//
//  Created by Allan Zhang on 15/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import GoogleMobileAds
import Firebase

class SearchViewController: UIViewController {
    
    //MARK: - OUTLETS
    

    @IBOutlet weak var searchAd: GADBannerView!
    @IBOutlet weak var txtSearch: UITextField!
    
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblUserName: UILabel!
    
    @IBOutlet weak var imgUserImageView: UIImageView!
    
    @IBOutlet weak var btnSearch: UIButton!
    
    @IBOutlet weak var viewContainer: UIView!
    
    //MARK: - VARIABLES
    
    var userInfoDict = [String : Any]()
    var tokens = [String]()
    var refHandleForUserInfoChanged: DatabaseHandle?
    var otherUserId: String?
    
    //MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setupView()
        searchAd.adUnitID = "ca-app-pub-5181179741663920/4611388305"
        searchAd.rootViewController = self
        searchAd.load(GADRequest())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewContainer.isHidden = true

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if otherUserId != nil {
            ref.child(kChild).child(kRegistration).child(otherUserId!).child(kUserInfo).removeObserver(withHandle: refHandleForUserInfoChanged!)
            ref.removeAllObservers()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func addObserver() {
        if otherUserId != nil {
            ref.child(kChild).child(kRegistration).child(otherUserId!).child(kUserInfo).child(kFcmToken).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    if let fcmToken = snapshot.value as? String {
                        if fcmToken.count > 0 {
                            if !(self.tokens.contains(fcmToken)) {
                                self.tokens.removeAll()
                                self.tokens.append(fcmToken)
                            }
                        }
                    }
                }
            }
            
            refHandleForUserInfoChanged =      ref.child(kChild).child(kRegistration).child(otherUserId!).child(kUserInfo).observe(.childChanged) { (snapshot) in
                if snapshot.exists() {
                    if snapshot.key == kFcmToken {
                        if let newToken = snapshot.value as? String {
                            if newToken.count > 0 {
                                if !(self.tokens.contains(newToken)) {
                                    self.tokens.removeAll()
                                    self.tokens.append(newToken)
                                }
                            }else {
                                self.tokens.removeAll()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setupView() {
        view.layoutIfNeeded()
        
        txtSearch.layer.cornerRadius = 4.0
        txtSearch.layer.borderWidth = 0.5
        txtSearch.layer.borderColor = UIColor.darkGray.cgColor
        
        imgUserImageView.layer.cornerRadius = imgUserImageView.frame.size.width/2.0
        imgUserImageView.clipsToBounds = true
        
    }
    
    @IBAction func btnSearchAction(_ sender: UIButton) {
        otherUserId = nil
        tokens.removeAll()
        if (txtSearch.text?.trimmingCharacters(in: .whitespaces).count)! > 0 {
            view.endEditing(true)
            viewContainer.isHidden = true
            imgUserImageView.image = #imageLiteral(resourceName: "user")
            let searchText = (txtSearch.text?.trimmingCharacters(in: .whitespaces))!
            
            if let userInfo = FPDataModel.userInfo {
                if (userInfo[kUserName] as! String) == searchText {
                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Oops...", message: "You can not search your name", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                    return
                }
            }
            
            FPSingleton.sharedInstance.showActivityIndicator()
            
            ref.child(kChild).child(kRegistration).queryOrdered(byChild: "\(kUserInfo)/\(kUserName)").queryEqual(toValue: searchText).observeSingleEvent(of: .value) { (snapshot) in
                FPSingleton.sharedInstance.hideActivityIndicator()
                if snapshot.exists() {
                    for (key, value) in (snapshot.value as! [String : Any]) {
                        let userName = (((value as! [String : Any])[kUserInfo] as! [String : Any])[kUserName] as! String)
                        
                        if userName == searchText {
                            self.userInfoDict = (value as! [String : Any])[kUserInfo] as! [String : Any]
                            self.updateUI()
                            if let value = self.userInfoDict[kUserId] as? String {
                                self.otherUserId = value
                                self.addObserver()
                            }
                            break
                        }
                    }
                }
                
                if self.viewContainer.isHidden {
                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Oops...", message: "No profile exist with this user name", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                }
            }
        }else {
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Empty", message: "Please enter user name to search", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
        }
        
    }
    
    @IBAction func btnAddFriendAction(_ sender: UIButton) {
        let alert = UIAlertController(title: "Friend Request", message: "Are you sure you want to send this user a friend request? \n\nNote: each user can only add a limited amount of friends in their Fampack.", preferredStyle: UIAlertController.Style.alert)
        let no = UIAlertAction(title: "No", style: .cancel, handler: nil)
        let yes = UIAlertAction(title: "Yes", style: UIAlertAction.Style.default) { (yes) in
            if let otherUserId = self.userInfoDict[kUserId] as? String {
                if let userId = FPDataModel.userId {
                    FPSingleton.sharedInstance.showActivityIndicator()
                    ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).child(kcFriendCount).observeSingleEvent(of: .value, with: { (snapshot) in
                        if snapshot.exists() {
                            if Int(snapshot.value as! String)! >= 20 {
                                FPSingleton.sharedInstance.hideActivityIndicator()
                                FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Oops...", message: "You have reached maximum number of friends.", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                                
                                return
                            }
                        }
                        
                        self.sendFriendRequestIfNeeded(otherUserId: otherUserId, userId: userId) { (isRequestSent) in
                            if isRequestSent {
                                //increase Friend Count in other id
                                //                            ref.child(kChild).child(kRegistration).child(otherUserId).child(kUserInfo).child(kcFriendCount).observeSingleEvent(of: .value, with: { (snapshot) in
                                //                                if snapshot.exists() {
                                //                                    ref.child(kChild).child(kRegistration).child(otherUserId).child(kUserInfo).child(kcFriendCount).setValue(String(format: "%d", Int(snapshot.value as! String)! + 1))
                                //                                }else {
                                //                                    ref.child(kChild).child(kRegistration).child(otherUserId).child(kUserInfo).child(kcFriendCount).setValue("1")
                                //                                }
                                //                            })
                                
                                //increase Friend Count in my id
                                ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).child(kcFriendCount).observeSingleEvent(of: .value, with: { (snapshot) in
                                    if snapshot.exists() {
                                        ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).child(kcFriendCount).setValue(String(format: "%d", Int(snapshot.value as! String)! + 1))
                                    }else {
                                        ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).child(kcFriendCount).setValue("1")
                                    }
                                })
                            }
                        }
                        
                        //uncomment below line to check other user also reached max limit
                        //                    ref.child(kChild).child(kRegistration).child(otherUserId).child(kUserInfo).child(kcFriendCount).observeSingleEvent(of: .value, with: { (snapshot) in
                        //                        if snapshot.exists() {
                        //                            if Int(snapshot.value as! String)! >= 20 {
                        //                                FPSingleton.sharedInstance.hideActivityIndicator()
                        //                                FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Other user already have maximum friend. Your request can not be possible.", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                        //
                        //                                return
                        //                            }
                        //                        }
                        //                    })
                    })
                }
                
                
                
                
                //Uncomment below line to set otheruser in my friend list
                
                //                ref.child(kChild).child(kRegistration).child(otherUserId).child(kFriends).child(userId).setValue(false) { (error, databaseRef) in
                //                    FPSingleton.sharedInstance.hideActivityIndicator()
                //                    if error == nil {
                ////                        ref.child(kChild).child(kRegistration).child(userId).child(kFriends).child(otherUserId).setValue(false) { (error, databaseRef) in
                ////
                ////                        }
                //                    }else {
                //                        //FPSingleton.sharedInstance.hideActivityIndicator()
                //                    }
                //                }
            }
        }
        alert.addAction(no)
        alert.addAction(yes)
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func sendFriendRequestIfNeeded(otherUserId: String, userId: String, completion: @escaping (_ isRequestSent: Bool) -> ()) {
        ref.child(kChild).child(kRegistration).child(otherUserId).child(kFriends).child(userId).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                FPSingleton.sharedInstance.hideActivityIndicator()
                if snapshot.value as! Bool {
                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Already Friends", message: "You both are already friends", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                }else {
                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Sent", message: "Friend request already sent. Please wait for response", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                }
                completion(false)
            }else {
                ref.child(kChild).child(kRegistration).child(otherUserId).child(kFriends).child(userId).setValue(false) { (error, databaseRef) in
                    if error == nil {
                        if let userInfo = FPDataModel.userInfo {
                            if self.tokens.count > 0 {
                                self.sendPushNotificationToFriend(tokens: self.tokens, myName: userInfo[kUserName] as! String)
                            }
                        }
                        Analytics.logEvent("Friend_Request_Sent", parameters: nil)
                        FPSingleton.sharedInstance.showToast(message: "Friend request sent.")
                        completion(true)
                    }else {
                        completion(false)
                    }
                    FPSingleton.sharedInstance.hideActivityIndicator()
                }
            }
        }
    }
    
    fileprivate func sendPushNotificationToFriend(tokens: [String], myName: String) {
        FPSingleton.sharedInstance.sendPUSHNotification(to: tokens, title: "New Request", subtitle: "", body: String(format: "You have a new friend request"), data: ["module" : "newFriendRequest"])
    }
    
    fileprivate func updateUI() {
        viewContainer.isHidden = false
        if let urlString = userInfoDict[kAvatarURL] {
            if (urlString as! String).count > 0 {
                imgUserImageView.sd_setImage(with: URL(string: (urlString as! String)), placeholderImage: #imageLiteral(resourceName: "user"), options: .highPriority) { (image, error, cacheType, url) in
                    
                }
            }
        }
        
        if (userInfoDict[kUserName] as! String).count > 0 {
            lblUserName.text = userInfoDict[kUserName] as? String
        }else {
            lblUserName.text = userInfoDict[kEmail] as? String
        }
//        lblEmail.text = userInfoDict[kEmail] as? String
    }
    
    // MARK: - Touch Began
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        view.endEditing(true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SearchViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

