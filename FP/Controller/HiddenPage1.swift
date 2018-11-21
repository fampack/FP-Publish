//
//  HiddenPage1.swift
//  FP
//
//  Created by Allan Zhang on 20/9/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import Firebase

class HiddenPage1: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.logEvent("Hidden_Page", parameters: nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
