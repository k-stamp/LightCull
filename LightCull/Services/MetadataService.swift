//
//  MetadataService.swift
//  LightCull
//
//  Created by Kevin Stamp on 02.10.25.
//
//  Verantwortlich für: Das Auslesen von EXIF-Daten und Datei-Informationen aus Bildern
//

import Foundation
import ImageIO


class MetadataService {
    
    // MARK: - Public Interface
    func extractMetadata(from url: URL) -> ImageMetadata?{
        
        // CGImageSourceCreateWithURL ist ein "Leser" für die Bilddatei
        // (wir laden nicht das gesamte Bild in den Speicher, nur die Metadaten)
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            print("Konnte ImageSource nicht erstellen für: \(url.lastPathComponent)")
            return nil
        }
        
        let fileName = url.lastPathComponent
        let fileSize = formatFileSize(for: url)
        
        // Properties Dictionary vom Bild holen -> Das Dictionary enthält ALLE Metadeten
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            // Wenn keine Properties vorhanden sind, geben wir nur die Basis-Info zurück
            print("Keine Properties gefunden für: \(fileName)")
            return ImageMetadata(fileName: fileName, fileSize: fileSize)
        }
        
        // EXIF-Sub-Dictionary extrahieren
        guard let exifData = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] else {
            print("Keine EXIF-Daten gefunden für: \(fileName)")
            return ImageMetadata(fileName: fileName, fileSize: fileSize)
        }
        
        
        // Die Hersteller-infos stehen oft im TIFF-Dictionary, nicht im EXIF
        let tiffData = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        
        // Einzelne EXIF-Werte extrahieren und formatieren
        let cameraMake = tiffData?[kCGImagePropertyTIFFMake as String] as? String
        let cameraModel = tiffData?[kCGImagePropertyTIFFModel as String] as? String
        let focalLength = formatFocalLength(from: exifData)
        let aperture = formatAperture(from: exifData)
        let shutterSpeed = formatShutterSpeed(from: exifData)
        
        
        return ImageMetadata(
            fileName: fileName,
            fileSize: fileSize,
            cameraMake: cameraMake,
            cameraModel: cameraModel,
            focalLength: focalLength,
            aperture: aperture,
            shutterSpeed: shutterSpeed
        )
    }
    
    
    // MARK: - Helper Methods
    
    private func formatFileSize(for url: URL) -> String {
        let fileManager = FileManager.default
        
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path), let sizeInBytes = attributes[.size] as? Int64 else {
            return "Unknown"
        }
        
        // ByteCountFormatter ist ein Apple-Helfer der automatisch die richtige Einheit wählt (Bytes, KB, MB, GB)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useMB, .useKB]
        
        return formatter.string(fromByteCount: sizeInBytes)
    }
    
    
    private func formatFocalLength(from exifData: [String: Any]) -> String? {
        guard let focalLength = exifData[kCGImagePropertyExifFocalLength as String] as? Double else {
            return nil
        }
        
        // Formatierung: Eine Nachkommastelle + " mm"
        return String(format: "%.1f mm", focalLength)
    }
    
    
    private func formatAperture(from exifData: [String: Any]) -> String? {
        // EXIF speichert Blende als "F-Number" (z.B. 2.8 für f/2.8)
        guard let aperture = exifData[kCGImagePropertyExifFNumber as String] as? Double else {
            return nil
        }
        
        // Formatierung: "f/" + eine Nachkommastelle
        return String(format: "f/%.1f", aperture)
    }
    
    
    private func formatShutterSpeed(from exifData: [String: Any]) -> String? {
        // EXIF speichert Belichtungszeit als Dezimalzahl in Sekunden
        // z.B. 0.004 = 1/250s, oder 2.5 = 2.5 Sekunden
        guard let exposureTime = exifData[kCGImagePropertyExifExposureTime as String] as? Double else {
            return nil
        }
        
        // Wenn die Zeit >= 1 Sekunde ist, zeige als Dezimalzahl
        if exposureTime >= 1.0 {
            return String(format: "%.1fs", exposureTime)
        }
        
        // Wenn < 1 Sekunde, zeige als Bruch (z.B. "1/250s")
        // Berechnung: 1 / 0.004 = 250
        let denominator = Int(1.0 / exposureTime)
        return "1/\(denominator)s"
    }
}
