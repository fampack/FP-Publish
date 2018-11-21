//
//  AppDelegate.swift
//  FP
//
//  Created by Allan Zhang on 13/08/18.
//  Copyright © 2018 Allan Zhang. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseMessaging
import UserNotifications
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        // For iOS 10 data message (sent via FCM
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        Fabric.with([Crashlytics.self])
        UIButton.appearance().isExclusiveTouch = true;
        UINavigationBar.appearance().isTranslucent = false
        
        if FPDataModel.userId == nil {
            setInitialViewController("IntroductionPageOne", isForHome: false)
        }else {
            setInitialViewController("TabBarViewController", isForHome: true)
        }
//        HomeViewController
        registerForRemoteNotification()
        
        GADMobileAds.configure(withApplicationID: "ca-app-pub-5181179741663920~8177182506")

        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack
    
    /**
     
     -  Returns the URL to the application's Documents directory.
     -   The directory the application uses to store the Core Data store file.
     */
    
    open lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    /**
     
     -   The managed object model for the application.
     
     */
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        let modelURL = Bundle.main.url(forResource: "ChatDB", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    /**
     
     -   Create the coordinator and store
     
     */
    
    open lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("ChatDB.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                               configurationName: nil,
                                               at: url, options: nil)
        } catch {
            // Report any error we got.
            abort()
        }
        
        return coordinator
    }()
    
    /**
     
     -   Returns the managed object context for the application
     
     */
    
    open lazy var managedObjectContext: NSManagedObjectContext? = {
        
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "ChatDB")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext ()  {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    //MARK: - Register For Remote Notification
    
    fileprivate func registerForRemoteNotification() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {(granted, error) in
                    guard granted else { return }
                    self.getNotificationSettings()
            })
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
    }
    
    func getNotificationSettings() {
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
        }
    }
    
    //MARK: - Set Initial View Controller
    
    public func setInitialViewController(_ viewCotroller:String, isForHome: Bool)  {
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if isForHome
        {
            let initialViewController = storyboard.instantiateViewController(withIdentifier: viewCotroller) as! TabBarViewController
        initialViewController.navigationController?.navigationBar.isHidden = false
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
        }
        else
        {
            let initialViewController = storyboard.instantiateViewController(withIdentifier: viewCotroller)
            
            let navigationController = UINavigationController.init(rootViewController: initialViewController)
            
            initialViewController.navigationController?.navigationBar.isHidden = true
            
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()
        }
    }
    
    //MARK: - Change to TabBar Controller
    
    public enum SwapRootVCAnimationType {
        case Push
        case Pop
        case Present
        case Dismiss
    }
    
    public func swapRootViewControllerWithAnimation(newViewController:UIViewController, animationType:SwapRootVCAnimationType, completion: (() -> ())? = nil)
    {
        guard let currentViewController = UIApplication.shared.delegate?.window??.rootViewController else {
            return
        }
        
        let width = currentViewController.view.frame.size.width;
        let height = currentViewController.view.frame.size.height;
        
        var newVCStartAnimationFrame: CGRect?
        var currentVCEndAnimationFrame:CGRect?
        
        var newVCAnimated = true
        
        switch animationType
        {
        case .Push:
            newVCStartAnimationFrame = CGRect(x: width, y: 0, width: width, height: height)
            currentVCEndAnimationFrame = CGRect(x: 0 - width/4, y: 0, width: width, height: height)
        case .Pop:
            currentVCEndAnimationFrame = CGRect(x: width, y: 0, width: width, height: height)
            newVCStartAnimationFrame = CGRect(x: 0 - width/4, y: 0, width: width, height: height)
            newVCAnimated = false
        case .Present:
            newVCStartAnimationFrame = CGRect(x: 0, y: height, width: width, height: height)
        case .Dismiss:
            currentVCEndAnimationFrame = CGRect(x: 0, y: height, width: width, height: height)
            newVCAnimated = false
        }
        
        newViewController.view.frame = newVCStartAnimationFrame ?? CGRect(x: 0, y: 0, width: width, height: height)
        
        self.window?.addSubview(newViewController.view)
        
        if !newVCAnimated {
            self.window?.bringSubviewToFront(currentViewController.view)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            if let currentVCEndAnimationFrame = currentVCEndAnimationFrame {
                currentViewController.view.frame = currentVCEndAnimationFrame
            }
            
            newViewController.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }, completion: { finish in
            self.window?.rootViewController = newViewController
            completion?()
        })
        
        self.window?.makeKeyAndVisible()
    }

}


extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        FPDataModel.fcmToken = fcmToken
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .sound, .badge])
    }
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Swift.Void)
    {
        if FPDataModel.userId != nil {
            let topController = UIApplication.topViewController()
            let notificationData = response.notification.request.content.userInfo
            var dataDict: [String : Any]? = [String : Any]()
            if let value = notificationData["gcm.notification.data"] as? [String : Any] {
                dataDict = value
            }else if let value = notificationData["gcm.notification.data"] as? String {
                dataDict = self.convertToDictionary(text: value)
            }
            if dataDict != nil {
                if dataDict!.count > 0 {
                    let module = dataDict!["module"] as! String
                    switch module {
                    case "chat":
                        if (window?.rootViewController as? UITabBarController) != nil
                        {
                            if topController != nil {
                                if !(topController is ChatDetailsViewController)
                                {
                                    goToChatDetails(with: dataDict! , controller: topController!)
                                }
                            }
                        }
                        break
                    case "newFriendRequest":
                        if let tabBarController = (window?.rootViewController as? UITabBarController)
                        {
                            if tabBarController.selectedIndex != 4 {
                                tabBarController.selectedIndex = 4
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25){
                                    
                                    if (tabBarController.selectedViewController as? UINavigationController) != nil {
                                        if let profileViewController = (tabBarController.selectedViewController as! UINavigationController).topViewController as? ProfileViewController {
                                            profileViewController.pageController.setViewControllers([profileViewController.getViewControllerAtIndex(1)] as [UIViewController], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
                                        }
                                    }
                                    
                                }
                                
                                
                            }
                        }
                        break
                    case "newPost":
                        if let tabBarController = (window?.rootViewController as? UITabBarController)
                        {
                            if tabBarController.selectedIndex != 0 {
                                tabBarController.selectedIndex = 0
                            }
                        }
                        break
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func goToChatDetails(with data: [AnyHashable : Any], controller: UIViewController) {
        var chatDetailsViewController = controller.storyboard?.instantiateViewController(withIdentifier: "ChatDetailsViewController") as? ChatDetailsViewController
        chatDetailsViewController?.conversationId = data["convoId"] as? String ?? ""
        chatDetailsViewController?.otherUserImageUrl = data["senderImageURL"] as? String ?? ""
        chatDetailsViewController?.otherUserName = data["senderName"] as? String ?? ""
        chatDetailsViewController?.otherUserId = data["senderId"] as! String
        chatDetailsViewController?.userId = data["receiverId"] as! String
        chatDetailsViewController?.userName = data["receiverName"] as? String ?? ""
        controller.navigationController?.pushViewController(chatDetailsViewController!, animated: true)
        chatDetailsViewController = nil
    }
}

