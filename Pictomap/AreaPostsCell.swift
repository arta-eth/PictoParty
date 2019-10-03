//
//  AreaPostsCell.swift
//  
//
//  Created by Artak on 2018-09-22.
//

import UIKit

class AreaPostsCell: UICollectionViewCell {
    
    @IBOutlet weak var postPic: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var fullnameLbl: UILabel!
    @IBOutlet weak var timestampLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    
    
    override func layoutSubviews() {
        
        postPic.clipsToBounds = true
        self.contentView.frame = self.bounds
        self.layer.borderWidth = 0.25
        self.layer.borderColor = UIColor.lightGray.cgColor
        postPic.layer.cornerRadius = postPic.frame.height / 2
        postPic.clipsToBounds = true

    }

    override func prepareForReuse() {
    }
}
