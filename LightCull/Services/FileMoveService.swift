//
//  FileMoveService.swift
//  LightCull
//
//  Responsible for: Moving images to destination folders (_toDelete, _Archive, _Outtakes)
//

import Foundation
import OSLog

class FileMoveService {

    // MARK: - Dependencies

    // Service for managing thumbnails
    private let thumbnailService: ThumbnailService

    // MARK: - Initializer

    /// Initializes the FileMoveService with a ThumbnailService
    /// - Parameter thumbnailService: The service for managing thumbnails
    init(thumbnailService: ThumbnailService = ThumbnailService()) {
        self.thumbnailService = thumbnailService
    }

    // MARK: - Public Methods

    /// Moves an ImagePair to a destination folder
    /// - Parameters:
    ///   - pair: The ImagePair to be moved
    ///   - folderURL: The folder where the images are currently located
    ///   - destinationFolderName: The name of the destination folder (e.g., "_toDelete", "_Archive", "_Outtakes")
    /// - Returns: A MoveOperation for Undo, or nil on error
    func movePair(_ pair: ImagePair, in folderURL: URL, toFolder destinationFolderName: String) -> MoveOperation? {
        // 1. Create destination folder (if it doesn't exist)
        let destinationFolderURL: URL = folderURL.appendingPathComponent(destinationFolderName)
        let didCreateFolder: Bool = ensureFolderExists(at: destinationFolderURL, named: destinationFolderName)

        if didCreateFolder == false {
            Logger.fileOps.error("Could not create \(destinationFolderName) folder")
            return nil
        }

        // 2. Move JPEG
        let jpegFileName: String = pair.jpegURL.lastPathComponent
        let newJpegURL: URL = destinationFolderURL.appendingPathComponent(jpegFileName)

        let jpegMoved: Bool = moveFile(from: pair.jpegURL, to: newJpegURL)

        if jpegMoved == false {
            Logger.fileOps.error("JPEG could not be moved")
            return nil
        }

        Logger.fileOps.info("JPEG moved to \(destinationFolderName): \(jpegFileName)")

        // 2b. Move thumbnail (non-critical - don't abort if it fails)
        let thumbnailMoved: Bool = thumbnailService.moveThumbnailToDeleteFolder(for: pair.jpegURL)
        if thumbnailMoved {
            Logger.fileOps.debug("Thumbnail moved to \(destinationFolderName)")
        } else {
            Logger.fileOps.notice("Thumbnail could not be moved (non-critical)")
        }

        // 3. Move RAW (if present)
        var newRawURL: URL? = nil

        if let rawURL = pair.rawURL {
            // There is a RAW - so we move it too
            let rawFileName: String = rawURL.lastPathComponent
            let targetRawURL: URL = destinationFolderURL.appendingPathComponent(rawFileName)

            let rawMoved: Bool = moveFile(from: rawURL, to: targetRawURL)

            if rawMoved == false {
                Logger.fileOps.error("RAW could not be moved")
                // IMPORTANT: Move JPEG back!
                let jpegRestored: Bool = moveFile(from: newJpegURL, to: pair.jpegURL)
                if jpegRestored {
                    Logger.fileOps.notice("JPEG was moved back")
                }
                return nil
            }

            newRawURL = targetRawURL
            Logger.fileOps.info("RAW moved to \(destinationFolderName): \(rawFileName)")
        }

        // 4. Create MoveOperation for Undo
        let operation = MoveOperation(
            originalJpegURL: pair.jpegURL,
            movedJpegURL: newJpegURL,
            originalRawURL: pair.rawURL,
            movedRawURL: newRawURL,
            timestamp: Date()
        )

        return operation
    }

    /// Convenience method: Moves an ImagePair to the _toDelete folder
    /// - Parameters:
    ///   - pair: The ImagePair to be moved
    ///   - folderURL: The folder where the images are currently located
    /// - Returns: A MoveOperation for Undo, or nil on error
    func deletePair(_ pair: ImagePair, in folderURL: URL) -> MoveOperation? {
        return movePair(pair, in: folderURL, toFolder: "_toDelete")
    }

