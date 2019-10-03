//
//  PhotoFiltersViewController.swift
//  Pictomap
//
//  Created by Artak on 2018-10-02.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreImage

class PhotoFiltersViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var CIFilterNames = [
        "CIPhotoEffectFade",
        "CIPhotoEffectTransfer",
        "CIPhotoEffectChrome",
        "CIPhotoEffectProcess",
        "CIPhotoEffectInstant",
        "CIFalseColor",
        "CISepiaTone",
        "CIColorMonochrome",
        "CIMaximumComponent",
        "CIPhotoEffectTonal",
        "CIPhotoEffectMono",
        "CIPhotoEffectNoir"
    ]
    
    var images = [UIImage]()
    var filterNames = [String]()
    var size = CGFloat()

    var defaultImg: UIImage?
    let button = UIButton()

    
    var collectionViewFlowLayout = UICollectionViewFlowLayout()
    
    override func viewDidLayoutSubviews() {
        
        collectionViewFlowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Filters", for: indexPath) as! FiltersCell
        
     
        cell.filterPhoto.image = images[indexPath.item]
        cell.filterName.text = filterNames[indexPath.item]
        
        
        self.size = cell.frame.height - 40
        showAnimate(cell: cell)

        return cell
    }
    
    
    

    @IBOutlet weak var collectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
    }
    
    
    
 
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        //let cell = collectionView.cellForItem(at: indexPath) as! FiltersCell
        
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
      
        update(item: indexPath, initial: false)
        
    }
    
    
    func startScrollAnimateBtn(){
        
        
        self.button.isEnabled = false
        UIView.animate(withDuration: 0.25, animations: {
            
            self.button.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            
        })
        
    }
    
    
    func stopScrollAnimateBtn(){
        
        UIView.animate(withDuration: 0.25, animations: {
            
            self.button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.button.isEnabled = true
            
        })
    }
    
    func update(item: IndexPath, initial: Bool){
        
        
        
        print("You selected cell #\(item.item)!")
        
        
        print("os")
        
        if let vc = self.parent as? EventDescriptionViewController{
            vc.partyPic.image = images[item.item]
        }
    }
    
    func center(){
        
        // Find collectionview cell nearest to the center of collectionView
        // Arbitrarily start with the last cell (as a default)
        var closestCell : UICollectionViewCell = collectionView.visibleCells[0];
        for cell in collectionView!.visibleCells as [UICollectionViewCell] {
            let closestCellDelta = abs(closestCell.center.x - collectionView.bounds.size.width/2.0 - collectionView.contentOffset.x)
            let cellDelta = abs(cell.center.x - collectionView.bounds.size.width/2.0 - collectionView.contentOffset.x)
            if (cellDelta < closestCellDelta){
                closestCell = cell
            }
        }
        let indexPath = collectionView.indexPath(for: closestCell)
        collectionView.scrollToItem(at: indexPath!, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
        
        update(item: (indexPath!), initial: false)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        
        if !decelerate{
           // stopScrollAnimateBtn()
            center()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
    }
    
    func showFilters(){
        
        
        if let parentVC = self.parent as? EventDescriptionViewController{
            
            guard let image = parentVC.image else{
                return}
            self.defaultImg = image
            self.images.removeAll()
            self.filterNames.removeAll()
            
            self.images.append(image)
            self.filterNames.append("Original")
            
            for i in 0..<CIFilterNames.count {
                let ciContext = CIContext(options: nil)
                let coreImage = CIImage(image: image)?.oriented(forExifOrientation: imageOrientationToTiffOrientation(value: (image.imageOrientation)))
                
                
                let filterName = "\(CIFilterNames[i])".replacingOccurrences(of: "CI", with: "").replacingOccurrences(of: "PhotoEffect", with: "").replacingOccurrences(of: "Tone", with: "").replacingOccurrences(of: "Color", with: "").replacingOccurrences(of: "Component", with: "")
                
                
                let filter = CIFilter(name: "\(CIFilterNames[i])" )
                filter!.setDefaults()
                filter!.setValue(coreImage, forKey: kCIInputImageKey)
                let filteredImageData = filter!.value(forKey: kCIOutputImageKey) as! CIImage
                let filteredImageRef = ciContext.createCGImage(filteredImageData, from: filteredImageData.extent)
                let filteredImage = UIImage(cgImage: filteredImageRef!);
                
                self.images.append(filteredImage)
                self.filterNames.append(filterName)
                
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func showAnimate(cell: UICollectionViewCell){
        
        cell.alpha = 0.0
        
        UIView.animate(withDuration: 0.30, animations: {
            cell.alpha = 1.0
        })
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfCell: CGFloat = 3   //you need to give a type as CGFloat
        let cellWidth = UIScreen.main.bounds.size.width / numberOfCell
        return CGSize(width: cellWidth, height: cellWidth + 20)
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        //stopScrollAnimateBtn()
        center()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        //startScrollAnimateBtn()
    }
    
    
    func imageOrientationToTiffOrientation(value: UIImage.Orientation) -> Int32
    {
        switch (value)
        {
        case .up:
            return 1
        case .down:
            return 3
        case .left:
            return 8
        case .right:
            return 6
        case .upMirrored:
            return 2
        case .downMirrored:
            return 4
        case .leftMirrored:
            return 5
        case .rightMirrored:
            return 7
        @unknown default:
            return 0
        }
    }
}
