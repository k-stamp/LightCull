//
//  FileService.swift
//  LightCull
//
//  Created by Kevin Stamp on 26.09.25.
//

import Foundation

class FileService {
    
    // MARK: - Dependencies
    private let tagService: FinderTagService
    
    
    // MARK: - Initializer
    
    /// Initializes the FileService with a TagService
    /// - Parameter tagService: The service for reading Finder tags
    init(tagService: FinderTagService = FinderTagService()) {
        self.tagService = tagService
    }
    
    
    // MARK: - Public Methods
    
    // finds JPEG/RAW pairs in the specified folder
    func findImagePairs(in folder: URL) -> [ImagePair] {
        var pairs: [ImagePair] = []
        let fileManager = FileManager.default
        
        
        // 1. Get all files in the folder
        guard let files = try? fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        
        // 2. Filter only JPEG files and sort by filename
        let jpegFiles = files
            .filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "jpg" || ext == "jpeg"
            }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        
        
        // 3. For each JPEG, check if there is a RAW file
        for jpeg in jpegFiles {
            let baseName = jpeg.deletingPathExtension().lastPathComponent
            
            // RAW file candidate
            let rawCandidate = folder.appendingPathComponent("\(baseName).RAF")
            let rawURL = fileManager.fileExists(atPath: rawCandidate.path) ? rawCandidate : nil
            
            // Check Top tag status (we check the JPEG file, not the RAW. When tagging,
            // both are tagged, but reading the JPEG is sufficient)
            let hasTopTag = tagService.hasTag("TOP", at: jpeg)
            
            // add new ImagePair
            let pair = ImagePair(jpegURL: jpeg, rawURL: rawURL, hasTopTag: hasTopTag)
            pairs.append(pair)
        }
        
    
        return pairs
    }
    
}
