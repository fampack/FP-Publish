//
//  FeedViewController.swift
//  FP
//
//  Created by Allan Zhang on 15/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Firebase
import MessageUI

class FeedViewController: UIViewController, MFMailComposeViewControllerDelegate {

    //MARK: - OUTLET
    
    @IBOutlet weak var tblFeeds: UITableView!
    
    //MARK: - VARIABLES
    
    var feedArray = [[String : Any]]()
    var refHandleForFeedAdded: DatabaseHandle?
    var isViewingSelfFeed = false
    var friendId: String?
    var newImageView = UIImageView()
    var previousOffset = CGPoint(x: 0.0, y: 0.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tblFeeds.tableFooterView = UIView()
        self.navigationItem.title = "Fampack"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black,NSAttributedString.Key.font: UIFont(name: "Chalkduster", size: 25)!]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIApplication.shared.isIgnoringInteractionEvents {
            UIApplication.shared.endIgnoringInteractionEvents()
        }
        
        if !isViewingSelfFeed {
            self.tabBarController?.tabBar.isHidden = false
            feedArray.removeAll()
            tblFeeds.reloadData()
            addObserver()
        }else {
            setNavigationRightBarButton()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !isViewingSelfFeed {
            removeObserver()
        }
        FPSingleton.sharedInstance.hideActivityIndicator()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func reportButton(_ sender: UIButton) {
        let reportUser = UIAlertController(title: "Report", message: "Are you sure you want to report this user for uploading offending contents?", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Yes", style: .default) { (report) in
            let mailComposeViewController = self.configureMailController()
            if MFMailComposeViewController.canSendMail() {
                self.present(mailComposeViewController, animated: true, completion: nil)
            }
            else {
                self.showMailError()
            }
        }
        let no = UIAlertAction(title: "No", style: .cancel, handler: nil)
        reportUser.addAction(no)
        reportUser.addAction(yes)
        self.present(reportUser, animated: true, completion: nil)
    }
    
    func configureMailController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients(["fampack.net@gmail.com"])
        mailComposerVC.setSubject("Report Offending Contents")
        mailComposerVC.setMessageBody("Fampack does not tolerate the upload or display of any form of illegal/offending contents. \n\nIf you believe this user has violated such rule, please send this email to us specifying the reason. \n\nUsername of the Offender: \n\nReason: \n\n\nAdditional infomation: (e.g. Image Evidence)", isHTML: false)
        return mailComposerVC
    }
    
    func showMailError() {
        let sendMailErrorAlert = UIAlertController(title: "Error", message: "There was a problem when sending this email.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        sendMailErrorAlert.addAction(ok)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    private func setNavigationRightBarButton() {
        self.navigationItem.hidesBackButton = false
        self.tabBarController?.tabBar.isHidden = true
        let leftBarButton = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(btnDeleteAction))
        leftBarButton.tintColor = UIColor.red
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.navigationItem.rightBarButtonItems = [leftBarButton, flexibleSpace]
        //self.navigationController?.navigationBar.tintColor = UIColor.red
    }
    
