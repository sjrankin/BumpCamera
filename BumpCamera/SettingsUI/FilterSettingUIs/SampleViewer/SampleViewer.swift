//
//  SampleViewer.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class SampleViewer: UIView, UICollectionViewDelegate, UICollectionViewDataSource
{
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        CommonInitialization(Frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        CommonInitialization(Frame: self.bounds)
    }
    
    var CView: UICollectionView!
    
    func CommonInitialization(Frame: CGRect)
    {
        CView = UICollectionView(frame: Frame)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        return UICollectionViewCell()
    }
}
