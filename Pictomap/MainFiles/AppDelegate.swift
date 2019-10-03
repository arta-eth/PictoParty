//
//  AppDelegate.swift
//  Pictomap
//
//  Created by Artak on 2018-05-13.
//  Copyright © 2018 ARTACORP. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import UserNotifications
import SwiftKeychainWrapper
import OneSignal
import Crashlytics



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate{
    
    var window: UIWindow?
    var date = String()
    var address = String()
    var city = String()
    var other = String()
    var name = String()
    var user = String()
    

    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Replace 'YOUR_APP_ID' with your OneSignal App ID.
        
      
        
        OneSignal.initWithLaunchOptions(launchOptions, appId: "b9ee51a2-c6d6-4b01-bb32-bb79ea09de89", handleNotificationReceived: {
            (notification) in
            if let notification = notification {
                //let title = notification.payload.title
                //let body = notification.payload.body
                
                if let notifType = notification.payload.title{
                    if let additionalData = notification.payload.additionalData {
                        
                        switch notifType{
                        case "New Follower":
                            self.user = additionalData["userID"] as! String
                            
                            //self.party.uid = self.user
                            
                            
                        case "New Party":
                            //self.address = additionalData["address"] as! String
                            //self.city = additionalData["city"] as! String
                            //self.date = additionalData["date"] as! String
                            print(self.date)
                            print(self.city)
                            print(self.address)
                            //self.party.address = self.address
                            //self.party.city = self.city
                            //self.party.date = self.date
                            
                            
                        default: break
                        }
                    }
                }
            }
        }, handleNotificationAction: {
            (result) in
            if let result = result {
                
                print("clicked")
                
                let sb = UIStoryboard(name: "Profile", bundle: nil)
                let yourViewController = sb.instantiateViewController(withIdentifier: "RootVC") as! TabBarVC
                
                if let additionalData = result.notification.payload.additionalData {
                    
                    switch result.notification.payload.title{
                        
                    case "New Follower":
                        print(result.notification.payload.title ?? "")
                        
                        //let new = yourViewController.viewControllers![3] as? UINavigationController
                        
                        //let child = new?.viewControllers.first as? UserViewController
                        
                        //child?.party.uid = additionalData["userID"] as! String
            
                        
                        yourViewController.selectedIndex = 3
                        self.window?.rootViewController = yourViewController
                        self.window?.makeKeyAndVisible()
                        
                        
                    case "New Party":
                        
                        print(result.notification.payload.title ?? "")
                        self.address = additionalData["address"] as! String
                        self.city = additionalData["city"] as! String
                        self.date = additionalData["date"] as! String
                        
                        print(self.date)
                        print(self.city)
                        print(self.address)
                        
                        yourViewController.selectedIndex = 0
                        
                        self.window?.rootViewController = yourViewController
                        self.window?.makeKeyAndVisible()
                        
                    default: break
                    }
                    
                    
                }
            }
        }, settings: [kOSSettingsKeyInAppLaunchURL: false, kOSSettingsKeyInFocusDisplayOption: OSNotificationDisplayType.none.rawValue])
        
        
        // Recommend moving the below line to prompt for push after informing the user about
        //   how your app will use them.
        
        
        FirebaseApp.configure()
        let settings = FirestoreSettings()
        
        settings.isPersistenceEnabled = true
        
        
        // Any additional options
        // ...
        
        // Enable offline data persistence
        let db = Firestore.firestore()
        db.settings = settings
        //Crashlytics.sharedInstance().crash()

        // Override point for customization after application launch.
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()

        let device = UIDevice.modelName
        print(device)
        UserDefaults.standard.set(device, forKey: "currentDevice")
        checkApp()
        return true
    }
    
    func checkAccount(window: UIWindow, noAccViewController: UIViewController, hasAccViewController: UIViewController){
        
        print("checking")
        let user = Auth.auth().currentUser
        user?.getIDTokenForcingRefresh(true) { (idToken, error) in
            if error?.localizedDescription == "There is no user record corresponding to this identifier. The user may have been deleted."{
                do{
                    print(error?.localizedDescription ?? "")
                    try Auth.auth().signOut()
                    let domain = Bundle.main.bundleIdentifier!
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                    KeychainWrapper.standard.removeAllKeys()
                }catch{}
                
                window.rootViewController = noAccViewController
                self.window?.makeKeyAndVisible()
            }
            else{
                window.rootViewController = hasAccViewController
                self.window?.makeKeyAndVisible()
            }
        }
    }
    
    func checkApp(){
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let signedInStoryboard = UIStoryboard(name: "LoadOnSignIn", bundle: nil)
        let noAccViewController = mainStoryboard.instantiateViewController(withIdentifier: "noAccVC")
        let hasAccViewController = signedInStoryboard.instantiateViewController(withIdentifier: "hasAccVC")
        if UserDefaults.standard.bool(forKey: "hasRunBefore") == false {
            print("The app is launching for the first time. Setting User Information")
            do {
                try Auth.auth().signOut()
                print("User Deleted App")
                UserDefaults.standard.set(true, forKey: "FirstTimeCam")
                UserDefaults.standard.set(true, forKey: "FirstTimePhoto")
                UserDefaults.standard.set(true, forKey: "FirstTimeLoc")

                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                let success = KeychainWrapper.standard.removeAllKeys()
                print(success)
                OneSignal.setSubscription(false)
            }catch {}
            // Update the flag indicator
            self.window?.rootViewController = noAccViewController
            self.window?.makeKeyAndVisible()
        } else {
            print("The app has been launched before. Loading User Information...")
            let user = Auth.auth().currentUser
            print(user?.uid ?? "")
            if(user != nil){
                print("has acc")
                //checkAccount(window: self.window!, noAccViewController: noAccViewController, hasAccViewController: hasAccViewController)

                window?.rootViewController = hasAccViewController
                self.window?.makeKeyAndVisible()
                
            } else{
                //Not In
                print("no acc")
                self.window?.rootViewController = noAccViewController
                self.window?.makeKeyAndVisible()
            }
        }
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
        if #available(iOS 12.0, *) {
            switch window?.traitCollection.userInterfaceStyle {
            case .dark:
                print("")
                UserInfo.isDark = true
            case .light, .unspecified:
                fallthrough
            case .none:
                print("")
                UserInfo.isDark = false
            @unknown default:
                print("")
                UserInfo.isDark = false
            }
        }
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        
    }
    
   
    // MARK: - Notification View Delegate
    
   
    
    
    
}



