//
//  ConversationViewController.swift
//  FP
//
//  Created by Allan Zhang on 24/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import CoreData

class ConversationViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UIGestureRecognizerDelegate,UITextFieldDelegate
{
    //MARK: - OUTLET
    
    @IBOutlet weak var tblConversation: UITableView!
    @IBOutlet weak var lblNoFriend: UILabel!
    @IBOutlet weak var btnFloatingAdd: UIButton!
    
    //MARK: - VARIABLES
    
    var conversationArray = NSMutableArray()
    var filteredArray = NSMutableArray()
    var userProfileArray = NSMutableArray()
    var userId = String()
    var searchButton: UIBarButtonItem?
    var  conversationCount: NSInteger = 0
    var searchBar = UISearchBar()
    var refHandleForGettingTypingInfo: DatabaseHandle!
    var isSearchingModeON: Bool = false
    var chatCount = 0
    var isInternetConnectionOFF = false
    
    // MARK: - Views Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        getDataFromDB(id: userId)
        userId = (FPDataModel.userId)!
        lblNoFriend.isHidden = true
        self.view.addGestureRecognizer(setRecognizer())
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        conversationArray.removeAllObjects()
        filteredArray.removeAllObjects()
        userProfileArray.removeAllObjects()
        tblConversation.reloadData()
        
        
        self.tabBarController?.tabBar.isHidden = false
        
        setNavigationBar()
        updateUI()
        addObserver()
        
        lblNoFriend.isHidden = true
        isSearchingModeON = false
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        isSearchingModeON = false
        setRightBarButton(isShow: true)
        self.tabBarItem.selectedImage = UIImage(named: "ChatInactive")?.withRenderingMode(.alwaysOriginal)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        setRightBarButton(isShow: true)
        
        if UIApplication.shared.isIgnoringInteractionEvents
        {
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }
    
    // MARK: - Memory Warning
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: -  Set Navigation Bar
    
    /**
     This method set up Navigation Bar appearance
     
     */
    
