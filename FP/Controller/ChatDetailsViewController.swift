//
//  ChatDetailsViewController.swift
//  FP
//
//  Created by Allan Zhang on 26/08/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Firebase
import FirebaseStorage
import SDWebImage
import CoreData
import UserNotifications

enum mediaType: Int{
    
    case textType = 1
    case imageType = 2
}

class ChatDetailsViewController: UIViewController,UITextViewDelegate,UITableViewDelegate,UITableViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIScrollViewDelegate {
    
    //MARK: - OUTLET
    
    @IBOutlet weak var tblChat: UITableView!
    @IBOutlet weak var lblNoMessage: UILabel!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var btnRecord: UIButton!
    
    @IBOutlet var messageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var txtMessageView: UITextView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var recordingView: UIView!
    
    @IBOutlet weak var nsLayoutTxtVwCommentConstraint: NSLayoutConstraint!
    
    //MARK: - VARIABLE
    
    var newImageView = UIImageView()
    
    var placeholderLabel : UILabel!
    var userId: String = String()
    var userName = String()
    var otherUserId: String = String()
    var chatArray = NSMutableArray()
    var selectedImageIndex: Int? = 0
    
    var request = NSFetchRequest<NSFetchRequestResult>(entityName: "Chat")
    var context: NSManagedObjectContext?
    
    var isFirstTimeStartedChat: Bool = false
    var isConversationExist: Bool = false
    var isConversationExistAtOtherSide: Bool = false
    var otherUserOnline: Bool = false
    var tapToLargeImage: Bool = false
    var isCameraOpened: Bool = false
    var isOtherUserIsOnChat: Bool = false
    var isDataNeedToUpdate: Bool = true
    var otherUserImageUrl = String()
    var otherUserName = String()
    var isMethodInvoked: Bool = false
    var isReachedToZeroIndex = false
    
    var originalImagePath: String? = String()
    var thumbImagePath: String? = String()
    
    var textEnteredTimeStamp = Date()
    var lastTextEnteredTime = Date()
    //var typingTimer = Timer()
    var typingTimer : Timer?
    
    var lblTyping = UILabel()
    var lblName = UILabel()
    
    var imagePickerController: UIImagePickerController? = UIImagePickerController()
    
    var conversationId = String()
    var tempChatArray = NSMutableArray()
    var tokens = [String]()
    
    var returnPressedCount: Int = 0
    
    var refHandleForGettingChatInfo: DatabaseHandle!, refHandleForGettingChatDeleteInfo: DatabaseHandle!, refHandleForGettingChatChangeInfo: DatabaseHandle!,refHandleForGettingConversationInfo: DatabaseHandle!, refHandleForGettingUserConversationInfo: DatabaseHandle!, refHandleForGettingFavoriteInfo: DatabaseHandle!, refHandleForGettingOwnBlockedInfo: DatabaseHandle!, refHandleForGettingUserBlockedInfo: DatabaseHandle!, refHandleForGettingTypingInfo: DatabaseHandle!, refHandleForGettingConvoTypingInfo: DatabaseHandle!, refHandleForSettingUserScreen: DatabaseHandle!, refHandleForGettingConversationDeleted: DatabaseHandle!, refHandleForUserInfoChanged: DatabaseHandle?, refHandleForNewConvoId: DatabaseHandle?
    
