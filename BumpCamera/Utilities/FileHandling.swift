//
//  FileManager.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit

/// Class that handles saving and retrieving files in the documents directory.
class FileHandler
{
    /// Name of the directory where user sample images (for viewing filter settings) are stored.
    static let SampleDirectory = "/UserSample"
    
    /// Name of the directory where scratch images are saved (for the purposes of appending meta data before
    /// being moved to the photo roll).
    static let ScratchDirectory = "/Scratch"
    
    /// Name of the directory where performance data is exported.
    static let PerformanceDirectory = "/Performance"
    
    /// Name of the directory used at runtime.
    static let RuntimeDirectory = "/Runtime"
    
    /// Name of the directory used for debugging.
    static let DebugDirectory = "/Debug"
    
    /// Determines if the passed directory exists. If it does not, it is created.
    ///
    /// - Note: A false return indicates something is terribly wrong and execution should stop.
    ///
    /// - Parameter DirectoryName: The name of the directory to test for existence. This name will be used
    ///                            to create the directory if it does not exist.
    /// - Returns: True on success (the directory already existed or was created successfully), false on error (the
    ///            directory does not exist and could not be created). A false return value indicates a fatal error
    ///            and execution should stop as soon as posible.
    public static func CreateIfDoesNotExist(DirectoryName: String) -> Bool
    {
        if DirectoryExists(DirectoryName: DirectoryName)
        {
            #if DEBUG
            print("\(DirectoryName) exists.")
            #endif
            return true
        }
        else
        {
            let DirURL = CreateDirectory(DirectoryName: DirectoryName)
            if DirURL == nil
            {
                print("Error creating \(DirectoryName)")
                return false
            }
        }
        #if DEBUG
        print("\(DirectoryName) created.")
        #endif
        return true
    }
    
    /// Returns an URL for the document directory.
    ///
    /// - Returns: Document directory URL on success, nil on error.
    public static func GetDocumentDirectory() -> URL?
    {
        let Dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return Dir
    }
    
    /// Determines if the passed directory exists. The document directory is used as the root directory (eg,
    /// the directory name is appended to the document directory).
    ///
    /// - Parameter DirectoryName: The directory to check for existence. The name of the directory is searched
    ///                            from the document directory.
    /// - Returns: True if the directory exists, false if not.
    public static func DirectoryExists(DirectoryName: String) -> Bool
    {
        let CPath = GetDocumentDirectory()?.appendingPathComponent(DirectoryName)
        if CPath == nil
        {
            return false
        }
        return FileManager.default.fileExists(atPath: CPath!.path)
    }
    
    /// Create a directory in the document directory.
    ///
    /// - Parameter DirectoryName: Name of the directory to create.
    /// - Returns: URL of the newly created directory on success, nil on error.
    @discardableResult public static func CreateDirectory(DirectoryName: String) -> URL?
    {
        var CPath: URL!
        do
        {
            CPath = GetDocumentDirectory()?.appendingPathComponent(DirectoryName)
            try FileManager.default.createDirectory(atPath: CPath!.path, withIntermediateDirectories: true, attributes: nil)
        }
        catch
        {
            print("Error creating directory \(CPath.path): \(error.localizedDescription)")
            return nil
        }
        return CPath
    }
    
    /// Returns the URL of the passed directory. The directory is assumed to be a sub-directory of the
    /// document directory.
    ///
    /// - Parameter DirectoryName: Name of the directory whose URL is returned.
    /// - Returns: URL of the directory on success, nil if not found.
    public static func GetDirectoryURL(DirectoryName: String) -> URL?
    {
        if !DirectoryExists(DirectoryName: DirectoryName)
        {
            return nil
        }
        let CPath = GetDocumentDirectory()?.appendingPathComponent(DirectoryName)
        return CPath
    }
    
    /// Return an URL to the scratch directory.
    ///
    /// - Returns: URL of the directory on success, nil if not found.
    public static func ScratchDirectoryURL() -> URL?
    {
        return GetDirectoryURL(DirectoryName: ScratchDirectory)
    }
    