    func setNavigationBar()
    {
        self.tabBarItem.title = ""
        self.navigationItem.title = "Message"
        
        setRightBarButton(isShow: true)
    }
    
    
    func setSearchButton() -> UIBarButtonItem
    {
        if searchButton == nil
        {
            searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchButtonPressed))
            searchButton?.tintColor = APP_DEEP_MAROON_COLOR
        }
        return searchButton!
    }
    
    @objc func searchButtonPressed()
    {
        searchBar.placeholder = "Search user"
        searchBar.text = ""
        searchBar.backgroundColor = UIColor.clear
        searchBar.tintColor = APP_DEEP_MAROON_COLOR
        searchBar.barTintColor = UIColor.black
        searchBar.showsCancelButton = true
        searchBar.isTranslucent = true
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        self.navigationItem.title = ""
        self.navigationItem.titleView = searchBar
        
        searchBar.setPlaceholderTextColorTo(color: UIColor.gray)
        searchBar.setMagnifyingGlassColorTo(color: APP_DEEP_MAROON_COLOR)
        searchBar.setClearButtonColorTo(color: APP_DEEP_MAROON_COLOR)
        
        setRightBarButton(isShow: false)
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        filteredArray.removeAllObjects()
        isSearchingModeON = false
        setRightBarButton(isShow: true)
        updateUI()
        tblConversation.reloadData()
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        if searchText.count > 0
        {
            isSearchingModeON = true
            
            let predicate = NSPredicate(format: "otherUserName contains[c] %@ ",searchText)
            
            filteredArray.removeAllObjects()
            
            filteredArray.addObjects(from: conversationArray.filtered(using: predicate))
            
            if filteredArray.count > 0
            {
                tblConversation.isHidden = false
                lblNoFriend.isHidden = true
            }
            else
            {
                lblNoFriend.text = "No user found"
                tblConversation.isHidden = true
                lblNoFriend.isHidden = false
            }
        }
        else
        {
            if conversationArray.count > 0
            {
                tblConversation.isHidden = false
            }
            
            isSearchingModeON = false
        }
        
        tblConversation.reloadData()
    }
    
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool
    {
        return true
    }
    
    func setRightBarButton(isShow: Bool)
    {
        if isShow
        {
            self.navigationItem.title = "Message"
            
            self.navigationItem.titleView = nil
            
            let flexibleSpace = UIBarButtonItem()
            flexibleSpace.customView = UIView()
            
            self.navigationItem.rightBarButtonItems = [setSearchButton(), flexibleSpace]
        }
        else
        {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    // MARK: - Set SingleTap Gesture
    
    func setRecognizer() -> UITapGestureRecognizer
    {
        let singleTap = UITapGestureRecognizer()
        singleTap.numberOfTouchesRequired = 1;
        singleTap.numberOfTapsRequired = 1;
        singleTap.delegate = self
        singleTap.addTarget(self, action: #selector(self.singleTapHandler(sender:)))
        return singleTap;
    }
    
    @objc func singleTapHandler(sender : UITapGestureRecognizer)
    {
        self.navigationItem.titleView?.endEditing(true)
    }
    
    
    //MARK:- Add observer
    func addObserver()
    {
        conversationCount = 0
        self.getConversation()
    }
    
    func deleteAllConversation()
    {
        checkUserConversationExists(id: userId)
    }
    
    /**
     This method is used to get sorted Arary in descending order of timestamp.
     
     - parameter conversationArray: pass an unsorted array.
     - returns: sorted Array in descending order for key lastMessagetime
     
     */
    
    func getShortedConversation (_ conversationArray: NSMutableArray) -> [Any] {

        let sortedArray=conversationArray.sorted(by: { (obj1, obj2) -> Bool in
            
            let str1  = (obj1 as! NSDictionary).value(forKey: "lastMessagetime")!
            let str2 = (obj2 as! NSDictionary).value(forKey: "lastMessagetime")!
            
            let resultString1 = String(describing: str1)
            let resultString2 = String(describing: str2)
            
            let dbl1 = (resultString1 as NSString).doubleValue
            let dbl2 = (resultString2 as NSString).doubleValue
            
            
            return dbl1 > dbl2
        })
        
        return sortedArray
    }
    
    /**
     This method is used to get all conversation list from Firebase.
     
     */
    
    func getConversation()  {
        
        // sort according to "lastMessagetime"
        
        chatCount = 0
        
        ref.child(kChild).child(kcConversations).child(userId).observe(.childAdded, with: { (snapshot) in
            
            DispatchQueue.global(qos: .default).sync(execute: {
                
                self.conversationCount += 1
                
                self.sync (lock: self.conversationArray)
                {
                    if self.getCurrentViewControllerID()
                    {
                        if let convoId = (snapshot.value as! NSMutableDictionary).value(forKey: kConversationId)
                        {
                            if !((self.userProfileArray.value(forKey: USER_ID) as! NSArray).contains((snapshot.value as! NSMutableDictionary).value(forKey: kOtherUserId) ?? ""))
                            {
                                self.getUserProfile(with: (snapshot.value as! NSMutableDictionary).value(forKey: kOtherUserId) as? String, convoDict:  (snapshot.value as! NSDictionary))
                            }
                            
                            if let timestamp = (snapshot.value as! NSMutableDictionary).value(forKey: kLastMessagetime)
                            {
                                if (self.conversationArray.value(forKey: kLastMessagetime) as! NSArray).index(of: timestamp) == NSNotFound
                                {
                                    self.saveConversation(convoDict: snapshot.value as! NSDictionary)
                                }
                            }
                            
                            let index =  (self.conversationArray.value(forKey: kConversationId) as! NSArray).index(of: convoId as! String)
                            
                            if(index != NSNotFound)
                            {
                                let tempConvoDict = snapshot.value as! NSMutableDictionary
                                tempConvoDict.setValue((self.conversationArray.object(at: index) as! NSDictionary).value(forKey: kImageUrl) ?? "", forKey: kImageUrl)
                                self.conversationArray.replaceObject(at: index, with: tempConvoDict)
                            }
                            else{
                                self.conversationArray.add(snapshot.value as! NSMutableDictionary)
                            }
                            
                            if self.hasUnReadCount(convoDict: snapshot.value as! NSDictionary)
                            {
                                self.chatCount = self.chatCount + 1
                            }
                            else
                            {
                                if let value = USER_DEFAULT.value(forKey: CHAT_COUNT)
                                {
                                    if Int(value as! String)! > 0
                                    {

                                    }
                                }
                            }
                            
                            USER_DEFAULT.setValue(String(format: "%d",self.chatCount), forKey: CHAT_COUNT)
                        }
                        else
                        {
                            self.conversationCount -= 1
                        }
                        
                        if self.conversationArray.count == self.conversationCount && self.chatCount <= 0
                        {
                            USER_DEFAULT.setValue(String(format: "%d",self.chatCount), forKey: CHAT_COUNT)
                        }
                        
                        if self.conversationCount > 0
                        {
                            
                            let shortedArray = self.getShortedConversation( self.conversationArray)
                            
                            
                            self.conversationArray.removeAllObjects()
                            
                            self.conversationArray.addObjects(from: shortedArray )
                            
                            if self.isSearchingModeON
                            {
                                let predicate = NSPredicate(format: "otherUserName contains[c] %@ ",self.searchBar.text!)
                                
                                self.filteredArray.removeAllObjects()
                                
                                self.filteredArray.addObjects(from: self.conversationArray.filtered(using: predicate))
                            }
                            
                            DispatchQueue.main.async {
                                self.updateUI()
                                self.tblConversation.reloadData()
                            }
                        }
                        else
                        {
                            self.lblNoFriend.text = "Add your friends for chat."
                            self.lblNoFriend.isHidden = false
                            self.tblConversation.isHidden = true
                            if self.conversationArray.count > 0
                            {
                                self.deleteAllConversation()
                            }
                            self.conversationArray.removeAllObjects()
                        }
                    }
                }
            })
        })
        
        ref.child(kChild).child(kcConversations).child(userId).observe(.childChanged, with: { (snapshot) in
            
            DispatchQueue.global(qos: .default).sync(execute: {
                self.sync (lock: self.conversationArray)
                {
                    if self.getCurrentViewControllerID()
                    {
                        let convoArray = self.conversationArray.value(forKey: kConversationId) as! NSArray
                        
                        if let value = (snapshot.value as! NSDictionary).value(forKey: kConversationId)
                        {
                            if let timestamp = (snapshot.value as! NSDictionary).value(forKey: kLastMessagetime)
                            {
                                if (self.conversationArray.value(forKey: kLastMessagetime) as! NSArray).index(of: timestamp) == NSNotFound
                                {

                                    self.saveConversation(convoDict: snapshot.value as! NSDictionary)
                                }
                            }
                            
                            let convoId = value as! String
                            let index = convoArray.index(of: convoId)
                            
                            if (index != NSNotFound)
                            {
                                let tempConvoDict = snapshot.value as! NSMutableDictionary
                                tempConvoDict.setValue((self.conversationArray.object(at: index) as! NSDictionary).value(forKey: kImageUrl) ?? "", forKey: kImageUrl)
                                self.conversationArray.replaceObject(at: index, with: tempConvoDict)
                                
                                let shortedArray = self.getShortedConversation( self.conversationArray)
                                
                                self.conversationArray.removeAllObjects()
                                
                                self.conversationArray.addObjects(from: shortedArray )
                            }
                            if self.isSearchingModeON
                            {
                                let predicate = NSPredicate(format: "otherUserName contains[c] %@ ",self.searchBar.text!)
                                
                                self.filteredArray.removeAllObjects()
                                
                                self.filteredArray.addObjects(from: self.conversationArray.filtered(using: predicate))
                            }
                            DispatchQueue.main.async {
                                if self.conversationArray.count > 0 || self.filteredArray.count > 0
                                {
                                    self.tblConversation.reloadData()
                                }
                            }
                        }
                    }
                }
            })            
        })
        
        
        ref.child(kChild).child(kcConversations).child(userId).observe(.childRemoved, with: { (snapshot) in
            
            DispatchQueue.global(qos: .default).sync(execute: {
                
                self.sync (lock: self.conversationArray)
                {
                    let convoArray = self.conversationArray.value(forKey: kConversationId) as! NSArray
                    
                    if let convoId = (snapshot.value as! NSMutableDictionary).value(forKey: kConversationId)
                    {
                        self.conversationCount -= 1
                        var index = convoArray.index(of: convoId)
                        
                        if (index != NSNotFound)
                        {
                            self.conversationArray.removeObject(at: index)
                        }
                        
                        if self.filteredArray.count > 0
                        {
                            index = (self.filteredArray.value(forKey: kConversationId) as! NSArray).index(of: convoId)
                            
                            if (index != NSNotFound)
                            {
                                self.filteredArray.removeObject(at: index)
                            }
                        }
                        
                        index = (self.userProfileArray.value(forKey: USER_ID) as! NSArray).index(of: (snapshot.value as! NSMutableDictionary).value(forKey: kOtherUserId) ?? "")
                        
                        if index != NSNotFound
                        {
                            self.userProfileArray.removeObject(at: index)
                        }
                    }
                    DispatchQueue.main.async {
                        self.tblConversation.reloadData()
                        self.updateUI()
                    }
                }
            })
        })
    }
    
    /**
     This method is used to match whether current screen on device is FitbitChat View Controller or not.
     
     - returns: true if screen matches otherwise false.
     
     */
    
    func getCurrentViewControllerID() -> Bool  {
        
        let n: Int! = self.navigationController?.viewControllers.count
        let myUIViewController = self.navigationController?.viewControllers[n-1]
        let viewControllerID =  myUIViewController?.restorationIdentifier
        if viewControllerID == "ConversationViewController" {
            
            return true
        }
        return false
    }
    
    func sync(lock: NSObject, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    /**
     This method is used to get user profile from Firebase.
     
     - parameter id: Id of User whoose profile you want to retrieve.
     - parameter convoDict: for matching id of user in conversation Array and replace user Image with matching id.
     
     */
    
    private func getUserProfile(with id:String?, convoDict: NSDictionary)
    {
        if id != nil
        {
            if (id?.count)! > 0
            {
                ref.child(kChild).child(kRegistration).child(id!).child(kUserInfo).observe(.value, with: { (snapshot) in
                    
                    if snapshot .exists()
                    {
                        DispatchQueue.global(qos: .default).sync(execute: {
                            self.sync (lock: self.conversationArray)
                            {
                                if self.getCurrentViewControllerID()
                                {
                                    if let value = (snapshot.value as! NSDictionary).value(forKey: USER_ID)
                                    {
                                        if self.userProfileArray.count > 0
                                        {
                                            let index = (self.userProfileArray.value(forKey: USER_ID) as! NSArray).index(of: id!)
                                            if index != NSNotFound
                                            {
                                                self.userProfileArray.replaceObject(at: index, with: snapshot.value as! NSDictionary)
                                            }
                                            else
                                            {
                                                self.userProfileArray.add(snapshot.value as! NSDictionary)
                                            }
                                        }
                                        else
                                        {
                                            self.userProfileArray.add(snapshot.value as! NSDictionary)
                                        }
                                        
                                        let index = (self.conversationArray.value(forKey: kOtherUserId) as! NSArray).index(of: (value as? String) ?? "" )
                                        if index != NSNotFound
                                        {
                                            let tempConvoDict = (self.conversationArray.object(at: index) as! NSMutableDictionary)
                                            tempConvoDict.setValue((snapshot.value as! NSDictionary).value(forKey: kAvatarURL)  as? String ?? "", forKey: kImageUrl)
                                            self.conversationArray.replaceObject(at: index, with: tempConvoDict)
                                            
                                            self.saveConversation(convoDict: tempConvoDict)
                                        }
                                        
                                        if self.filteredArray.count > 0
                                        {
                                            let index = (self.filteredArray.value(forKey: kOtherUserId) as! NSArray).index(of: (value as? String) ?? "" )
                                            if index != NSNotFound
                                            {
                                                let tempConvoDict = (self.filteredArray.object(at: index) as! NSMutableDictionary)
                                                tempConvoDict.setValue((snapshot.value as! NSDictionary).value(forKey: kAvatarURL)  as? String ?? "", forKey: kImageUrl)
                                                self.filteredArray.replaceObject(at: index, with: tempConvoDict)
                                            }
                                        }
                                        
                                        DispatchQueue.main.async {
                                            self.tblConversation.reloadData()
                                        }
                                    }
                                }
                            }
                        })
                        
                    }
                })
                
            }
        }
    }
    
    //MARK: - Save Conversation in DB
    
    /**
     This method is used to save conversation Info in Local Database.
     
     - parameter convoDict: pass conversation Dictionary it will save according to key-Value of Dictionary.
     
     */
    
    fileprivate func saveConversation(convoDict: NSDictionary)
    {
        let convoId = convoDict.value(forKey: kConversationId) as! String
        if (checkConversationExists(id: convoId, convoDict:  convoDict, isForDelete: false))  // Update in DB
        {
            
        }
        else // Save in DB
        {
            let entity =  NSEntityDescription.entity(forEntityName: "Conversation", in:appDelegate.managedObjectContext!)
            let item = NSManagedObject(entity: entity!, insertInto:appDelegate.managedObjectContext!)
            
            item.setValue(convoId, forKey: "convoId")
            item.setValue(convoDict.value(forKey: kChatMessage), forKey: "chatMessage")
            item.setValue(convoDict.value(forKey: kChatSenderId), forKey: "chatSenderId")
            item.setValue(userId, forKey: "userId")
            if userProfileArray.count > 0
            {
                let otherUserId = convoDict.value(forKey: kOtherUserId) as! String
                let index = (userProfileArray.value(forKey: USER_ID) as! NSArray).index(of: otherUserId)
                if index != NSNotFound
                {
                    item.setValue((userProfileArray.object(at: index) as! NSDictionary).value(forKey: kAvatarURL) as! String, forKey: kImageUrl)
                }
                else
                {
                    item.setValue("", forKey: kImageUrl)
                }
            }
            else
            {
                item.setValue("", forKey: kImageUrl)
            }
            
            if let value = convoDict.value(forKey: kcIsChatOpen) as? Bool
            {
                item.setValue(value, forKey: "isChatOpen")
            }
            else
            {
                item.setValue((convoDict.value(forKey: kcIsChatOpen) as AnyObject).boolValue, forKey: "isChatOpen")
            }
            
            item.setValue(false, forKey: "isOtherUserOnline")
            
            item.setValue(convoDict.value(forKey: kLastMessagetime), forKey: "lastMessagetime")
            item.setValue(convoDict.value(forKey: kOtherUserId), forKey: "otherUserId")
            item.setValue(convoDict.value(forKey: kOtherUserName), forKey: "otherUserName")
            item.setValue("", forKey: "typing")
            
            if let value = (convoDict.value(forKey: kUnReadCount) as? String){
                item.setValue(value, forKey: "unReadCount")
            }
            else{
                item.setValue((convoDict.value(forKey: kUnReadCount) as AnyObject).stringValue, forKey: "unReadCount")
            }
            
            
            do {
                try appDelegate.managedObjectContext!.save()
            } catch _ {
            }
            
        }
    }
    
    //MARK:- Delete All Conversation
    
    func checkUserConversationExists(id : String)
    {
        let predicate = NSPredicate(format: "userId == %@", id)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Conversation")
        fetchRequest.predicate = predicate
        fetchRequest.includesSubentities = false
        
        let asynchronousUserConversationFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.processUserConversationAsynchronousFetchResult(asynchronousFetchResult: asynchronousFetchResult)
            })
        }
        
        
        do {
            _ = try appDelegate.managedObjectContext!.execute(asynchronousUserConversationFetchRequest)
        }
        catch {
        }
    }
    
    func processUserConversationAsynchronousFetchResult(asynchronousFetchResult: NSAsynchronousFetchResult<NSFetchRequestResult>)
    {
        if let result = asynchronousFetchResult.finalResult
        {
            for object in result as! [NSManagedObject]
            {
                appDelegate.managedObjectContext!.delete(object)
            }
            
            do {
                try appDelegate.managedObjectContext!.save()
            } catch _ {
            }
        }
    }
    
    func checkConversationExists(id: String, convoDict: NSDictionary?, isForDelete: Bool) -> Bool
    {
        let predicate = NSPredicate(format: "convoId == %@", id)
        print("KKK1")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Conversation")
        fetchRequest.predicate = predicate
        fetchRequest.includesSubentities = false
        var entitiesCount = 0
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.processAsynchronousFetchResult(asynchronousFetchResult: asynchronousFetchResult, convoId: id, convoDict: convoDict, isForDelete: isForDelete)
            })
        }
        
        
        do {
            _ = try appDelegate.managedObjectContext!.execute(asynchronousFetchRequest)
            entitiesCount = try appDelegate.managedObjectContext!.count(for: fetchRequest)
        }
        catch {
        }
        
        return entitiesCount > 0
        
    }
    
    func processAsynchronousFetchResult(asynchronousFetchResult: NSAsynchronousFetchResult<NSFetchRequestResult>, convoId: String, convoDict: NSDictionary?, isForDelete: Bool)
    {
        if let result = asynchronousFetchResult.finalResult
        {
            if result.count > 0 {   // Update Items
                let item = (result as! [NSManagedObject])[0]
                
                if isForDelete{
                    deleteFromChat(id: convoId)
                    appDelegate.managedObjectContext!.delete(item)
                }
                else{
                    //item.setValue(convoDict.value(forKey: kConversationId) as! String, forKey: "convoId")
                    item.setValue(convoDict?.value(forKey: kChatMessage), forKey: "chatMessage")
                    item.setValue(convoDict?.value(forKey: kChatSenderId), forKey: "chatSenderId")
                    item.setValue(userId, forKey: "userId")
                    if let value = convoDict?.value(forKey: kcIsChatOpen) as? Bool
                    {
                        item.setValue(value, forKey: "isChatOpen")
                    }
                    else
                    {
                        item.setValue((convoDict?.value(forKey: kcIsChatOpen) as AnyObject).boolValue, forKey: "isChatOpen")
                    }
                    
                    if userProfileArray.count > 0
                    {
                        let otherUserId = convoDict?.value(forKey: kOtherUserId) as! String
                        let index = (userProfileArray.value(forKey: USER_ID) as! NSArray).index(of: otherUserId)
                        if index != NSNotFound
                        {
                            item.setValue((userProfileArray.object(at: index) as! NSDictionary).value(forKey: kAvatarURL) as! String, forKey: kImageUrl)
                        }
                        else
                        {
                            item.setValue("", forKey: kImageUrl)
                        }
                    }
                    else
                    {
                        item.setValue("", forKey: kImageUrl)
                    }
                    
                    item.setValue(false, forKey: "isOtherUserOnline")
                    
                    item.setValue(convoDict?.value(forKey: kLastMessagetime), forKey: "lastMessagetime")
                    //item.setValue(78794569, forKey: "lastModifiedTime")
                    item.setValue(convoDict?.value(forKey: kOtherUserId), forKey: "otherUserId")
                    item.setValue(convoDict?.value(forKey: kOtherUserName), forKey: "otherUserName")
                    item.setValue("", forKey: "typing")
                    
                    if let value = (convoDict?.value(forKey: kUnReadCount) as? String){
                        item.setValue(value, forKey: "unReadCount")
                    }
                    else{
                        item.setValue((convoDict?.value(forKey: kUnReadCount) as AnyObject).stringValue, forKey: "unReadCount")
                    }
                }
                
                do {
                    try appDelegate.managedObjectContext!.save()
                } catch _ {
                }
                
            }
        }
    }
    
    private func deleteFromChat(id: String)
    {
        let predicate = NSPredicate(format: "convoId == %@", id)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chat")
        fetchRequest.predicate = predicate
        fetchRequest.includesSubentities = false
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.processAsynchronousFetchResultOfChat(asynchronousFetchResult: asynchronousFetchResult)
            })
        }
        do {
            
            // Execute Asynchronous Fetch Request
            _ = try appDelegate.managedObjectContext!.execute(asynchronousFetchRequest)
            
        }
        catch {
        }
    }
    
    func processAsynchronousFetchResultOfChat(asynchronousFetchResult: NSAsynchronousFetchResult<NSFetchRequestResult>)
    {
        if let result = asynchronousFetchResult.finalResult
        {
            for object in result as! [NSManagedObject]
            {
                appDelegate.managedObjectContext!.delete(object)
            }
            
            do {
                try appDelegate.managedObjectContext!.save()
            } catch _ {
            }
        }
    }
    
    //MARK: - Get Conversation Data From DB
    
    /**
     This method is used to get all conversation from Local Database.
     
     - parameter id: Id of User whoose conversation list you want to retrieve.
     
     */
    
    private func getDataFromDB(id: String)
    {
        print("KKK2")
        let predicate = NSPredicate(format: "userId == %@", id)
        let sortDescriptor = NSSortDescriptor(key: kLastMessagetime, ascending: false)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Conversation")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.includesSubentities = false
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.processFetchedData(asynchronousFetchResult: asynchronousFetchResult)
            })
        }
        
        do {
            _ = try appDelegate.managedObjectContext!.execute(asynchronousFetchRequest)
            
        }
        catch {
        }
    }
    
    func processFetchedData(asynchronousFetchResult: NSAsynchronousFetchResult<NSFetchRequestResult>)
    {
        if let result = asynchronousFetchResult.finalResult
        {
            self.sync (lock: self.conversationArray)
            {
                if self.getCurrentViewControllerID()
                {
                    for value in result
                    {
                        print("KKK3")
                        let managedObject = value as! NSManagedObject
                        
                        let keys = Array(managedObject.entity.attributesByName.keys)
                        
                        let convoDict = NSMutableDictionary()
                        convoDict.addEntries(from: managedObject.dictionaryWithValues(forKeys: keys))
                        
                        let index =  (self.conversationArray.value(forKey: kConversationId) as! NSArray).index(of: convoDict[kConversationId] ?? "")
                        
                        if(index != NSNotFound)
                        {
                            self.conversationArray.replaceObject(at: index, with: convoDict)
                        }
                        else{
                            self.conversationArray.add(convoDict)
                        }
                    }
                    
                    let sortedArray = self.getShortedConversation( self.conversationArray)
                    
                    
                    self.conversationArray.removeAllObjects()
                    
                    self.conversationArray.addObjects(from: sortedArray )
                    
                    lblNoFriend.isHidden = false
                    tblConversation.isHidden = true
                    
                    if self.isSearchingModeON
                    {
                        let predicate = NSPredicate(format: "otherUserName contains[c] %@ ",self.searchBar.text!)
                        
                        self.filteredArray.removeAllObjects()
                        
                        self.filteredArray.addObjects(from: self.conversationArray.filtered(using: predicate))
                        
                        if filteredArray.count > 0
                        {
                            lblNoFriend.isHidden = true
                            tblConversation.isHidden = false
                            tblConversation.reloadData()
                        }
                    }
                    else
                    {
                        if conversationArray.count > 0
                        {
                            lblNoFriend.isHidden = true
                            tblConversation.isHidden = false
                            tblConversation.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - TableView Delegates & DataSources
    
    public func numberOfSections(in tableView: UITableView) -> Int
    {
        if isSearchingModeON
        {
            return filteredArray.count
        }
        else
        {
            return conversationArray.count
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let cellDefaultHeight: CGFloat = 90.0 /*the default height of the cell*/
        let screenDefaultHeight: CGFloat = 380.0/*the default height of the screen i.e. 480 in iPhone 4*/;
        
        let factor = cellDefaultHeight / screenDefaultHeight
        
        return factor * screenHeight
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell = tableView.dequeueReusableCell(withIdentifier: "userChatCell") as UITableViewCell?
        
        if cell == nil
        {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "userChatCell")
        }
        
        let cellView = (cell?.contentView.viewWithTag(1))! as UIView
        let userImageView: UIImageView = cell?.contentView.viewWithTag(2) as! UIImageView
        let lblUserName: UILabel = cell?.contentView.viewWithTag(3) as! UILabel
        let lblUserUnreadMessage: UILabel = cell?.contentView.viewWithTag(4) as! UILabel
        let lblLastMessageTime: UILabel = cell?.contentView.viewWithTag(5) as! UILabel
        let lblLastMessage: UILabel = cell?.contentView.viewWithTag(6) as! UILabel
        let lblUserOnlineStatus: UILabel = cell?.contentView.viewWithTag(7) as! UILabel
        
        lblUserOnlineStatus.layer.cornerRadius = lblUserOnlineStatus.frame.size.height/2.0
        lblUserOnlineStatus.clipsToBounds = true
        lblUserOnlineStatus.isHidden = true
        
        var convoDict = NSDictionary()
        
        if isSearchingModeON
        {
            convoDict = (filteredArray.object(at: indexPath.section) as! NSDictionary)
        }
        else
        {
            convoDict = (conversationArray.object(at: indexPath.section) as! NSDictionary)
        }
        
        FPSingleton.sharedInstance.setCardView(view: cellView, cornerRadius: 4.0)
        
        userImageView.layer.cornerRadius = userImageView.frame.size.height/2.0
        userImageView.clipsToBounds = true
        userImageView.contentMode = .scaleAspectFill
        
        if userProfileArray.count > 0
        {
            let index = (userProfileArray.value(forKey: USER_ID) as! NSArray).index(of: convoDict.value(forKey: kOtherUserId) ?? "")
            if index != NSNotFound
            {
                if let value =  (userProfileArray[index] as! NSDictionary).value(forKey: kOnlineStatus)
                {
                    if !(isInternetConnectionOFF)
                    {
                        lblUserOnlineStatus.isHidden = !((value as AnyObject).boolValue)
                    }
                }
                
                let URLString = String(format:"%@", (userProfileArray.object(at: index) as! NSDictionary).value(forKey: kAvatarURL) as! String)
                
                userImageView.sd_setImage(with: URL(string: URLString), placeholderImage: #imageLiteral(resourceName: "user"), options: SDWebImageOptions(rawValue: 3),  completed: { (image, error, cacheType, imageURL) in
                })
            }
            else
            {
                if userImageView.image == nil
                {
                    userImageView.image = #imageLiteral(resourceName: "user")
                }
            }
        }
        else
        {
            if let value = convoDict.value(forKey: kImageUrl)
            {
                let URLString = String(format:"%@", value as! String)
                
                userImageView.sd_setImage(with: URL(string: URLString), placeholderImage: #imageLiteral(resourceName: "user"), options: SDWebImageOptions(rawValue: 3),  completed: { (image, error, cacheType, imageURL) in
                })
            }
        }
        
        lblUserUnreadMessage.layer.cornerRadius = lblUserUnreadMessage.frame.size.height/2.0
        lblUserUnreadMessage.clipsToBounds = true
        lblUserUnreadMessage.isHidden = true
        lblUserName.font = UIFont(name: "Ubuntu", size: 18.0)
        //////***************
        
        if hasUnReadCount(convoDict: convoDict)
        {
            lblUserUnreadMessage.isHidden = false
            
            if let val  = (convoDict.value(forKey: kUnReadCount) as? AnyObject) {
                lblUserUnreadMessage.text = "\(val)"
            }
            lblUserName.font = UIFont(name: "Ubuntu-Bold", size: 18.0)
        }
        else
        {
            lblUserUnreadMessage.isHidden = true
        }
        
        
        lblUserName.text = String(format: "%@",convoDict.value(forKey: kOtherUserName) as! String)
        
        lblLastMessageTime.text = (Date.init(timeIntervalSince1970: (convoDict.value(forKey: kLastMessagetime) as AnyObject).doubleValue / 1000.0)).timeAgoSinceNow()
        
        lblLastMessage.text = convoDict.value(forKey: kChatMessage) as? String
        lblLastMessage.textColor = APP_LIGHT_TEXT_COLOR
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        var convoDict = NSMutableDictionary()
        if isSearchingModeON
        {
            convoDict = (filteredArray.object(at: indexPath.section) as! NSMutableDictionary)
        }
        else
        {
            convoDict = (conversationArray.object(at: indexPath.section) as! NSMutableDictionary)
        }
        
        var friendDict = [String : Any]()
        friendDict[kAvatarURL] = convoDict[kImageUrl]
        friendDict[kUserName] = convoDict[kOtherUserName]
        friendDict[kUserId] = convoDict[kOtherUserId]
        
        self.goToChatDetail(with: convoDict[kConversationId] as! String, otherUserData: friendDict, myData: (FPDataModel.userInfo)!)
    }
    
    fileprivate func goToChatDetail(with convoId: String, otherUserData: [String : Any], myData: [String : Any]) {
        print("KKK4")
        Analytics.logEvent("Chat_Through_Chat", parameters: nil)
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
    
    func hasUnReadCount(convoDict: NSDictionary) -> Bool
    {
        if let val  = (convoDict.value(forKey: kUnReadCount) as? AnyObject) {
            let intVal = val.integerValue
            if intVal! > 0
            {
                return true
            }
        }
        return false
    }
    
    
    func updateUI()
    {
        if conversationArray.count > 0
        {
            lblNoFriend.isHidden = true
            tblConversation.isHidden = false
        }
        else
        {
            if isSearchingModeON
            {
                lblNoFriend.text = "No user found"
            }
            else
            {
                lblNoFriend.text = "Add your friends for chat."
            }
            lblNoFriend.isHidden = false
            tblConversation.isHidden = true
        }
        
    }
    
    // MARK: - Gesture Recogniser Delegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        if let titleView = self.navigationItem.titleView
        {
            if (titleView.isFirstResponder)
            {
                return true
            }
        }
        return false
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


extension UISearchBar: UITextFieldDelegate
{
    func setPlaceholderTextColorTo(color: UIColor)
    {
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        let textFieldInsideSearchBarLabel = textFieldInsideSearchBar!.value(forKey: "placeholderLabel") as? UILabel
        textFieldInsideSearchBar?.delegate = self
        textFieldInsideSearchBar?.textColor = UIColor(red: 44.0/255.0, green: 44.0/255.0, blue: 44.0/255.0, alpha: 1.0)
        textFieldInsideSearchBar?.backgroundColor = UIColor.clear
        textFieldInsideSearchBarLabel?.textColor = color
    }
    
    func setMagnifyingGlassColorTo(color: UIColor)
    {
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        let glassIconView = textFieldInsideSearchBar?.leftView as? UIImageView
        glassIconView?.image = glassIconView?.image?.withRenderingMode(.alwaysTemplate)
        glassIconView?.tintColor = color
    }
    
    func setClearButtonColorTo(color: UIColor)
    {
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        if let clearButton = textFieldInsideSearchBar?.value(forKey: "_clearButton") as? UIButton
        {
            let templateImage =  clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
            // Set the template image copy as the button image
            clearButton.setImage(templateImage, for: .normal)
            clearButton.setImage(templateImage, for: .highlighted)
            // Finally, set the image color
            clearButton.tintColor = UIColor.white
        }
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if let topController = UIApplication.topViewController()
        {
            topController.navigationItem.titleView?.endEditing(true)
        }
        
        return true
    }
    
}


