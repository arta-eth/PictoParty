//
//  RootPageViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-05-31.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwiftKeychainWrapper
import FirebaseDatabase


class RootPageViewController: UIPageViewController {

    var viewController: ViewController!
    var fromProfile = Bool()

    
    lazy var viewControllerList: [UIViewController] = {
        
        let sb1 = UIStoryboard(name: "PhotosTab", bundle: nil)
        let sb2 = UIStoryboard(name: "EventDescription", bundle: nil)

        
        let vc1 = sb1.instantiateViewController(withIdentifier: "Photos")
        

        let vc2 = sb2.instantiateViewController(withIdentifier: "NewEvent")
        

        return [vc1, vc2]
        
        
    }()
    
    

   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("oy")
        
        self.view.backgroundColor = UIColor.white
        
        if let firstViewController = viewControllerList.first{
            
            self.setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        
        setNavigationItem(button: UIBarButtonItem.SystemItem.stop)
        
        
        // Do any additional setup after loading the view.
    }
    
    func setNavigationItem(button: UIBarButtonItem.SystemItem) {
        let button = UIBarButtonItem(barButtonSystemItem: button, target: self, action: #selector(self.goBack))
        button.tintColor = UIColor.darkGray
        self.navigationItem.leftBarButtonItem = button
    }
    
    
    @objc func goBack(){
        self.performSegue(withIdentifier: "back2feed", sender: nil)
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let vcIndex = viewControllerList.firstIndex(of: viewController) else {return nil}
        
        let previousIndex = vcIndex - 1
        
        guard previousIndex >= 0 else {return nil}
        
        guard viewControllerList.count > previousIndex else {return nil}
        
        return viewControllerList[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let vcIndex = viewControllerList.firstIndex(of: viewController) else {return nil}
        
        let nextIndex = vcIndex + 1
        
        guard viewControllerList.count != nextIndex else{return nil}
        
        guard viewControllerList.count > nextIndex else {return nil}
        
        
        return viewControllerList[nextIndex]

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
    }
 

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}


