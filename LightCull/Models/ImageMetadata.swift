//
//  ImageMetadata.swift
//  LightCull
//
//  Represents the metadata of an image (EXIF data + file info)
//

import Foundation

struct ImageMetadata {
    
    // MARK: - File Information
    // These fields are ALWAYS present, therefore not Optionals
    let fileName: String
    let fileSize: String

    // MARK: - Camera Information (EXIF)
    // These fields are OPTIONAL, as not every image has this data
    // (e.g. screenshots, edited images, etc.)
    let cameraMake: String?
    let cameraModel: String?
    let focalLength: String?
    let aperture: String?
    let shutterSpeed: String?
    let iso: String?
}

// MARK: - Convenience Initializer

extension ImageMetadata {
    /// Creates an ImageMetadata object with only file information
    /// Useful when no EXIF data is available
    /// - Parameters:
    ///   - fileName: Name of the file
    ///   - fileSize: Formatted file size
    init(fileName: String, fileSize: String) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.cameraMake = nil
        self.cameraModel = nil
        self.focalLength = nil
        self.aperture = nil
        self.shutterSpeed = nil
        self.iso = nil
    }
}
