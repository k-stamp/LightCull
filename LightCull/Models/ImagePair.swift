//
//  ImagePair.swift
//  LightCull
//
//  Created by Kevin Stamp on 26.09.25.
//

import Foundation

// Represents a JPEG + RAW file pair
struct ImagePair: Identifiable, Equatable {
    let id: UUID = UUID()
    let jpegURL: URL
    let rawURL: URL?
    let hasTopTag: Bool
    let thumbnailURL: URL?  // NEW: URL to cached thumbnail (optional)

    // Default initializer without thumbnail URL (for backwards compatibility)
    init(jpegURL: URL, rawURL: URL?, hasTopTag: Bool, thumbnailURL: URL? = nil) {
        self.jpegURL = jpegURL
        self.rawURL = rawURL
        self.hasTopTag = hasTopTag
        self.thumbnailURL = thumbnailURL
    }

    // Equatable implementation based on the URLs
    static func == (lhs: ImagePair, rhs: ImagePair) -> Bool {
        return lhs.jpegURL == rhs.jpegURL && lhs.rawURL == rhs.rawURL
    }
}
