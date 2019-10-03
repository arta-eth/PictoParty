//
//  FeedTextPostCell.swift
//  Pictomap
//
//  Created by Artak on 2018-12-17.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit

class FeedTextPostCell: UITableViewCell {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var postCaption: UITextView!
    
    @IBOutlet weak var quickLikePostBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.fullName.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0) /* #fcfcfc */



        self.username.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0) /* #fcfcfc */



        self.username.text?.removeAll()
        self.fullName.text?.removeAll()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.userImage.layer.cornerRadius = self.userImage.frame.height / 2
        self.userImage.clipsToBounds = true
        self.username.layer.cornerRadius = self.username.frame.height / 3
        self.username.clipsToBounds = true
        self.fullName.layer.cornerRadius = self.fullName.frame.height / 3
        self.fullName.clipsToBounds = true
        
        
        self.quickLikePostBtn.backgroundColor = UIColor.clear
        self.quickLikePostBtn.setImage(UIImage(named: "likeIcon"), for: .normal)
        
        self.quickLikePostBtn.tintColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) /* #e8e8e8 */

        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
