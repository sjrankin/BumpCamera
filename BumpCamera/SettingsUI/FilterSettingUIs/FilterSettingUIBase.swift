//
//  FilterSettingUIBase.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/30/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import Photos

/// Base class for filter setting UIs.
class FilterSettingUIBase: UITableViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIActivityItemSource
{
    let _Settings = UserDefaults.standard
    var Filter = FilterManager.FilterTypes.PassThrough
    var FilterID: UUID!
    let Filters = FilterManager(Preload: false)
    var SampleFilter: Renderer? = nil
    var SampleImageName: String = "Norio"
    var SampleView: UIImageView!
    var SampleViewEx: UICollectionView!
    var ShowingSample: Bool = true
    var ImagePicker: UIImagePickerController? = nil
    var ADelegate: AppDelegate? = nil
    var MainFilter: FilterManager? = nil
    var CallsFilter: Bool = true
    var SampleViewImage: UIImage? = nil
    
    /// Initializes the base class.
    ///
    /// - Parameters:
    ///   - Sample: The UIImageView where the sample image will be shown.
    ///   - FilterType: The filter type.
    ///   - CallFilter: Set to false only if there is input but no output (eg, measuration filters).
    func Initialize(FilterType: FilterManager.FilterTypes, EnableSelectImage: Bool = true, CallFilter: Bool = true)
    {
        print("\(FilterType) start at \(CACurrentMediaTime())")
        CallsFilter = CallFilter
        let Start = CACurrentMediaTime()
        LoadUIElements()
        ADelegate = UIApplication.shared.delegate as? AppDelegate
        MainFilter = ADelegate?.Filters
        SampleView = UIImageView(image: UIImage(named: "Norio"))
        SampleView.contentMode = .scaleAspectFit
        ShowingSample = _Settings.bool(forKey: "ShowFilterSampleImages")
        DoEnableSelect = EnableSelectImage
        if !ShowingSample
        {
            DoEnableSelect = false
        }
        tableView.tableFooterView = UIView()
        Filter = FilterType
        FilterID = FilterManager.FilterInfoMap[Filter]!.0
        SampleFilter = Filters.CreateFilter(For: Filter)
        SampleFilter?.InitializeForImage()
        if !(SampleFilter?.Ports().contains(.Input))!
        {
            //User can't change sample images if the filter doesn't accept input. In that case,
            //the generated image is shown instead. Until the image is actually generated, just
            //show a solid color.
            ShowingSample = false
            SampleView.backgroundColor = UIColor.darkGray
            SampleView.image = nil
            SampleView.isUserInteractionEnabled = false
        }
        if ShowingSample
        {
            ImagePicker = UIImagePickerController()
            ImagePicker!.delegate = self
            
            SampleImageName = _Settings.string(forKey: "SampleImage")!
            SampleView.image = UIImage(named: SampleImageName)
            SampleViewImage = UIImage(named: SampleImageName)
            SampleView.backgroundColor = UIColor.darkGray
            SampleView.isUserInteractionEnabled = true
            ShowSampleView()
        }
        let Cell = RatingCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "RatingCell")
        Cell.SetData(FilterType: Filter)
        tableView.tableFooterView = Cell
        
