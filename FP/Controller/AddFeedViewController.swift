//
//  AddFeedViewController.swift
//  FP
//
//  Created by Allan Zhang on 15/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import Firebase
import GoogleMobileAds

class AddFeedViewController: UIViewController {

    @IBOutlet weak var postAd: GADBannerView!
    @IBOutlet weak var txtFeedTitle: UITextField!
    @IBOutlet weak var txtFeedComment: UITextField!
    
    @IBOutlet weak var imgFeedImageView: UIImageView!

    var isImageChanged = false, isNeedToAddObserver = false
    var friendArray = [String]()
    var tokens = [[String : Any]]()
    
    var refHandleForFriendAdded: DatabaseHandle?, refHandleForFriendDeleted: DatabaseHandle?, refHandleForFriendChanged: DatabaseHandle?, refHandleForUserInfoChanged: DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setupView()
        
        isImageChanged = false
        NotificationCenter.default.addObserver(self, selector: #selector(imagePickerPresented), name: .imagePickerPresented, object: nil)
    
        postAd.adUnitID = "ca-app-pub-5181179741663920/2326746564"
        postAd.rootViewController = self
        postAd.load(GADRequest())
            }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !isNeedToAddObserver {
            friendArray.removeAll()
            clearAllFields()
            addObserver()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !isNeedToAddObserver {
            if let userId = FPDataModel.userId { ref.child(kChild).child(kRegistration).child(userId).child(kFriends).removeObserver(withHandle: refHandleForFriendAdded!)
                ref.child(kChild).child(kRegistration).child(userId).child(kFriends).removeObserver(withHandle: refHandleForFriendDeleted!)
                ref.child(kChild).child(kRegistration).child(userId).child(kFriends).removeObserver(withHandle: refHandleForFriendChanged!)
                
            }
            ref.child(kChild).child(kRegistration).removeAllObservers()
            ref.removeAllObservers()
        }
        isNeedToAddObserver = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @objc fileprivate func imagePickerPresented(){
        isNeedToAddObserver = true
    }
    
    fileprivate func clearAllFields(){
        txtFeedTitle.text = ""
        txtFeedComment.text = ""
        imgFeedImageView.image = #imageLiteral(resourceName: "round-help-button")
        isImageChanged = false
    }
    
    private func addObserver() {
        if let userId = FPDataModel.userId {
            self.tokens.removeAll()
            refHandleForFriendAdded = ref.child(kChild).child(kRegistration).child(userId).child(kFriends).queryOrderedByValue().queryEqual(toValue: true).observe(.childAdded, with: { (snapshot) in
                if snapshot.exists() {
                    self.getUserInfo(of: snapshot.key)
                    if !(self.friendArray.contains(snapshot.key)) {
                        self.friendArray.append(snapshot.key)
                    }
                }
            })
            
            refHandleForFriendDeleted = ref.child(kChild).child(kRegistration).child(userId).child(kFriends).observe(.childRemoved, with: { (snapshot) in
                if snapshot.exists() {
                    if (self.friendArray.contains(snapshot.key)) {
                        if let index = self.friendArray.index(of: snapshot.key) {
                            self.friendArray.remove(at: index)
                        }
                    }
                }
            })
            
            refHandleForFriendChanged = ref.child(kChild).child(kRegistration).child(userId).child(kFriends).observe(.childChanged, with: { (snapshot) in
                if snapshot.exists() {
                    if !(self.friendArray.contains(snapshot.key)) {
                        self.getUserInfo(of: snapshot.key)
                        self.friendArray.append(snapshot.key)
                    }
                }
            })
        }
    }
    
    fileprivate func getUserInfo(of userId: String) {
        ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                if let userInfo = snapshot.value as? [String : Any] {
                    if self.tokens.index(where: { (oldUser) -> Bool in
                        return oldUser[kUserId] as! String == userInfo[kUserId] as! String
                    }) == nil {
                        if let fcmToken = userInfo[kFcmToken] as? String {
                            if fcmToken.count > 0 {
                                self.tokens.append(userInfo)
                            }
                        }
                    }
                }
            }
        }
        