    /// Convenience method: Moves an ImagePair to the _Archive folder
    /// - Parameters:
    ///   - pair: The ImagePair to be moved
    ///   - folderURL: The folder where the images are currently located
    /// - Returns: A MoveOperation for Undo, or nil on error
    func archivePair(_ pair: ImagePair, in folderURL: URL) -> MoveOperation? {
        return movePair(pair, in: folderURL, toFolder: "_Archive")
    }

    /// Convenience method: Moves an ImagePair to the _Outtakes folder
    /// - Parameters:
    ///   - pair: The ImagePair to be moved
    ///   - folderURL: The folder where the images are currently located
    /// - Returns: A MoveOperation for Undo, or nil on error
    func outtakePair(_ pair: ImagePair, in folderURL: URL) -> MoveOperation? {
        return movePair(pair, in: folderURL, toFolder: "_Outtakes")
    }

    /// Undoes a move operation (moves files back)
    /// - Parameter operation: The MoveOperation to be undone
    /// - Returns: true on success, false on error
    func undoMove(_ operation: MoveOperation) -> Bool {
        // 1. Move JPEG back
        let jpegRestored: Bool = moveFile(from: operation.movedJpegURL, to: operation.originalJpegURL)

        if jpegRestored == false {
            Logger.fileOps.error("JPEG could not be moved back")
            return false
        }

        Logger.fileOps.info("JPEG restored: \(operation.originalJpegURL.lastPathComponent)")

        // 1b. Restore thumbnail (non-critical - don't abort if it fails)
        let thumbnailRestored: Bool = thumbnailService.moveThumbnailFromDeleteFolder(for: operation.originalJpegURL)
        if thumbnailRestored {
            Logger.fileOps.debug("Thumbnail restored")
        } else {
            Logger.fileOps.notice("Thumbnail could not be restored (non-critical)")
        }

        // 2. Move RAW back (if present)
        if let movedRawURL = operation.movedRawURL {
            // We also need to have the original RAW URL
            if let originalRawURL = operation.originalRawURL {
                let rawRestored: Bool = moveFile(from: movedRawURL, to: originalRawURL)

                if rawRestored == false {
                    Logger.fileOps.error("RAW could not be moved back")
                    // IMPORTANT: Move JPEG back to destination folder!
                    let jpegMovedBack: Bool = moveFile(from: operation.originalJpegURL, to: operation.movedJpegURL)
                    if jpegMovedBack {
                        Logger.fileOps.notice("JPEG was moved back to destination folder")
                    }
                    return false
                }

                Logger.fileOps.info("RAW restored: \(originalRawURL.lastPathComponent)")
            }
        }

        return true
    }

    // MARK: - Private Helper Methods

    /// Ensures that a folder exists
    /// - Parameters:
    ///   - url: The URL of the folder
    ///   - named: The name of the folder (for logging)
    /// - Returns: true if folder exists or was created, false on error
    private func ensureFolderExists(at url: URL, named folderName: String) -> Bool {
        let fileManager = FileManager.default

        // Check if folder already exists
        var isDirectory: ObjCBool = false
        let exists: Bool = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if exists {
            // Folder already exists
            if isDirectory.boolValue {
                // It really is a folder - all good!
                return true
            } else {
                // A FILE with this name exists - error!
                Logger.fileOps.error("'\(folderName)' exists as a file, not as a folder")
                return false
            }
        }

        // Folder doesn't exist - so we create it
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
            Logger.fileOps.info("\(folderName) folder created")
            return true
        } catch {
            Logger.fileOps.error("Error creating \(folderName) folder: \(error.localizedDescription)")
            return false
        }
    }

    /// Moves a file from A to B
    /// - Parameters:
    ///   - sourceURL: Where is the file currently?
    ///   - destinationURL: Where should the file go?
    /// - Returns: true on success, false on error
    private func moveFile(from sourceURL: URL, to destinationURL: URL) -> Bool {
        let fileManager = FileManager.default

        // Check if destination file already exists
        let destinationExists: Bool = fileManager.fileExists(atPath: destinationURL.path)
        if destinationExists {
            Logger.fileOps.error("Destination file already exists: \(destinationURL.lastPathComponent)")
            return false
        }

        // Move file
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            Logger.fileOps.error("Error moving file: \(error.localizedDescription)")
            return false
        }
    }
}
