//
//  LoginViewController.swift
//  FP
//
//  Created by Allan Zhang on 13/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class LoginViewController: UIViewController {

    //MARK: - OUTLETS
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    
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
//       sender.isUserInteractionEnabled = false
//        navigationController?.popViewController(animated: true)
    }

    @IBAction func btnSignupAction(_ sender: UIButton) {
        view.endEditing(true)
        manageNavigationStack()
        var signupViewController = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController
        navigationController?.pushViewController(signupViewController!, animated: true)
        signupViewController = nil
    }
    
    @IBAction func btnForgotPassword(_ sender: UIButton) {
        view.endEditing(true)
        var resetPasswordViewController = self.storyboard?.instantiateViewController(withIdentifier: "ResetPasswordViewController") as? ResetPasswordViewController
        navigationController?.pushViewController(resetPasswordViewController!, animated: true)
        resetPasswordViewController = nil
    }
    
    @IBAction func btnLoginAction(_ sender: UIButton) {
        if validateFields() {
            view.endEditing(true)
            let emailId = (txtEmail.text?.trimmingCharacters(in: .whitespaces))!
            if (FPSingleton.sharedInstance.validateEmail(email: emailId as NSString)) {
                self.loginUser(with: emailId)
            }else {
                FPSingleton.sharedInstance.showActivityIndicator()
                self.getUserEmail(by: emailId) { (email) in
                    FPSingleton.sharedInstance.hideActivityIndicator()
                    if email == nil {
                       FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "No such username exist in our database", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                    }else {
                        self.loginUser(with: email!)
                    }
                }//here email id is user name
            }            
        }
    }
            
    //MARK: - Get user Email by User Name
            
    fileprivate func getUserEmail(by userName: String, completion: @escaping (_ email: String?) -> ()) {
        ref.child(kChild).child(kRegistration).queryOrdered(byChild: "\(kUserInfo)/\(kUserName)").queryEqual(toValue: userName).observeSingleEvent(of: .value) { (snapshot) in
            FPSingleton.sharedInstance.hideActivityIndicator()
            if snapshot.exists() {
                var email: String?
                for (_, value) in (snapshot.value as! [String : Any]) {
                    email = (((value as! [String : Any])[kUserInfo] as! [String : Any])[kEmail] as! String)
                }
                completion(email)
            }else {
                completion(nil)
            }
        }
    }
    
    //MARK: - Login User
    
    fileprivate func loginUser(with email: String) {
        let password = (txtPassword.text?.trimmingCharacters(in: .whitespaces))!
        FPSingleton.sharedInstance.showActivityIndicator()
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if error == nil {
                guard let user = user?.user else {
                    FPSingleton.sharedInstance.hideActivityIndicator()
                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Email or username not exist", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                    
                    return
                    
                }
                FPDataModel.userId = user.uid
                var fcmToken = ""
                if let value = FPDataModel.fcmToken {
                    fcmToken = value
                }
                ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kUserInfo).child(kFcmToken).setValue(fcmToken, withCompletionBlock: { (error, databasrRef) in
                    if error == nil {
                        ref.child(kChild).child(kRegistration).child(user.uid).child(kUserInfo).observeSingleEvent(of: .value, with: { (snapshot) in
                            FPSingleton.sharedInstance.hideActivityIndicator()
                            if snapshot.exists() {
                                FPDataModel.userInfo = snapshot.value as? [String : Any]
                            }
                            self.moveToNextVC()
                        })
                    }else {
                        FPSingleton.sharedInstance.hideActivityIndicator()
                    }
                })
            }else {
                FPSingleton.sharedInstance.hideActivityIndicator()
                FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Error", message: "Email and/or Password is wrong", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
            }
        }
    }
    
    //MARK: - Validate TextFields
    
    private func validateFields() -> Bool {
        if (txtEmail.text?.trimmingCharacters(in: .whitespaces).count)! <= 0 {
            txtEmail.text = ""
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Please enter email or username", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
            return false
//        }else if !(FPSingleton.sharedInstance.validateEmail(email: txtEmail.text! as NSString)) {
//            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert",message: "The email is not a valid email address.", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
//            return false
        }else if (txtPassword.text?.trimmingCharacters(in: .whitespaces).count)! <= 0 {
            txtPassword.text = ""
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Please enter password", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
            return false
        }
        return true
    }
    
    //MARK: - Move To Next VC
    
    fileprivate func moveToNextVC() {
        let tabBarViewController = self.storyboard?.instantiateViewController(withIdentifier: "TabBarViewController") as! TabBarViewController
        
        appDelegate.swapRootViewControllerWithAnimation(newViewController: tabBarViewController, animationType: .Present)
    }
    
    //MARK: - Manage Navigation Stack
    
    private func manageNavigationStack() {
        if let viewControllers = self.navigationController?.viewControllers
        {
            navigationController?.viewControllers = viewControllers.filter {!($0 is SignupViewController)}
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

extension LoginViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtEmail {
            txtPassword.becomeFirstResponder()
        }else {
            textField.resignFirstResponder()
        }
        return true
    }
}
