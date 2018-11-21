//
//  FriendListViewController.swift
//  FP
//
//  Created by Allan Zhang on 16/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Firebase

class FriendListViewController: UIViewController {
    
    //MARK: - OUTLET
    
    @IBOutlet weak var tblFriend: UITableView!
    
    //MARK: - VARIABLES
    
    var friendArray = [Any]()
    var newFriendArray = [[String : Any]]()
    var oldFriendArray = [[String : Any]]()
    
    var refHandleForFriendAdded: DatabaseHandle?, refHandleForFriendDeleted: DatabaseHandle?, refHandleForFriendChanged: DatabaseHandle!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tblFriend.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        friendArray.removeAll()
        newFriendArray.removeAll()
        oldFriendArray.removeAll()
        addObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let userId = FPDataModel.userId {
        ref.child(kChild).child(kRegistration).child(userId).child(kFriends).removeObserver(withHandle: refHandleForFriendAdded!)
        ref.child(kChild).child(kRegistration).child(userId).child(kFriends).removeObserver(withHandle: refHandleForFriendChanged!)
        ref.child(kChild).child(kRegistration).child(userId).child(kFriends).removeObserver(withHandle: refHandleForFriendDeleted!)
        }
        ref.removeAllObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func addObserver() {
        if let userId = FPDataModel.userId {
            refHandleForFriendAdded = ref.child(kChild).child(kRegistration).child(userId).child(kFriends).observe(.childAdded, with: { (snapshot) in
                if snapshot.exists() {
                    DispatchQueue.global(qos: .default).sync(execute: {
                        self.getUserInfo(of: snapshot.key, isOldFriend: snapshot.value as! Bool)
                    })
                }
            })
            
            refHandleForFriendDeleted = ref.child(kChild).child(kRegistration).child(userId).child(kFriends).observe(.childRemoved, with: { (snapshot) in
                if snapshot.exists() {
                    DispatchQueue.global(qos: .default).sync(execute: {
                        self.sync (lock: self.friendArray as NSObject)
                        {
                            self.friendArray = self.friendArray.filter({ (obj) -> Bool in
                                return !(((obj as! [String : Any])[kUserId] as! String) == snapshot.key)
                                
                            })
                            
                            DispatchQueue.main.async {
                                self.tblFriend.reloadData()
                            }
                        }
                    })
                }
            })
            
            refHandleForFriendChanged = ref.child(kChild).child(kRegistration).child(userId).child(kFriends).observe(.childChanged, with: { (snapshot) in
                if snapshot.exists() {
                    DispatchQueue.global(qos: .default).sync(execute: {
                        self.sync (lock: self.friendArray as NSObject)
                        {
                            if let index = self.friendArray.index(where: { (obj) -> Bool in
                                return (((obj as! [String : Any])[kUserId] as! String) == snapshot.key)
                            }) {
                                var userInfoDict = (self.friendArray[index] as! [String : Any])
                                userInfoDict["isNewRequest"] = !(snapshot.value as! Bool)
                                self.friendArray[index] = userInfoDict
                                
                                DispatchQueue.main.async {
                                    self.tblFriend.reloadData()
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    fileprivate func getUserInfo(of friendId: String, isOldFriend: Bool) {
        ref.child(kChild).child(kRegistration).child(friendId).child(kUserInfo).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                DispatchQueue.global(qos: .default).sync(execute: {
                    self.sync (lock: self.friendArray as NSObject)
                    {
                        var userInfoDict = snapshot.value as! [String: Any]
                        userInfoDict["isNewRequest"] = !isOldFriend
                        
                        if self.friendArray.count > 0 {
                            if let index = self.friendArray.index(where: { (obj) -> Bool in
                                return ((obj as! [String : Any])[kUserId] as! String) == (userInfoDict[kUserId] as! String)
                            }) {
                                self.friendArray[index] = userInfoDict
                            }else {
                                self.friendArray.append(userInfoDict)
                            }
                        }else {
                            self.friendArray.append(userInfoDict)
                        }
                        if self.friendArray.count > 1 {
                            self.friendArray = self.friendArray.sorted(by: { (obj1, obj2) -> Bool in
                                return ((obj1 as! [String : Any])["isNewRequest"] as! Bool) && ((obj1 as! [String : Any])["isNewRequest"] as! Bool)
                            })
                        }
                        DispatchQueue.main.async {
                            self.tblFriend.reloadData()
                        }
                    }
                })
            }
        }
    }
    
    @objc fileprivate func btnAcceptAction(sender: UIButton) {
        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Accept", message: "Are you sure you want to accept friend request", inViewController: self, buttonOneCaption: "Accept", buttonTwoCaption: "Cancel", multipleButtons: true) { (isAcceptPressed) in
            if isAcceptPressed {
                if let indexPath = self.tblFriend.indexPath(forItem: sender) {
                    let userInfoDict = (self.friendArray[indexPath.row] as! [String : Any])
                    if let otherUserId = userInfoDict[kUserId] as? String {
                        FPSingleton.sharedInstance.showActivityIndicator()
                        ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kUserInfo).child(kcFriendCount).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists() {
                                if Int(snapshot.value as! String)! > 20 {
                                    FPSingleton.sharedInstance.hideActivityIndicator()
                                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Oops...", message: "You have already maximum number of friends. If you want to accept this request then you have to remove another friend.", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                                    Analytics.logEvent("Max_Friends_Alert", parameters: nil)
                                    return
                                }
                            }
                            ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kFriends).child(otherUserId).setValue(true, withCompletionBlock: { (error, databaseRef) in
                                FPSingleton.sharedInstance.hideActivityIndicator()
                                if error == nil {
                                    ref.child(kChild).child(kRegistration).child(otherUserId).child(kFriends).child((FPDataModel.userId)!).setValue(true, withCompletionBlock: { (error, databaseRef) in
                                        if error == nil {
                                            Analytics.logEvent("Friend_Added", parameters: nil)
                                            self.increaseFriendCount(userId: (FPDataModel.userId)!, otherUserId: otherUserId)
                                           FPSingleton.sharedInstance.showToast(message: "Friend request accepted.")
                                        }
                                    })
                                }
                            })
                        })
                        
                    }
                }
            }
        }
    }
    
    @objc fileprivate func btnRejectAction(sender: UIButton) {
        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Reject", message: "Are you sure you want to reject friend request", inViewController: self, buttonOneCaption: "Reject", buttonTwoCaption: "Cancel", multipleButtons: true) { (isRejectPressed) in
            if isRejectPressed {
                if let indexPath = self.tblFriend.indexPath(forItem: sender) {
                    let userInfoDict = (self.friendArray[indexPath.row] as! [String : Any])
                    if let otherUserId = userInfoDict[kUserId] as? String {
                        ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kFriends).child(otherUserId).removeValue(completionBlock: { (error, databaseRef) in
                            if error == nil {
                                Analytics.logEvent("Friend_Rejected", parameters: nil)
                                FPSingleton.sharedInstance.showToast(message: "Friend Request rejected.")
                            }
                        })
                        
                        self.decreaseFriendCount(userId: nil, otherUserId: otherUserId)
                    }
                }
            }
        }
    }
    
    fileprivate func decreaseFriendCount(userId: String?, otherUserId: String) {
        //decrease Friend Count in other id
        ref.child(kChild).child(kRegistration).child(otherUserId).child(kUserInfo).child(kcFriendCount).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                ref.child(kChild).child(kRegistration).child(otherUserId).child(kUserInfo).child(kcFriendCount).setValue(String(format: "%d", Int(snapshot.value as! String)! - 1))
            }else {
                ref.child(kChild).child(kRegistration).child(otherUserId).child(kUserInfo).child(kcFriendCount).setValue("0")
            }
        })
        
        //decrease Friend Count in my id
        if userId != nil {
            ref.child(kChild).child(kRegistration).child(userId!).child(kUserInfo).child(kcFriendCount).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    ref.child(kChild).child(kRegistration).child(userId!).child(kUserInfo).child(kcFriendCount).setValue(String(format: "%d", Int(snapshot.value as! String)! - 1))
                }else {
                    ref.child(kChild).child(kRegistration).child(userId!).child(kUserInfo).child(kcFriendCount).setValue("0")
                }
            })
        }
    }
    
    fileprivate func increaseFriendCount(userId: String, otherUserId: String) {
       //increase Friend Count in my id
        ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).child(kcFriendCount).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).child(kcFriendCount).setValue(String(format: "%d", Int(snapshot.value as! String)! + 1))
            }else {
                ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).child(kcFriendCount).setValue("1")
            }
        })
    }
    
    func sync(lock: NSObject, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
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

extension FriendListViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (friendArray).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendListTableViewCell") as! FriendListTableViewCell
        
        cell.lblUserNameTrailingConstraint.isActive = false
        cell.btnAccept.isHidden = true
        cell.btnReject.isHidden = true
        
        let userInfoDict = (friendArray[indexPath.row] as! [String : Any])
        
        if (userInfoDict["isNewRequest"] as! Bool) {
            cell.btnAccept.isHidden = false
            cell.btnReject.isHidden = false
            cell.btnAccept.addTarget(self, action: #selector(btnAcceptAction(sender:)), for: .touchUpInside)
            cell.btnReject.addTarget(self, action: #selector(btnRejectAction(sender:)), for: .touchUpInside)
            cell.lblUserNameTrailingConstraint.isActive = true
        }
        
        
        
        cell.imgUserImageView.sd_setImage(with: URL(string: (userInfoDict[kAvatarURL] as! String)), placeholderImage: #imageLiteral(resourceName: "user"), options: .highPriority) { (image, error, cacheType, url) in
            
        }
        
        FPSingleton.sharedInstance.addCornerRadiusWithBorder(button: cell.imgUserImageView, cornerRadius: cell.imgUserImageView.frame.size.height/2.0, borderWidth: 0.0, borderColor: nil)
        
        cell.lblUserName.text = userInfoDict[kUserName] as? String
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if friendArray.count > 0 {
            let userInfoDict = (friendArray[indexPath.row] as! [String : Any])
            if (userInfoDict["isNewRequest"] as! Bool) {
                return false
            }
        }
        return true
    }
}

extension FriendListViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCell.EditingStyle.delete)
        {
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Remove", message: "Are you sure you want to remove this friend?", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "Cancel", multipleButtons: true, completion: { (success) in
                if success
                {
                    let userInfoDict = (self.friendArray[indexPath.row] as! [String : Any])
                    if let otherUserId = userInfoDict[kUserId] as? String {
                        ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kFriends).child(otherUserId).removeValue(completionBlock: { (error, databaseRef) in
                            if error == nil {
                                Analytics.logEvent("Friend_Removed", parameters: nil)
                                self.decreaseFriendCount(userId: (FPDataModel.userId)!, otherUserId: otherUserId)
                                FPSingleton.sharedInstance.showToast(message: "Friend Removed.")
                            }
                        })
                        
                        ref.child(kChild).child(kRegistration).child(otherUserId).child(kFriends).child((FPDataModel.userId)!).removeValue(completionBlock: { (error, databaseRef) in
                        })
                    }
                }
            })
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            FPSingleton.sharedInstance.showAlert(style: .actionSheet, title: nil, message: "Select option", firstButtonText: "Go to chat", secondButtonText: "Go to feed", parentVC: self) { (selectedText) in
                switch selectedText {
                case "Go to chat":
                    Analytics.logEvent("Chat_Through_FriendList", parameters: nil)
                    let friendDict = (self.friendArray[indexPath.row] as! [String : Any])
                    self.getConversationId(with: friendDict[kUserId] as! String, completion: { (convoId) in
                        self.goToChatDetail(with: convoId, otherUserData: friendDict, myData: (FPDataModel.userInfo)!)
                    })
                    break
                case "Go to feed":
                    self.moveToFeedScreen(at: indexPath.row)
                    break
                default:
                    break
                }
            }
        }
    }
    
    fileprivate func getConversationId(with otherUserId: String, completion: @escaping (_ convoId: String) -> ()) {
        ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kcConversations).queryOrderedByValue().queryEqual(toValue: otherUserId).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                completion(Array((snapshot.value as! [String : Any]).keys)[0])
            }else {
                completion("")
            }
        }
    }
    
    fileprivate func goToChatDetail(with convoId: String, otherUserData: [String : Any], myData: [String : Any]) {
        var chatDetailsViewController = self.storyboard?.instantiateViewController(withIdentifier: "ChatDetailsViewController") as? ChatDetailsViewController
        chatDetailsViewController?.conversationId = convoId
        chatDetailsViewController?.otherUserImageUrl = otherUserData[kAvatarURL] as? String ?? ""
        chatDetailsViewController?.otherUserName = otherUserData[kUserName] as? String ?? ""
        chatDetailsViewController?.otherUserId = otherUserData[kUserId] as? String ?? ""
        chatDetailsViewController?.userId = (FPDataModel.userId)!
        chatDetailsViewController?.userName = myData[kUserName] as? String ?? ""
        self.navigationController?.pushViewController(chatDetailsViewController!, animated: true)
        chatDetailsViewController = nil
    }
    
    fileprivate func moveToFeedScreen(at index: Int) {
        var feedViewController = self.storyboard?.instantiateViewController(withIdentifier: "FeedViewController") as? FeedViewController
        feedViewController!.isViewingSelfFeed = false
        feedViewController?.friendId = (friendArray[index] as! [String : Any])[kUserId] as? String
        self.navigationController?.pushViewController(feedViewController!, animated: true)
        feedViewController = nil
    }
}
