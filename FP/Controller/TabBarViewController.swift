//
//  TabBarViewController.swift
//  FP
//
//  Created by Allan Zhang on 14/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {

    var nav1: UINavigationController!
    var nav2: UINavigationController!
    var nav3: UINavigationController!
    var nav4: UINavigationController!
    var nav5: UINavigationController!
    
    // MARK: - Views Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.delegate = self
        self.tabBar.tintColor = APP_DEEP_MAROON_COLOR
        if #available(iOS 10.0, *) {
            self.tabBar.unselectedItemTintColor = APP_LIGHT_GRAY_COLOR
        }
        
         let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
         let feedViewController = storyboard.instantiateViewController(withIdentifier: "FeedViewController") as! FeedViewController
        
         let conversationViewController = storyboard.instantiateViewController(withIdentifier: "ConversationViewController") as! ConversationViewController
        
         let addFeedViewController = storyboard.instantiateViewController(withIdentifier: "AddFeedViewController") as! AddFeedViewController
        
         let searchViewController = storyboard.instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
        
        
         let profileViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
 
        
        nav1 = UINavigationController(rootViewController: feedViewController)
        nav2 = UINavigationController(rootViewController: conversationViewController)
        nav3 = UINavigationController(rootViewController: addFeedViewController)
        nav4 = UINavigationController(rootViewController: searchViewController)
        nav5 = UINavigationController(rootViewController: profileViewController)
        
        self.viewControllers = [nav1,nav2,nav3,nav4,nav5]
        
        let item1 = UITabBarItem(title: "", image: #imageLiteral(resourceName: "Feed"), tag: 1)
        let item2 = UITabBarItem(title: "", image: #imageLiteral(resourceName: "Chat"), tag: 2)
        let item3 = UITabBarItem(title: "", image: #imageLiteral(resourceName: "AddFeed"), tag: 3)
        let item4 = UITabBarItem(title: "", image: #imageLiteral(resourceName: "Search"), tag: 4)
        let item5 = UITabBarItem(title: "", image: #imageLiteral(resourceName: "Profile"), tag: 5)

        
        
        feedViewController.tabBarItem = item1
        conversationViewController.tabBarItem = item2
        addFeedViewController.tabBarItem = item3
        searchViewController.tabBarItem = item4
        profileViewController.tabBarItem = item5
        
        feedViewController.tabBarItem.imageInsets=UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        conversationViewController.tabBarItem.imageInsets=UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        addFeedViewController.tabBarItem.imageInsets=UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        searchViewController.tabBarItem.imageInsets=UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        profileViewController.tabBarItem.imageInsets=UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        
        nav1.isNavigationBarHidden = false;
        nav2.isNavigationBarHidden = false;
        nav3.isNavigationBarHidden = false;
        nav4.isNavigationBarHidden = false;
        nav5.isNavigationBarHidden = false;

    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
    }

    // MARK: - Memory Warning
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Tab Bar Delegates
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem)
    {
         self.tabBar.isHidden = false
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController)
    {

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