        refHandleForUserInfoChanged =      ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).observe(.childChanged) { (snapshot) in
            if snapshot.exists() {
                print(userId)
                if snapshot.key == kFcmToken {
                    if let newToken = snapshot.value as? String {
                        if newToken.count > 0 {
                            if let index = self.tokens.index(where: { (oldUser) -> Bool in
                                return oldUser[kUserId] as! String == userId
                            }) {
                                self.tokens[index][kFcmToken] = newToken
                            }
                        }else {
                            if let index = self.tokens.index(where: { (oldUser) -> Bool in
                                return oldUser[kUserId] as! String == userId
                            }) {
                                self.tokens.remove(at: index)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setupView() {
        view.layoutIfNeeded()
        
        imgFeedImageView.layer.cornerRadius = 4.0
        imgFeedImageView.clipsToBounds = true
    }
    
    @IBAction func btnAddFeedImageAction(_ sender: UIButton) {
        optionForImageSource()
    }
    
    @IBAction func btnShareFeedAction(_ sender: UIBarButtonItem) {
        if (txtFeedTitle.text?.trimmingCharacters(in: .whitespaces).count)! <= 0 {
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Empty", message: "Title can not be empty", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
        }else if !isImageChanged {
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Empty", message: "Please choose an image", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
        }else {
            uploadImage()
        }
    }
    
    func optionForImageSource()
    {
        FPSingleton.sharedInstance.showAlertController(message: "Select image source.", inViewController: self) { (selectedButton: NSString) in
            
            //print("Selected Button : ",selectedButton)
            FPSingleton.sharedInstance.delegate = self
            if selectedButton == "Photo Library"
            {
                FPSingleton.sharedInstance.checkPhotoLibraryPermission()
            }
            else if selectedButton == "Capture Photo"
            {
                FPSingleton.sharedInstance.checkCameraPermission()
            }
        }
    }
    
    func presentImagePicker(isForCamera: Bool)  {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        if !isForCamera
        {
            imagePicker.sourceType = .photoLibrary
        }
        else
        {
            if  UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
            }
            else {
                FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Oops...",message: "Camera Not Available", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                
                return
            }
        }
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    fileprivate func startSharingFeedWith(url feedImageUrl: String) {
        let feedId = FPSingleton.sharedInstance.getUniqueId()
        let created = FPSingleton.sharedInstance.getCurrentTimeStamp()
        if feedId.count > 0 {
            if let userId = FPDataModel.userId {
                let feedInfo = createFeedInfoWith(feedId: feedId, created: created, creator: userId, imgUrl: feedImageUrl)
                shareFeed(with: feedInfo, at: feedId)
            }
        }else {
            FPSingleton.sharedInstance.hideActivityIndicator()
           FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Oops...",message: "Unable to share feed right now.", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
        }
    }
    
    fileprivate func createFeedInfoWith(feedId: String, created: u_long, creator: String, imgUrl: String) -> [String : Any] {

        var feedInfoDict = [String : Any]()
        feedInfoDict[kcCreator] = creator
        feedInfoDict[kcCreated] = created
        feedInfoDict[kcTitle] = txtFeedTitle.text?.trimmingCharacters(in: .whitespaces)
        feedInfoDict[kcComment] = txtFeedComment.text?.trimmingCharacters(in: .whitespaces)
        feedInfoDict[kcFeedImageUrl] = imgUrl
        feedInfoDict[kcFeedId] = feedId
        
        return feedInfoDict
    }
    
    fileprivate func shareFeed(with feedInfo: [String : Any], at feedId: String) {
        ref.child(kChild).child(kFeeds).child(feedId).setValue(feedInfo) { (error, databaseRef) in
            if error == nil {
                self.saveFeedId(feedId, in: (feedInfo[kcCreator] as! String), creator: feedInfo[kcCreator] as! String, isForShare: false, at: 0)
            }
        }
    }
    
    fileprivate func saveFeedId(_ feedId: String, in userId: String, creator: String, isForShare: Bool, at index: Int) {
        let feedNode = kFeeds
//        if isForShare {
//            feedNode = kSharedFeeds
//        }
        ref.child(kChild).child(kRegistration).child(userId).child(feedNode).child(feedId).setValue(creator) { (error, databaseRef) in
            if error == nil {
                if self.friendArray.count > 0 {
                    self.saveFeedInFriend(at: index, feedId: feedId)
                }else {
                    FPSingleton.sharedInstance.hideActivityIndicator()
                    self.clearAllFields()
                    FPSingleton.sharedInstance.showToast(message: "Feed shared successfully")
                }
            }
        }
    }
    
    fileprivate func saveFeedInFriend(at index: Int, feedId: String) {
        var newIndex = index
        if newIndex >= friendArray.count {
            FPSingleton.sharedInstance.hideActivityIndicator()
            clearAllFields()
            FPSingleton.sharedInstance.showToast(message: "Feed shared successfully")
            let tokenArray = self.tokens.map { (userInfo) -> String in
                if let fcmToken = userInfo[kFcmToken] as? String {
                    return fcmToken
                }
                return ""
            }
            FPSingleton.sharedInstance.sendPUSHNotification(to: tokenArray, title: "New Post", subtitle: "", body: "One of your friends has uploaded a new post.", data: ["module" : "newPost"])
            return
        }
        newIndex += 1
        
        if let userId = FPDataModel.userId {
            ref.child(kChild).child(kRegistration).child(userId).child(kFriends).child(friendArray[index]).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    self.saveFeedId(feedId, in: self.friendArray[index], creator: userId, isForShare: true, at: newIndex)
                }
            }
        }
    }
    
    private func uploadImage() {
        FPSingleton.sharedInstance.showActivityIndicator()
        
        let originalImageData: Data = (imgFeedImageView.image)!.jpegData(compressionQuality: 0.8)!
        let imgNm = FPSingleton.sharedInstance.getCurrentTimeStamp(withRandom: true)
        let imageName:String = "\(imgNm)"
        
        let storage = Storage.storage()
        
        
        let storageRef = storage.reference()

        if let userId = FPDataModel.userId {
            let originalImagesRef = storageRef.child(kFeedImages).child(userId).child(kcImage).child(imageName)
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            originalImagesRef.putData(originalImageData, metadata: metadata) { (metadata, error) in
                
                if error != nil
                {
                    FPSingleton.sharedInstance.hideActivityIndicator()
                }
                else
                {
                    Analytics.logEvent("Post_Shared", parameters: nil)
                    originalImagesRef.downloadURL(completion: { (url, error) in
                        if error != nil {
                            print(error!.localizedDescription)
                            return
                        }
                        if let feedImageUrl = url?.absoluteString {
                            self.startSharingFeedWith(url: feedImageUrl)
                        }
                    })
                }
            }
        }
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

extension AddFeedViewController: FPSingletonDelegate
{
    //MARK: - Camera and Photo Library Permission Delegate
    
    func userDidAuthorisedPhotoGallaryPermission() {
        presentImagePicker(isForCamera: false)
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
        presentImagePicker(isForCamera: true)
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

extension AddFeedViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //MARK: - Image Picker Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
            imgFeedImageView.image = image
            isImageChanged = true
        }
        NotificationCenter.default.post(name: .imagePickerPresented, object: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: .imagePickerPresented, object: nil)
    }
}

extension AddFeedViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtFeedTitle {
            txtFeedComment.becomeFirstResponder()
        }else {
            textField.resignFirstResponder()
        }
        return true
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
