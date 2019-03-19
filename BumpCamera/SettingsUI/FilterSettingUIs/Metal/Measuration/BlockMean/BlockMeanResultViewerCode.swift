//
//  BlockMeanResultViewerCode.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 3/19/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

class BlockmeanResultViewerCode: FilterSettingUIBase, BlockMeanProtocol
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Initialize(FilterType: FilterManager.FilterTypes.BlockMean, EnableSelectImage: true, CallFilter: false, IsChildDialog: true)
        self.tableView.reloadData()
    }
    
    func SetMeanData(MeanData: [(Int, Int, UIColor, Int)])
    {
        ResultMeanData = MeanData
    }
    
    var ResultMeanData = [(Int, Int, UIColor, Int)]()
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return ResultMeanData.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let Cell = BlockMeanResultCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "MeanColorAtBlock")
        let (X, Y, Color, _) = ResultMeanData[indexPath.row]
        Cell.SetData(IndexValue: "(\(X),\(Y))", Color: Color)
        return Cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return BlockMeanResultCell.CellHeight
    }
}
