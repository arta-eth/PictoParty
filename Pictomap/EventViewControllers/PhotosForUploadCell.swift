//
//  PhotosForUploadCell.swift
//  Pictomap
//
//  Created by Artak on 2018-11-10.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit

class PhotosForUploadCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            self.contentView.backgroundColor = isSelected ? UIColor.darkGray : UIColor.white
            self.imageView.alpha = isSelected ? 0.3 : 1.0
        }
    }


    override func layoutSubviews() {
        super.layoutSubviews()
     
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 0.5
    }
}
