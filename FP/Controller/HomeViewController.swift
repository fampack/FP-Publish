//
//  HomeViewController.swift
//  FP
//
//  Created by Allan Zhang on 13/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

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
    
    @IBAction func btnSignUpAction(_ sender: UIButton) {        
        var signupViewController = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController
        navigationController?.pushViewController(signupViewController!, animated: true)
        signupViewController = nil
    }
    
    @IBAction func btnLoginAction(_ sender: UIButton) {
        var loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
        navigationController?.pushViewController(loginViewController!, animated: true)
        loginViewController = nil
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
