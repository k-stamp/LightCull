//
//  MoveOperation.swift
//  LightCull
//
//  Stores information about a move operation for undo functionality
//

import Foundation

// This struct stores all the information we need to undo a move.
// It's like a "memory" of the move operation.
struct MoveOperation {
    // The original URL of the JPEG (before it was moved)
    let originalJpegURL: URL

    // The new URL of the JPEG (in the destination folder)
    let movedJpegURL: URL

    // The original URL of the RAW (before it was moved)
    // Optional, because not every image has a RAW
    let originalRawURL: URL?

    // The new URL of the RAW (in the destination folder)
    // Optional, because not every image has a RAW
    let movedRawURL: URL?

    // When was the image moved? (for debugging purposes)
    let timestamp: Date
}
