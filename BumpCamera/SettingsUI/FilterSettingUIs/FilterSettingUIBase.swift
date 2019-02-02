//
//  FilterSettingUIBase.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/30/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Base class for filter setting UIs.
class FilterSettingUIBase: UITableViewController
{
    let _Settings = UserDefaults.standard
    var Filter = FilterManager.FilterTypes.PassThrough
    var FilterID: UUID!
    let Filters = FilterManager(Preload: false)
    var SampleFilter: Renderer? = nil
    var SampleImageName: String = "Norio"
    var SampleView: UIImageView!
    
    /// Initializes the base class.
    ///
    /// - Parameters:
    ///   - Sample: The UIImageView where the sample image will be shown.
    ///   - FilterType: The filter type.
    func Initialize(FilterType: FilterManager.FilterTypes, EnableSelectImage: Bool = true)
    {
        print("\(FilterType) start at \(CACurrentMediaTime())")
        let Start = CACurrentMediaTime()
        DoEnableSelect = EnableSelectImage
        tableView.tableFooterView = UIView()
        Filter = FilterType
        FilterID = FilterManager.FilterMap[Filter]
        SampleFilter = Filters.CreateFilter(For: Filter)
        SampleFilter?.InitializeForImage()
        SampleImageName = _Settings.string(forKey: "SampleImage")!
        SampleView.image = UIImage(named: SampleImageName)
        SampleView.isUserInteractionEnabled = true
        if DoEnableSelect
        {
            let Tap = UITapGestureRecognizer(target: self, action: #selector(HandleSampleSelection))
            SampleView.addGestureRecognizer(Tap)
        }
        let End = CACurrentMediaTime()
        print("FilterSettingUIBase(Filter) start-up duration: \(End - Start) seconds")
    }
    
    /// Return the contents of the header row, which in our case is the sample image. The sample image is kept in
    /// the header row of the table to make sure it is visible regardless of how far the user scrolls the table.
    ///
    /// - Note: https://stackoverflow.com/questions/43555124/how-to-freeze-a-tableview-cell-in-swift
    ///
    /// - Parameters:
    ///   - tableView: Not used.
    ///   - section: Not used.
    /// - Returns: Previously created UIImageView where the sample image lives.
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView
    {
        return SampleView
    }
    
    /// Set the size of the header row. The header row is where the sample image is displayed. It's displayed
    /// in the header row because it is always visible, no matter how much the contents of the table have
    /// scrolled.
    ///
    /// - Note: https://stackoverflow.com/questions/43555124/how-to-freeze-a-tableview-cell-in-swift
    ///
    /// - Parameters:
    ///   - tableView: Not used.
    ///   - section: Not used.
    /// - Returns: The vertical height of the header row.
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 180
    }
    
    private var DoEnableSelect: Bool = true
    
    /// Handle tap events on the sample image.
    ///
    /// - Parameter Gesture: Gesture/tap state.
    @objc func HandleSampleSelection(_ Gesture: UITapGestureRecognizer)
    {
        if Gesture.state == .ended
        {
            ShowSampleSelectionDialog()
        }
    }
    