    @objc fileprivate func btnDeleteAction() {
        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Delete", message: "Are you sure you want to delete this post?", inViewController: self, buttonOneCaption: "Yes", buttonTwoCaption: "No", multipleButtons: true) { (isYesPressed) in
            if isYesPressed {
                self.deleteFeedFromFirebase()
            }
        }
    }
    
    fileprivate func deleteFeedFromFirebase() {
        if feedArray.count > 0 {
            let feedDict = feedArray[0]
            let feedId = (feedDict["feedInfo"] as! [String : Any])[kcFeedId] as! String
            ref.child(kChild).child(kFeeds).child(feedId).removeValue()
            ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kFeeds).child(feedId).removeValue { (error, databaseRef) in
                if error == nil {
                    self.feedArray.removeAll()
                    self.tblFeeds.reloadData()
                    FPSingleton.sharedInstance.showToast(message: "Post deleted.")
                    self.navigationItem.rightBarButtonItems = nil
                }
                else {
                    FPSingleton.sharedInstance.showToast(message: "Something went wrong...")
                }
            }
            
        }
    }
    
    private func addObserver() {
        if let userId = FPDataModel.userId {
            FPSingleton.sharedInstance.showActivityIndicator()
            var databaseRef = ref.child(kChild).child(kRegistration).child(userId).child(kFeeds) as DatabaseQuery
            if friendId != nil {
                databaseRef = ref.child(kChild).child(kRegistration).child(userId).child(kFeeds).queryOrderedByValue().queryEqual(toValue: friendId) 
            }
            databaseRef.observeSingleEvent(of: .value) { (snapshot) in
                if !(snapshot.exists()) {
                    FPSingleton.sharedInstance.hideActivityIndicator()
                }
            }
            
            refHandleForFeedAdded = databaseRef.observe(.childAdded, with: { (snapshot) in
                if snapshot.exists() {
                    DispatchQueue.global(qos: .default).sync(execute: {
                        self.getFeedInfo(of: snapshot.key, creator: snapshot.value as! String)
                    })
                }
            })
        }
    }
    
    private func removeObserver() {
        if let userId = FPDataModel.userId {
            if refHandleForFeedAdded != nil {
                ref.child(kChild).child(kRegistration).child(userId).child(kFeeds).removeObserver(withHandle: refHandleForFeedAdded!)
            }
            ref.removeAllObservers()
        }
    }
    
    fileprivate func getFeedInfo(of feedId: String, creator: String) {
        ref.child(kChild).child(kFeeds).child(feedId).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                DispatchQueue.global(qos: .default).sync(execute: {
                    self.sync (lock: self.feedArray as NSObject)
                    {
                        var feedInfoDict = [String : Any]()
                        feedInfoDict["feedInfo"] = snapshot.value as! [String : Any]
                        if let index = self.feedArray.index(where: { (feedDict) -> Bool in
                            return ((feedDict["feedInfo"] as! [String : Any])[kcFeedId] as! String == feedId)
                        }) {
                            self.feedArray[index]["feedInfo"] = feedInfoDict["feedInfo"]
                        }else {
                            self.feedArray.append(feedInfoDict)
                        }
                        self.getCreatorInfo(of: creator, feedId: feedId)
                    }
                })
            }else {
                FPSingleton.sharedInstance.hideActivityIndicator()
                ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kFeeds).child(feedId).removeValue()
            }
        }
    }
    
    fileprivate func getCreatorInfo(of creator: String, feedId: String) {
        ref.child(kChild).child(kRegistration).child(creator).child(kUserInfo).observeSingleEvent(of: .value) { (snapshot) in
            DispatchQueue.main.async {
                FPSingleton.sharedInstance.hideActivityIndicator()
            }
            if snapshot.exists() {
                DispatchQueue.global(qos: .default).sync(execute: {
                    self.sync (lock: self.feedArray as NSObject)
                    {
                        let userInfoDict = snapshot.value as! [String : Any]
                        if let index = self.feedArray.index(where: { (feedDict) -> Bool in
                            return ((feedDict["feedInfo"] as! [String : Any])[kcFeedId] as! String == feedId)
                        }) {
                            var obj = self.feedArray[index]
                            obj[kUserInfo] = userInfoDict
                            self.feedArray[index] = obj
                            
                            if self.feedArray.count > 0 {
                                let sortedArray = FPSingleton.sharedInstance.getSortedFeeds(self.feedArray)
                                self.feedArray.removeAll()
                                
                                self.feedArray.append(contentsOf: sortedArray)
                                DispatchQueue.main.async {
                                    self.tblFeeds.reloadData()
                                }
                            }
                        }
                        
                    }
                })
            }
        }
    }
    
    func sync(lock: NSObject, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
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
        scrollImageView.decelerationRate = UIScrollView.DecelerationRate.fast
        
        //        selectedImageIndex = (tblFeeds.indexPath(forItem: sender.view!))?.row
        previousOffset = tblFeeds.contentOffset
        let imageView = sender.view as! UIImageView
        newImageView = UIImageView(image: imageView.image)
        newImageView.frame = scrollImageView.bounds
        newImageView.backgroundColor = .black
        newImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin]
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        newImageView.clipsToBounds = true
//        newImageView.sizeToFit()
//        scrollImageView.contentSize = CGSize(width: imageView.frame.size.width, height: imageView.frame.size.height)
        

        //        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
        //        newImageView.addGestureRecognizer(tap)
        
        
        
        scrollImageView.addSubview(newImageView)
        
        imageContainerView.addSubview(scrollImageView)
        imageContainerView.addSubview(btnDismissFullScreen)
        
        UIApplication.shared.keyWindow?.addSubview(imageContainerView)
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func dismissFullscreenImage(_ sender: UIButton)
    {
        self.navigationController?.isNavigationBarHidden = false
        self.tabBarController?.tabBar.isHidden = false
        sender.superview?.removeFromSuperview()
        
        tblFeeds.setContentOffset(previousOffset, animated: false)
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

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell") as! FeedTableViewCell
        DispatchQueue.main.async {
            FPSingleton.sharedInstance.addCornerRadiusWithBorder(button: cell.imgUserImageView, cornerRadius: cell.imgUserImageView.frame.size.height/2.0, borderWidth: 0.0, borderColor: nil)
            FPSingleton.sharedInstance.addCornerRadiusWithBorder(button: cell.btnChat, cornerRadius: 4.0, borderWidth: 0.5, borderColor: APP_DEEP_MAROON_COLOR)
        }
        cell.imgUserImageView.image = nil
        cell.imgFeedImageView.image = nil
        
        let infodict = feedArray[indexPath.row]
        let feedInfoDict = infodict["feedInfo"] as! [String : Any]
        if let userInfoDict = infodict[kUserInfo] as? [String : Any] {
            let userName = userInfoDict[kUserName] as? String
            cell.lblUserName.text = userName
            cell.imgUserImageView.sd_setImage(with: URL(string: userInfoDict[kAvatarURL] as! String), placeholderImage: #imageLiteral(resourceName: "user"), options: .highPriority, completed: nil)
            cell.btnChat.setTitle(String(format: "Say something to %@",userName!), for: .normal)
        }
        
        let feedDate = Date(timeIntervalSince1970: (feedInfoDict[kcCreated] as! Double) / 1000.0)
        
        
        cell.lblFeedDate.text = feedDate.timestampToStringTime(format: "MMM dd, yyyy", timestamp: nil)
        cell.lblFeedTitle.text = feedInfoDict[kcTitle] as? String
        cell.lblFeedComment.text = feedInfoDict[kcComment] as? String
        

        cell.imgFeedImageView.sd_setImage(with: URL(string: feedInfoDict[kcFeedImageUrl] as! String), placeholderImage: #imageLiteral(resourceName: "round-help-button"), options: .highPriority, completed: nil)
        cell.imgFeedImageView.addGestureRecognizer(setImageRecognizer())
        cell.imgFeedImageView.isUserInteractionEnabled = true
        
        cell.btnChat.isHidden = (isViewingSelfFeed) || (feedInfoDict[kcCreator] as! String == (FPDataModel.userId)!)
        
        cell.btnChat.addTarget(self, action: #selector(btnChatAction), for: .touchUpInside)
        
        return cell
    }
    
    
    @objc fileprivate func btnChatAction(sender: UIButton) {
        Analytics.logEvent("Chat_Through_Post", parameters: nil)
        sender.isUserInteractionEnabled = false
        if let indexPath = tblFeeds.indexPath(forItem: sender) {
            let infodict = feedArray[indexPath.row]
            if let userInfoDict = infodict[kUserInfo] as? [String : Any] {
                let friendId = userInfoDict[kUserId]

                ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kcConversations).queryOrderedByValue().queryEqual(toValue: friendId as! String).observeSingleEvent(of: .value) { (snapshot) in
                    var friendDict = [String : Any]()
                    friendDict[kAvatarURL] = userInfoDict[kAvatarURL] as! String
                    friendDict[kUserName] = userInfoDict[kUserName] as! String
                    friendDict[kUserId] = friendId
                    sender.isUserInteractionEnabled = true
                    if snapshot.exists() {
                        self.goToChatDetail(with: (Array((snapshot.value as! [String : Any]).keys)[0]), otherUserData: friendDict, myData: (FPDataModel.userInfo)!)
                    }else {
                        self.goToChatDetail(with: "", otherUserData: friendDict, myData: (FPDataModel.userInfo)!)
                    }
                }
                
            }
        }
    }
    
}

//MARK:- ScrollView Delegate

extension FeedViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return newImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageViewSize = newImageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        let verticalInset = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalInset = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }
    
    func centeredFrame(for scroll: UIScrollView, andUIView rView: UIView) -> CGRect {
        let boundSize = scroll.bounds.size
        var frameToCenter = rView.frame
        //center horizontally
        if (frameToCenter.size.width) < boundSize.width {
            frameToCenter.origin.x = (boundSize.width - frameToCenter.size.width)/2
        }else {
           frameToCenter.origin.x = 0
        }
        //center vertically
        if frameToCenter.size.height < boundSize.height {
            frameToCenter.origin.y = (boundSize.height - frameToCenter.size.height)/2
        }else {
            frameToCenter.origin.y = 0
        }
        
        return frameToCenter
    }
    
    
    
//    - (CGRect)centeredFrameForScrollView:(UIScrollView *)scroll andUIView:(UIView *)rView {
//    CGSize boundsSize = scroll.bounds.size;
//    CGRect frameToCenter = rView.frame;
//    // center horizontally
//    if (frameToCenter.size.width < boundsSize.width) {
//    frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
//    }
//    else {
//    frameToCenter.origin.x = 0;
//    }
//    // center vertically
//    if (frameToCenter.size.height < boundsSize.height) {
//    frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
//    }
//    else {
//    frameToCenter.origin.y = 0;
//    }
//    return frameToCenter;
//    }
}
