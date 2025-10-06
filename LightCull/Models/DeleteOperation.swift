//
//  DeleteOperation.swift
//  LightCull
//
//  Stores information about a delete operation for undo functionality
//

import Foundation

// This struct stores all the information we need to undo a deletion.
// It's like a "memory" of the move operation.
struct DeleteOperation {
    // The original URL of the JPEG (before it was moved)
    let originalJpegURL: URL

    // The new URL of the JPEG (in the _toDelete folder)
    let deletedJpegURL: URL

    // The original URL of the RAW (before it was moved)
    // Optional, because not every image has a RAW
    let originalRawURL: URL?

    // The new URL of the RAW (in the _toDelete folder)
    // Optional, because not every image has a RAW
    let deletedRawURL: URL?

    // When was the image deleted? (for debugging purposes)
    let timestamp: Date
}
