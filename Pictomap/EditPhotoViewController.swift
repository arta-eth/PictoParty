//
//  EditPhotoViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-09-30.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit

class EditPhotoViewController: UIViewController {

    var image: UIImage?

    @IBOutlet weak var imageToEdit: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if image == nil{
            
        }
        imageToEdit.image = image
    }
    
    @IBAction func nextPage(){
        
        if let parent = self.parent as? RootPageViewController{
            
            if let vc = parent.viewControllerList[2] as? EventDescriptionViewController{
                
                vc.image = imageToEdit.image
                
                parent.setViewControllers([vc], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
            }
        }
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
