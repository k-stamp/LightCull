//
//  FinderTagService.swift
//  LightCull
//
//  Created by Kevin Stamp on 03.10.25.
//
//  Responsible for: Reading and writing macOS Finder tags
//

import Foundation
import OSLog

class FinderTagService {
    
    /// Adds a tag to a file
    /// - Parameters:
    ///     - tag: the name of the tag
    ///     - url: the URL of the file
    /// - Returns: true if successful, false on error
    @discardableResult
    func addTag(_ tag: String, to url: URL) -> Bool {
        // read current tags from the file
        guard var currentTags = getTags(from: url) else {
            // if no tags exist, create a new array
            return setTags([tag], to: url)
        }

        // check if tag already exists
        if currentTags.contains(tag) {
            return true
        }

        // add tag to array
        currentTags.append(tag)

        // write updated tag list back
        return setTags(currentTags, to: url)
    }
    
    /// Removes a tag from a file
    /// - Parameters:
    ///     - tag: the name of the tag
    ///     - url: the URL of the file
    /// - Returns: true if successful, false on error
    @discardableResult
    func removeTag(_ tag: String, from url: URL) -> Bool {
        guard var currentTags = getTags(from: url) else {
            return true
        }
        
        // remove tag from array
        currentTags.removeAll { $0 == tag }

        // write updated tag list back
        return setTags(currentTags, to: url)
    }
    
    
    /// Checks if a file has a specific tag
    /// - Parameters:
    ///     - tag: the name of the tag
    ///     - url: the URL of the file
    /// - Returns: true if the tag exists, false if not
    func hasTag(_ tag: String, at url: URL) -> Bool {
        guard let tags = getTags(from: url) else {
            return false
        }
        
        return tags.contains(tag)
    }
    
    
    
    // MARK: - Helper Methods
    
    /// Reads all tags from a file
    /// - Parameter url: the URL of the file
    /// - Returns: array with tag names, or nil on error
    private func getTags(from url: URL) -> [String]? {
        #if os(macOS)
        // URLResourceValues is a container for file metadata
        // IMPORTANT: The security-scoped access must come from the FOLDER (not from the file)
        // The folder access is started in MainView.handleFolderSelection()
        guard let resourceValues = try? url.resourceValues(forKeys: [.tagNamesKey]) else {
            Logger.tagging.error("Error reading resource values from: \(url.lastPathComponent)")
            return nil
        }

        return resourceValues.tagNames
        #elseif os(iOS)
        // Finder tags are not available on iOS
        // Return empty array to indicate no tags
        Logger.tagging.debug("Finder tags not supported on iOS: \(url.lastPathComponent)")
        return []
        #endif
    }
    
    
    /// Writes tags to a file
    /// - Parameters:
    ///     - tags: array with tag names
    ///     - url: the URL of the file
    /// - Returns: true if successful, false on error
    private func setTags(_ tags: [String], to url: URL) -> Bool {
        #if os(macOS)
        var resourceValues = URLResourceValues()
        resourceValues.tagNames = tags

        // important! url must be declared as var since setResourceValues is a mutating method
        var mutableURL = url

        // IMPORTANT: The security-scoped access must come from the FOLDER (not from the file)
        // The folder access is started in MainView.handleFolderSelection()
        // and remains active as long as the folder is selected

        do {
            // write tags to file
            try mutableURL.setResourceValues(resourceValues)
            Logger.tagging.info("Tags successfully written to \(url.lastPathComponent)")
            return true
        } catch {
            Logger.tagging.error("Error writing tags to \(url.lastPathComponent): \(error.localizedDescription)")
            return false
        }
        #elseif os(iOS)
        // Finder tags are not available on iOS
        Logger.tagging.debug("Finder tags not supported on iOS - skipping write for: \(url.lastPathComponent)")
        return true  // Return true to avoid errors in the UI
        #endif
    }
    
}
