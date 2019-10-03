//
//  CollectionViewLayout.swift
//  Pictomap
//
//  Created by Artak on 2018-11-10.
//  Copyright © 2018 artacorp. All rights reserved.
//

import UIKit

class CollectionViewLayout: UICollectionViewFlowLayout {

    let innerSpace: CGFloat = 0.0
    let numberOfCellsOnRow: CGFloat = 5
    override init() {
        super.init()
        self.minimumLineSpacing = innerSpace
        self.minimumInteritemSpacing = innerSpace
        self.scrollDirection = .horizontal
    }
    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    func itemWidth() -> CGFloat {
        return (collectionView!.frame.size.width/self.numberOfCellsOnRow)-self.innerSpace
    }
    override var itemSize: CGSize {
        set {
            self.itemSize = CGSize(width:itemWidth(), height:itemWidth())
        }
        get {
            return CGSize(width:itemWidth(),height:itemWidth())
        }
    }
}
