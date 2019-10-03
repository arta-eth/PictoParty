//
//  FullPostHeader.swift
//  Pictomap
//
//  Created by Artak on 2018-10-13.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit

class FullPostHeader: UITableViewHeaderFooterView {
    var height = CGFloat()

    var cell : UITableViewCell? {
        willSet {
            cell?.removeFromSuperview()
        }
        didSet {
            if let cell = cell {
                cell.frame = self.bounds
                
                cell.autoresizingMask = [UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleWidth]
                self.contentView.backgroundColor = UIColor .clear
                self.contentView.addSubview(cell)
                
            }
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        // do your thing
        self.height = self.contentView.frame.height
        print(self.contentView.frame.height)
        
    }
    
}
