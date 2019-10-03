//
//  PictureUIViewController.swift
//  Party Time
//
//  Created by Artak on 2018-08-16.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit

class PictureUIViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet public weak var bigImage: UIImageView!
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var displayView: UIView!
    
    
    func showAnimate(){
        self.bigImage.transform = CGAffineTransform(translationX: self.view.frame.minX, y: self.view.frame.maxY)
        self.bigImage.alpha = 0.5
        UIView.animate(withDuration: 0.35, animations: {
            self.bigImage.alpha = 1.0
            self.bigImage.transform = CGAffineTransform(translationX: self.view.frame.minX, y: self.view.frame.minY)
            let vc = self.parent?.parent as? EventDescriptionViewController
            vc?.backBtn.tintColor = UIColor.clear
            vc?.backBtn.isEnabled = false
        })
        self.displayView.transform = CGAffineTransform(translationX: self.view.frame.maxX, y: self.view.frame.minY)
        self.displayView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.displayView.alpha = 1.0
            
            self.displayView.transform = CGAffineTransform(translationX: self.view.frame.minX, y: self.view.frame.minY)
        })
    }
    
    func usePhoto(fromProfile: Bool) {
        let choseData = bigImage.image!.jpegData(compressionQuality: 0.8)
        UserDefaults.standard.set(choseData, forKey: "CHOSE")
        if(fromProfile){
            
            self.performSegue(withIdentifier: "choseDP", sender: nil)
        }
        else{
            if let parentVC = self.parent?.parent as? RootPageViewController{
                if let navVC = parentVC.viewControllerList[1] as? UINavigationController{
                    
                    if let vc = navVC.viewControllers.first as? EventDescriptionViewController{
                        vc.image = self.bigImage.image
                        parentVC.setViewControllers([vc], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.parent?.parent?.navigationController?.delegate = self
    }
    
   
    public func loadImage(image: UIImage){
        let vc = self.parent as? PhotosTabVC
        if(vc?.fromProfile ?? false){
            bigImage.layer.cornerRadius = bigImage.frame.height / 2
        }
        bigImage.clipsToBounds = true
        bigImage.image = image
    }
    
    override func viewWillAppear(_ animated: Bool) {
        showAnimate()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if let vc = segue.destination as? ProfileViewController{
            vc.dp = bigImage.image ?? UIImage(named: "default_DP.png")!
            vc.changedDP = true
        }
    }
}