    /// When the user taps on the sample image, show a dialog that allows the user to change sample images.
    func ShowSampleSelectionDialog()
    {
        let Alert = UIAlertController(title: "Select Sample Image",
                                      message: "Select the sample image to use.",
                                      preferredStyle: UIAlertController.Style.actionSheet)
        Alert.addAction(UIAlertAction(title: "Cat", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        Alert.addAction(UIAlertAction(title: "Rose", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        Alert.addAction(UIAlertAction(title: "Dandelion", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        Alert.addAction(UIAlertAction(title: "Painted Portrait", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        Alert.addAction(UIAlertAction(title: "Black and White Portrait", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        Alert.addAction(UIAlertAction(title: "Test Pattern", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        Alert.addAction(UIAlertAction(title: "Select Your Own", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        Alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(Alert, animated: true, completion: nil)
    }
    
    /// Handle actions selected by the user from the change sample image dialog. The new image to view will be saved to the
    /// user's default settings, which are monitored for changes by the descendent class and acted on as appropriate to the
    /// filter.
    ///
    /// - Parameter Action: The action related to what the user tapped.
    @objc func HandleNewSampleImage(_ Action: UIAlertAction)
    {
        var NewImageName: String? = nil
        switch Action.title
        {
        case "Cat":
            NewImageName = "Norio"
            
        case "Rose":
            NewImageName = "HamanasuSample"
            
        case "Dandelion":
            NewImageName = "DandelionSample"
            
        case "Painted Portrait":
            NewImageName = "Painting"
            
        case "Black and White Portrait":
            NewImageName = "BWPortrait"
            
        case "Test Pattern":
            NewImageName = "TestPattern"
            
        case "Select Your Own":
            break
            
        default:
            break
        }
        if let NewImage = NewImageName
        {
            _Settings.set(NewImage, forKey: "SampleImage")
        }
    }
    
    /// Create a keyboard that contains a "Done" button to help the user close the keyboard.
    ///
    /// - Parameter ActionSelection: The action to take when the Done button is pressed.
    /// - Returns: The keyboard toolbar.
    func MakeToolbarForKeyboard(ActionSelection: Selector) -> UIToolbar
    {
        //Create a keyboard button bar that contains a button that lets the user finish editing cleanly.
        let KeyboardBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 50))
        KeyboardBar.barStyle = .default
        let FlexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let KeyboardDoneButton = UIBarButtonItem(title: "Done", style: .plain, target: self,
                                                 action: ActionSelection)
        KeyboardBar.sizeToFit()
        KeyboardBar.items = [FlexSpace, KeyboardDoneButton]
        return KeyboardBar
    }
    
    /// Create a keyboard that contains a "Done" button to the passed input text field. The keyboard toolbar
    /// is stored internally.
    ///
    /// - Parameters:
    ///   - For: The input text field whose keyboard will get a toolbar with a "Done" button.
    ///   - ActionSelection: The action to take when the Done button is pressed.
    func MakeToolbarForKeyboard(For: UITextField, ActionSelection: Selector)
    {
        let DoneBar = MakeToolbarForKeyboard(ActionSelection: ActionSelection)
        For.inputAccessoryView = DoneBar
        if Keyboards == nil
        {
            Keyboards = [UIToolbar]()
        }
        Keyboards?.append(DoneBar)
    }
    
    var Keyboards: [UIToolbar]? = nil
    
    /// Rounds the passed value to the specified number of decimal places and returns a string value of the result,
    /// optionally adding trailing zeroes to ensure the number of decimal digits is equal to ToPlace.
    ///
    /// - Parameters:
    ///   - Value: The value to round and return as a string.
    ///   - ToPlace: Number of places to round the value to.
    ///   - ZeroFill: If true, trailing zeros are added as needed to match ToPlace in count.
    /// - Returns: String equilavent of rounded passed value,
    func ToString(_ Value: Double, ToPlace: Int, ZeroFill: Bool = true) -> String
    {
        let Rounded = Value.Round(To: ToPlace)
        let Raw = String(Rounded)
        let Parts = Raw.split(separator: ".")
        let IntPart = String(Parts[0])
        var DecPart = String(Parts[1])
        if ZeroFill
        {
        if DecPart.count < ToPlace
        {
            let AddCount = ToPlace - DecPart.count
           for _ in 0 ..< AddCount
           {
            DecPart = DecPart + "0"
            }
        }
        }
        return "\(IntPart).\(DecPart)"
    }
    
    /// Return a double value from the passed text field. If the text field does not contain a double, return the default value.
    ///
    /// - Parameters:
    ///   - TextBox: The text field whose double value will be returned.
    ///   - Default: The value to return if the contents of the text field do not resolve to a double value.
    /// - Returns: The value of the text field as a double on success, the default value if the value cannot be resolved.
    func GetDoubleFrom(_ TextBox: UITextField, Default: Double) -> Double
    {
        if let Raw = TextBox.text
        {
            if let DVal = Double(Raw)
            {
                return DVal
            }
            else
            {
                return Default
            }
        }
        else
        {
            return Default
        }
    }
    
    /// Return a double value from the passed text field. If the text field does not contain a double, return the default value.
    /// Additionally, if the double falls outside the passed range, it is clamped to the range.
    ///
    /// - Parameters:
    ///   - TextBox: The text field whose double value will be returned.
    ///   - Min: Low end of the valid range. If this value is greater than Max, a fatal error occurs.
    ///   - Max: High end of the valid range. If this value is less than Min, a fatal error occurs.
    ///   - Default: The value to return if the contents of the text field do not resolve to a double value. If the default
    ///              value is outside of the passed range, a fatal error occurs.
    /// - Returns: The value of the text field as a double on success, the default value if the value cannot be resolved.
    func GetDoubleFrom(_ TextBox: UITextField, Min: Double, Max: Double, Default: Double) -> Double
    {
        if Min > Max
        {
            fatalError("Invalid range - Min \(Min) is greater than Max \(Max).")
        }
        if Default < Min || Default > Max
        {
            fatalError("Default value \(Default) out of Min:Max range (\(Min):\(Max))")
        }
        if let Raw = TextBox.text
        {
            if let DVal = Double(Raw)
            {
                if DVal < Min
                {
                    return Min
                }
                if DVal > Max
                {
                    return Max
                }
                return DVal
            }
            else
            {
                return Default
            }
        }
        else
        {
            return Default
        }
    }
    
    /// Determines if the passed UITextField contains a valid double number. Optionally replace invalid values with a passed value.
    ///
    /// - Parameters:
    ///   - TextBox: The text field to check for a valid double.
    ///   - SetIfInvalid: If the text field does not contain a valid double, if this parameter is defined, it will be
    ///                   placed into the text field.
    /// - Returns: True if the text field contains a valid double value, false if not.
    @discardableResult func InputContainsValidDouble(_ TextBox: UITextField, SetIfInvalid: String? = nil) -> Bool
    {
        if let Raw = TextBox.text
        {
            if let _ = Double(Raw)
            {
                return true
            }
            else
            {
                if let FixIt = SetIfInvalid
                {
                    TextBox.text = FixIt
                }
                return false
            }
        }
        else
        {
            if let FixIt = SetIfInvalid
            {
                TextBox.text = FixIt
            }
            return false
        }
    }
    
    func UpdateValue(WithValue: Double, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
    }
    
    func UpdateValue(WithValue: Int, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
    }
    
    func UpdateValue(WithValue: Bool, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
    }
    
    func UpdateValue(WithValue: String, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
    }
    
    func UpdateValue(WithValue: CGPoint, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
    }
}
