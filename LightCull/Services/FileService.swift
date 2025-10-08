//
//  FileService.swift
//  LightCull
//
//  Created by Kevin Stamp on 26.09.25.
//

import Foundation

// MARK: - FolderStatistics

/// Statistiken über einen Ordner mit Bildern
struct FolderStatistics {
    let totalFiles: Int          // Alle Dateien (JPEG + RAF)
    let jpegWithRaw: Int         // Anzahl der Pairs (JPEG + RAF)
    let jpegWithoutRaw: Int      // JPEGs ohne passende RAF
    let deletedFiles: Int        // Dateien im _toDelete Verzeichnis
    let topTaggedFiles: Int      // Anzahl der mit TOP getaggten Bilder
}

// MARK: - FileService

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

    // MARK: - Folder Statistics

    /// Berechnet Statistiken für einen Ordner
    /// - Parameter folder: Der zu analysierende Ordner
    /// - Returns: FolderStatistics mit allen Zählern
    func getFolderStatistics(in folder: URL) -> FolderStatistics {
        let fileManager = FileManager.default

        // 1. Alle Dateien im Hauptordner holen
        guard let files = try? fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            // Bei Fehler: Alle Werte auf 0
            return FolderStatistics(
                totalFiles: 0,
                jpegWithRaw: 0,
                jpegWithoutRaw: 0,
                deletedFiles: 0,
                topTaggedFiles: 0
            )
        }

        // 2. JPEG und RAF Dateien trennen
        let jpegFiles = files.filter { url in
            let ext = url.pathExtension.lowercased()
            return ext == "jpg" || ext == "jpeg"
        }

        let rafFiles = files.filter { url in
            url.pathExtension.lowercased() == "raf"
        }

        // 3. Gesamtanzahl Dateien
        let totalFiles = jpegFiles.count + rafFiles.count

        // 4. Pairs und JPEGs ohne RAF zählen
        var jpegWithRaw = 0
        var jpegWithoutRaw = 0
        var topTaggedFiles = 0

        for jpeg in jpegFiles {
            let baseName = jpeg.deletingPathExtension().lastPathComponent
            let rawCandidate = folder.appendingPathComponent("\(baseName).RAF")

            if fileManager.fileExists(atPath: rawCandidate.path) {
                jpegWithRaw += 1
            } else {
                jpegWithoutRaw += 1
            }

            // TOP Tag prüfen
            if tagService.hasTag("TOP", at: jpeg) {
                topTaggedFiles += 1
            }
        }

        // 5. Gelöschte Dateien im _toDelete Verzeichnis zählen
        let toDeleteFolder = folder.appendingPathComponent("_toDelete")
        var deletedFiles = 0

        if let deletedContents = try? fileManager.contentsOfDirectory(
            at: toDeleteFolder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            // Nur JPEG und RAF Dateien zählen (keine versteckten Dateien oder Thumbnails)
            deletedFiles = deletedContents.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "jpg" || ext == "jpeg" || ext == "raf"
            }.count
        }

        // 6. Statistik zurückgeben
        return FolderStatistics(
            totalFiles: totalFiles,
            jpegWithRaw: jpegWithRaw,
            jpegWithoutRaw: jpegWithoutRaw,
            deletedFiles: deletedFiles,
            topTaggedFiles: topTaggedFiles
        )
    }

}
