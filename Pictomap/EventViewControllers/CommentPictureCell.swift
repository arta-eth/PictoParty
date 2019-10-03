//
//  CommentPictureCell.swift
//  Pictomap
//
//  Created by Artak on 2018-10-15.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit

class CommentPictureCell: UITableViewCell {
    
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var commentImg: UIImageView!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var fullName: UILabel!
    
    @IBOutlet weak var commentActivityView: UIActivityIndicatorView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        commentImg.image = UIImage(named: "blank.png")
    }
    
    override func layoutSubviews() {

        commentImg.layer.cornerRadius = profileImg.frame.height / 2
        commentImg.clipsToBounds = true
        commentImg.layer.borderWidth = 1
        profileImg.layer.cornerRadius = profileImg.frame.height / 2
        profileImg.clipsToBounds = true
        profileImg.layer.borderWidth = 0.5
        profileImg.layer.borderColor = UIColor.white.cgColor
        
    }
    
    

    override func prepareForReuse() {
        super.prepareForReuse()
        layoutSubviews()
        //elf.commentTextView.text = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
        // Configure the view for the selected state
    }

}
