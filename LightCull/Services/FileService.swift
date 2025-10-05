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
    
    /// Initialisiert den FileService mit einem TagService
    /// - Parameter tagService: Der Service zum Lesen von Finder-Tags
    init(tagService: FinderTagService = FinderTagService()) {
        self.tagService = tagService
    }
    
    
    // MARK: - Public Methods
    
    // findet JPEG/RAW-Paare im angegebenen Ordner
    func findImagePairs(in folder: URL) -> [ImagePair] {
        var pairs: [ImagePair] = []
        let fileManager = FileManager.default
        
        
        // 1. Alle Dateien im Ordner holen
        guard let files = try? fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        
        // 2. Nur JPEG-Dateien herausfiltern und nach Dateinamen sortieren
        let jpegFiles = files
            .filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "jpg" || ext == "jpeg"
            }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        
        
        // 3. Für jedes JPEG schauen, ob es ein RAW gibt
        for jpeg in jpegFiles {
            let baseName = jpeg.deletingPathExtension().lastPathComponent
            
            // RAW-Datei-Kandidat
            let rawCandidate = folder.appendingPathComponent("\(baseName).RAF")
            let rawURL = fileManager.fileExists(atPath: rawCandidate.path) ? rawCandidate : nil
            
            // Top-Tag Status prüfen (wir pürfen die JPEG-Datei, nicht die RAW. Beim taggen werden
            // beide getaggt, aber zum Lesen reicht JPEG)
            let hasTopTag = tagService.hasTag("TOP", at: jpeg)
            
            // neues ImagePair hinzufügen
            let pair = ImagePair(jpegURL: jpeg, rawURL: rawURL, hasTopTag: hasTopTag)
            pairs.append(pair)
        }
        
    
        return pairs
    }
    
}
