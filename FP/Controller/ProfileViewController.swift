//
//  ProfileViewController.swift
//  FP
//
//  Created by Allan Zhang on 15/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var imgUserImageView: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    @IBOutlet weak var lblNumberOfFriend: UILabel!
    @IBOutlet weak var secretButton: UIButton!
    
    var pageController = UIPageViewController()
    var userInfoDict = [String : Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        createPageViewController()
        setNavigationBar()
        setupView()
        addObserver()
        secretButton.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        

        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func createPageViewController() {
        
        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.view.frame = containerView.bounds
        pageController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.addChild(pageController)
        containerView.addSubview(pageController.view)
        pageController.didMove(toParent: self)
        
        pageController.setViewControllers([getViewControllerAtIndex(0)] as [UIViewController], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
        
    }
    
    
    func getViewControllerAtIndex(_ index: Int ) -> UIViewController
    {
        
        switch index {
            
        case 0: // My Feed
            
            segmentControl.selectedSegmentIndex = 0
            let myFeedViewController = self.storyboard?.instantiateViewController(withIdentifier: "MyFeedViewController") as! MyFeedViewController
            
            myFeedViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            return myFeedViewController
            
        default: // Friend List
            
            segmentControl.selectedSegmentIndex = 1
            let friendListViewController = self.storyboard?.instantiateViewController(withIdentifier: "FriendListViewController") as! FriendListViewController
            
            return friendListViewController
            
        }
        
    }
    
    //MARK: - Set Navigation Bar
    
    /**
     This method set up Navigation Bar appearance
     
     */
    
    func setNavigationBar()
    {
        self.title = ""
        navigationItem.title = "Profile"        
        let leftBarButton = UIBarButtonItem(title: "Edit Profile", style: .plain, target: self, action: #selector(btnEditProfileAction))
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let rightButton  = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0))
        rightButton.setImage(#imageLiteral(resourceName: "logout"), for: .normal)
        rightButton.addTarget(self, action: #selector(btnLogoutAction), for: .touchUpInside)
        
        let rightBarButton = UIBarButtonItem(customView: rightButton)
        
        navigationItem.setLeftBarButtonItems([leftBarButton, flexibleSpace], animated: false)
        navigationItem.setRightBarButtonItems([rightBarButton, flexibleSpace], animated: false)
    }
    
    private func setupView() {
        view.layoutIfNeeded()
        
        imgUserImageView.layer.cornerRadius = imgUserImageView.frame.size.height/2.0
        imgUserImageView.clipsToBounds = true
    }
    
    fileprivate func addObserver() {
        if let userId = FPDataModel.userId {
            FPSingleton.sharedInstance.showActivityIndicator()
            ref.child(kChild).child(kRegistration).child(userId).child(kUserInfo).observe(.value) { (snapshot) in
                FPSingleton.sharedInstance.hideActivityIndicator()
                if snapshot.exists() {
                    self.userInfoDict = snapshot.value as! [String : Any]
                    
                    self.updateUserSection()
                }
            }
            
            ref.child(kChild).child(kRegistration).child(userId).child(kFriends).queryOrderedByValue().queryEqual(toValue: true).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    let totalAcceptedFriend = snapshot.childrenCount
                    var strFriend = "friend"
                    if totalAcceptedFriend > 1 {
                        strFriend = "friends"
                    }
                    if totalAcceptedFriend < 20 {
                        self.lblNumberOfFriend.font = UIFont(name: "Helvetica Neue", size: 14)
                        self.lblNumberOfFriend.text = String(format: "You have added %d %@, you can add %d more...", totalAcceptedFriend, strFriend, (20 - totalAcceptedFriend))
                    }else {
                        self.lblNumberOfFriend.font = UIFont(name: "Chalkduster", size: 16)
                        self.lblNumberOfFriend.text = "Congrats😆"
                        self.secretButton.isHidden = false
                    }
                }
            }
        }
    }
    
    fileprivate func updateUserSection() {
        if let urlString = userInfoDict[kAvatarURL] {
            if (urlString as! String).count > 0 {
                imgUserImageView.sd_setImage(with: URL(string: (urlString as! String)), placeholderImage: #imageLiteral(resourceName: "user"), options: .highPriority) { (image, error, cacheType, url) in
                    
                }
            }
        }
        if (userInfoDict[kUserName] as! String).count > 0 {
            lblUserName.text = userInfoDict[kUserName] as? String
        }else {
            lblUserName.text = userInfoDict[kEmail] as? String
        }
        lblEmail.text = userInfoDict[kEmail] as? String
    }
    
    @objc private func btnEditProfileAction() {
        var editProfileViewController = self.storyboard?.instantiateViewController(withIdentifier: "EditProfileViewController") as? EditProfileViewController
        editProfileViewController?.userProfileDict = userInfoDict
        navigationController?.pushViewController(editProfileViewController!, animated: true)
        editProfileViewController = nil
    }
    
    @objc private func btnLogoutAction() {
        FPSingleton.sharedInstance.showAlertWithMultipleButtons(title: "Logout", message: "Are you sure you want to logout?", inViewController: self, buttonOneCaption: "Yes", buttonTwoCaption: "No", multipleButtons: true) { (isLogoutPressed) in
            if isLogoutPressed {
               self.logoutFromFirebase()
            }
        }
        
    }
    
    fileprivate func logoutFromFirebase() {
        let firebaseAuth = Auth.auth()
        do {
            ref.child(kChild).child(kRegistration).child((FPDataModel.userId)!).child(kUserInfo).child(kFcmToken).setValue("")
            try firebaseAuth.signOut()
            FPDataModel.userId = nil
            FPDataModel.userInfo = nil
            
            appDelegate.setInitialViewController("HomeViewController", isForHome: false)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    @IBAction func segmentControlAction(_ sender: UISegmentedControl) {
        segmentChanged(sender: sender)
    }
    
    func segmentChanged(sender: UISegmentedControl)
    {
        if sender.selectedSegmentIndex == 1
        {
            pageController.setViewControllers([getViewControllerAtIndex(sender.selectedSegmentIndex)] as [UIViewController], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
        }
        else
        {
            pageController.setViewControllers([getViewControllerAtIndex(sender.selectedSegmentIndex)] as [UIViewController], direction: UIPageViewController.NavigationDirection.reverse, animated: true, completion: nil)
        }
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
