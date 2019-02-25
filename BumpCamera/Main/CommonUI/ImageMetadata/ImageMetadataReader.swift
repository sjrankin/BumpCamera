//
//  ImageMetadataReader.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 2/25/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

/// This class reads metadata from images and constructs a simple tree with the results. All values read are cast to strings.
/// - Note: [Exif data read and write](https://stackoverflow.com/questions/40175160/exif-data-read-and-write)
class ImageMetadataReader
{
    /// Initializer. Fails on bad URL or bad file reads.
    ///
    /// - Parameter FileURL: The URL of the image whose metadata is intended to be read.
    init?(FileURL: URL)
    {
        if FileURL.path.isEmpty
        {
            return nil
        }
        if let RawData = LoadImageFromURL(FileURL)
        {
            if ParseDictionary(RawData)
            {
                SortDictionary()
                return
            }
            else
            {
                return nil
            }
        }
        else
        {
            return nil
        }
    }
    
    /// Load an image from the passed URL and read and return the metadata in that image.
    ///
    /// - Parameter FileURL: The URL of the file to read.
    /// - Returns: Metadata read from the image on success, nil on failure.
    func LoadImageFromURL(_ FileURL: URL) -> [String: Any]?
    {
        if let ImageSource = CGImageSourceCreateWithURL(FileURL as CFURL, nil)
        {
            let ImageProperties = CGImageSourceCopyPropertiesAtIndex(ImageSource, 0, nil)
            if let RawDictionary = ImageProperties as? [String: Any]
            {
                return RawDictionary
            }
            else
            {
                return nil
            }
        }
        else
        {
            return nil
        }
    }
    
    /// Group names we separate metadata into.
    let GroupNames = [String(kCGImagePropertyMakerAppleDictionary), String(kCGImagePropertyMakerCanonDictionary),
                      String(kCGImagePropertyMakerPentaxDictionary), String(kCGImagePropertyMakerFujiDictionary),
                      String(kCGImagePropertyMakerNikonDictionary), String(kCGImagePropertyMakerMinoltaDictionary),
                      String(kCGImagePropertyMakerOlympusDictionary),
                      "{MakerSony}", "{MakerKodak}",
                      String(kCGImagePropertyExifDictionary), String(kCGImagePropertyExifAuxDictionary),
                      String(kCGImagePropertyTIFFDictionary), String(kCGImagePropertyIPTCDictionary),
                      String(kCGImagePropertyGIFDictionary), String(kCGImagePropertyJFIFDictionary),
                      String(kCGImagePropertyPNGDictionary), String(kCGImagePropertyGPSDictionary),
                      String(kCGImagePropertyRawDictionary), String(kCGImagePropertyCIFFDictionary),
                      String(kCGImageProperty8BIMDictionary), String(kCGImagePropertyDNGDictionary)]
    
    /// Readable group name map.
    let ReadableNames =
        [
            String(kCGImagePropertyMakerAppleDictionary): "Apple",
            String(kCGImagePropertyMakerCanonDictionary): "Canon",
            String(kCGImagePropertyMakerPentaxDictionary): "Pentax",
            String(kCGImagePropertyMakerFujiDictionary): "Fuji",
            String(kCGImagePropertyMakerNikonDictionary): "Nikon",
            String(kCGImagePropertyMakerMinoltaDictionary): "Minolta",
            String(kCGImagePropertyMakerOlympusDictionary): "Olympus",
            "{MakerSony}": "Sony",
            "{MakeKodak}": "Kodak",
            String(kCGImagePropertyExifDictionary): "Exif",
            String(kCGImagePropertyExifAuxDictionary): "Aux Exif",
            String(kCGImagePropertyTIFFDictionary): "TIFF",
            String(kCGImagePropertyIPTCDictionary): "ITPC",
            String(kCGImagePropertyGIFDictionary): "GIF",
            String(kCGImagePropertyJFIFDictionary): "JFIF",
            String(kCGImagePropertyPNGDictionary): "PNG",
            String(kCGImagePropertyGPSDictionary): "GPS",
            String(kCGImagePropertyRawDictionary): "Raw",
            String(kCGImagePropertyCIFFDictionary): "CIFF",
            String(kCGImageProperty8BIMDictionary): "8BIM",
            String(kCGImagePropertyDNGDictionary): "DNG"
    ]
    
    /// Parse a raw dictionary read from image metadata into the metadata tree that will be found in this class' Metadata property
    /// on success.
    ///
    /// - Parameter Raw: The raw metadata data dictionary (from LoadImageFromULR) to parse.
    /// - Returns: True on success, false on failure. On success, the results ar found in the Metadata property. On failure, the
    ///            Metadata property is set to nil.
    func ParseDictionary(_ Raw: [String: Any]) -> Bool
    {
        Metadata = ImageMetadata()
        let Top = Metadata?.AddGroup(ImageMetadata.TopLevelName)
        
        for (Key, Value) in Raw
        {
            if GroupNames.contains(Key)
            {
                if let GroupDictionary = Value as? [String: Any]
                {
                    var NiceGroupName = ""
                    if ReadableNames[Key] == nil
                    {
                        NiceGroupName = Key
                    }
                    else
                    {
                        NiceGroupName = ReadableNames[Key]!
                    }
                    DoParseDictionary(GroupDictionary, WithName: NiceGroupName, AddTo: Metadata!)
                }
                else
                {
                    print("Error casting dictionary to [String: Any]")
                    Metadata = nil
                    return false
                }
            }
            else
            {
                Top!.TagList.append(TagTypes(Key, "\(Value)"))
            }
        }
        return true
    }
    
    /// Parse a metadata group (with a name found in GroupNames).
    ///
    /// - Parameters:
    ///   - Raw: The raw dictionary with the group.
    ///   - WithName: Nice (eg, human) readable for the group.
    /// - Returns: TagGroup with parsed data.
    private func DoParseDictionary(_ Raw: [String: Any], WithName: String, AddTo: ImageMetadata)
    {
        let Group = AddTo.AddGroup(WithName)
        Group.GroupName = WithName
        for (Key, Value) in Raw
        {
            let scratch = "\(Value)"
            let FinalValue = scratch.replacingOccurrences(of: "\n", with: " ")
            Group.TagList.append(TagTypes(Key, "\(FinalValue)"))
        }
    }
    
    /// Sort the dictionary by group name.
    public func SortDictionary()
    {
        if Metadata == nil
        {
            print("No dictionary data to sort.")
            return
        }
        Metadata?.Sort()
    }
    
    /// Holds the image's metadata.
    private var _Metadata: ImageMetadata? = nil
    /// Get or set the metadata for the image. (Setting doesn't make much sense...) If nil, either no image has been read or
    /// there was an error reading the image's meta data.
    public var Metadata: ImageMetadata?
    {
        get
        {
            return _Metadata
        }
        set
        {
            _Metadata = newValue
        }
    }
}
