//
//  PerformanceCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class PerformanceCell: UITableViewCell
{
    public static var CellHeight: CGFloat = 75.0
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    var TitleLabel: UILabel!
    var ImageTitle: UILabel!
    var ImageCountTitle: UILabel!
    var ImageTimeTitle: UILabel!
    var LiveTitle: UILabel!
    var LiveCountTitle: UILabel!
    var LiveTimeTitle: UILabel!
    
    override init(style Style: UITableViewCell.CellStyle, reuseIdentifier ReuseIdentifier: String?)
    {
        super.init(style: Style, reuseIdentifier: ReuseIdentifier)
        let Width = UIScreen.main.bounds.width
        TitleLabel = UILabel()
        TitleLabel.frame = CGRect(x: 10, y: 0, width: Width, height: 30.0)
        TitleLabel.font = UIFont(name: "Avenir-Bold", size: 18.0)
        TitleLabel.text = "Filter name"
        self.contentView.addSubview(TitleLabel)
        
        ImageTitle = UILabel()
        ImageTitle.frame = CGRect(x: 10, y: 30, width: 60.0, height: 20.0)
        ImageTitle.font = UIFont(name: "Avenir", size: 16.0)
        ImageTitle.text = "Image"
        self.contentView.addSubview(ImageTitle)
        ImageCountTitle = UILabel()
        ImageCountTitle.frame = CGRect(x: 80, y: 30, width: 180, height: 20.0)
        ImageCountTitle.font = UIFont(name: "Avenir", size: 15.0)
        ImageCountTitle.text = "Count: xxxx"
        self.contentView.addSubview(ImageCountTitle)
        ImageTimeTitle = UILabel()
        ImageTimeTitle.frame = CGRect(x: 220, y: 30, width: 200, height: 20.0)
        ImageTimeTitle.font = UIFont(name: "Avenir", size: 15.0)
        ImageTimeTitle.text = "Mean: xxxx s"
        self.contentView.addSubview(ImageTimeTitle)
        
        LiveTitle = UILabel()
        LiveTitle.frame = CGRect(x: 10, y: 50, width: 60.0, height: 20.0)
        LiveTitle.font = UIFont(name: "Avenir", size: 16.0)
        LiveTitle.text = "Live"
        self.contentView.addSubview(LiveTitle)
        LiveCountTitle = UILabel()
        LiveCountTitle.frame = CGRect(x: 80, y: 50, width: 180, height: 20.0)
        LiveCountTitle.font = UIFont(name: "Avenir", size: 15.0)
        LiveCountTitle.text = "Count: xxxx"
        self.contentView.addSubview(LiveCountTitle)
        LiveTimeTitle = UILabel()
        LiveTimeTitle.frame = CGRect(x: 220, y: 50, width: 200, height: 20.0)
        LiveTimeTitle.font = UIFont(name: "Avenir", size: 15.0)
        LiveTimeTitle.text = "Mean: xxxx s"
        self.contentView.addSubview(LiveTimeTitle)
        
        self.selectionStyle = .none
    }
    
    public func SetData(FilterName: String, ImageCount: Int, ImageMean: Double, LiveCount: Int, LiveMean: Double)
    {
        TitleLabel.text = FilterName
        ImageCountTitle.text = "Count: \(ImageCount)"
        let ImageDivisor = ImageCount == 0 ? 1 : ImageCount
        let ImageMeanTime = ImageMean / Double(ImageDivisor)
        ImageTimeTitle.text = "Mean: \(ImageMeanTime.Round(To: 3))s"
        let LiveCountString = Utility.ReduceBigNum(BigNum: Int64(LiveCount), AsBytes: false, ReturnUnchangedThreshold: 100000)
        LiveCountTitle.text = "Count: \(LiveCountString)"
        let LiveDivisor = LiveCount == 0 ? 1 : LiveCount
        let LiveMeanTime = LiveMean / Double(LiveDivisor)
        LiveTimeTitle.text = "Mean: \(LiveMeanTime.Round(To: 3))s"
    }
}
