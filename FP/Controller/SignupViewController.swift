//
//  SignupViewController.swift
//  FP
//
//  Created by Allan Zhang on 13/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignupViewController: UIViewController {

    //MARK: - OUTLETS
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtRetypePassword: UITextField!
    
    
    //MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UIButton Action
    
    @IBAction func btnBackAction(_ sender: UIButton) {
//        sender.isUserInteractionEnabled = false
//        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnLoginAction(_ sender: UIButton) {
        view.endEditing(true)
        manageNavigationStack()
        var loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
        navigationController?.pushViewController(loginViewController!, animated: true)
        loginViewController = nil
    }
    
    @IBAction func btnRegisterAction(_ sender: UIButton) {
        if validateFields() {
            view.endEditing(true)
            let emailId = (txtEmail.text?.trimmingCharacters(in: .whitespaces))!
            let password = (txtPassword.text?.trimmingCharacters(in: .whitespaces))!
            FPSingleton.sharedInstance.showActivityIndicator()
            Auth.auth().createUser(withEmail: emailId, password: password) { (authResult, error) in
                // ...
                
                guard let user = authResult?.user else {
                    FPSingleton.sharedInstance.hideActivityIndicator()
                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "This email is already registered with us.", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                    
                    return
                    
                }
                
               let userInfoDict = self.createUserInfo(user: user)
                ref.child(kChild).child(kRegistration).child(user.uid).child(kUserInfo).setValue(userInfoDict) { (error, databaseRef) in
                    FPSingleton.sharedInstance.hideActivityIndicator()
                    if error != nil {
                        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Something went wrong", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                    }
                    else {
                        FPDataModel.userId = user.uid
                        FPDataModel.userInfo = userInfoDict
                        FPSingleton.sharedInstance.showToast(message: "Registered Successfuly")
                        self.performSegue(withIdentifier: "username", sender: nil)
                    }
                }
            }
        }
    }
    
    //MARK: - Create User Info
    
    fileprivate func createUserInfo(user: User) -> [String : Any] {
        var userInfoDict = [String : Any]()
        userInfoDict[kUserName] = user.email ?? ""
        userInfoDict[kEmail] = user.email ?? ""
        userInfoDict[kAvatarURL] = ""
        userInfoDict[kUserId] = user.uid
        userInfoDict[kcFriendCount] = "0"
        userInfoDict[kFcmToken] = ""
        if let fcmToken = FPDataModel.fcmToken {
            userInfoDict[kFcmToken] = fcmToken
        }
        
        return userInfoDict
    }
    
    //MARK: - Validate TextFields
    
    private func validateFields() -> Bool {
        if (txtEmail.text?.trimmingCharacters(in: .whitespaces).count)! <= 0 {
            txtEmail.text = ""
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Please enter email", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
            return false
        }else if !(FPSingleton.sharedInstance.validateEmail(email: txtEmail.text! as NSString)) {
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert",message: "The email is not a valid email address.", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
            return false
        }else if (txtPassword.text?.trimmingCharacters(in: .whitespaces).count)! <= 0 {
            txtPassword.text = ""
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Please enter password", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
            return false
        }else if (txtPassword.text?.trimmingCharacters(in: .whitespaces).count)! < 6 {
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Password should be atleast 6 character in length", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
            return false
        }else if (txtRetypePassword.text?.trimmingCharacters(in: .whitespaces).count)! <= 0 {
            txtRetypePassword.text = ""
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Please fill retype password", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
            return false
        }else if (txtPassword.text?.trimmingCharacters(in: .whitespaces))! != (txtRetypePassword.text?.trimmingCharacters(in: .whitespaces))! {
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Password mismatch.\n Password and Retype Password must be same", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
            return false
        }
        return true
    }
    
    //MARK: - Move to Next VC
    
    fileprivate func moveToNextVC() {
        var userInfoViewController = self.storyboard?.instantiateViewController(withIdentifier: "UserInfoViewController") as? UserInfoViewController
        navigationController?.pushViewController(userInfoViewController!, animated: true)
        userInfoViewController = nil
    }
    
    //MARK: - Manage Navigation Stack
    
    private func manageNavigationStack() {
        if let viewControllers = self.navigationController?.viewControllers
        {
            navigationController?.viewControllers = viewControllers.filter {!($0 is LoginViewController)}
        }
    }
    
    // MARK: - Touch Began
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        view.endEditing(true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
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

extension SignupViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtEmail {
            txtPassword.becomeFirstResponder()
        }else if textField == txtPassword {
            txtRetypePassword.becomeFirstResponder()
        }else {
            textField.resignFirstResponder()
        }
        return true
    }
}
