//
//  UserInfoViewController.swift
//  FP
//
//  Created by Allan Zhang on 13/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit

class UserInfoViewController: UIViewController {

    //MARK: - OUTLETS
    
    @IBOutlet weak var txtUserName: UITextField!
    
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
    
    @IBAction func btnContinueAction(_ sender: UIButton) {
        if validateFields() {
            view.endEditing(true)
            if let userId = FPDataModel.userId {
               let userName = (txtUserName.text?.trimmingCharacters(in: .whitespaces))!
               sender.isUserInteractionEnabled = false
                
                ref.child(kChild).child(kRegistration).queryOrdered(byChild: "\(kUserInfo)/\(kUserName)").queryEqual(toValue: userName).observeSingleEvent(of: .value) { (snapshot) in
                    if snapshot.exists() {
                        FPSingleton.sharedInstance.hideActivityIndicator()
                        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "This user name is already taken please try with different user name", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                    }else {
                        ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).child(kUserName).setValue(userName){ (error, databaseRef) in
                            sender.isUserInteractionEnabled = true
                            if error == nil {
                                if var userInfo = FPDataModel.userInfo {
                                    userInfo[kUserName] = userName
                                    FPDataModel.userInfo = userInfo
                                }
                                self.moveToNextVC()
                            }else {
                                FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Unable to save", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func btnSkipAction(_ sender: UIButton) {
        view.endEditing(true)
        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Skip", message: "Your username will be set as your email address, are you sure?", inViewController: self, buttonOneCaption: "Yes", buttonTwoCaption: "No", multipleButtons: true) { (isYesPressed) in
            if isYesPressed {
                self.moveToNextVC()
            }
        }
    }
    
    //MARK: - Validation
    
    private func validateFields() -> Bool {
        if (txtUserName.text?.trimmingCharacters(in: .whitespaces).count)! <= 0 {
            txtUserName.text = ""
            FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Alert", message: "Please enter user name", inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
            return false
        }
        return true
    }
    
    //MARK: - Move To Next VC
    
    fileprivate func moveToNextVC() {
        let tabBarViewController = self.storyboard?.instantiateViewController(withIdentifier: "TabBarViewController") as! TabBarViewController
        
        appDelegate.swapRootViewControllerWithAnimation(newViewController: tabBarViewController, animationType: .Present)
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

extension UserInfoViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
