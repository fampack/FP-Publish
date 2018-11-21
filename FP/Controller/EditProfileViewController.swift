//
//  EditProfileViewController.swift
//  FP
//
//  Created by Allan Zhang on 16/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import FirebaseStorage
import Firebase
import GoogleMobileAds

class EditProfileViewController: UIViewController {

    @IBOutlet weak var profileAd: GADBannerView!
    @IBOutlet weak var imgUserImageView: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var txtUserName: UITextField!
    @IBOutlet weak var btnUploadImage: UIButton!
    
    var isImageChanged = false
    var isDataChange = false
    var userProfileDict = [String : Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setNavigationBar()
        setupView()
        updateUI()
        profileAd.adUnitID = "ca-app-pub-5181179741663920/6588768663"
        profileAd.rootViewController = self
        profileAd.load(GADRequest())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Set Navigation Bar
    
    /**
     This method set up Navigation Bar appearance
     
     */
    
    func setNavigationBar()
    {
        self.title = ""
        navigationItem.title = "Edit Profile"
        let leftBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(btnCancelAction))
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let rightBarButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(btnSaveAction))
        
        navigationItem.setLeftBarButtonItems([leftBarButton, flexibleSpace], animated: false)
        navigationItem.setRightBarButtonItems([rightBarButton, flexibleSpace], animated: false)
    }
    
    fileprivate func updateUI() {
        if userProfileDict.count > 0 {
            if let urlString = userProfileDict[kAvatarURL] {
                if (urlString as! String).count > 0 {
                    imgUserImageView.sd_setImage(with: URL(string: (urlString as! String)), placeholderImage: #imageLiteral(resourceName: "user"), options: .highPriority) { (image, error, cacheType, url) in
                        
                    }
                }
            }
            
            lblUserName.text = String(format: "Current Username: %@", userProfileDict[kUserName] as! String)
            txtUserName.text = userProfileDict[kUserName] as? String
        }
    }
    
    @objc private func btnCancelAction() {
        goBack()
    }
    
    fileprivate func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func btnSaveAction() {
        
        let newUserName = txtUserName.text?.trimmingCharacters(in: .whitespaces)
        if newUserName != lblUserName.text?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) {
           isDataChange = true
            
            FPSingleton.sharedInstance.showActivityIndicator()
            ref.child(kChild).child(kRegistration).queryOrdered(byChild: "\(kUserInfo)/\(kUserName)").queryEqual(toValue: newUserName).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    FPSingleton.sharedInstance.hideActivityIndicator()
                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "This user name is already taken please try with different user name", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                }else {
                    if self.isImageChanged {
                        self.uploadImage()
                    }else {
                        self.updateProfile()
                    }
                }
            }
        }else {
            if self.isImageChanged {
                FPSingleton.sharedInstance.showActivityIndicator()
                self.uploadImage()
            }else {
                self.goBack()
            }
        }
    }
    
    private func setupView() {
        view.layoutIfNeeded()
        
        FPSingleton.sharedInstance.addCornerRadiusWithBorder(button: imgUserImageView, cornerRadius: imgUserImageView.frame.size.height/2.0, borderWidth: 0.0, borderColor: nil)
    }
    
    @IBAction func btnUploadImageAction(_ sender: UIButton) {
        view.endEditing(true)
        optionForImageSource()
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
                FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert",message: "Camera Not Available", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                
                return
            }
        }
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func uploadImage() {
        
        let originalImageData: Data = (imgUserImageView.image)!.jpegData(compressionQuality: 0.8)!
        let imgNm = FPSingleton.sharedInstance.getCurrentTimeStamp()
        let imageName:String = "\(imgNm)"
        
        let storage = Storage.storage()
        
        
        let storageRef = storage.reference()
        //_conversationInfo[kConversationId]
        if let userId = FPDataModel.userId {
            let originalImagesRef = storageRef.child(kUserImage).child(userId).child(kcImage).child(imageName)
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            originalImagesRef.putData(originalImageData, metadata: metadata) { (metadata, error) in
                
                if error != nil
                {
                    FPSingleton.sharedInstance.hideActivityIndicator()
                }
                else
                {
                    
                    originalImagesRef.downloadURL(completion: { (url, error) in
                        if error != nil {
                            FPSingleton.sharedInstance.hideActivityIndicator()
                            print(error!.localizedDescription)
                            return
                        }
                        if let profileImageUrl = url?.absoluteString {
                            
                            self.saveImageUrl(profileImageUrl)
                            if self.isDataChange {
                                self.updateProfile()
                            }
                        }else {
                            FPSingleton.sharedInstance.hideActivityIndicator()
                        }
                    })
                    
                    //                originalPath = (metadata?.downloadURL()?.description)!
                    
                    
                }
            }
        }
    }
    
    fileprivate func saveImageUrl(_ url: String) {
        if let userId = FPDataModel.userId {
            ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).child(kAvatarURL).setValue(url) { (error, databaseRef) in
                FPSingleton.sharedInstance.hideActivityIndicator()
                if error == nil {
                    if var userInfo = FPDataModel.userInfo {
                        userInfo[kAvatarURL] = url
                        FPDataModel.userInfo = userInfo
                    }
                    if !(self.isDataChange) {
                        FPSingleton.sharedInstance.showToast(message: "Profile saved successfully")
                        self.goBack()
                    }
                }
            }
        }else {
            FPSingleton.sharedInstance.hideActivityIndicator()
        }
    }
    
    fileprivate func updateProfile() {
        if let userId = FPDataModel.userId {
           
           let userName = (txtUserName.text?.trimmingCharacters(in: .whitespaces))!
            ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).child(kUserName).setValue(userName) { (error, databaseRef) in
                FPSingleton.sharedInstance.hideActivityIndicator()
                if error == nil {
                    FPSingleton.sharedInstance.showToast(message: "Profile saved successfully")
                    self.goBack()
                }else {
                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Error", message: (error?.localizedDescription)!, inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
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

extension EditProfileViewController: FPSingletonDelegate
{
    //MARK: - Camera and Photo Library Permission Delegate
    
    func userDidAuthorisedPhotoGallaryPermission() {
        presentImagePicker(isForCamera: false)
    }
    
    func userDidDeniedPhotoGallaryPermission() {
        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Permission is blocked.\nPlease tap on settings and allow FP to access your Photos", inViewController: self, buttonOneCaption: "Cancel", buttonTwoCaption: "Settings", multipleButtons: true) { (bool) in
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
        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Permission is blocked.\nPlease tap on settings and allow FP to access your Camera", inViewController: self, buttonOneCaption: "Cancel", buttonTwoCaption: "Settings", multipleButtons: true) { (bool) in
            if !(bool)
            {
                let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)! as URL
                UIApplication.shared.open(settingsUrl, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler:{ (success) in
                    
                })
            }
        }
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    //MARK: - Image Picker Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
            imgUserImageView.image = image
            isImageChanged = true
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        dismiss(animated: true, completion: nil)
    }
}

extension EditProfileViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
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
