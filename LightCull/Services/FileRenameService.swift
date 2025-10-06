//
//  FileRenameService.swift
//  LightCull
//
//  Responsible for: Renaming image files with prefix
//

import Foundation

class FileRenameService {

    // MARK: - Public Methods

    /// Renames a JPEG file by adding a prefix before the filename
    /// - Parameters:
    ///   - jpegURL: The URL of the JPEG file
    ///   - prefix: The prefix to be added before the filename
    /// - Returns: The new URL of the renamed file, or nil on error
    func renameJPEG(url jpegURL: URL, withPrefix prefix: String) -> URL? {
        // 1. Ensure that the prefix is not empty
        if prefix.isEmpty {
            print("⚠️ Prefix is empty - no renaming necessary")
            return jpegURL
        }

        // 2. Get old filename (with extension)
        let oldFileName: String = jpegURL.lastPathComponent

        // 3. Build new filename: "Prefix_OldName"
        let newFileName: String = "\(prefix)_\(oldFileName)"

        // 4. Build new URL (in the same folder as the old file)
        let folderURL: URL = jpegURL.deletingLastPathComponent()
        let newURL: URL = folderURL.appendingPathComponent(newFileName)

        // 5. Check if a file with the new name already exists
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: newURL.path) {
            print("❌ File already exists: \(newFileName)")
            return nil
        }

        // 6. Rename file with FileManager
        do {
            try fileManager.moveItem(at: jpegURL, to: newURL)
            print("✅ JPEG renamed: \(oldFileName) → \(newFileName)")
            return newURL
        } catch {
            print("❌ Error renaming: \(error.localizedDescription)")
            return nil
        }
    }

    /// Renames a RAW file by adding a prefix before the filename
    /// - Parameters:
    ///   - rawURL: The URL of the RAW file
    ///   - prefix: The prefix to be added before the filename
    /// - Returns: The new URL of the renamed file, or nil on error
    func renameRAW(url rawURL: URL, withPrefix prefix: String) -> URL? {
        // Exact same logic as for JPEG - only for RAW files

        // 1. Ensure that the prefix is not empty
        if prefix.isEmpty {
            print("⚠️ Prefix is empty - no renaming necessary")
            return rawURL
        }

        // 2. Get old filename (with extension)
        let oldFileName: String = rawURL.lastPathComponent

        // 3. Build new filename: "Prefix_OldName"
        let newFileName: String = "\(prefix)_\(oldFileName)"

        // 4. Build new URL (in the same folder as the old file)
        let folderURL: URL = rawURL.deletingLastPathComponent()
        let newURL: URL = folderURL.appendingPathComponent(newFileName)

        // 5. Check if a file with the new name already exists
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: newURL.path) {
            print("❌ File already exists: \(newFileName)")
            return nil
        }

        // 6. Rename file with FileManager
        do {
            try fileManager.moveItem(at: rawURL, to: newURL)
            print("✅ RAW renamed: \(oldFileName) → \(newFileName)")
            return newURL
        } catch {
            print("❌ Error renaming: \(error.localizedDescription)")
            return nil
        }
    }

    /// Renames a complete ImagePair (JPEG + optional RAW)
    /// - Parameters:
    ///   - pair: The ImagePair to be renamed
    ///   - prefix: The prefix to be added before the filename
    /// - Returns: A new ImagePair with the new URLs, or nil on error
    func renamePair(_ pair: ImagePair, withPrefix prefix: String) -> ImagePair? {
        // 1. Rename JPEG
        guard let newJPEGURL: URL = renameJPEG(url: pair.jpegURL, withPrefix: prefix) else {
            print("❌ Error renaming JPEG")
            return nil
        }

        // 2. Rename RAW (if present)
        var newRAWURL: URL? = nil
        if let rawURL = pair.rawURL {
            // RAW file is present - rename it too
            newRAWURL = renameRAW(url: rawURL, withPrefix: prefix)

            // If RAW renaming fails, we need to revert the JPEG rename
            if newRAWURL == nil {
                print("⚠️ RAW renaming failed - reverting JPEG rename")
                // Revert: newJPEGURL back to pair.jpegURL
                let fileManager = FileManager.default
                try? fileManager.moveItem(at: newJPEGURL, to: pair.jpegURL)
                return nil
            }
        }

        // 3. Create new ImagePair with the new URLs
        let newPair = ImagePair(
            jpegURL: newJPEGURL,
            rawURL: newRAWURL,
            hasTopTag: pair.hasTopTag  // Tag status remains the same
        )

        return newPair
    }
}
