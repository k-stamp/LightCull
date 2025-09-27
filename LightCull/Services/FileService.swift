//
//  FileService.swift
//  LightCull
//
//  Created by Kevin Stamp on 26.09.25.
//

import Foundation

class FileService {
    
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
        
        
        // 2. Nur JPEG-Dateien herausfiltern
        let jpegFiles = files.filter { url in
            let ext = url.pathExtension.lowercased()
            return ext == "jpg" || ext == "jpeg"
        }
        
        
        // 3. Für jedes JPEG schauen, ob es ein RAW gibt
        for jpeg in jpegFiles {
            let baseName = jpeg.deletingPathExtension().lastPathComponent
            
            // RAW-Datei-Kandidat
            let rawCandidate = folder.appendingPathComponent("\(baseName).RAF")
            let rawURL = fileManager.fileExists(atPath: rawCandidate.path) ? rawCandidate : nil
            
            // neues ImagePair hinzufügen
            let pair = ImagePair(jpegURL: jpeg, rawURL: rawURL)
            pairs.append(pair)
        }
        
    
        return pairs
    }
    
}