        let End = CACurrentMediaTime()
        print("FilterSettingUIBase(Filter) start-up duration: \(End - Start) seconds")
    }
    
    /// Load common UI elements. Specifically, the Back, Action, and Camera Home buttons are added.
    /// - Note: For some reason, if you don't have any buttons in the toolbar, this function is not able to add new buttons. So, it
    ///         is important that when you create a filter settings UI you leave at least one dummy item in the toolbar or no
    ///         buttons will appear at run time. (This function will remove all original buttons so the dummy button/item will be
    ///         removed.)
    func LoadUIElements()
    {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(HandleAction))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(HandleBBackButton(_:)))
        //See note in function documentation.
        self.toolbarItems?.removeAll()
        self.toolbarItems?.append(UIBarButtonItem(image: UIImage(named: "CameraHome"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(HandleCameraHomeBButton(_:))))
        self.toolbarItems?.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil))
        let PersonIcon = UIBarButtonItem(image: UIImage(named: "PersonIcon"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(HandlePersonButton(_:)))
        self.toolbarItems?.append(PersonIcon)
        if DoEnableSelect
        {
            PersonIcon.isEnabled = true
        }
        else
        {
            PersonIcon.isEnabled = false
        }
    }
    
    /// Contains the image to save/export via the action button.
    var ActionSaveImage: UIImage? = nil
    
    /// Handle the Action button press. Save and/or exports the current sample image.
    ///
    /// - Parameter sender: Not used.
    @objc func HandleAction(_ sender: Any)
    {
        if (SampleFilter?.Ports().contains(.Input))!
        {
            //Have to make sure the image to save is "CGImage-backed" or UIImageWriteToSavedPhotosAlbum will silently fail.
            if let SaveMe = LastSampleImage
            {
                if let ciimg = CIImage(image: SaveMe)
                {
                    //If we're here, the image is well-behaved and we can convert it to CGImage backed easily.
                    let Context = CIContext()
                    let cgimg = Context.createCGImage(ciimg, from: ciimg.extent)
                    ActionSaveImage = UIImage(cgImage: cgimg!)
                }
                else
                {
                    let ciimg = SampleFilter?.LastImageRendered(AsUIImage: false) as! CIImage
                    let Context = CIContext()
                    let cgimg = Context.createCGImage(ciimg, from: ciimg.extent)
                    ActionSaveImage = UIImage(cgImage: cgimg!)
                }
            }
        }
        else
        {
            ActionSaveImage = GetLastGeneratedImage()!
        }
        let Items: [Any] = [self]
        let ACV = UIActivityViewController(activityItems: Items, applicationActivities: nil)
        present(ACV, animated: true)
    }
    
    /// Returns the type of the action item.
    ///
    /// - Parameter activityViewController: Not used.
    /// - Returns: The type of the action item. In our case, a UIImage.
    @objc func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return UIImage()
    }
    
    /// Returns the title (subject) for the Action button.
    ///
    /// - Parameters:
    ///   - activityViewController: Not used.
    ///   - activityType: Not used.
    /// - Returns: Title of the Action.
    @objc func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        return "BumpCamera Sample Output"
    }
    
    /// Handles sending the sample output to the user-specified location.
    ///
    /// - Parameters:
    ///   - activityViewController: Not used.
    ///   - activityType: Describes where the user wants to send the sample image.
    /// - Returns: The sample image.
    @objc func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any?
    {
        let Generated: UIImage = ActionSaveImage!
        
        switch activityType!
        {
        case .postToTwitter:
            return Generated
            
        case .airDrop:
            return Generated
            
        case .copyToPasteboard:
            return Generated
            
        case .mail:
            return Generated
            
        case .postToTencentWeibo:
            return Generated
            
        case .postToWeibo:
            return Generated
            
        case .print:
            return Generated
            
        case .markupAsPDF:
            return Generated
            
        case .message:
            return Generated
            
        default:
            return Generated
        }
    }
    
    /// Handle presses of the camera home button.
    ///
    /// - Parameter sender: Not used.
    @objc func HandleCameraHomeBButton(_ sender: Any)
    {
    }
    
    /// Handle presses of the back button - returns to the calling view controller.
    ///
    /// - Parameter sender: Not used.
    @objc func HandleBBackButton(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func HandlePersonButton(_ sender: Any)
    {
        let Alert = UIAlertController(title: "Manage Sample Image",
                                      message: "Select the action to perform on the sample image.",
                                      preferredStyle: UIAlertController.Style.actionSheet)
        Alert.addAction(UIAlertAction(title: "Select Custom Image", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        Alert.addAction(UIAlertAction(title: "Clear Custom Image", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        Alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(Alert, animated: true, completion: nil)
    }
    
    #if true
    /// Return the contents of the header row, which in our case is the sample image. The sample image is kept in
    /// the header row of the table to make sure it is visible regardless of how far the user scrolls the table.
    ///
    /// - Note: Note: See [How to freeze a table view in Swift](https://stackoverflow.com/questions/43555124/how-to-freeze-a-tableview-cell-in-swift)
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
    /// - Note: See [How to freeze a table view in Swift](https://stackoverflow.com/questions/43555124/how-to-freeze-a-tableview-cell-in-swift)
    ///
    /// - Parameters:
    ///   - tableView: Not used.
    ///   - section: Not used.
    /// - Returns: The vertical height of the header row.
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 180.0
    }
    #endif
    
    #if false
    /// Change the size of the sample image.
    func ChangeImageSize()
    {
        var CurrentHeight = SampleView.frame.size.height
        var CurrentWidth = SampleView.frame.size.width
        print("Old SampleView size: \(CurrentWidth)x\(CurrentHeight)")
        if CurrentHeight == 180.0
        {
            CurrentHeight = CurrentHeight * 2.0
            CurrentWidth = CurrentWidth * 2.0
        }
        else
        {
            CurrentHeight = CurrentHeight / 2.0
            CurrentWidth = CurrentWidth / 2.0
        }
        print("New SampleView size: \(CurrentWidth)x\(CurrentHeight)")
        SampleView.frame.size.height = CurrentHeight
        SampleView.frame.size.width = CurrentWidth
        SizeHeaderToFit()
    }
    #endif
    
    #if true
    override func viewWillAppear(_ animated: Bool)
    {
        #if false
        NotificationCenter.default.addObserver(self, selector: #selector(DefaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
        #endif
        if ShowingSample
        {
            if DoEnableSelect
            {
                let Tap = UITapGestureRecognizer(target: self, action: #selector(HandleSampleSelection))
                SampleView.addGestureRecognizer(Tap)
                let LeftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(HandleSampleChange))
                LeftSwipe.direction = UISwipeGestureRecognizer.Direction.left
                SampleView.addGestureRecognizer(LeftSwipe)
                let RightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(HandleSampleChange))
                RightSwipe.direction = UISwipeGestureRecognizer.Direction.right
                SampleView.addGestureRecognizer(RightSwipe)
            }
        }
    }
    #endif
    
    /// When the view disappears, remove the notification observer.
    ///
    /// - Parameter animated: Passed unchanged to super.viewWillDisappear.
    override func viewWillDisappear(_ animated: Bool)
    {
        #if false
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
        #endif
        super.viewWillDisappear(animated)
    }
    
    #if false
    /// Handle changes in the settings. Specifically, we look for changes to "SampleImage" and update the sample
    /// image as appropriate. Selecting the same image twice in a row results in no action taken.
    ///
    /// - Parameter notification: Notification information.
    @objc func DefaultsChanged(notification: NSNotification)
    {
        if let Defaults = notification.object as? UserDefaults
        {
            if let _ = Defaults.value(forKey: "SampleImage") as? String
            {
                ShowSampleView()
            }
        }
    }
    #endif
    
    #if false
    func AddSampleView()
    {
        let OldFrame = SampleView.frame
        let Ratio = 180.0 / SampleView.frame.size.height
        let NewFrame = CGRect(x: OldFrame.minX, y: OldFrame.minY, width: OldFrame.width * Ratio, height: OldFrame.height * Ratio)
        SampleView.frame = NewFrame
        self.tableView.SetTableHeaderView(HeaderView: SampleView)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        self.SizeHeaderToFit()
    }
    #endif
    
    /// Object used to lock the sample viewer.
    let SampleViewLock = NSObject()
    /// Previous image name.
    var PreviousSampleImage = ""
    
    /// Show the sample. Two types of sample image are supported. On error, the default "Norio" image is used. The current filter
    /// and settings are applied before the image is displayed.
    /// - Supported image types:
    ///     - **Stock image** Image compiled into the binary and referred to by name. The user can select these via the tap handler on
    ///       the sample image.
    ///     - **User customizable** Image selected by the user. This image is copied to a special directory. When this option is selected,
    ///       it is loaded everytime it is selected as the sample image so some performance issues may occur.
    func ShowSampleView()
    {
        objc_sync_enter(SampleViewLock)
        defer{objc_sync_exit(SampleViewLock)}
        
        SampleView.image = nil
        var SampleImage: UIImage!
        var FinalImage: UIImage?
        
        if (SampleFilter?.Ports().contains(.Input))!
        {
            //The filter can take input images - we'll use the standard sample images.
            if var ImageName = _Settings.string(forKey: "SampleImage")
            {
                if PrivacyManager.IsPrivacyViolation(For: .SampleImage) && ImageName == "custom image"
                {
                    //If the user set privacy to not use sample images but previously had a sample
                    //image, reset it to Norio.
                    ImageName = "Norio"
                    _Settings.set("Norio", forKey: "SampleImage")
                }
                if ImageName == "custom image"
                {
                    //print("Looking for custom image.")
                    if let UserSample = FileHandler.GetSampleImage()
                    {
                        SampleImage = UserSample
                        //print("Found custom image.")
                    }
                    else
                    {
                        SampleImage = UIImage(named: "Norio")
                        _Settings.set("Norio", forKey: "SampleImage")
                    }
                }
                else
                {
                    //print("Loading sample image \(ImageName)")
                    SampleImage = UIImage(named: ImageName)
                }
            }
            else
            {
                print("Sample image name invalid - loading default Norio image.")
                SampleImage = UIImage(named: "Norio")
                _Settings.set("Norio", forKey: "SampleImage")
            }
            if CallsFilter
            {
            FinalImage = SampleFilter?.Render(Image: SampleImage)
            }
        }
        else
        {
            //The filter cannot take input images - we'll just call generated on the filter every time the
            //descendent class shows the sample view.
            if let CiImage = SampleFilter?.Generate()
            {
                LastGeneratedImage = CiImage
                FinalImage = UIImage(ciImage: CiImage)
            }
            else
            {
                print("Error converting generated image from CIImage to UIImage.")
                return
            }
        }
        if let TheImage = FinalImage
        {
            SampleView.image = TheImage
            SampleViewImage = TheImage
        }
        LastSampleImage = FinalImage
        #if false
        SizeHeaderToFit()
        #endif
    }
    
    var LastGeneratedImage: CIImage!
    
    /// Return the most recently generated image. Before the image is returned, it is turned into a CG-backed
    /// image to let it be saved and sent without silent failures.
    ///
    /// - Returns: Most recently generated image on success, nil on error (such as no recently generated image,
    ///            conversion errors, and the like).
    func GetLastGeneratedImage() -> UIImage?
    {
        if let Source = LastGeneratedImage
        {
            let ciContext = CIContext()
            let cgImg = ciContext.createCGImage(Source, from: Source.extent)
            if let Final = cgImg
            {
                return UIImage(cgImage: Final)
            }
            return nil
        }
        else
        {
            return nil
        }
    }
    
    var CustomizedImageAvailable: Bool
    {
        get
        {
            if let _ = FileHandler.GetSampleImage()
            {
                return true
            }
            return false
        }
    }
    
    var SampleIndex = 0
    let SampleImageList: [String] =
        [
            "Norio",
            "HamanasuSample",
            "DandelionSample",
            "Painting",
            "BWPortrait",
            "TestPattern",
            "TestPattern2",
            "TestPattern3",
            "MarsBayerEncoded",
            "TheProgrammer",
            "custom image"
    ]
    
    @objc func HandleSampleChange(_ Swipe: UISwipeGestureRecognizer)
    {
        if Swipe.direction == UISwipeGestureRecognizer.Direction .left
        {
            SampleIndex = SampleIndex - 1
            if SampleIndex < 0
            {
                if CustomizedImageAvailable
                {
                    SampleIndex = SampleImageList.count - 1
                }
                else
                {
                    SampleIndex = SampleImageList.count - 2
                }
            }
        }
        else
        {
            SampleIndex = SampleIndex + 1
            if CustomizedImageAvailable
            {
                if SampleIndex > SampleImageList.count - 1
                {
                    SampleIndex = 0
                }
            }
            else
            {
                if SampleIndex > SampleImageList.count - 2
                {
                    SampleIndex = 0
                }
            }
        }
        
        let NewImage = SampleImageList[SampleIndex]
        print("NewImage=\(NewImage) at index \(SampleIndex)")
        _Settings.set(NewImage, forKey: "SampleImage")
        ShowSampleView()
    }
    
    var LastSampleImage: UIImage? = nil
    
    /// Flag that lets the user select various sample images.
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
        let Alert = UIAlertController(title: "Manage Sample Image",
                                      message: "Select the action to perform on the sample image.",
                                      preferredStyle: UIAlertController.Style.actionSheet)
        Alert.addAction(UIAlertAction(title: "Select Custom Image", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        Alert.addAction(UIAlertAction(title: "Clear Custom Image", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
        //Alert.addAction(UIAlertAction(title: "Save Sample Image", style: UIAlertAction.Style.default, handler: HandleNewSampleImage))
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
        switch Action.title
        {
        case "Save Sample Image":
            SaveSampleImage()
            
        case "Select Custom Image":
            GetUserSelectedImage()
            
        case "Clear Custom Image":
            RemoveCustomImage()
            
        default:
            break
        }
    }
    
    func RemoveCustomImage()
    {
        if SampleIndex == SampleImageList.count - 1
        {
            SampleIndex = 0
            ShowSampleView()
        }
        FileHandler.DeleteSampleImage()
    }
    
    /// Run the image picker to let the user select a custom image to use for the sample image.
    /// - Links:
    ///    - [Choosing images with UIImagePickerControl in Swift](https://www.codingexplorer.com/choosing-images-with-uiimagepickercontroller-in-swift/)
    ///    - [Swift Using the UIImagePickerController for a Camera and Photo Library](https://makeapppie.com/2014/12/04/swift-swift-using-the-uiimagepickercontroller-for-a-camera-and-photo-library/)
    func GetUserSelectedImage()
    {
        ImagePicker?.allowsEditing = false
        ImagePicker?.sourceType = .photoLibrary
        present(ImagePicker!, animated: true, completion: nil)
    }
    
    /// Save the passed image to the photo roll. Assumes the user has permission to save images there. See [Saving to User Photo Libary Silently Fails](https://stackoverflow.com/questions/44864432/saving-to-user-photo-library-silently-fails)
    /// - Note: The image is internally converted to different types until it is CGImage-backed to ensure
    ///         UIImageWriteToSavedPhotosAlbum won't silently fail.
    func SaveSampleImage()
    {
        if let SaveMe = LastSampleImage
        {
            var Final: UIImage!
            //Have to make sure the image to save is "CGImage-backed" or UIImageWriteToSavedPhotosAlbum will silently fail.
            if let ciimg = CIImage(image: SaveMe)
            {
                //If we're here, the image is well-behaved and we can convert it to CGImage backed easily.
                let Context = CIContext()
                let cgimg = Context.createCGImage(ciimg, from: ciimg.extent)
                //print("ciimage.extent=\(ciimg.extent)")
                Final = UIImage(cgImage: cgimg!)
            }
            else
            {
                let ciimg = SampleFilter?.LastImageRendered(AsUIImage: false) as! CIImage
                let Context = CIContext()
                //print("ciiage.extentX=\(ciimg.extent)")
                let cgimg = Context.createCGImage(ciimg, from: ciimg.extent)
                Final = UIImage(cgImage: cgimg!)
            }
            UIImageWriteToSavedPhotosAlbum(Final, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        else
        {
            print("Error saving image.")
        }
    }
    
    /// Completion block for saving images to the photo roll. Will display an error message if the save was unsuccessful, and
    /// a "saved OK" message if there was no error.
    ///
    /// - Parameters:
    ///   - image: Not used.
    ///   - error: Error information for when errors occur.
    ///   - contextInfo: Not used.
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer)
    {
        if let SaveError = error
        {
            let Alert = UIAlertController(title: "Image Save Error", message: SaveError.localizedDescription, preferredStyle: .alert)
            Alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(Alert, animated: true)
        }
        else
        {
            let Alert = UIAlertController(title: "Sample Image Saved", message: "The sample image with current effect parameters has been saved to the photo roll.", preferredStyle: .alert)
            Alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(Alert, animated: true)
        }
    }
    
    /// Handle the image picker completion. On successful selection of a new image, the image will be saved to a special
    /// directory where it can be retrieved at will. The image will also be immediately used for the sample image. On error,
    /// an alert is shown to let the user know there was an issue.
    ///
    /// - Parameters:
    ///   - picker: The UIImagePickerController. Will be dismissed at end of function.
    ///   - info: Dictionary that contains the image (or not, if the user canceled).
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        if let PickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        {
            SampleView.image = PickedImage
            SampleViewImage = PickedImage
            let OK = FileHandler.SaveSampleImage(PickedImage)
            if OK
            {
                print("Sample image saved successfully.")
                ShowSampleView()
            }
            else
            {
                let Alert = UIAlertController(title: "Error Saving", message: "There was an error saving your image to BumpCamera's data directory.", preferredStyle: UIAlertController.Style.alert)
                Alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                present(Alert, animated: true, completion: nil)
            }
        }
        else
        {
            print("User canceled image picker.")
        }
        picker.dismiss(animated: true, completion: nil)
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
    
    /// Holds various keyboards.
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
    
    func LogChange()
    {
        #if DEBUG
        let FilterName = FilterManager.GetFilterTitle(Filter)
        let IsActive = ADelegate?.Filters?.IsActive(Filter)
        let FilterDesc = FilterManager.GetFilterSettingString(For: SampleFilter!,
                                                              FrameNumber: nil,
                                                              TimeStamp: Date(),
                                                              ActiveFilter: IsActive!,
                                                              ShowVersionInfo: false)
        ActivityLog.LogPrint("Edited parameter for \((FilterName)!)", FilterData: FilterDesc)
        #endif
    }
    
    /// Save a filter settings double value to user settings.
    ///
    /// - Parameters:
    ///   - WithValue: Value to save.
    ///   - ToField: Indicates the field where the value will be saved.
    func UpdateValue(WithValue: Double, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
        LogChange()
    }
    
    /// Save a filter settings integer value to user settings.
    ///
    /// - Parameters:
    ///   - WithValue: Value to save.
    ///   - ToField: Indicates the field where the value will be saved.
    func UpdateValue(WithValue: Int, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
        LogChange()
    }
    
    /// Save a filter settings boolean value to user settings.
    ///
    /// - Parameters:
    ///   - WithValue: Value to save.
    ///   - ToField: Indicates the field where the value will be saved.
    func UpdateValue(WithValue: Bool, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
        LogChange()
    }
    
    /// Save a filter settings string value to user settings.
    ///
    /// - Parameters:
    ///   - WithValue: Value to save.
    ///   - ToField: Indicates the field where the value will be saved.
    func UpdateValue(WithValue: String, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
        LogChange()
    }
    
    /// Save a filter settings CGPoint to user settings.
    ///
    /// - Parameters:
    ///   - WithValue: Value to save.
    ///   - ToField: Indicates the field where the value will be saved.
    func UpdateValue(WithValue: CGPoint, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
        LogChange()
    }
    
    /// Save a filter settings CIVector to user settings.
    ///
    /// - Note: The vector is internally converted to a CGPoint before being saved.
    ///
    /// - Parameters:
    ///   - WithValue: Value to save.
    ///   - ToField: Indicates the field where the value will be saved.
    func UpdateValue(WithValue: CIVector, ToField: FilterManager.InputFields)
    {
        let NewPoint = CGPoint(x: WithValue.x, y: WithValue.y)
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: NewPoint as Any?)
        LogChange()
    }
    
    /// Save a filter settings UIColor value to user settings.
    ///
    /// - Parameters:
    ///   - WithValue: Value to save.
    ///   - ToField: Indicates the field where the value will be saved.
    func UpdateValue(WithValue: UIColor, ToField: FilterManager.InputFields)
    {
        ParameterManager.SetField(To: FilterID, Field: ToField, Value: WithValue as Any?)
        LogChange()
    }
}

#if false
extension UITableView
{
    func SetTableHeaderView(HeaderView: UIView)
    {
        HeaderView.translatesAutoresizingMaskIntoConstraints = false
        self.tableHeaderView = HeaderView
        HeaderView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        HeaderView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        HeaderView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
    }
}

extension FilterSettingUIBase
{
    //https://spin.atomicobject.com/2017/08/11/swift-extending-uitableviewcontroller/
    func SizeHeaderToFit()
    {
        if let HeaderView = tableView.tableHeaderView
        {
            print("Setting constraints on sample view.")
            SampleView.centerXAnchor.constraint(equalTo: HeaderView.centerXAnchor).isActive = true
            SampleView.centerYAnchor.constraint(equalTo: HeaderView.centerYAnchor).isActive = true
            HeaderView.setNeedsLayout()
            HeaderView.layoutIfNeeded()
            
            let Height = HeaderView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var Frame = HeaderView.frame
            Frame.size.height = Height
            tableView.tableHeaderView = HeaderView
        }
    }
    
    //https://spin.atomicobject.com/2017/08/11/swift-extending-uitableviewcontroller/
    func SizeFooterToFit()
    {
        if let FooterView = tableView.tableFooterView
        {
            FooterView.setNeedsLayout()
            FooterView.layoutIfNeeded()
            
            let Height = FooterView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var Frame = FooterView.frame
            Frame.size.height = Height
            tableView.tableFooterView = FooterView
        }
    }
}
#endif
