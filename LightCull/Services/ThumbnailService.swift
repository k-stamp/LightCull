//
//  ThumbnailService.swift
//  LightCull
//
//  Responsible for: Generating and managing thumbnail cache
//

import Foundation
import CoreGraphics
import ImageIO
import OSLog
import UniformTypeIdentifiers

class ThumbnailService {

    // MARK: - Constants

    // Thumbnail size: 200x200 pixels
    private let thumbnailSize: CGFloat = 200.0

    // JPEG compression quality (0.0 to 1.0)
    private let jpegQuality: CGFloat = 0.8


    // MARK: - Cache Directory Management

    /// Returns the URL of the cache directory
    /// Example: ~/Library/Caches/LightCull/current/
    nonisolated private func getCacheDirectoryURL() -> URL {
        let fileManager = FileManager.default

        // Get the system cache directory
        let cachesDirectory: URL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]

        // Build the path: Caches/LightCull/current/
        let lightCullCache: URL = cachesDirectory.appendingPathComponent("LightCull")
        let currentCache: URL = lightCullCache.appendingPathComponent("current")

        return currentCache
    }

    /// Clears the entire cache directory
    /// This is called on app startup and when the folder changes
    func clearCache() {
        let fileManager = FileManager.default

        // Get the root cache directory (LightCull, not current)
        let cachesDirectory: URL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let lightCullCache: URL = cachesDirectory.appendingPathComponent("LightCull")

        // Check if the directory exists
        if fileManager.fileExists(atPath: lightCullCache.path) {
            // Delete entire directory
            do {
                try fileManager.removeItem(at: lightCullCache)
                Logger.fileOps.info("Cache cleared: \(lightCullCache.path)")
            } catch {
                Logger.fileOps.error("Error clearing cache: \(error.localizedDescription)")
            }
        } else {
            Logger.fileOps.debug("Cache directory does not exist - nothing to clear")
        }
    }

    /// Creates the cache directory if it doesn't exist
    /// - Returns: true if directory exists or was created, false on error
    private func ensureCacheDirectoryExists() -> Bool {
        let fileManager = FileManager.default
        let cacheURL: URL = getCacheDirectoryURL()

        // Check if directory already exists
        var isDirectory: ObjCBool = false
        let exists: Bool = fileManager.fileExists(atPath: cacheURL.path, isDirectory: &isDirectory)

        if exists && isDirectory.boolValue {
            // Directory already exists - all good
            return true
        }

        // Directory doesn't exist - create it
        do {
            try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
            Logger.fileOps.info("Cache directory created: \(cacheURL.path)")
            return true
        } catch {
            Logger.fileOps.error("Error creating cache directory: \(error.localizedDescription)")
            return false
        }
    }


    // MARK: - Thumbnail URL Mapping

    /// Returns the thumbnail URL for a given original file URL
    /// Example: /original/DSCF1234.JPG → ~/Library/Caches/LightCull/current/DSCF1234.jpg
    nonisolated func getThumbnailURL(for originalURL: URL) -> URL {
        let cacheDirectory: URL = getCacheDirectoryURL()

        // Get the filename from the original URL
        let fileName: String = originalURL.lastPathComponent

        // Build the thumbnail URL
        let thumbnailURL: URL = cacheDirectory.appendingPathComponent(fileName)

        return thumbnailURL
    }


    // MARK: - Thumbnail Generation

    /// Generates thumbnails for an array of ImagePairs
    /// - Parameters:
    ///   - pairs: The ImagePairs to generate thumbnails for
    ///   - progress: Callback for progress updates (current, total) - executed on MainActor
    /// - Returns: Updated ImagePairs with thumbnailURL property set
    func generateThumbnails(for pairs: [ImagePair], progress: @escaping @MainActor (Int, Int) -> Void) async -> [ImagePair] {
        // 1. Start time measurement
        let startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
        Logger.fileOps.info("⏱️ Starting thumbnail generation for \(pairs.count) pairs...")

        // 2. Ensure cache directory exists
        let cacheReady: Bool = ensureCacheDirectoryExists()
        if cacheReady == false {
            Logger.fileOps.error("Cache directory could not be created - returning original pairs")
            return pairs
        }

        // 3. Total count for progress
        let totalCount: Int = pairs.count

        // 4. Create dictionary to store results (key = index, value = updated pair)
        var resultsDict: [Int: ImagePair] = [:]

        // 5. Use TaskGroup for parallel thumbnail generation
        await withTaskGroup(of: (Int, ImagePair, URL?).self) { group in
            // Start all tasks in parallel
            for (index, pair) in pairs.enumerated() {
                group.addTask {
                    // Generate thumbnail for this pair (on background thread)
                    let thumbnailURL: URL? = self.generateThumbnail(for: pair.jpegURL)
                    return (index, pair, thumbnailURL)
                }
            }

            // Collect results as they complete
            var completedCount: Int = 0
            for await (index, pair, thumbnailURL) in group {
                completedCount += 1

                // Report progress on main thread
                await MainActor.run {
                    progress(completedCount, totalCount)
                }

                // Create updated pair with thumbnail URL
                let updatedPair = ImagePair(
                    jpegURL: pair.jpegURL,
                    rawURL: pair.rawURL,
                    hasTopTag: pair.hasTopTag,
                    thumbnailURL: thumbnailURL
                )

                // Store in dictionary
                resultsDict[index] = updatedPair
            }
        }

        // 6. Sort results by index and convert to array
        let updatedPairs: [ImagePair] = resultsDict.sorted(by: { $0.key < $1.key }).map { $0.value }

        // 7. End time measurement and log results
        let endTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
        let totalTime: Double = endTime - startTime
        let avgTimePerThumbnail: Double = totalTime / Double(pairs.count)

        Logger.fileOps.info("✅ Thumbnail generation complete: \(updatedPairs.count) thumbnails")
        Logger.fileOps.info("⏱️ Total time: \(String(format: "%.2f", totalTime))s | Avg per thumbnail: \(String(format: "%.0f", avgTimePerThumbnail * 1000))ms")

        return updatedPairs
    }

    /// Generates a single thumbnail for a JPEG file
    /// - Parameter jpegURL: The URL of the JPEG file
    /// - Returns: The URL of the generated thumbnail, or nil on error
    /// - Note: This method is nonisolated to allow parallel execution from TaskGroup
    nonisolated private func generateThumbnail(for jpegURL: URL) -> URL? {
        // 1. Get the thumbnail URL
        let thumbnailURL: URL = getThumbnailURL(for: jpegURL)

        // 2. Check if thumbnail already exists (skip if yes)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: thumbnailURL.path) {
            Logger.fileOps.debug("Thumbnail already exists: \(thumbnailURL.lastPathComponent)")
            return thumbnailURL
        }

        // 3. Create CGImageSource from the JPEG file
        guard let imageSource = CGImageSourceCreateWithURL(jpegURL as CFURL, nil) else {
            Logger.fileOps.error("Could not create image source for: \(jpegURL.lastPathComponent)")
            return nil
        }

        // 4. Create thumbnail options
        // PERFORMANCE OPTIMIZATION: Try to use embedded EXIF thumbnail first (10-50x faster!)
        // If no embedded thumbnail exists, CGImageSource will generate one automatically
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,  // Respect EXIF orientation
            kCGImageSourceCreateThumbnailFromImageAlways: false,  // Use embedded thumbnail if available
            kCGImageSourceThumbnailMaxPixelSize: thumbnailSize  // Max size: 200px
        ]

        // 5. Generate thumbnail image
        guard let thumbnailImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            Logger.fileOps.error("Could not create thumbnail image for: \(jpegURL.lastPathComponent)")
            return nil
        }

        // 6. Save thumbnail as JPEG file
        let saved: Bool = saveThumbnailAsJPEG(image: thumbnailImage, to: thumbnailURL)

        if saved == false {
            Logger.fileOps.error("Could not save thumbnail for: \(jpegURL.lastPathComponent)")
            return nil
        }

        Logger.fileOps.debug("Thumbnail generated: \(thumbnailURL.lastPathComponent)")

        return thumbnailURL
    }

    /// Saves a CGImage as JPEG file
    /// - Parameters:
    ///   - image: The CGImage to save
    ///   - url: The destination URL
    /// - Returns: true on success, false on error
    nonisolated private func saveThumbnailAsJPEG(image: CGImage, to url: URL) -> Bool {
        // 1. Create CGImageDestination for JPEG
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            Logger.fileOps.error("Could not create image destination")
            return false
        }

        // 2. Set JPEG quality
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: jpegQuality
        ]

        // 3. Add image to destination
        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        // 4. Write to disk
        let success: Bool = CGImageDestinationFinalize(destination)

        if success == false {
            Logger.fileOps.error("Could not finalize image destination")
            return false
        }

        return true
    }


    // MARK: - Cache Management for File Operations

    /// Moves a thumbnail to the _toDelete subfolder
    /// This is called when a file is deleted
    /// - Parameter originalURL: The URL of the original JPEG file
    /// - Returns: true on success, false on error (non-critical)
    func moveThumbnailToDeleteFolder(for originalURL: URL) -> Bool {
        let fileManager = FileManager.default

        // 1. Get thumbnail URL
        let thumbnailURL: URL = getThumbnailURL(for: originalURL)

        // 2. Check if thumbnail exists
        if fileManager.fileExists(atPath: thumbnailURL.path) == false {
            Logger.fileOps.debug("No thumbnail to move: \(thumbnailURL.lastPathComponent)")
            return true  // Not an error - just no thumbnail
        }

        // 3. Get _toDelete folder URL
        let cacheDirectory: URL = getCacheDirectoryURL()
        let toDeleteFolder: URL = cacheDirectory.appendingPathComponent("_toDelete")

        // 4. Ensure _toDelete folder exists
        if fileManager.fileExists(atPath: toDeleteFolder.path) == false {
            do {
                try fileManager.createDirectory(at: toDeleteFolder, withIntermediateDirectories: true, attributes: nil)
                Logger.fileOps.debug("_toDelete folder created in cache")
            } catch {
                Logger.fileOps.error("Could not create _toDelete folder: \(error.localizedDescription)")
                return false
            }
        }

        // 5. Build destination URL
        let fileName: String = thumbnailURL.lastPathComponent
        let destinationURL: URL = toDeleteFolder.appendingPathComponent(fileName)

        // 6. Move thumbnail
        do {
            try fileManager.moveItem(at: thumbnailURL, to: destinationURL)
            Logger.fileOps.debug("Thumbnail moved to _toDelete: \(fileName)")
            return true
        } catch {
            Logger.fileOps.error("Could not move thumbnail: \(error.localizedDescription)")
            return false
        }
    }

    /// Moves a thumbnail back from the _toDelete subfolder
    /// This is called when a delete is undone
    /// - Parameter originalURL: The URL of the original JPEG file
    /// - Returns: true on success, false on error (non-critical)
    func moveThumbnailFromDeleteFolder(for originalURL: URL) -> Bool {
        let fileManager = FileManager.default

        // 1. Get thumbnail URL
        let thumbnailURL: URL = getThumbnailURL(for: originalURL)

        // 2. Get _toDelete folder URL
        let cacheDirectory: URL = getCacheDirectoryURL()
        let toDeleteFolder: URL = cacheDirectory.appendingPathComponent("_toDelete")

        // 3. Build source URL (in _toDelete folder)
        let fileName: String = thumbnailURL.lastPathComponent
        let sourceURL: URL = toDeleteFolder.appendingPathComponent(fileName)

        // 4. Check if thumbnail exists in _toDelete folder
        if fileManager.fileExists(atPath: sourceURL.path) == false {
            Logger.fileOps.debug("No thumbnail in _toDelete folder: \(fileName)")
            return true  // Not an error - just no thumbnail
        }

        // 5. Move thumbnail back
        do {
            try fileManager.moveItem(at: sourceURL, to: thumbnailURL)
            Logger.fileOps.debug("Thumbnail restored from _toDelete: \(fileName)")
            return true
        } catch {
            Logger.fileOps.error("Could not restore thumbnail: \(error.localizedDescription)")
            return false
        }
    }

    /// Renames a thumbnail in the cache
    /// This is called when a file is renamed
    /// - Parameters:
    ///   - oldURL: The old URL of the JPEG file
    ///   - newURL: The new URL of the JPEG file
    /// - Returns: true on success, false on error (non-critical)
    func renameThumbnail(from oldURL: URL, to newURL: URL) -> Bool {
        let fileManager = FileManager.default

        // 1. Get old and new thumbnail URLs
        let oldThumbnailURL: URL = getThumbnailURL(for: oldURL)
        let newThumbnailURL: URL = getThumbnailURL(for: newURL)

        // 2. Check if old thumbnail exists
        if fileManager.fileExists(atPath: oldThumbnailURL.path) == false {
            Logger.fileOps.debug("No thumbnail to rename: \(oldThumbnailURL.lastPathComponent)")
            return true  // Not an error - just no thumbnail
        }

        // 3. Check if new thumbnail already exists
        if fileManager.fileExists(atPath: newThumbnailURL.path) {
            Logger.fileOps.warning("Destination thumbnail already exists: \(newThumbnailURL.lastPathComponent)")
            return false
        }

        // 4. Rename thumbnail
        do {
            try fileManager.moveItem(at: oldThumbnailURL, to: newThumbnailURL)
            Logger.fileOps.debug("Thumbnail renamed: \(oldThumbnailURL.lastPathComponent) → \(newThumbnailURL.lastPathComponent)")
            return true
        } catch {
            Logger.fileOps.error("Could not rename thumbnail: \(error.localizedDescription)")
            return false
        }
    }
}

