//
//  MetadataService.swift
//  LightCull
//
//  Created by Kevin Stamp on 02.10.25.
//
//  Responsible for: Reading EXIF data and file information from images
//

import Foundation
import ImageIO


class MetadataService {
    
    // MARK: - Public Interface
    func extractMetadata(from url: URL) -> ImageMetadata?{
        
        // CGImageSourceCreateWithURL is a "reader" for the image file
        // (we don't load the entire image into memory, only the metadata)
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            print("Could not create ImageSource for: \(url.lastPathComponent)")
            return nil
        }
        
        let fileName = url.lastPathComponent
        let fileSize = formatFileSize(for: url)
        
        // Get Properties Dictionary from image -> The Dictionary contains ALL metadata
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            // If no properties are available, return only the basic info
            print("No properties found for: \(fileName)")
            return ImageMetadata(fileName: fileName, fileSize: fileSize)
        }
        
        // Extract EXIF sub-dictionary
        guard let exifData = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] else {
            print("No EXIF data found for: \(fileName)")
            return ImageMetadata(fileName: fileName, fileSize: fileSize)
        }
        
        
        // Manufacturer info is often in the TIFF dictionary, not in EXIF
        let tiffData = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        
        // Extract and format individual EXIF values
        let cameraMake = tiffData?[kCGImagePropertyTIFFMake as String] as? String
        let cameraModel = tiffData?[kCGImagePropertyTIFFModel as String] as? String
        let focalLength = formatFocalLength(from: exifData)
        let aperture = formatAperture(from: exifData)
        let shutterSpeed = formatShutterSpeed(from: exifData)
        
        
        return ImageMetadata(
            fileName: fileName,
            fileSize: fileSize,
            cameraMake: cameraMake,
            cameraModel: cameraModel,
            focalLength: focalLength,
            aperture: aperture,
            shutterSpeed: shutterSpeed
        )
    }
    
    
    // MARK: - Helper Methods
    
    private func formatFileSize(for url: URL) -> String {
        let fileManager = FileManager.default
        
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path), let sizeInBytes = attributes[.size] as? Int64 else {
            return "Unknown"
        }
        
        // ByteCountFormatter is an Apple helper that automatically chooses the right unit (Bytes, KB, MB, GB)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useMB, .useKB]
        
        return formatter.string(fromByteCount: sizeInBytes)
    }
    
    
    private func formatFocalLength(from exifData: [String: Any]) -> String? {
        guard let focalLength = exifData[kCGImagePropertyExifFocalLength as String] as? Double else {
            return nil
        }
        
        // Formatting: No decimal places + " mm"
        return String(format: "%.0f mm", focalLength)
    }
    
    
    private func formatAperture(from exifData: [String: Any]) -> String? {
        // EXIF stores aperture as "F-Number" (e.g. 2.8 for f/2.8)
        guard let aperture = exifData[kCGImagePropertyExifFNumber as String] as? Double else {
            return nil
        }
        
        // Formatting: "f/" + one decimal place
        return String(format: "f/%.1f", aperture)
    }
    
    
    private func formatShutterSpeed(from exifData: [String: Any]) -> String? {
        // EXIF stores exposure time as decimal number in seconds
        // e.g. 0.004 = 1/250s, or 2.5 = 2.5 seconds
        guard let exposureTime = exifData[kCGImagePropertyExifExposureTime as String] as? Double else {
            return nil
        }
        
        // If the time is >= 1 second, show as decimal number
        if exposureTime >= 1.0 {
            return String(format: "%.1fs", exposureTime)
        }
        
        // If < 1 second, show as fraction (e.g. "1/250s")
        // Calculation: 1 / 0.004 = 250
        let denominator = Int(1.0 / exposureTime)
        return "1/\(denominator)s"
    }
}
