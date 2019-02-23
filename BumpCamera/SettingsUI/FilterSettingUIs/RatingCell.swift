//
//  RatingCell.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Set of controls that allows the user to rate and set as favorite filters. This is a UITableViewCell which is used as a
/// table footer view for all filter setting UIs.
class RatingCell: UITableViewCell
{
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    var Title: UILabel!
    var HeartButton: UIButton!
    var StarButton0: UIButton!
    var StarButton1: UIButton!
    var StarButton2: UIButton!
    var StarButton3: UIButton!
    var StarButton4: UIButton!
    
    override init(style Style: UITableViewCell.CellStyle, reuseIdentifier ReuseIdentifier: String?)
    {
        super.init(style: Style, reuseIdentifier: ReuseIdentifier)
        
        Title = UILabel()
        Title.text = "Rating"
        Title.frame = CGRect(x: 20.0, y: 12.0, width: 50.0, height: 20.0)
        contentView.addSubview(Title)
        let Width = UIScreen.main.bounds.size.width
        
        HeartButton = UIButton()
        HeartButton.frame = CGRect(x: Width - 60.0, y: 0.0, width: 48, height: 48)
        contentView.addSubview(HeartButton)
        HeartButton.setImage(UIImage(named: "EmptyHeart"), for: UIControl.State.normal)
        HeartButton.addTarget(self, action: #selector(HeartButtonPressed), for: .touchUpInside)
        
        StarButton0 = UIButton()
        StarButton0.frame = CGRect(x: 80, y: 0, width: 48, height: 48)
        contentView.addSubview(StarButton0)
        StarButton0.setImage(UIImage(named: "EmptyStar"), for: UIControl.State.normal)
        StarButton0.tag = 1
        StarButton0.addTarget(self, action: #selector(StarButtonPressed), for: .touchUpInside)
        
        StarButton1 = UIButton()
        StarButton1.frame = CGRect(x: 110, y: 0, width: 48, height: 48)
        contentView.addSubview(StarButton1)
        StarButton1.setImage(UIImage(named: "EmptyStar"), for: UIControl.State.normal)
        StarButton1.tag = 2
        StarButton1.addTarget(self, action: #selector(StarButtonPressed), for: .touchUpInside)
        
        StarButton2 = UIButton()
        StarButton2.frame = CGRect(x: 140, y: 0, width: 48, height: 48)
        contentView.addSubview(StarButton2)
        StarButton2.setImage(UIImage(named: "EmptyStar"), for: UIControl.State.normal)
        StarButton2.tag = 3
        StarButton2.addTarget(self, action: #selector(StarButtonPressed), for: .touchUpInside)
        
        StarButton3 = UIButton()
        StarButton3.frame = CGRect(x: 170, y: 0, width: 48, height: 48)
        contentView.addSubview(StarButton3)
        StarButton3.setImage(UIImage(named: "EmptyStar"), for: UIControl.State.normal)
        StarButton3.tag = 4
        StarButton3.addTarget(self, action: #selector(StarButtonPressed), for: .touchUpInside)
        
        StarButton4 = UIButton()
        StarButton4.frame = CGRect(x: 200, y: 0, width: 48, height: 48)
        contentView.addSubview(StarButton4)
        StarButton4.setImage(UIImage(named: "EmptyStar"), for: UIControl.State.normal)
        StarButton4.tag = 5
        StarButton4.addTarget(self, action: #selector(StarButtonPressed), for: .touchUpInside)
        
        contentView.backgroundColor = UIColor(named: "PaleGray")
        contentView.layer.borderColor = UIColor.black.cgColor
        contentView.layer.borderWidth = 0.5
    }
    
    @objc func StarButtonPressed(_ sender: Any)
    {
        let StarButton = sender as? UIButton
        let StarCount = StarButton?.tag
        print("Setting star count to \((StarCount)!)")
        FilterRatings?.StarCount = StarCount!
        SetStars(StarCount!)
    }
    
    @objc func HeartButtonPressed(_ sender: Any)
    {
        if (FilterRatings?.Faved)!
        {
            FilterRatings?.Faved = false
            HeartButton.setImage(UIImage(named: "EmptyHeart"), for: UIControl.State.normal)
        }
        else
        {
            FilterRatings?.Faved = true
            HeartButton.setImage(UIImage(named: "FilledHeart"), for: UIControl.State.normal)
        }
    }
    
    func SetStar(StarControl: UIButton, To: Bool)
    {
        let ImageName = To ? "FilledStar" : "EmptyStar"
        StarControl.setImage(UIImage(named: ImageName), for: UIControl.State.normal)
    }
    
    func SetStars(_ StarCount: Int)
    {
        SetStar(StarControl: StarButton0, To: StarCount >= 1)
        SetStar(StarControl: StarButton1, To: StarCount >= 2)
        SetStar(StarControl: StarButton2, To: StarCount >= 3)
        SetStar(StarControl: StarButton3, To: StarCount >= 4)
        SetStar(StarControl: StarButton4, To: StarCount >= 5)
    }
    
    func PopulateUI()
    {
        let FaveImageName = (FilterRatings?.Faved)! ? "FilledHeart" : "EmptyHeart"
        HeartButton.setImage(UIImage(named: FaveImageName), for: UIControl.State.normal)
        SetStars((FilterRatings?.StarCount)!)
    }
    
    public func SetData(FilterType: FilterManager.FilterTypes)
    {
        FilterRatings = FilterManager.RatingsFor(FilterType, CreateOnDemand: true)
        if FilterRatings == nil
        {
            print("Error getting filter ratings for \(FilterType).")
            return
        }
        PopulateUI()
    }
    
    var FilterRatings: Ratings? = nil
}
