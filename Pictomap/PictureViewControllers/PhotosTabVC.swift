//
//  PhotosTabVC.swift
//  Party Time
//
//  Created by Artak on 2018-08-25.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit

class PhotosTabVC: UIViewController {

    @IBOutlet weak var tab: UISegmentedControl!
    var fromProfile = Bool()
    
    
    @IBOutlet weak var container: UIView!
    
    private lazy var firstViewController: CameraViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Camera", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "Camera") as! CameraViewController
        
        // Add View Controller as Child View Controller
        self.addChild(viewController)
        
        return viewController
    }()
    
    
    private lazy var secondViewController: PictureUIViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Photos", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "Photos") as! PictureUIViewController
        
        // Add View Controller as Child View Controller
        self.addChild(viewController)
        
        return viewController
    }()
    
    
    func showView(tabButton: UISegmentedControl){
        
        switch tabButton.selectedSegmentIndex{
        case 1:
            print("1")
            
        default:
            print("0")
        }
    }
    

    
    private func add(asChildViewController viewController: UIViewController) {
        
        // Add Child View Controller
        addChild(viewController)
        
        // Add Child View as Subview
        container.addSubview(viewController.view)
        
        // Configure Child View
        viewController.view.frame = container.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Notify Child View Controller
        viewController.didMove(toParent: self)
    }
    
    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParent: nil)
        
        // Remove Child View From Superview
        viewController.view.removeFromSuperview()
        
        // Notify Child View Controller
        viewController.removeFromParent()
    }
    
    private func updateView() {
        if tab.selectedSegmentIndex == 0 {
            remove(asChildViewController: secondViewController)
            add(asChildViewController: firstViewController)
        } else {
            remove(asChildViewController: firstViewController)
            add(asChildViewController: secondViewController)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tab.layer.cornerRadius = tab.bounds.height / 10
        tab.layer.borderColor = UIColor.white.cgColor
        tab.backgroundColor = UIColor.white
        tab.tintColor = UIColor().mainColor()
        tab.layer.borderWidth = 1.5
        tab.layer.masksToBounds = true
        // Do any additional setup after loading the view.
        
        updateView()

    }
    
    @IBAction func switchTab(_ sender: UISegmentedControl) {
        
        updateView()

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