    //MARK: - View Life cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        if conversationId.count <= 0 {
            conversationId = FPSingleton.sharedInstance.getUniqueId()
            isFirstTimeStartedChat = true
        }
        
        btnSend.isHidden = false;
        btnRecord.isHidden = true;
        recordingView.isHidden = true;
        
        txtMessageView.delegate = self
        
        placeholderLabel = UILabel()
        placeholderLabel.text = "Type a message..."
        placeholderLabel.font = UIFont.systemFont(ofSize: (txtMessageView.font?.pointSize)!)
        placeholderLabel.sizeToFit()
        txtMessageView.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 4.0, y: (txtMessageView.font?.pointSize)! / 2)
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.isHidden = !txtMessageView.text.isEmpty
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(aNotification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(aNotification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(clearData), name: Notification.Name(rawValue: "clearData"), object: nil)
        
        btnSend.addTarget(self, action: #selector(btnSendAction(sender:)), for: .touchUpInside)
        
        tblChat.addGestureRecognizer(setRecognizer())
        tblChat.isExclusiveTouch = true
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        setupView()
        
        if isDataNeedToUpdate
        {
            lblNoMessage.isHidden = false
            tblChat.isHidden = true
            chatArray.removeAllObjects()
            isReachedToZeroIndex = false
            if !isReachedToZeroIndex
            {
                getChatDataFromDB(offset: chatArray.count, isScrollToBottom: true)
            }
            setNavigationBar()
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
            
            
            setUserIsOnChatScreen(isOnCurrentSceen: true)
            
            getConversationInfo()
            
            if(!tapToLargeImage && !isCameraOpened)
            {
                setUnreadCount(autoId: "")
                
                addObserver()
            }
            else
            {
                tapToLargeImage = false
                isCameraOpened = false
                
            }
            
        }
        observerOnTyping()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        setUserIsOnChatScreen(isOnCurrentSceen: false)
        
        selectedImageIndex = nil
        ref.child(kChild).child(kcConversations).child(userId).child(conversationId).removeObserver(withHandle: refHandleForGettingConversationInfo)
        ref.child(kChild).child(kcConversations).child(otherUserId).child(conversationId).removeObserver(withHandle: refHandleForGettingUserConversationInfo)
        ref.child(kChild).child(kcConversations).child(userId).child(conversationId).removeObserver(withHandle: refHandleForGettingConvoTypingInfo)
        
        ref.child(kChild).child(kcConversations).child(otherUserId).child(conversationId).removeObserver(withHandle: refHandleForGettingConversationDeleted)
        
        
        removeNewObserver()
        if refHandleForNewConvoId != nil {
            ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kcConversations).removeObserver(withHandle: refHandleForNewConvoId!)
        }
        ref.removeAllObservers()
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        isDataNeedToUpdate = true
        
        if let navBarView =  self.navigationController?.navigationBar.subviews
        {
            for view in navBarView
            {
                if view.tag != 1
                {
                    view.removeFromSuperview()
                }
            }
        }
        
    }
    
    //MARK: - Memory Warning
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func  clearData()
    {
        isDataNeedToUpdate = false
    }
    
    func sync(lock: NSObject, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    fileprivate func removeNewObserver() {
        if refHandleForUserInfoChanged != nil {
            ref.child(kChild).child(kRegistration).child(otherUserId).child(kUserInfo).removeObserver(withHandle: refHandleForUserInfoChanged!)
        }
    }
    
    //MARK: - Both User Started Chat At Same Time
    
    private func observForOtherUserIsAlsoOnChat() {
        refHandleForNewConvoId = ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kcConversations).queryOrderedByValue().queryEqual(toValue: otherUserId).observe(.value, with: { (snapshot) in
            if snapshot.exists() {
                let convoIDs = Array((snapshot.value as! [String : Any]).keys)
                if convoIDs.count > 0 {
                    self.conversationId = convoIDs[0]
                    self.isFirstTimeStartedChat = false
                    self.isOtherUserIsOnChat = true
                    self.removeNewObserver()
                    self.addObserver()
                }
            }
        })
    }
    
    //MARK: - Get Chat Data From DB
    
    private func getChatDataFromDB(offset: Int, isScrollToBottom: Bool)
    {
        let predicate = NSPredicate(format: "convoId == %@", conversationId)
        let sortDescriptor = NSSortDescriptor(key: kChatTimeStamp, ascending: true)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chat")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDescriptor]
        var count = 0
        do {
            count = try appDelegate.managedObjectContext!.count(for: fetchRequest)
        }
        catch
        {
            
        }
        
        let size = 20 + offset
        count -= size
        
        if count <= 0
        {
            isReachedToZeroIndex = true
        }
        
        fetchRequest.fetchOffset = count > 0 ? count : 0
        fetchRequest.fetchLimit = size
        
        fetchRequest.includesSubentities = false
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.processFetchedData(asynchronousFetchResult: asynchronousFetchResult, isScrollToBottom: isScrollToBottom)
            })
        }
        
        do {
            _ = try appDelegate.managedObjectContext!.execute(asynchronousFetchRequest)
            
        }
        catch {
        }
    }
    
    func processFetchedData(asynchronousFetchResult: NSAsynchronousFetchResult<NSFetchRequestResult>, isScrollToBottom: Bool)
    {
        if let result = asynchronousFetchResult.finalResult
        {
            self.sync (lock: self.chatArray)
            {
                if self.getCurrentViewControllerID()
                {
                    for value in result
                    {
                        let managedObject = value as! NSManagedObject
                        
                        let keys = Array(managedObject.entity.attributesByName.keys)
                        
                        let chatDict = NSMutableDictionary()
                        chatDict.addEntries(from: managedObject.dictionaryWithValues(forKeys: keys))
                        
                        let index =  (self.chatArray.value(forKey: kChatId) as! NSArray).index(of: chatDict.value(forKey: kChatId) as! String)
                        
                        if(index != NSNotFound) {
                            self.chatArray.replaceObject(at: index, with: chatDict)
                        }
                        else {
                            self.chatArray.add(chatDict)
                        }
                    }
                    
                    let shortedArray = self.getSortedChat(self.chatArray)
                    
                    
                    self.chatArray.removeAllObjects()
                    
                    self.chatArray.addObjects(from: shortedArray )
                    
                    lblNoMessage.isHidden = true
                    tblChat.isHidden = false
                    if self.chatArray.count <= 0
                    {
                        lblNoMessage.isHidden = false
                        tblChat.isHidden = true
                    }
                    
                    DispatchQueue.main.async(execute: {
                        let oldContentSizeHeight = self.tblChat.contentSize.height
                        self.tblChat.reloadData()
                        let newContentSizeHeight = self.tblChat.contentSize.height
                        self.tblChat.contentOffset = CGPoint(x:self.tblChat.contentOffset.x,y:newContentSizeHeight - oldContentSizeHeight)
                        if isScrollToBottom
                        {
                            self.scrollTableView(withAnimation: false)
                        }
                        //self.updateContentInsetForTableView(tableView: self.tblChat, animated: true)
                        self.isMethodInvoked = false
                    })
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //MARK: - Set Navigation Bar
    
    /**
     This method set up Navigation Bar appearance
     
     */
    
    func setNavigationBar()
    {
        self.title = ""
        self.navigationItem.title = ""
        
        self.navigationController?.view.backgroundColor = UIColor.white
        
        let customButton = UIButton(frame: CGRect(x:0.0,y: 0.0,width: 44.0, height: 44.0))
        customButton.setImage(#imageLiteral(resourceName: "Back_Grey"), for: UIControl.State.normal)
        customButton.addTarget(self, action: #selector(self.backButtonAction), for: UIControl.Event.touchUpInside)
        customButton.contentEdgeInsets = UIEdgeInsets.init(top: 0.0, left: -34.0, bottom: 0.0, right: 0.0)
        customButton.tag = 1
        //customButton.sizeToFit()
        let flexibleSpace = UIBarButtonItem()
        flexibleSpace.customView = UIView()
        
        let leftBarButton = UIBarButtonItem()
        leftBarButton.customView = customButton
        leftBarButton.tintColor = APP_DEEP_MAROON_COLOR
        
        self.navigationItem.leftBarButtonItems = [leftBarButton,flexibleSpace]
    }
    
    @objc func backButtonAction()
    {
        backToPreviousView()
    }
    
    //MARK: - Setup View
    
    /**
     This Method is set up an initial appearance of UI Components, add action to UIButtons
     
     
     */
    
    func setupView()
    {
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.hidesBackButton = true
        self.navigationItem.title = ""
        
        //var viewsObject = Array<UIBarButtonItem>()
        
        let viewsObject = UIView()
        
        let avatarImage: UIImageView = UIImageView(frame: CGRect(x: 0.0, y: 4.0, width: 36.0, height: 36.0))
        avatarImage.image = #imageLiteral(resourceName: "user")
        avatarImage.layer.cornerRadius = avatarImage.frame.size.height/2
        avatarImage.layer.masksToBounds = true
        avatarImage.contentMode = .scaleAspectFill
        avatarImage.tag = 2
        
        lblName.frame = CGRect(x: 50.0, y: 12.0, width: 290.0, height: 18.0)
        lblName.tag = 3
        lblTyping.frame=CGRect(x: 50.0, y: 24.0, width: 290.0, height: 18.0)
        lblTyping.tag = 4
        
        lblName.font = UIFont.systemFont(ofSize: 16.0)
        lblName.textColor = APP_DEEP_MAROON_COLOR
        
        
        lblName.text = String(format: "%@",otherUserName)
        
        otherUserImageUrl = otherUserImageUrl.trimmingCharacters(in: .whitespaces)
        if otherUserImageUrl.count > 0 {
            avatarImage.sd_setImage(with: URL(string: otherUserImageUrl), placeholderImage: #imageLiteral(resourceName: "user"), options: .highPriority,  completed: { (image, error, cacheType, imageURL) in
            })
        }
        
        updateNamePosition(isTyping: false)
        
        lblTyping.font = UIFont.systemFont(ofSize: 13.0)//UIFont(name: "Ubuntu-Light", size: 13.0)
        lblTyping.textColor = APP_DEEP_MAROON_COLOR
        lblTyping.text = ""
        
        
        let chatView = UIView(frame: CGRect(x: 50.0, y: 0.0, width: 300.0, height: 40.0))
        
        chatView.addSubview(avatarImage)
        chatView.addSubview(lblName)
        chatView.addSubview(lblTyping)
        
        viewsObject.addSubview(chatView)
        
        self.navigationItem.hidesBackButton = true
        
        self.navigationController?.navigationBar.addSubview(viewsObject)
    }
    
    
    // MARK: - TableView Delegates
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return chatArray.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if indexPath.section == 0
        {
            let messageDict = chatArray[indexPath.row] as!  NSDictionary
            
            switch (messageDict.value(forKey: kChatMediaType) as AnyObject).integerValue
            {
            case mediaType.textType.rawValue:
                
                var maxWidth = 0.0
                if messageDict.value(forKey: kChatSenderId) as! String == userId
                {
                    maxWidth = 281.0
                }
                else
                {
                    maxWidth = 249.5
                }
                
                if ((messageDict.value(forKey: kChatMessage) as! String).height(withConstrainedWidth: CGFloat(maxWidth), font:UIFont.systemFont(ofSize: 13.0)) + 28) < 54
                {
                    return 54.0
                }
                
                return (messageDict.value(forKey: kChatMessage) as! String).height(withConstrainedWidth: CGFloat(maxWidth), font:UIFont.systemFont(ofSize: 13.0)) + 40
                
            case mediaType.imageType.rawValue:
                return 248.0
            default:
                break
            }
            return 0.0
        }
        return 0.0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let messageDict = chatArray[indexPath.row] as!  NSDictionary
        
        var cell: UITableViewCell!
        var otherUser: Bool = false, isRead: Bool = false
        
        if messageDict.value(forKey: kChatSenderId) as! String == userId
        {
            if let chatStatus = messageDict.value(forKey: kChatStatus)
            {
                if (chatStatus as AnyObject).integerValue == 2
                {
                    isRead = true
                }
            }
            otherUser = false
            
        }
        else
        {
            otherUser = true
        }
        switch (messageDict.value(forKey: kChatMediaType) as AnyObject).integerValue
        {
        case mediaType.textType.rawValue:
            
            let txtChatMessageView: UITextView!
            let imgVwMessageSender: UIImageView!
            var cellIdentifier: String = String()
            
            if(otherUser)
            {
                cellIdentifier = "otherSideTextMessageTableViewCell"
            }
            else
            {
                cellIdentifier = "userSideTextMessageTableViewCell"
            }
            
            cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
            
            if (cell == nil)
            {
                cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
            }
            cell.selectionStyle = .none;
            
            txtChatMessageView = cell.contentView.viewWithTag(1) as! UITextView
            txtChatMessageView.dataDetectorTypes = .all;
            txtChatMessageView.isUserInteractionEnabled = true;
            
            
            let lblTime = cell.contentView.viewWithTag(2) as! UILabel
            
            let dateTimeStamp = (messageDict.value(forKey: kChatTimeStamp) as AnyObject).doubleValue
            
            let messageDate = Date(timeIntervalSince1970: dateTimeStamp! / 1000.0)
            
            if FPSingleton.sharedInstance.getDays(startDay: messageDate.toString(), endDay: Date().toString()) != "1"
            {
                lblTime.text = String(format: "%@, %@", messageDate.timestampToStringDate(), messageDate.timestampToStringTime(timestamp: dateTimeStamp!) )
            }
            else
            {
                lblTime.text = String(format: "%@", messageDate.timestampToStringTime(timestamp: dateTimeStamp!) )
            }
            
            
            if !(otherUser)
            {
                txtChatMessageView.backgroundColor = UIColor.init(rgb: 0xF07442)
                txtChatMessageView.textColor = UIColor.white
                let tickImageView = cell.contentView.viewWithTag(3) as! UIImageView
                
                if(isRead)
                {
                    tickImageView.image = UIImage(named:"check_icon")
                }
                else
                {
                    tickImageView.image = UIImage(named:"checked_light-icon")
                }
                
                tickImageView.updateConstraints()
            }
            else
            {
                txtChatMessageView.backgroundColor = UIColor.white
                txtChatMessageView.textColor = UIColor.black
                imgVwMessageSender = cell.contentView.viewWithTag(121) as! UIImageView
                imgVwMessageSender.image = #imageLiteral(resourceName: "user")
                if otherUserImageUrl.count > 0 {
                    imgVwMessageSender.sd_setImage(with: URL(string: otherUserImageUrl), placeholderImage: #imageLiteral(resourceName: "user"), options: .retryFailed, completed: nil)
                }
                imgVwMessageSender.layer.cornerRadius = imgVwMessageSender.frame.size.height/2
                imgVwMessageSender.layer.masksToBounds = true
                imgVwMessageSender.contentMode = .scaleAspectFill
                
            }
            
            txtChatMessageView.text = messageDict.value(forKey: kChatMessage) as! String
            txtChatMessageView.layer.cornerRadius = 5.0
            txtChatMessageView.font = UIFont.systemFont(ofSize: 13.0)
            txtChatMessageView.clipsToBounds = true
            
            lblTime.updateConstraints()
            
            return cell
        case mediaType.imageType.rawValue:
            
            var cellIdentifier: String!
            
            if(otherUser)
            {
                cellIdentifier = "otherSideImageMessageTableViewCell"
            }
            else
            {
                cellIdentifier = "userSideImageMessageTableViewCell"
            }
            
            cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
            
            if (cell == nil)
            {
                cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
            }
            
            cell.selectionStyle = .none;
            
            var imageShadowView = UIView()
            var imageActivityIndicator = UIActivityIndicatorView()
            
            if(!otherUser)
            {
                imageShadowView = cell.contentView.viewWithTag(150)! as UIView
                imageActivityIndicator = cell.contentView.viewWithTag(151)! as! UIActivityIndicatorView
            }
            
            imageShadowView.isHidden = true
            imageActivityIndicator.stopAnimating()
            
            let imageContainerView = cell.contentView.viewWithTag(1)! as UIView
            let chatImageView = cell.contentView.viewWithTag(2) as! UIImageView
            let lblTime = cell.contentView.viewWithTag(3) as! UILabel
            
            
            imageContainerView.layer.cornerRadius = 5.0
            imageContainerView.clipsToBounds = true
            chatImageView.layer.cornerRadius = 5.0
            chatImageView.layer.masksToBounds = true
            chatImageView.contentMode = .scaleAspectFill
            
            chatImageView.isUserInteractionEnabled = true
            chatImageView.addGestureRecognizer(setImageRecognizer())
            chatImageView.isExclusiveTouch = true
            chatImageView.image = nil
            
            if let imageData = messageDict.value(forKey: kChatMediaUrlOriginal) as? Data {
                chatImageView.image = UIImage(data: imageData)
                imageShadowView.isHidden = false
                imageActivityIndicator.startAnimating()
            }
            else
            {
                if otherUser
                {
                    if let chatImageUrlThumb = messageDict.value(forKey: kChatMediaUrlThumb)
                    {
                        if (chatImageUrlThumb as! String).count > 0
                        {
                            chatImageView.sd_setImage(with: URL(string: chatImageUrlThumb as! String), placeholderImage: UIImage(named: "image_thumb") , completed: { (image, error, cacheType, imageURL) in
                                
                                if image != nil
                                {
                                    imageShadowView.isHidden = true
                                    imageActivityIndicator.stopAnimating()
                                    chatImageView.image = image
                                    
                                    if let chatImageUrlOrginal = messageDict.value(forKey: kChatMediaUrlOriginal)
                                    {
                                        if (chatImageUrlOrginal as! String).count > 0
                                        {
                                            chatImageView.sd_setImage(with: URL(string: chatImageUrlOrginal as! String), placeholderImage: chatImageView.image , completed: { (image, error, cacheType, imageURL) in
                                                
                                                if image != nil
                                                {
                                                    imageShadowView.isHidden = true
                                                    imageActivityIndicator.stopAnimating()
                                                    chatImageView.image = image
                                                }
                                            })
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
                else
                {
                    if let chatImageUrlOrginal = messageDict.value(forKey: kChatMediaUrlOriginal)
                    {
                        if (chatImageUrlOrginal as! String).count > 0
                        {
                            chatImageView.sd_setImage(with: URL(string: chatImageUrlOrginal as! String), placeholderImage: chatImageView.image , completed: { (image, error, cacheType, imageURL) in
                                
                                if image != nil
                                {
                                    imageShadowView.isHidden = true
                                    imageActivityIndicator.stopAnimating()
                                    chatImageView.image = image
                                }
                            })
                        }
                    }
                }
            }
            
            let dateTimeStamp = (messageDict.value(forKey: kChatTimeStamp) as AnyObject).doubleValue
            
            let messageDate = Date(timeIntervalSince1970: dateTimeStamp! / 1000.0)
            
            if FPSingleton.sharedInstance.getDays(startDay: messageDate.toString(), endDay: Date().toString()) != "1"
            {
                lblTime.text = String(format: "%@, %@", messageDate.timestampToStringDate(), messageDate.timestampToStringTime(timestamp: dateTimeStamp!) )
            }
            else
            {
                lblTime.text = String(format: "%@", messageDate.timestampToStringTime(timestamp: dateTimeStamp!) )
            }
            
            if(!otherUser)
            {
                imageContainerView.backgroundColor = UIColor.init(rgb: 0xFF820E)
                
                let tickImageView = cell.contentView.viewWithTag(4) as! UIImageView
                if(isRead)
                {
                    tickImageView.image = UIImage(named:"check_icon")
                }
                else
                {
                    tickImageView.image = UIImage(named:"checked_light-icon")
                }
                tickImageView.updateConstraints()
            }
            else
            {
                imageContainerView.backgroundColor = UIColor.init(rgb: 0xF6F6F6)
            }
            
            return cell;
        default:
            break
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        self.view.endEditing(true)
    }
    
    func updateContentInsetForTableView( tableView:UITableView,animated:Bool) {
        
        let lastRow = tableView.numberOfRows(inSection: 0)
        let lastIndex = lastRow > 0 ? lastRow - 1 : 0;
        
        let lastIndexPath = IndexPath(row: lastIndex, section: 0)
        
        
        let lastCellFrame = tableView.rectForRow(at: lastIndexPath)
        let topInset = max(tableView.frame.height - lastCellFrame.origin.y - lastCellFrame.height, 0)
        
        var contentInset = tableView.contentInset;
        contentInset.top = topInset;
        
        // UnComment below line if want animation
        
        //        _ = UIViewAnimationOptions.beginFromCurrentState;
        //        UIView.animate(withDuration: 0.3, animations: { () -> Void in
        //            
        //            tableView.contentInset = contentInset;
        //        })
        
        tableView.contentInset = contentInset
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        if scrollView == tblChat {
            if tblChat.contentOffset.y < 150 && !(isMethodInvoked) && !isReachedToZeroIndex
            {
                isMethodInvoked = true
                getChatDataFromDB(offset: chatArray.count, isScrollToBottom: false)
            }
        }
    }
    
    //MARK: - TapGesture on Image
    
    func setImageRecognizer() -> UITapGestureRecognizer
    {
        let singleTap = UITapGestureRecognizer()
        singleTap.numberOfTouchesRequired = 1;
        singleTap.numberOfTapsRequired = 1;
        singleTap.addTarget(self, action: #selector(addImageView(_:)))
        return singleTap;
    }
    
    @objc func addImageView(_ sender: UITapGestureRecognizer)
    {
        self.view.endEditing(true)
        
        let imageContainerView = UIView(frame: UIScreen.main.bounds)
        imageContainerView.backgroundColor = .black
        
        let btnDismissFullScreen = UIButton(frame: CGRect(x: 8.0, y: 20.0, width: 44.0, height: 44.0))
        btnDismissFullScreen.backgroundColor = UIColor.clear
        btnDismissFullScreen.contentEdgeInsets = UIEdgeInsets.init(top: 0.0, left: -18.0, bottom: 0.0, right: 0.0)
        btnDismissFullScreen.setImage(#imageLiteral(resourceName: "Close"), for: .normal)
        btnDismissFullScreen.addTarget(self, action: #selector(dismissFullscreenImage(_:)), for: .touchUpInside)
        
        let scrollImageView = UIScrollView(frame: CGRect(x:0.0, y: 64, width: screenWidth, height: (screenHeight - 64)))
        scrollImageView.delegate = self
        scrollImageView.backgroundColor = .black
        scrollImageView.minimumZoomScale = 1.0
        scrollImageView.maximumZoomScale = 6.0
        scrollImageView.bounces = false
        
        selectedImageIndex = (tblChat.indexPath(forItem: sender.view!))?.row
        let imageView = sender.view as! UIImageView
        newImageView = UIImageView(image: imageView.image)
        newImageView.frame = scrollImageView.bounds
        newImageView.backgroundColor = .black
        newImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        newImageView.clipsToBounds = true
        //        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
        //        newImageView.addGestureRecognizer(tap)
        
        
        
        scrollImageView.addSubview(newImageView)
        
        imageContainerView.addSubview(scrollImageView)
        imageContainerView.addSubview(btnDismissFullScreen)
        
        self.view.addSubview(imageContainerView)
        self.navigationController?.isNavigationBarHidden = true
        //        self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func dismissFullscreenImage(_ sender: UIButton)
    {
        self.navigationController?.isNavigationBarHidden = false
        sender.superview?.removeFromSuperview()
        
        if (selectedImageIndex != nil)
        {
            if selectedImageIndex == (chatArray.count - 1)
            {
                self.tblChat.scrollRectToVisible(CGRect(origin: CGPoint(x: 0.0, y: self.tblChat.contentSize.height - self.tblChat.bounds.size.height), size: CGSize(width: self.tblChat.frame.size.width, height: self.tblChat.frame.size.height)), animated: false)
            }
        }
    }
    
    
    
    //MARK:- ScrollView Delegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return newImageView
    }
    
    // MARK: - TextView Delegates
    
    func textViewDidChange(_ textView: UITextView)
    {
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        let sizeThatShouldFitTheContent = textView.sizeThatFits(textView.frame.size)
        nsLayoutTxtVwCommentConstraint.constant = sizeThatShouldFitTheContent.height
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        if text == "\n"
        {
            if textView.text.count + (text.count - range.length) == 1
            {
                return false
            }
            
            returnPressedCount = returnPressedCount+1
            
            if returnPressedCount >= 2
            {
                return false
            }
        }
        else
        {
            returnPressedCount=0;
        }
        
        if (textView.text.count - range.length + text.count) > 0
        {
            recordingView.isHidden = true
            textEnteredTimeStamp = Date()
            setTypingOn(value: true)
            
            
        }
        else
        {
            setTypingOn(value:  false)
        }
        
        return true;
        
    }
    
    public func textViewDidEndEditing(_ textView: UITextView)
    {
        if textView.text.count > 0
        {
            btnSend.isHidden = false
            recordingView.isHidden = true
        }
        else
        {
            
        }
        setTypingOn(value: false)
    }
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool
    {
        if  URL.scheme == "username"
        {
            _ = URL.host
            
            return false
        }
        
        return true
    }
    
    
    // MARK: - Keyboard Notification Method
    
    @objc func keyboardWillShow(aNotification : Notification) -> Void
    {
        let beginFrame = (aNotification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        let kbSize = (aNotification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        
        let duration = aNotification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber
        let curve = aNotification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber
        
        let delta = ((kbSize?.origin.y)! - (beginFrame?.origin.y)!) as CGFloat
        
        UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: UIView.AnimationOptions(rawValue: UInt(curve)), animations: {
            
            self.messageViewBottomConstraint.constant = CGFloat((kbSize?.height)!)
            
            self.tblChat.contentOffset = CGPoint(x: 0, y: self.tblChat.contentOffset.y - delta)
            
            self.view.layoutIfNeeded()
        }, completion: { aaa in
        })
    }
    
    @objc func keyboardWillHide(aNotification : NSNotification) -> Void
    {
        let duration = aNotification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber
        let curve = aNotification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber
        
        
        UIView.animate(withDuration: TimeInterval(truncating: duration), delay: 0.0, options: UIView.AnimationOptions(rawValue: UInt(truncating: curve)), animations: {
            
            
            self.messageViewBottomConstraint.constant = 0.0
        }, completion: { _ in
        })
    }
    
    // MARK: - Button Send Action
    
    @objc func btnSendAction(sender: UIButton)
    {
        let message = txtMessageView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if message.count > 0
        {
            let strMessage = message
            recordingView.isHidden = true
            let messageDict = NSMutableDictionary()
            
            let chatId = FPSingleton.sharedInstance.getChatID(length: 8)
            
            messageDict[kUserSide] = getConversationInfo(chatID: chatId, isUserSide: true, message: strMessage)
            messageDict[kOtherSide] = getConversationInfo(chatID: chatId, isUserSide: false, message: strMessage)
            messageDict[kChatInfo] = getMessageInfo(chatID: chatId, mediaType: mediaType.textType, message: strMessage, originalPath: "", thumbPath: "")
            
            sendMessage(messageDict: messageDict)
        }
        
        txtMessageView.text = ""
        placeholderLabel.isHidden = false
    }
    
    func getConversationInfo(chatID: String, isUserSide: Bool, message: String) -> NSMutableDictionary
    {
        let messageDict = NSMutableDictionary()
        
        messageDict[kConversationId] = conversationId
        messageDict[kChatMessage] = message
        messageDict[kChatSenderId] = userId
        if chatArray.count > 0
        {
            let index = (chatArray.value(forKey: kChatId) as! NSArray).index(of: chatID)
            if index != NSNotFound
            {
                messageDict[kLastMessagetime] = (chatArray.object(at: index) as! NSDictionary).value(forKey: kChatTimeStamp)
            }
            else
            {
                messageDict[kLastMessagetime] = FPSingleton.sharedInstance.getCurrentTimeStamp()
            }
        }
        else
        {
            messageDict[kLastMessagetime] = FPSingleton.sharedInstance.getCurrentTimeStamp()
        }
        
        if(isUserSide) // Save other user info at my end
        {
            messageDict[kOtherUserId] = otherUserId;
            messageDict[kOtherUserName] = otherUserName
            messageDict[kUnReadCount] = "0"
            messageDict[kcIsChatOpen] = true
        }
        else // Save my user info at other user end
        {
            messageDict[kOtherUserId] =  userId;
            messageDict[kOtherUserName] = userName
            
            messageDict[kcIsChatOpen] = isOtherUserIsOnChat
        }
        
        return messageDict;
    }
    
    func getMessageInfo(chatID: String, mediaType: mediaType, message: String, originalPath: String, thumbPath: String) -> NSMutableDictionary
    {
        let messageDict = NSMutableDictionary()
        
        messageDict[kChatId] = chatID
        messageDict[kChatMessage] = message
        messageDict[kChatSenderId] = userId
        messageDict[kChatSenderName] = userName
        messageDict[kChatStatus] = "0"
        
        if chatArray.count > 0
        {
            let index = (chatArray.value(forKey: kChatId) as! NSArray).index(of: chatID)
            if index != NSNotFound
            {
                messageDict[kChatTimeStamp] = (chatArray.object(at: index) as! NSDictionary).value(forKey: kChatTimeStamp)
            }
            else
            {
                messageDict[kChatTimeStamp] = FPSingleton.sharedInstance.getCurrentTimeStamp()
            }
        }
        else
        {
            messageDict[kChatTimeStamp] = FPSingleton.sharedInstance.getCurrentTimeStamp()
        }
        
        messageDict[kChatMediaLength] = "0"
        messageDict[kChatMediaType] = String(format: "%d",mediaType.rawValue)
        messageDict[kChatMediaUrlOriginal] = originalPath;
        messageDict[kChatMediaUrlThumb] = thumbPath;
        
        return messageDict;
    }
    
    func sendMessage(messageDict: NSMutableDictionary)
    {
        nsLayoutTxtVwCommentConstraint.constant = 35
        
        saveUserChat(chatDict: messageDict[kChatInfo] as! NSDictionary, mediaOriginalData: nil, mediaThumbData: nil)
        
        if let chatId = (messageDict[kChatInfo] as! NSDictionary).value(forKey: kChatId)
        {
            let index =  (self.chatArray.value(forKey: kChatId) as! NSArray).index(of: chatId as! String)
            
            if(index != NSNotFound) {
                self.chatArray.replaceObject(at: index, with: messageDict[kChatInfo] as! NSMutableDictionary)
            }
            else {
                self.chatArray.add(messageDict[kChatInfo] as! NSMutableDictionary)
            }
        }
        
        tblChat.reloadData()
        
        ref.child(kChild).child(kcConversations).child(userId).child(conversationId).setValue(messageDict[kUserSide]) { (error, databaseRef) in
            
        }
        
        ref.child(kChild).child(kcUsersChat).child(conversationId).child(kcChat).childByAutoId().setValue(messageDict[kChatInfo]) { (error, databaseRef) in
            if error == nil {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.3, execute: {
                    self.getReadyForSendPUSHNotification(messageDict: messageDict)
                })
            }
        }
        
        if isFirstTimeStartedChat {
            ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kcConversations).child(conversationId).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    
                }else {
                    ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kcConversations).child(self.conversationId).setValue(self.otherUserId, withCompletionBlock: { (error, databaseRef) in
                        
                    })
                    ref.child(kChild).child(kRegistration).child(self.otherUserId).child(kcConversations).child(self.conversationId).setValue((FPDataModel.userId)!, withCompletionBlock: { (error, databaseRef) in
                        
                    })
                }
            }
        }
        
        var isUSerSending:Bool = true
        
        
        ref.child(kChild).child(kcConversations).child(otherUserId).child(conversationId).observe(.value, with: { (snapshot) in
            
            let operationQueue = OperationQueue()
            operationQueue.addOperation({ 
                
                if isUSerSending
                {
                    isUSerSending = false
                    var unreadCount = 0
                    
                    if( snapshot.value is  NSDictionary){
                        
                        if (snapshot.value as! NSDictionary).value(forKey: kConversationId) != nil
                        {
                            let message = snapshot.value as! NSDictionary
                            
                            if message.count > 0
                            {
                                unreadCount = ((message.value(forKey: kUnReadCount) as AnyObject).integerValue)!
                            }
                        }
                        unreadCount += 1
                    }
                    else{
                        
                        unreadCount = 1
                    }
                    
                    OperationQueue.main.addOperation({ 
                        
                        let tempMessageDict = messageDict[kOtherSide]  as! NSMutableDictionary
                        
                        tempMessageDict[kUnReadCount] = String(format: "%d", unreadCount)
                        
                        
                        
                        ref.child(kChild).child(kcConversations).child(self.otherUserId).child(self.conversationId).setValue(messageDict[kOtherSide], withCompletionBlock: { (error, databaseRef) in
                            
                        })
                        
                    })
                    
                    
                }
                
            })
            
        })
    }
    
    //MARK: - Send PUSH Notification
    
    fileprivate func getReadyForSendPUSHNotification(messageDict: NSDictionary) {
        
        if !(isOtherUserIsOnChat)
        {
            if tokens.count > 0 {
                var dataDict = [String : Any]()
                dataDict["convoId"] = self.conversationId
                dataDict["senderId"] = userId
                dataDict["receiverId"] = otherUserId
                dataDict["senderImageURL"] = FPDataModel.userInfo![kAvatarURL] as! String
                dataDict["senderName"] = userName
                dataDict["receiverName"] = otherUserName
                dataDict["module"] = "chat"
                FPSingleton.sharedInstance.sendPUSHNotification(to: tokens, title: "\(userName)", subtitle: "", body: String(format: "You have a new message from %@", userName), data: dataDict)
            }
        }
    }
    
    
    // MARK: - Application Active Notification Method
    
    @objc func appDidBecomeActive()
    {
        if isConversationExist
        {
            setUserIsOnChatScreen(isOnCurrentSceen: true)
        }
    }
    
    @objc func appDidEnterBackground()
    {
        if isConversationExist
        {
            setTypingOn(value: false)
            
            setUserIsOnChatScreen(isOnCurrentSceen: false)
        }
    }
    
    @objc func appWillTerminate()
    {
        if isConversationExist
        {
            setTypingOn(value: false)
            
            setUserIsOnChatScreen(isOnCurrentSceen: false)
        }
    }
    
    //MARK: - Add Observer
    
    func addObserver()
    {
        if isFirstTimeStartedChat {
            observForOtherUserIsAlsoOnChat()
        }
        ref.child(kChild).child(kRegistration).child(otherUserId).child(kUserInfo).child(kFcmToken).observeSingleEvent(of: .value) { (snapshot) in
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
        
        refHandleForUserInfoChanged = ref.child(kChild).child(kRegistration).child(otherUserId).child(kUserInfo).observe(.childChanged) { (snapshot) in
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
                    print(self.tokens)
                }
            }
        }
        ref.child(kChild).child(kcUsersChat).child(conversationId).child(kcChat).observe(.childAdded, with: { (snapshot) in
            
            DispatchQueue.global(qos: .default).sync(execute: {
                
                self.sync (lock: self.chatArray)
                {
                    let messageDict = snapshot.value as!  NSDictionary
                    
                    if self.getCurrentViewControllerID()
                    {
                        if let chatId = messageDict.value(forKey: kChatId)
                        {
                            if messageDict.value(forKey: kChatSenderId) as! String == self.otherUserId
                            {
                                self.saveUserChat(chatDict: snapshot.value as! NSDictionary, mediaOriginalData: nil, mediaThumbData: nil)
                                
                                let index =  (self.chatArray.value(forKey: kChatId) as! NSArray).index(of: chatId as! String)
                                
                                if(index != NSNotFound) {
                                    self.chatArray.replaceObject(at: index, with: messageDict)
                                }
                                else {
                                    if let value = messageDict.value(forKey: kChatStatus) as? Int
                                    {
                                        if value != 2
                                        {
                                            self.chatArray.add(snapshot.value as! NSMutableDictionary)
                                            self.setUnreadCount(autoId: snapshot.key)
                                        }
                                    }
                                    else if let value = (messageDict.value(forKey: kChatStatus) as? String)
                                    {
                                        if Int(value)! != 2
                                        {
                                            self.chatArray.add(snapshot.value as! NSMutableDictionary)
                                            self.setUnreadCount(autoId: snapshot.key)
                                        }
                                    }
                                }
                            }
                            else {
                                
                                if let value = messageDict.value(forKey: kChatStatus) as? Int
                                {
                                    if value == 2
                                    {
                                        // Remove Message From Firebase
                                        ref.child(kChild).child(kcUsersChat).child(self.conversationId).child(kcChat).child(snapshot.key).removeValue()
                                    }
                                }
                                else if let value = (messageDict.value(forKey: kChatStatus) as? String)
                                {
                                    if Int(value)! == 2
                                    {
                                        ref.child(kChild).child(kcUsersChat).child(self.conversationId).child(kcChat).child(snapshot.key).removeValue()
                                    }
                                }
                            }
                            let shortedArray = self.getSortedChat(self.chatArray)
                            
                            self.chatArray.removeAllObjects()
                            self.chatArray.addObjects(from: shortedArray )
                            
                            self.lblNoMessage.isHidden = true
                            self.tblChat.isHidden = false
                            if self.chatArray.count <= 0
                            {
                                self.lblNoMessage.isHidden = false
                                self.tblChat.isHidden = true
                            }
                            
                            DispatchQueue.main.async {
                                self.tblChat.reloadData()
                                self.scrollTableView(withAnimation: false)
                            }
                        }
                    }
                }
            })
            
        })
        
        ref.child(kChild).child(kcUsersChat).child(conversationId).child(kcChat).observe(.childChanged, with: { (snapshot) in
            
            if snapshot.exists()
            {
                DispatchQueue.global(qos: .default).sync(execute: {
                    
                    let messageDict = snapshot.value as!  NSDictionary
                    if self.getCurrentViewControllerID()
                    {
                        self.saveUserChat(chatDict: snapshot.value as! NSDictionary, mediaOriginalData: nil, mediaThumbData: nil)
                        
                        if let value = messageDict.value(forKey: kChatStatus) as? Int
                        {
                            if value == 2
                            {
                                // Remove Message From Firebase
                                self.isOtherUserIsOnChat = true
                                ref.child(kChild).child(kcUsersChat).child(self.conversationId).child(kcChat).child(snapshot.key).removeValue()
                            }
                        }
                        else if let value = messageDict.value(forKey: kChatStatus) as? String
                        {
                            if Int(value)! == 2
                            {
                                self.isOtherUserIsOnChat = true
                                // Remove Message From Firebase
                                
                                ref.child(kChild).child(kcUsersChat).child(self.conversationId).child(kcChat).child(snapshot.key).removeValue()
                            }
                        }
                    }
                    
                })
                
            }
        })
        
        ref.child(kChild).child(kcConversations).child(otherUserId).child(conversationId).child(kcIsChatOpen).observe(.value, with: { (snapshot) in
            
            if snapshot.exists()
            {
                if let value = snapshot.value as? Bool {
                    self.isOtherUserIsOnChat = value
                }else {
                    self.isOtherUserIsOnChat = false
                }
            }
        })
        
    }
    
    func getSortedChat (_ chatArray: NSMutableArray) -> [Any] {
        let sortedArray=chatArray.sorted(by: { (obj1, obj2) -> Bool in
            
            let str1  = (obj1 as! NSDictionary).value(forKey: kChatTimeStamp)!
            let str2 = (obj2 as! NSDictionary).value(forKey: kChatTimeStamp)!
            
            let resultString1 = String(describing: str1)
            let resultString2 = String(describing: str2)
            
            let dbl1 = (resultString1 as NSString).doubleValue
            let dbl2 = (resultString2 as NSString).doubleValue
            
            
            return dbl1 < dbl2
        })
        return sortedArray
    }
    
    
    func getCurrentViewControllerID() -> Bool  {
        
        let n: Int! = self.navigationController?.viewControllers.count
        let myUIViewController = self.navigationController?.viewControllers[n-1]
        let viewControllerID =  myUIViewController?.restorationIdentifier
        if viewControllerID == "ChatDetailsViewController" {
            
            return true
        }
        return false
    }
    
    func setUserIsOnChatScreen(isOnCurrentSceen: Bool)
    {
        ref.child(kChild).child(kcConversations).child(userId).child(conversationId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.exists()
            {
                ref.child(kChild).child(kcConversations).child(self.userId).child(self.conversationId).child(kcIsChatOpen).setValue(isOnCurrentSceen) { (error, refrence) in
                    
                }
            }
        })
        
        ref.child(kChild).child(kcConversations).child(self.userId).child(self.conversationId).child(kcIsChatOpen).onDisconnectSetValue(false)
    }
    
    func setOnlineStatus(status: String)
    {
        if isConversationExistAtOtherSide
        {
            
            ref.child(kChild).child(kcConversations).child(otherUserId).child(conversationId).child(kIsOtherUserOnline) .setValue(status, withCompletionBlock: { (error, databaseRef) in
                
            })
        }
        
    }
    
    func setTypingOn(value: Bool)
    {
        if value
        {
            ref.child(kChild).child(kcConversations).child(otherUserId).child(conversationId).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if snapshot.exists() && self.isConversationExistAtOtherSide
                {
                    if (snapshot.value as! NSDictionary).value(forKey: kChatSenderId) != nil
                    {
                        ref.child(kChild).child(kcConversations).child(self.otherUserId).child(self.conversationId).child(kcTyping) .setValue(true,  withCompletionBlock: { (error, databaseRef) in
                            
                            self.lastTextEnteredTime = self.textEnteredTimeStamp
                            
                            if (self.typingTimer == nil)
                            {
                                self.typingTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.checkLastTextTime), userInfo: nil, repeats: false)
                            }
                        })
                    }
                }
            })
            
        }
        else
        {
            ref.child(kChild).child(kcConversations).child(otherUserId).child(conversationId).child(kcTyping).removeValue(completionBlock: { (error, databaseRef) in
                
            })
            
        }
        
        ref.child(kChild).child(kcConversations).child(otherUserId).child(conversationId).child(kcTyping).onDisconnectRemoveValue { (erorr, databaseRef) in
            
        }
    }
    
    func getConversationInfo()
    {
        refHandleForGettingConversationInfo = ref.child(kChild).child(kcConversations).child(userId).child(conversationId).observe(.value, with: { (snapshot) in
            
            self.otherUserOnline = false
            
            if snapshot.exists()
            {
                self.isConversationExist = true
                
                let message = snapshot.value as! NSDictionary
                
                if let value = message.value(forKey: kIsOtherUserOnline)
                {
                    self.otherUserOnline = (value as AnyObject).boolValue
                    
                }
            }
        })
        
        refHandleForGettingUserConversationInfo = ref.child(kChild).child(kcConversations).child(otherUserId).child(conversationId).observe(.value, with: { (snapshot) in
            
            self.isConversationExistAtOtherSide = false
            
            if snapshot.exists()
            {
                self.isConversationExistAtOtherSide = true
            }
            
        })
        
        
        refHandleForGettingConversationDeleted = ref.child(kChild).child(kcConversations).child(otherUserId).child(conversationId).observe(.childRemoved, with: { (snapshot) in
            
            self.isConversationExistAtOtherSide = false
            
        })
        
    }
    
    func setUnreadCount(autoId: String)
    {
        ref.child(kChild).child(kcConversations).child(userId).child(conversationId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.exists()
            {
                ref.child(kChild).child(kcConversations).child(self.userId).child(self.conversationId).child(kUnReadCount) .setValue("0", withCompletionBlock: { (error, databaseRef) in
                    
                })
            }
        })
        
        if autoId.count > 0
        {
            ref.child(kChild).child(kcUsersChat).child(conversationId).child(kcChat).child(autoId).updateChildValues([kChatStatus : "2"], withCompletionBlock: { (error, databaseRef) in
                
            })
        }
    }
    
    func observerOnTyping()
    {
        
        refHandleForGettingConvoTypingInfo = ref.child(kChild).child(kcConversations).child(userId).child(conversationId).child(kcTyping).observe(.value, with: { (snapshot) in
            
            if snapshot.exists()
            {
                if (snapshot.value as! Bool)
                {
                    DispatchQueue.main.async {
                        
                        self.lblTyping.text = "typing..."
                        
                        self.updateNamePosition(isTyping: true)
                    }
                }
                else
                {
                    DispatchQueue.main.async {
                        
                        self.lblTyping.text = ""
                        
                        self.updateNamePosition(isTyping: false)
                    }
                }
            }
            else
            {
                DispatchQueue.main.async {
                    
                    self.lblTyping.text = ""
                    
                    self.updateNamePosition(isTyping: false)
                }
            }
            
        })
    }
    
    func updateNamePosition(isTyping: Bool)
    {
        UIView.animate(withDuration: 0.5) {
            
            if(isTyping)
            {
                self.lblTyping.isHidden = false
                self.lblName.frame=CGRect(x: 50.0, y: 4.0, width: 290, height: 18.0)
                self.lblTyping.frame=CGRect(x: 50.0, y: 24.0, width: 290, height: 18.0)
            }
            else
            {
                self.lblTyping.isHidden = true
                self.lblName.frame=CGRect(x: 50.0, y: 12.0, width: 290, height: 18.0)
                self.lblTyping.frame=CGRect(x: 50.0, y: 24.0, width: 290, height: 18.0)
            }
        }
    }
    
    @objc func checkLastTextTime()
    {
        if lastTextEnteredTime == textEnteredTimeStamp
        {
            setTypingOn(value: false)
        }
        typingTimer!.invalidate()
        typingTimer = nil
    }
    
    func scrollTableView(withAnimation: Bool)
    {
        if (chatArray.count > 0)
        {
            
            DispatchQueue.main.async {
                
                self.tblChat.scrollRectToVisible(CGRect(origin: CGPoint(x: 0.0, y: self.tblChat.contentSize.height - self.tblChat.bounds.size.height), size: CGSize(width: self.tblChat.frame.size.width, height: self.tblChat.frame.size.height)), animated: false)
            }
        }
    }
    
    func setRecognizer() -> UITapGestureRecognizer
    {
        let singleTap = UITapGestureRecognizer()
        singleTap.numberOfTouchesRequired = 1;
        singleTap.numberOfTapsRequired = 1;
        singleTap.addTarget(self, action: #selector(self.singleTapHandler))
        return singleTap;
    }
    
    @objc func singleTapHandler(recogniser: UITapGestureRecognizer) -> Void
    {
        self.view.endEditing(true)
    }
    
    func backToPreviousView()
    {
        self.view.endEditing(true)
        
        setTypingOn(value: false)
        
        tapToLargeImage = false
        
        _ = self.navigationController?.popViewController(animated: true)
        
    }
    
    
    
    //MARK: - Save Chat in DB
    
    fileprivate func saveUserChat(chatDict: NSDictionary, mediaOriginalData: Data?, mediaThumbData: Data?)
    {
        
        
        if let chatId = chatDict.value(forKey: kChatId)
        {
            if !(checkChatExists(id: chatId as! String, chatDict: chatDict, isForDelete: false))
            {
                // Save in DB
                let entity =  NSEntityDescription.entity(forEntityName: "Chat", in:appDelegate.managedObjectContext!)
                let item = NSManagedObject(entity: entity!, insertInto:appDelegate.managedObjectContext!)
                
                item.setValue(chatId, forKey: "chatId")
                item.setValue(chatDict.value(forKey: kChatMessage), forKey: "chatMessage")
                item.setValue(chatDict.value(forKey: kChatSenderId), forKey: "chatSenderId")
                item.setValue(chatDict.value(forKey: kChatSenderName), forKey: "chatSenderName")
                item.setValue(conversationId, forKey: "convoId")
                if let value =  chatDict.value(forKey: kChatStatus) as? Int
                {
                    item.setValue(String(format: "%d", value), forKey: "chatStatus")
                }
                else
                {
                    item.setValue(chatDict.value(forKey: kChatStatus), forKey: "chatStatus")
                }
                item.setValue(chatDict.value(forKey: kChatTimeStamp), forKey: "chatTimeStamp")
                if let value =  chatDict.value(forKey: kChatMediaType) as? Int{
                    item.setValue(String(format: "%d", value), forKey: "mediaType")
                }
                else{
                    item.setValue(chatDict.value(forKey: kChatMediaType), forKey: "mediaType")
                }
                
                
                item.setValue(chatDict.value(forKey: kChatMediaUrlOriginal), forKey: "mediaUrlOriginal")
                item.setValue(chatDict.value(forKey: kChatMediaUrlThumb), forKey: "mediaUrlThumb")
                
                if let value =  chatDict.value(forKey: kChatMediaLength) as? Int{
                    item.setValue(String(format: "%d", value), forKey: "mediaLength")
                }
                else{
                    item.setValue(chatDict.value(forKey: kChatMediaLength), forKey: "mediaLength")
                }
                
                do {
                    try appDelegate.managedObjectContext!.save()
                } catch _ {
                }
            }
        }
    }
    
    func checkChatExists(id: String, chatDict: NSDictionary?, isForDelete: Bool) -> Bool
    {
        let predicate = NSPredicate(format: "chatId == %@", id)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chat")
        fetchRequest.predicate = predicate
        fetchRequest.includesSubentities = false
        var entitiesCount = 0
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.processAsynchronousFetchResult(asynchronousFetchResult: asynchronousFetchResult, chatDict: chatDict, isForDelete: isForDelete)
            })
        }
        
        
        do {
            entitiesCount = try appDelegate.managedObjectContext!.count(for: fetchRequest)
            
            // Execute Asynchronous Fetch Request
            _ = try appDelegate.managedObjectContext!.execute(asynchronousFetchRequest)
            
        }
        catch {
        }
        
        return entitiesCount > 0
    }
    
    func processAsynchronousFetchResult(asynchronousFetchResult: NSAsynchronousFetchResult<NSFetchRequestResult>, chatDict: NSDictionary?, isForDelete: Bool)
    {
        if let result = asynchronousFetchResult.finalResult
        {
            if result.count > 0 {   // Update Items
                let item = (result as! [NSManagedObject])[0]
                
                if isForDelete{
                    appDelegate.managedObjectContext!.delete(item)
                }
                else{
                    item.setValue(chatDict?.value(forKey: kChatMessage), forKey: "chatMessage")
                    item.setValue(chatDict?.value(forKey: kChatSenderId), forKey: "chatSenderId")
                    item.setValue(chatDict?.value(forKey: kChatSenderName), forKey: "chatSenderName")
                    item.setValue(conversationId, forKey: "convoId")
                    if let value =  chatDict?.value(forKey: kChatStatus) as? Int
                    {
                        item.setValue(String(format: "%d", value), forKey: "chatStatus")
                    }
                    else
                    {
                        item.setValue(chatDict?.value(forKey: kChatStatus), forKey: "chatStatus")
                    }
                    item.setValue(chatDict?.value(forKey: kChatTimeStamp), forKey: "chatTimeStamp")
                    if let value =  chatDict?.value(forKey: kChatMediaType) as? Int{
                        item.setValue(String(format: "%d", value), forKey: "mediaType")
                    }
                    else{
                        item.setValue(chatDict?.value(forKey: kChatMediaType), forKey: "mediaType")
                    }
                    
                    item.setValue(chatDict?.value(forKey: kChatMediaUrlOriginal), forKey: "mediaUrlOriginal")
                    item.setValue(chatDict?.value(forKey: kChatMediaUrlThumb), forKey: "mediaUrlThumb")
                    
                    if let value =  chatDict?.value(forKey: kChatMediaLength) as? Int{
                        item.setValue(String(format: "%d", value), forKey: "mediaLength")
                    }
                    else{
                        item.setValue(chatDict?.value(forKey: kChatMediaLength), forKey: "mediaLength")
                    }
                    
                    do {
                        try appDelegate.managedObjectContext!.save()
                    } catch _ {
                    }
                    
                }
            }
        }
    }
    
    //MARK: - Camera / Library Button Action
    
    @IBAction func btnOpenLibraryForImageSelecting(_ sender: UIButton)
    {
        FPSingleton.sharedInstance.delegate = self
        
        FPSingleton.sharedInstance.checkPhotoLibraryPermission()
    }
    
    @IBAction func btnOpenCameraForImagePicking(_ sender: UIButton)
    {
        FPSingleton.sharedInstance.delegate = self
        
        FPSingleton.sharedInstance.checkCameraPermission()
    }
    
    
    func openCamera(forImageTaking: Bool)
    {
        txtMessageView.text = ""
        txtMessageView.resignFirstResponder()
        isCameraOpened = true
        tapToLargeImage = false
        recordingView.isHidden = true
        
        
        imagePickerController = UIImagePickerController()
        imagePickerController?.delegate = self;
        if forImageTaking
        {
            if  UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePickerController?.sourceType = .camera
                imagePickerController?.cameraCaptureMode = .photo
            }
            else {
                FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Oops...",message: "Camera Not Available", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: { (Bool) in
                })
                
                return
            }
            
        }
        else
        {
            imagePickerController?.sourceType = .photoLibrary
        }
        
        self.present(imagePickerController!, animated: true, completion: nil)
    }
    
    //MARK: - Camera Delegate
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        
        NotificationCenter.default.post(name: Notification.Name("clearData"), object: nil)
        
        let orgImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
        
        let image = orgImage.scaleAndRotateImage()
        
        let thumImage = (image.resized(withPercentage: 0.06))!.resized(toWidth: 200)
        
        var originalImageData: Data? = image.jpegData(compressionQuality: 0.8)
        var thumbImageData: Data? = thumImage!.jpegData(compressionQuality: 0.0)
        
        let imgNm = FPSingleton.sharedInstance.getCurrentTimeStamp()
        var imageName:String? = "\(imgNm)"
        
        let chatId = FPSingleton.sharedInstance.getChatID(length: 8)
        
        let tempChatDict = createImageDict(chatID: chatId)
        tempChatArray.add(tempChatDict)
        saveUserChat(chatDict: tempChatDict, mediaOriginalData: nil, mediaThumbData: nil)
        tempChatDict.setValue(originalImageData, forKey: kChatMediaUrlOriginal)
        
        uploadImage(chatID: chatId, imageName: imageName!, originalImageData: originalImageData!, thumbImageData: thumbImageData!)
        
        self.chatArray.add(tempChatDict)
        self.tblChat.beginUpdates()
        self.tblChat.insertRows(at: [IndexPath.init(row: self.chatArray.count-1, section: 0)], with: .automatic)
        self.tblChat.endUpdates()
        self.scrollTableView(withAnimation: false)
        //self.updateContentInsetForTableView(tableView: self.tblChat, animated: true)
        
        
        imageName = nil
        originalImageData = nil
        thumbImageData = nil
        
        picker.dismiss(animated: true, completion: nil)
        
        imagePickerController=nil;
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        tapToLargeImage = false
        NotificationCenter.default.post(name: Notification.Name("clearData"), object: nil)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func uploadImage(chatID: String, imageName: String, originalImageData: Data, thumbImageData: Data)
    {
        
        let storageRef = Storage.storage().reference()
        
        let originalImagesRef = storageRef.child(kcChat).child(conversationId).child(kcImage).child(kcOrginal).child(imageName)
        let thumbImagesRef = storageRef.child(kcChat).child(conversationId).child(kcImage).child(kcThumb).child(imageName)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        originalImagesRef.putData(originalImageData, metadata: metadata) { (metadata, error) in
            
            if error != nil
            {
            }
            else
            {
                
                originalImagesRef.downloadURL(completion: { (url, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    if let profileImageUrl = url?.absoluteString {
                        
                        self.saveImageUrl(chatID: chatID, imageUrl: profileImageUrl, isForOriginal: true)
                    }
                })
            }
        }
        
        
        thumbImagesRef.putData(thumbImageData, metadata: metadata) { (metadata, error) in
            
            if error != nil
            {
            }
            else
            {
                thumbImagesRef.downloadURL(completion: { (url, error) in
                    if error != nil {
                        print(error!.localizedDescription)
                        return
                    }
                    FPSingleton.sharedInstance.hideActivityIndicator()
                    if let profileImageUrl = url?.absoluteString {
                        
                        self.saveImageUrl(chatID: chatID, imageUrl:
                            profileImageUrl, isForOriginal: false)
                    }
                })
            }
        }
        
    }
    
    func createImageDict(chatID: String) -> NSMutableDictionary
    {
        let chatDict = NSMutableDictionary()
        
        chatDict.setValue(chatID, forKey: kChatId)
        chatDict.setValue("Image", forKey: kChatMessage)
        chatDict.setValue(userId, forKey: kChatSenderId)
        chatDict.setValue(String(format: "%@",otherUserName), forKey: kChatSenderName)
        chatDict.setValue("0", forKey: kChatStatus)
        chatDict.setValue(FPSingleton.sharedInstance.getCurrentTimeStamp(), forKey: kChatTimeStamp)
        chatDict.setValue("0", forKey: kChatMediaLength)
        chatDict.setValue(String(format: "%d",mediaType.imageType.rawValue), forKey: kChatMediaType)
        chatDict.setValue("", forKey: kChatMediaUrlOriginal)
        chatDict.setValue("", forKey: kChatMediaUrlThumb)
        
        return chatDict
    }
    
    func saveImageUrl(chatID: String, imageUrl: String, isForOriginal: Bool)
    {
        if isForOriginal
        {
            originalImagePath = imageUrl
        }
        else
        {
            thumbImagePath = imageUrl
        }
        
        
        if originalImagePath != nil && thumbImagePath != nil
        {
            if((originalImagePath?.count)! > 0 && (thumbImagePath?.count)! > 0)
            {
                let messageDict = NSMutableDictionary()
                
                messageDict[kUserSide] = getConversationInfo(chatID: chatID, isUserSide: true, message: "Image")
                messageDict[kOtherSide] = getConversationInfo(chatID: chatID, isUserSide: false, message:"Image")
                messageDict[kChatInfo] = getMessageInfo(chatID: chatID, mediaType: mediaType.imageType, message: "Image", originalPath: originalImagePath!, thumbPath: thumbImagePath!)
                
                sendMessage(messageDict: messageDict)
                
                originalImagePath = nil
                thumbImagePath = nil
            }
        }
        
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("clearData"), object: nil)
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

extension ChatDetailsViewController: FPSingletonDelegate
{
    func userDidAuthorisedPhotoGallaryPermission() {
        openCamera(forImageTaking: false)
    }
    
    func userDidDeniedPhotoGallaryPermission() {
        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Oops...", message: "Permission is blocked.\nPlease tap on settings and allow FP to access your Photos", inViewController: self, buttonOneCaption: "Cancel", buttonTwoCaption: "Settings", multipleButtons: true) { (bool) in
            if !(bool)
            {
                let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)! as URL
                UIApplication.shared.open(settingsUrl, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler:{ (success) in
                    
                })
            }
        }
    }
    
    func userDidAuthorisedCameraPermission() {
        openCamera(forImageTaking: true)
    }
    
    func userDidDeniedCameraPermission() {
        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Oops...", message: "Permission is blocked.\nPlease tap on settings and allow FP to access your Camera", inViewController: self, buttonOneCaption: "Cancel", buttonTwoCaption: "Settings", multipleButtons: true) { (bool) in
            if !(bool)
            {
                let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)! as URL
                UIApplication.shared.open(settingsUrl, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler:{ (success) in
                    
                })
            }
        }
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
