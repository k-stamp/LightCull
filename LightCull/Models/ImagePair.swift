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

    // Equatable implementation based on the URLs
    static func == (lhs: ImagePair, rhs: ImagePair) -> Bool {
        return lhs.jpegURL == rhs.jpegURL && lhs.rawURL == rhs.rawURL
    }
}
