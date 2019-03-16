//
//  HighlightPixelsCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/16/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class HighlightPixelsCode: FilterSettingUIBase
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.PixellateMetal)
        
        GroupAction.backgroundColor = UIColor.white
        GroupAction.layer.borderColor = UIColor.black.cgColor
        GroupAction.layer.borderWidth = 0.5
        GroupAction.layer.cornerRadius = 5.0
        
        HighlightPixelSelector.selectedSegmentIndex = ParameterManager.GetInt(From: FilterID, Field: .PixellationHighlighting, Default: 3)
        IsVisible = HighlightPixelSelector.selectedSegmentIndex != 3
        OriginalGroupActionFrame = GroupAction.frame
         OriginalTitleLabelFrame = HighlightPixelLabel.frame
         EnableIfFrame = EnableIfSelector.frame
         HighlightSliderFrame = HighlightSlider.frame
         HighlightValueFrame = HighlightValueLabel.frame
        HighlightValueLabel.text = ""
        
        SetUI()
    }
    
    var OriginalTitleLabelFrame: CGRect!
    var EnableIfFrame: CGRect!
    var HighlightSliderFrame: CGRect!
    var HighlightValueFrame: CGRect!
    var OriginalGroupActionFrame: CGRect!
    var IsVisible = true
    /*
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        OriginalGroupActionFrame = GroupAction.frame
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        OriginalGroupActionFrame = GroupAction.frame
        super.viewWillAppear(animated)
    }
    */
    func SetUI()
    {
        let DoHighlight = HighlightPixelSelector.selectedSegmentIndex != 3
        if DoHighlight && IsVisible
        {
            print("Return: DoHighlight && IsVisible")
            return
        }
        if !DoHighlight && !IsVisible
        {
            print("Return: !DoHighlight && !IsVisible")
            return
        }
        if DoHighlight
        {
            UIView.animate(withDuration: 0.15, delay: 0.0,
                           usingSpringWithDamping: 0.4, initialSpringVelocity: 0.8,
                           options: [.curveEaseOut],
                           animations: {
                self.GroupAction.frame = self.OriginalGroupActionFrame
                self.HighlightPixelLabel.frame = self.OriginalTitleLabelFrame
                self.EnableIfSelector.frame = self.EnableIfFrame
                self.HighlightSlider.frame = self.HighlightSliderFrame
                self.HighlightValueLabel.frame = self.HighlightValueFrame
            }, completion:
                {
                    _ in
                    self.IsVisible = true
            }
            )
        }
        else
        {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseIn],
                           animations: {
                self.GroupAction.frame = CGRect(x: -1000, y: self.OriginalGroupActionFrame.minY,
                                                width: self.OriginalGroupActionFrame.width,
                                                height: self.OriginalGroupActionFrame.height)
                self.HighlightPixelLabel.frame = CGRect(x: -1000, y: self.OriginalTitleLabelFrame.minY,
                                                        width: self.OriginalTitleLabelFrame.width,
                                                        height: self.OriginalTitleLabelFrame.height)
                self.EnableIfSelector.frame = CGRect(x: -1000, y: self.EnableIfFrame.minY,
                                                     width: self.EnableIfFrame.width,
                                                     height: self.EnableIfFrame.height)
                self.HighlightSlider.frame = CGRect(x: -1000, y: self.HighlightSliderFrame.minY,
                                                    width: self.HighlightSliderFrame.width,
                                                    height: self.HighlightSliderFrame.height)
                self.HighlightValueLabel.frame = CGRect(x: -1000, y: self.HighlightValueFrame.minY,
                                                        width: self.HighlightValueFrame.width,
                                                        height: self.HighlightValueFrame.height)
            }, completion:
                {
            _ in
                    self.IsVisible = false
            }
            )
        }
    }
    
    @IBAction func HandleHighlightSliderChanged(_ sender: Any)
    {
    }
    
    @IBAction func HandleHighlightPixelChanged(_ sender: Any)
    {
        UpdateValue(WithValue: HighlightPixelSelector.selectedSegmentIndex, ToField: .PixellationHighlighting)
        ShowSampleView()
        SetUI()
    }
    
    @IBAction func HandleEnableIfChanged(_ sender: Any)
    {
    }
    
    @IBOutlet weak var HighlightPixelLabel: UILabel!
    @IBOutlet weak var HighlightValueLabel: UILabel!
    @IBOutlet weak var HighlightSlider: UISlider!
    @IBOutlet weak var EnableIfSelector: UISegmentedControl!
    @IBOutlet weak var HighlightPixelSelector: UISegmentedControl!
    @IBOutlet weak var GroupAction: UIView!
}
