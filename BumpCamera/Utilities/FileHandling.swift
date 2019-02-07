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
    
    /// Return the user-selected sample image previously stored in the sample image directory.
    ///
    /// - Returns: The sample image as a UIImage on success, nil if not found or on failure.
    public static func GetSampleImage() -> UIImage?
    {
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
}
