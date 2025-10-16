//
//  ImageViewModel.swift
//  LightCull
//
//  Responsible for: State management of image display (zoom, position, etc.)
//

import SwiftUI
import Combine
import OSLog

/// ViewModel for image display with zoom functionality
class ImageViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current zoom level (1.0 = 100%, 4.0 = 400%)
    @Published var zoomScale: CGFloat = 1.0

    /// Position of the image when zooming (for pan gestures)
    @Published var imageOffset: CGSize = .zero
    
    
    // MARK: - Dependencies

    private let tagService: FinderTagService
    private let moveService: FileMoveService
    
    
    // MARK: - Constants
    
    /// Minimum zoom level (100% = fit to window)
    let minZoom: CGFloat = 1.0

    /// Maximum zoom level (400% according to documentation)
    let maxZoom: CGFloat = 4.0

    /// Zoom steps for keyboard shortcuts (25%)
    let zoomStep: CGFloat = 0.25
    
    
    // MARK: - Move History (for Undo)

    // Here we store all move operations for undo
    // This is a simple array - the newest element is always at the end
    private var moveHistory: [MoveOperation] = []


    // MARK: - Initializer

    init(tagService: FinderTagService = FinderTagService(), moveService: FileMoveService = FileMoveService()) {
        self.tagService = tagService
        self.moveService = moveService
    }
    
    
    // MARK: - Zoom Actions
    
    /// Increases the zoom level by one step
    func zoomIn() {
        let newScale = min(zoomScale + zoomStep, maxZoom)
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = newScale
        }
    }
    
    /// Decreases the zoom level by one step
    func zoomOut() {
        let newScale = max(zoomScale - zoomStep, minZoom)
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = newScale
            // If back to 100%, reset offset
            if newScale == minZoom {
                imageOffset = .zero
            }
        }
    }
    
    /// Resets zoom to 100% (fit to window)
    func resetZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = minZoom
            imageOffset = .zero
        }
    }
    
    /// Sets zoom to a specific value (e.g. from slider)
    func setZoom(to scale: CGFloat) {
        // Ensure the value is within the allowed range
        let clampedScale = min(max(scale, minZoom), maxZoom)
        zoomScale = clampedScale

        // If back to 100%, reset offset
        if clampedScale == minZoom {
            imageOffset = .zero
        }
    }
    
    /// Handles magnification gestures from trackpad
    /// - Parameter magnification: The change in magnification
    func handleMagnification(_ magnification: CGFloat) {
        // Calculate new scale based on current scale
        let newScale = zoomScale * magnification

        // Keep within allowed range
        let clampedScale = min(max(newScale, minZoom), maxZoom)

        // Without animation for smooth gestures
        zoomScale = clampedScale

        // If back to 100%, reset offset
        if clampedScale == minZoom {
            imageOffset = .zero
        }
    }
    
    // MARK: - Pan Actions

    /// Applies a scroll delta to the current image offset (for scrollWheel events)
    /// - Parameters:
    ///   - deltaX: Horizontal scroll delta
    ///   - deltaY: Vertical scroll delta
    ///   - imageSize: The size of the image (for boundary calculation)
    ///   - viewSize: The size of the view area
    func applyScrollDelta(deltaX: CGFloat, deltaY: CGFloat, imageSize: CGSize, viewSize: CGSize) {
        // Only allow pan when zoomed
        guard zoomScale > minZoom else {
            imageOffset = .zero
            return
        }

        // Apply delta to current offset
        let newOffset = CGSize(
            width: imageOffset.width + deltaX,
            height: imageOffset.height + deltaY
        )

        // Calculate boundaries based on zoom level
        let scaledImageWidth = imageSize.width * zoomScale
        let scaledImageHeight = imageSize.height * zoomScale

        // Maximum translation in both directions
        let maxOffsetX = max(0, (scaledImageWidth - viewSize.width) / 2)
        let maxOffsetY = max(0, (scaledImageHeight - viewSize.height) / 2)

        // Limit the offset to the calculated maximum values
        let clampedX = min(max(newOffset.width, -maxOffsetX), maxOffsetX)
        let clampedY = min(max(newOffset.height, -maxOffsetY), maxOffsetY)

        imageOffset = CGSize(width: clampedX, height: clampedY)
    }

    /// Handles drag gestures to move the zoomed image
    /// - Parameters:
    ///   - translation: The translation in pixels
    ///   - imageSize: The size of the image (for boundary calculation)
    ///   - viewSize: The size of the view area
    func handleDrag(translation: CGSize, imageSize: CGSize, viewSize: CGSize) {
        // Only allow pan when zoomed
        guard zoomScale > minZoom else {
            imageOffset = .zero
            return
        }

        // Calculate boundaries based on zoom level
        // The image scales, so we must consider the scaled dimensions
        let scaledImageWidth = imageSize.width * zoomScale
        let scaledImageHeight = imageSize.height * zoomScale

        // Maximum translation in both directions
        // (Half the difference between scaled image and view)
        let maxOffsetX = max(0, (scaledImageWidth - viewSize.width) / 2)
        let maxOffsetY = max(0, (scaledImageHeight - viewSize.height) / 2)

        // Limit the offset to the calculated maximum values
        let clampedX = min(max(translation.width, -maxOffsetX), maxOffsetX)
        let clampedY = min(max(translation.height, -maxOffsetY), maxOffsetY)

        imageOffset = CGSize(width: clampedX, height: clampedY)
    }

    /// Adjusts the pan bounds when the image changes
    /// This ensures the pan offset stays valid for images with different aspect ratios
    /// - Parameters:
    ///   - imageSize: The size of the new image
    ///   - viewSize: The size of the view area
    func adjustPanBounds(imageSize: CGSize, viewSize: CGSize) {
        // Only adjust when zoomed
        guard zoomScale > minZoom else {
            imageOffset = .zero
            return
        }

        // Calculate boundaries based on current zoom level
        let scaledImageWidth = imageSize.width * zoomScale
        let scaledImageHeight = imageSize.height * zoomScale

        // Maximum translation in both directions
        let maxOffsetX = max(0, (scaledImageWidth - viewSize.width) / 2)
        let maxOffsetY = max(0, (scaledImageHeight - viewSize.height) / 2)

        // Clamp current offset to new bounds
        let clampedX = min(max(imageOffset.width, -maxOffsetX), maxOffsetX)
        let clampedY = min(max(imageOffset.height, -maxOffsetY), maxOffsetY)

        imageOffset = CGSize(width: clampedX, height: clampedY)
    }
    
    /// Called when a drag gesture ends
    /// Can be used for momentum effects or snap behavior
    func endDrag() {
        // Currently do nothing, but ready for future features
        // such as momentum animation or snap-to-grid
    }
    
    
    // MARK: - Tagging Actions
    
    /// Toggles the TOP tag for an image pair
    /// - Parameters:
    ///     - pair: the image pair to be tagged
    ///     - completion: Callback with the updated ImagePair (new tag status)
    func toggleTopTag(for pair: ImagePair, completion: @escaping (ImagePair) -> Void) {
        // Reverse current tag status
        let newTagStatus = !pair.hasTopTag
        
        if newTagStatus {
            addTopTag(to: pair, completion: completion)
        } else {
            removeTopTag(from: pair, completion: completion)
        }
    }
    
    private func addTopTag(to pair: ImagePair, completion: @escaping (ImagePair) -> Void) {
        let jpegSuccess = tagService.addTag("TOP", to: pair.jpegURL)

        var rawSuccess = true
        if let rawURL = pair.rawURL {
            rawSuccess = tagService.addTag("TOP", to: rawURL)
        }

        // Create new ImagePair with updated tag status
        // Important: We create a NEW ImagePair since it's a struct (immutable)
        // The hasTopTag should be set to TRUE if we successfully tagged
        let updatedPair = ImagePair(
            jpegURL: pair.jpegURL,
            rawURL: pair.rawURL,
            hasTopTag: jpegSuccess && rawSuccess  // TRUE if both operations succeeded
        )

        // Debug output
        if jpegSuccess && rawSuccess {
            Logger.tagging.info("TOP tag added to: \(pair.jpegURL.lastPathComponent) - new status: \(updatedPair.hasTopTag)")
        } else {
            Logger.tagging.error("Error adding TOP tag - jpeg: \(jpegSuccess), raw: \(rawSuccess)")
        }

        // Call callback with updated pair
        completion(updatedPair)
    }
    
    private func removeTopTag(from pair: ImagePair, completion: @escaping (ImagePair) -> Void) {
        let jpegSuccess = tagService.removeTag("TOP", from: pair.jpegURL)

        var rawSuccess = true
        if let rawURL = pair.rawURL {
            rawSuccess = tagService.removeTag("TOP", from: rawURL)
        }

        // After removal, hasTopTag should ALWAYS be false (even on error)
        let updatedPair = ImagePair(
            jpegURL: pair.jpegURL,
            rawURL: pair.rawURL,
            hasTopTag: false  // ALWAYS false after removeTag
        )

        // Debug output
        if jpegSuccess && rawSuccess {
            Logger.tagging.info("TOP tag removed from: \(pair.jpegURL.lastPathComponent) - new status: \(updatedPair.hasTopTag)")
        } else {
            Logger.tagging.error("Error removing TOP tag - jpeg: \(jpegSuccess), raw: \(rawSuccess)")
        }

        // Call callback with updated pair
        completion(updatedPair)
    }
    
    
    // MARK: - Move Actions

    /// Moves an ImagePair to the _toDelete folder
    /// - Parameters:
    ///   - pair: The ImagePair to be moved
    ///   - folderURL: The folder where the images are located
    ///   - completion: Callback when the operation is finished (true = success, false = error)
    func deleteImagePair(pair: ImagePair, in folderURL: URL, completion: @escaping (Bool) -> Void) {
        moveImagePair(pair: pair, in: folderURL, using: moveService.deletePair, operationName: "delete", completion: completion)
    }

    /// Moves an ImagePair to the _Archive folder
    /// - Parameters:
    ///   - pair: The ImagePair to be moved
    ///   - folderURL: The folder where the images are located
    ///   - completion: Callback when the operation is finished (true = success, false = error)
    func archiveImagePair(pair: ImagePair, in folderURL: URL, completion: @escaping (Bool) -> Void) {
        moveImagePair(pair: pair, in: folderURL, using: moveService.archivePair, operationName: "archive", completion: completion)
    }

    /// Moves an ImagePair to the _Outtakes folder
    /// - Parameters:
    ///   - pair: The ImagePair to be moved
    ///   - folderURL: The folder where the images are located
    ///   - completion: Callback when the operation is finished (true = success, false = error)
    func outtakeImagePair(pair: ImagePair, in folderURL: URL, completion: @escaping (Bool) -> Void) {
        moveImagePair(pair: pair, in: folderURL, using: moveService.outtakePair, operationName: "outtake", completion: completion)
    }

    /// Generic helper method to move an ImagePair using a specific move service method
    /// - Parameters:
    ///   - pair: The ImagePair to be moved
    ///   - folderURL: The folder where the images are located
    ///   - moveMethod: The move service method to use
    ///   - operationName: The name of the operation (for logging)
    ///   - completion: Callback when the operation is finished (true = success, false = error)
    private func moveImagePair(pair: ImagePair, in folderURL: URL, using moveMethod: (ImagePair, URL) -> MoveOperation?, operationName: String, completion: @escaping (Bool) -> Void) {
        // Call move service to move the files
        let operation: MoveOperation? = moveMethod(pair, folderURL)

        // Did it work?
        if let operation = operation {
            // Yes! Add operation to history
            moveHistory.append(operation)
            Logger.fileOps.info("ImagePair \(operationName)d - history now contains \(self.moveHistory.count) operations")

            // Call callback with success
            completion(true)
        } else {
            // No - error!
            Logger.fileOps.error("Error \(operationName)ing ImagePair")

            // Call callback with error
            completion(false)
        }
    }

    /// Undoes the last move operation
    /// - Parameter completion: Callback when the operation is finished (true = success, false = error)
    func undoLastMove(completion: @escaping (Bool) -> Void) {
        // Is there anything to undo?
        if moveHistory.isEmpty {
            Logger.fileOps.notice("No move operations to undo")
            completion(false)
            return
        }

        // Get last operation from history
        // removeLast() gets the last element AND removes it from the array
        let lastOperation: MoveOperation = moveHistory.removeLast()

        Logger.fileOps.debug("Undoing move: \(lastOperation.originalJpegURL.lastPathComponent)")

        // Call move service to move the files back
        let success: Bool = moveService.undoMove(lastOperation)

        if success {
            Logger.fileOps.info("Undo successful - history now contains \(self.moveHistory.count) operations")
            completion(true)
        } else {
            Logger.fileOps.error("Undo failed")
            // On error, add the operation BACK to history
            self.moveHistory.append(lastOperation)
            completion(false)
        }
    }

    /// Checks if there are move operations that can be undone
    /// - Returns: true if undo is possible, false if not
    func canUndo() -> Bool {
        // Simply check if the history is empty or not
        let hasHistory: Bool = moveHistory.isEmpty == false
        return hasHistory
    }

    /// Clears the complete move history (e.g. on folder change)
    func clearMoveHistory() {
        moveHistory.removeAll()
        Logger.fileOps.debug("Move history cleared")
    }

    /// Legacy method name for backward compatibility
    @available(*, deprecated, renamed: "undoLastMove")
    func undoLastDelete(completion: @escaping (Bool) -> Void) {
        undoLastMove(completion: completion)
    }

    /// Legacy method name for backward compatibility
    @available(*, deprecated, renamed: "clearMoveHistory")
    func clearDeleteHistory() {
        clearMoveHistory()
    }


    // MARK: - Computed Properties

    /// Returns the zoom level as a percentage (for UI display)
    var zoomPercentage: Int {
        Int(zoomScale * 100)
    }

    /// Checks if maximum zoom is reached
    var isMaxZoom: Bool {
        zoomScale >= maxZoom
    }

    /// Checks if minimum zoom is reached
    var isMinZoom: Bool {
        zoomScale <= minZoom
    }

    /// Checks if pan functionality should be available
    var isPanEnabled: Bool {
        zoomScale > minZoom
    }
}

