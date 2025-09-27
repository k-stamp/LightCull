//
//  ImagePair.swift
//  LightCull
//
//  Created by Kevin Stamp on 26.09.25.
//

import Foundation

// repräsentiert ein JPEG + RAW Dateipaar
struct ImagePair: Identifiable {
    let id: UUID = UUID()
    let jpegURL: URL
    let rawURL: URL?
}
