//
//  ResetPasswordViewController.swift
//  FP
//
//  Created by Allan Zhang on 13/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import FirebaseAuth

class ResetPasswordViewController: UIViewController {

    //MARK: - OUTLETS
    
    @IBOutlet weak var txtEmail: UITextField!
    
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
        sender.isUserInteractionEnabled = false
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnResetPasswordAction(_ sender: UIButton) {
        if validateFields() {
            view.endEditing(true)
            let emailId = (txtEmail.text?.trimmingCharacters(in: .whitespaces))!
            sender.isUserInteractionEnabled = false
            FPSingleton.sharedInstance.showActivityIndicator()
            Auth.auth().sendPasswordReset(withEmail: emailId) { error in
                FPSingleton.sharedInstance.hideActivityIndicator()
                if error != nil {
                    sender.isUserInteractionEnabled = true
                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Error", message: (error?.localizedDescription)!, inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: nil)
                }else {
                    FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Success", message: String(format:"A link is sent to %@. Please follow link to Reset your password", emailId), inViewController: self, buttonOneCaption: "Ok", buttonTwoCaption: "", multipleButtons: false, completion: { (success) in
                        if success {
                            sender.isUserInteractionEnabled = true
                            self.navigationController?.popViewController(animated: true)
                        }
                    })
                }
            }
        }
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
        }
        return true
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

extension ResetPasswordViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