    /// Remove all files from the given directory.
    ///
    /// - Note: [Delete files from directory](https://stackoverflow.com/questions/32840190/delete-files-from-directory-inside-document-directory)
    ///
    /// - Parameter Name: Name of the directory whose contents will be deleted.
    /// - Returns: True on success, false on failure.
    @discardableResult public static func ClearDirectory(_ Name: String) -> Bool
    {
        if !DirectoryExists(DirectoryName: Name)
        {
            return false
        }
        let CPath = GetDocumentDirectory()?.appendingPathComponent(Name)
        do
        {
            let Contents = try FileManager.default.contentsOfDirectory(atPath: CPath!.path)
            for Content in Contents
            {
                let ContentPath = CPath?.appendingPathComponent(Content)
                do
                {
                    try FileManager.default.removeItem(at: ContentPath!)
                }
                catch
                {
                    print("Error removing \((ContentPath?.path)!): \(error.localizedDescription)")
                    return false
                }
            }
        }
        catch
        {
            print("Error getting contents of \(CPath!.path): \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    /// Return a list of all files (in URL form) in the passed directory.
    ///
    /// - Parameters:
    ///   - Directory: URL of the directory whose contents will be returned.
    ///   - FilterBy: How to filter the results. This is assumed to be a list of file extensions.
    /// - Returns: List of files in the specified directory.
    public static func GetFilesIn(Directory: URL, FilterBy: String? = nil) -> [URL]?
    {
        var URLs: [URL]!
        do
        {
            URLs = try FileManager.default.contentsOfDirectory(at: Directory, includingPropertiesForKeys: nil)
        }
        catch
        {
            return nil
        }
        if FilterBy != nil
        {
            let Scratch = URLs.filter{$0.pathExtension == FilterBy!}
            URLs.removeAll()
            for SomeURL in Scratch
            {
                URLs.append(SomeURL)
            }
        }
        return URLs
    }
    
    /// Return an image from the passed URL.
    ///
    /// - Parameter From: URL of the image (including all directory parts).
    /// - Returns: UIImage form of the image at the passed URL. Nil on error or file not found.
    public static func LoadImage(_ From: URL) -> UIImage?
    {
        if InMaximumPrivacy()
        {
            print("In Maximum Privacy mode. No reading of directories allowed.")
            return nil
        }
        do
        {
            let ImageData = try Data(contentsOf: From)
            let Final = UIImage(data: ImageData)
            return Final
        }
        catch
        {
            print("Error loading image at \(From.path): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Save an image to the specified directory.
    ///
    /// - Parameters:
    ///   - Image: The UIImage to save.
    ///   - WithName: The name to use when saving the image.
    ///   - InDirectory: The directory in which to save the image.
    ///   - AsJPG: If true, save as a .JPG image. If false, save as a .PNG image.
    /// - Returns: True on success, nil on failure.
    public static func SaveImage(_ Image: UIImage, WithName: String, InDirectory: URL, AsJPG: Bool = true) -> Bool
    {
        if InMaximumPrivacy()
        {
            print("In Maximum Privacy mode. No image writing allowed.")
            return false
        }
        if AsJPG
        {
            if let Data = Image.jpegData(compressionQuality: 1.0)
            {
                let FileName = InDirectory.appendingPathComponent(WithName)
                do
                {
                    try Data.write(to: FileName)
                }
                catch
                {
                    print("Error writing \(FileName.path): \(error.localizedDescription)")
                    return false
                }
            }
        }
        else
        {
            if let Data = Image.pngData()
            {
                let FileName = InDirectory.appendingPathComponent(WithName)
                do
                {
                    try Data.write(to: FileName)
                }
                catch
                {
                    print("Error writing \(FileName.path): \(error.localizedDescription)")
                    return false
                }
            }
        }
        return true
    }
    
    /// Save an image to the specified directory.
    ///
    /// - Parameters:
    ///   - Image: The UIImage to save.
    ///   - WithName: The name to use when saving the image.
    ///   - Directory: Name of the directory where to save the image.
    ///   - AsJPG: If true, save as a .JPG image. If false, save as a .PNG image.
    /// - Returns: True on success, nil on failure.
    public static func SaveImage(_ Image: UIImage, WithName: String, Directory: String, AsJPG: Bool = true) -> Bool
    {
        if !DirectoryExists(DirectoryName: Directory)
        {
            CreateDirectory(DirectoryName: Directory)
        }
        let FinalDirectory = GetDirectoryURL(DirectoryName: Directory)
        return SaveImage(Image, WithName: WithName, InDirectory: FinalDirectory!, AsJPG: AsJPG)
    }
    
    /// Save an image the user has selected as a sample image for filter settings.
    ///
    /// - Parameter SampleImage: The sample image in UIImage format.
    /// - Returns: True on success, false on failure.
    public static func SaveSampleImage(_ SampleImage: UIImage) -> Bool
    {
        return SaveImage(SampleImage, WithName: "UserSelected.jpg", Directory: SampleDirectory, AsJPG: true)
    }
    
    /// Save an image to the scratch directory.
    ///
    /// - Parameters:
    ///   - ScratchImage: The image to save to the scratch directory.
    ///   - WithName: The name to use when saving the image.
    /// - Returns: True on success, false on failure.
    public static func SaveScratchImage(_ ScratchImage: UIImage, WithName: String) -> Bool
    {
        return SaveImage(ScratchImage, WithName: WithName, Directory: ScratchDirectory, AsJPG: true)
    }
    
    /// Return the user-selected sample image previously stored in the sample image directory.
    ///
    /// - Returns: The sample image as a UIImage on success, nil if not found or on failure.
    public static func GetSampleImage() -> UIImage?
    {
        if InMaximumPrivacy()
        {
            print("In Maximum Privacy mode. No sample images allowed.")
            return nil
        }
        if !DirectoryExists(DirectoryName: SampleDirectory)
        {
            CreateDirectory(DirectoryName: SampleDirectory)
        }
        if let SampleURL = GetDirectoryURL(DirectoryName: SampleDirectory)
        {
            if let Images = GetFilesIn(Directory: SampleURL)
            {
                if Images.count < 1
                {
                    print("No files returned from " + SampleDirectory)
                    return nil
                }
                return LoadImage(Images[0])
            }
            else
            {
                print("No images found in " + SampleDirectory)
                return nil
            }
        }
        else
        {
            print("Error getting URL for " + SampleDirectory)
            return nil
        }
    }
    
    /// Return the name of the user-selected sample image previously stored in the sample image directory.
    ///
    /// - Returns: The name of the sample image on success, nil on failure.
    public static func GetSampleImageName() -> String?
    {
        if InMaximumPrivacy()
        {
            print("In Maximum Privacy mode. No sample images allowed.")
            return nil
        }
        if !DirectoryExists(DirectoryName: SampleDirectory)
        {
            return nil
        }
        if let SampleURL = GetDirectoryURL(DirectoryName: SampleDirectory)
        {
            if let Images = GetFilesIn(Directory: SampleURL)
            {
                if Images.count < 1
                {
                    print("No files returned.")
                    return nil
                }
                return Images[0].path
            }
            else
            {
                print("No files found in " + SampleDirectory)
                return nil
            }
        }
        else
        {
            print("Error getting URL for " + SampleDirectory)
            return nil
        }
    }
    
    /// Delete the file at the specified URL.
    ///
    /// - Parameter FileURL: The URL of the file to delete.
    /// - Returns: True if the file was deleted, false if not.
    public static func DeleteFile(_ FileURL: URL) -> Bool
    {
        if !FileManager.default.fileExists(atPath: FileURL.path)
        {
            print("Unable to find the file \(FileURL.path) - cannot delete.")
            return false
        }
        do
        {
            try FileManager.default.removeItem(at: FileURL)
            return true
        }
        catch
        {
            print("Error deleting file \(FileURL.path): error: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Delete the sample image in the sample image directory.
    ///
    /// - Returns: True if the file was deleted, false if not (for any reason - not necessarily an error).
    @discardableResult public static func DeleteSampleImage() -> Bool
    {
        if !DirectoryExists(DirectoryName: SampleDirectory)
        {
            //No sample directory. Nothing to delete. Nothing deleted.
            return false
        }
        if let SampleDirURL = GetDirectoryURL(DirectoryName: SampleDirectory)
        {
            if let Images = GetFilesIn(Directory: SampleDirURL)
            {
                if Images.count < 1
                {
                    return false
                }
                return DeleteFile(Images[0])
            }
            else
            {
                return false
            }
        }
        else
        {
            return false
        }
    }
    
    /// Save the contents of the passed string to a file with the passed file name. The file is saved in BumpCamera's
    /// performance directory.
    ///
    /// - Parameters:
    ///   - SaveMe: Contains the string to save.
    ///   - FileName: The name of the file to save.
    /// - Returns: True on success, false on failure.
    @discardableResult public static func SaveStringToFile(_ SaveMe: String, FileName: String) -> Bool
    {
        if InMaximumPrivacy()
        {
            print("In Maximum Privacy mode. No writing allowed.")
            return false
        }
        let SaveDirectory = GetDirectoryURL(DirectoryName: PerformanceDirectory)
        let FinalFile = SaveDirectory?.appendingPathComponent(FileName)
        do
        {
            try SaveMe.write(to: FinalFile!, atomically: false, encoding: .utf8)
        }
        catch
        {
            print("Error saving string to \(FinalFile!.path): error: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    /// Save the contents of the passed string to a file with the passed file name. The file will be saved in the
    /// indicated directory.
    ///
    /// - Parameters:
    ///   - SaveMe: Contains the string to save.
    ///   - FileName: The name of the file to save.
    ///   - ToDirectory: The name of the directory.
    /// - Returns: True on success, false on failure.
    @discardableResult public static func SaveStringToFile(_ SaveMe: String, FileName: String, ToDirectory: String) -> Bool
    {
        if InMaximumPrivacy()
        {
            print("In Maximum Privacy mode. No writing allowed.")
            return false
        }
        let SaveDirectory = GetDirectoryURL(DirectoryName: ToDirectory)
        let FinalFile = SaveDirectory?.appendingPathComponent(FileName)
        do
        {
            try SaveMe.write(to: FinalFile!, atomically: false, encoding: .utf8)
        }
        catch
        {
            print("Error saving string to \(FinalFile!.path): error: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    /// Save the contents of the passed string to a file with the passed file name. The file will be saved in the
    /// indicated directory. The URL to the saved file will be returned on success.
    ///
    /// - Parameters:
    ///   - SaveMe: Contains the string to save.
    ///   - FileName: The name of the file to save.
    ///   - ToDirectory: The name of the directory.
    /// - Returns: The URL of the saved file on success, nil on error.
    @discardableResult public static func SaveStringToFileEx(_ SaveMe: String, FileName: String, ToDirectory: String) -> URL?
    {
        if InMaximumPrivacy()
        {
            print("In Maximum Privacy mode. No writing allowed.")
            return nil
        }
        let SaveDirectory = GetDirectoryURL(DirectoryName: ToDirectory)
        let FinalFile = SaveDirectory?.appendingPathComponent(FileName)
        do
        {
            try SaveMe.write(to: FinalFile!, atomically: false, encoding: .utf8)
        }
        catch
        {
            print("Error saving string to \(FinalFile!.path): error: \(error.localizedDescription)")
            return nil
        }
        return FinalFile
    }
    
    /// Returns the current state of the maximum privacy flag in user settings.
    ///
    /// - Returns: Current maximum privacy state. If false, nothing should be written.
    private static func InMaximumPrivacy() -> Bool
    {
        return UserDefaults.standard.bool(forKey: "MaximumPrivacy")
    }
    
    /// This function should be called to delete all data in all directories created by BumpCamera. It is called by
    /// the Privacy view controller when the user enables Maximum Privacy.
    ///
    /// - Parameter IncludingDebug: Determines if the debug directory is cleared as well.
    public static func ClearAllDirectories(IncludingDebug: Bool = false)
    {
        print("Clearing all directories.")
        ClearDirectory(SampleDirectory)
        print("Sample directory cleared.")
        ClearDirectory(ScratchDirectory)
        print("Scratch directory cleared.")
        ClearDirectory(PerformanceDirectory)
        print("Performance directory cleared.")
        ClearDirectory(RuntimeDirectory)
        print("Runtime directory cleared.")
        if IncludingDebug
        {
            ClearDirectory(DebugDirectory)
        }
    }
}
