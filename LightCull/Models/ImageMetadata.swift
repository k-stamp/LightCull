//
//  ImageMetadata.swift
//  LightCull
//
//  Repräsentiert die Metadaten eines Bildes (EXIF-Daten + Datei-Info)
//

import Foundation

struct ImageMetadata {
    
    // MARK: - Datei-Informationen
    // Diese Felder sind IMMER vorhanden, daher keine Optionals
    let fileName: String
    let fileSize: String
    
    // MARK: - Kamera-Informationen (EXIF)
    // Diese Felder sind OPTIONAL, da nicht jedes Bild diese Daten hat
    // (z.B. Screenshots, bearbeitete Bilder, etc.)
    let cameraMake: String?
    let cameraModel: String?
    let focalLength: String?
    let aperture: String?
    let shutterSpeed: String?
}

// MARK: - Convenience Initializer

extension ImageMetadata {
    /// Erstellt ein ImageMetadata-Objekt nur mit Datei-Informationen
    /// Nützlich wenn keine EXIF-Daten vorhanden sind
    /// - Parameters:
    ///   - fileName: Name der Datei
    ///   - fileSize: Formatierte Dateigröße
    init(fileName: String, fileSize: String) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.cameraMake = nil
        self.cameraModel = nil
        self.focalLength = nil
        self.aperture = nil
        self.shutterSpeed = nil
    }
}
