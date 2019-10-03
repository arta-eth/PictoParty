//
//  TabBarVC.swift
//  Pictomap
//
//  Created by Artak on 2018-07-26.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftKeychainWrapper
import OneSignal
import MapKit
import AudioToolbox


class Details{
    
    var date = String()
    var address = String()
    var city = String()
    var name = String()
    var partyImage = UIImage()
    var uid = "gaza"
    
    
}

var party = Details()
let new = ""



class TabBarVC: UITabBarController {

    let notificationCenter = NotificationCenter.default

    lazy var button: UIButton = {
        
        let tabHeight = self.tabBar.frame.size.height

        let window = UIApplication.shared.windows.first
        let bottom = window?.safeAreaLayoutGuide.layoutFrame.maxY
        
        let width = (self.view.frame.width / 3) - 40
        let height = width
        let x = (self.view.frame.width / 3) + 20
    
        let y = (bottom ?? 0) - tabHeight - (height  / 2)

        let button = UIButton.init(frame: CGRect(x: x, y: y, width: width, height: height))
        
        button.backgroundColor = UIColor(named: "tabBar")
            
            //UIColor.init(red: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)
        button.tintColor = UIColor.gray//UserBackgroundColor().primaryColor
        button.layer.borderColor = UIColor.gray.cgColor //UserBackgroundColor().primaryColor.withAlphaComponent(1.0).cgColor
        button.layer.borderWidth = 7
        button.setImage(UIImage(named: "AddImage"), for: UIControl.State.normal)
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true
        
        return button
    }()
    
 
    

    
    override func viewWillAppear(_ animated: Bool) {
        //animatePhotoBtn()
    }
    
    
    @objc func appMovedToForeground() {
        print("App moved to foreground!")
        //animatePhotoBtn()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        notificationCenter.removeObserver(self)
        //button.layer.removeAllAnimations()
    }
    
    func animatePhotoBtn(){
        
        let colorAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.borderColor))
        colorAnimation.fromValue = UIColor().mainColor().cgColor
        colorAnimation.toValue = UserBackgroundColor().primaryColor.cgColor
        let widthAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.borderWidth))
        widthAnimation.fromValue = 11.25
        widthAnimation.toValue = 12
        let bothAnimations = CAAnimationGroup()
        bothAnimations.duration = 1
        bothAnimations.animations = [colorAnimation, widthAnimation]
        bothAnimations.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        bothAnimations.repeatCount = .infinity
        bothAnimations.autoreverses = true
        button.layer.add(bothAnimations, forKey: "color/width")
        
    }
    
    var spinner: MapSpinnerView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
       
        
        spinner = MapSpinnerView.init(frame: CGRect(x: button.frame.minX - 3, y: button.frame.minY - 3, width: button.frame.width + 6, height: button.frame.height + 6))
        
        
        //print(UIScreen.main.scale)
        tabBar.tintColor = UIColor().mainColor()
        if let im = self.loadImage(withName: "DP"){
            UserInfo.dp = im
        }
    
    
        
        if let list = UserDefaults.standard.array(forKey: "followingList") as? [String]{
            UserFollowing.userFollowing = list
        }
        //KeychainWrapper.standard.removeObject(forKey: "handle")
        if let vcList = viewControllerList{
            vcList[1].tabBarItem.isEnabled = false
        }
        
        OneSignal.setSubscription(true)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        tabBar.isTranslucent = false
    }
    
    
    
    override func viewDidLayoutSubviews() {
        
        

        if let spin = self.spinner{
            self.view.insertSubview(spin, aboveSubview: tabBar)
            self.view.insertSubview(button, aboveSubview: spin)
        }
 
        //button.setRadiusWithShadow()
        //animatePhotoBtn()
        if let vcList = viewControllerList{
            viewControllers = vcList
        }
        button.addTarget(self, action: #selector(centerOnUser(_:)), for: UIControl.Event.touchUpInside)
        
    }
    
    @IBAction func unwindToTab(segue:  UIStoryboardSegue) {
        
    }
    
    @objc func centerOnUser(_ sender: UIButton) {
        
        AudioServicesPlaySystemSound(1520) // Actuate `Pop` feedback (strong boom)
        self.performSegue(withIdentifier: "NewPost", sender: nil)
    }
    
    lazy var viewControllerList: [UIViewController]? = {
        
        let sb1 = UIStoryboard(name: "Map", bundle: nil)
        let sb2 = UIStoryboard(name: "Placeholder", bundle: nil)
        let sb3 = UIStoryboard(name: "User", bundle: nil)

        guard let vc1 = sb1.instantiateViewController(withIdentifier: "Map") as? UINavigationController else {return nil}
        vc1.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "Feed"), tag: 1)
        
        guard let vc2 = sb2.instantiateViewController(withIdentifier: "Placeholder") as? UINavigationController else {return nil}

        guard let vc3 = sb3.instantiateViewController(withIdentifier: "Profile") as? UINavigationController else {return nil}
        vc3.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "Profile"), tag: 3)

        return [vc1, vc2, vc3]
        
    }()

    
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        if item.tag == 1{
            if let navVC = viewControllerList?[0] as? UINavigationController{
                
                if let feedView = navVC.viewControllers.first as? MapViewController{
                    
                    if (feedView.isViewLoaded && ((feedView.view?.window) != nil)) {
                        let region = MKCoordinateRegion.init(center: feedView.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 2000, longitude: 2000), latitudinalMeters: 5000, longitudinalMeters: 5000)
                        feedView.map.setRegion(region, animated: true)
                    }
                }
            }
        }
        else if item.tag == 3{
            if let navVC = viewControllerList?[2] as? UINavigationController{
                
                if let userView = navVC.viewControllers.first as? UserViewController{
                    
                    if (userView.isViewLoaded && ((userView.view?.window) != nil)) {
                        if userView.cellHeights.count != 0{
                            if userView.tableView.numberOfRows(inSection: 0) != 0{
                                userView.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
                                userView.navigationController?.setNavigationBarHidden(false, animated: true)

                            }
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        
    }
    

}
extension UIView {
    func roundCorners(_ corners:UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
        self.clipsToBounds = true
    }
}

extension UIViewController{
    
    func getDate() -> String{
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "YYYY-MM-dd"
        let date = Date()
        let td = dateFormatter.string(from: date)
        
        return td
    }
}
