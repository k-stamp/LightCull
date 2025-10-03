//
//  FinderTagService.swift
//  LightCull
//
//  Created by Kevin Stamp on 03.10.25.
//
//  Verantwortlich für: Lesen und Schreiben von macOS Finder-Tags
//

import Foundation

class FinderTagService {
    
    /// Fügt einen Tag zu einer Datei hinzu
    /// - Parameters:
    ///     - tag: der Name des Tags
    ///     - url: die URL der Datei
    /// - Returns: true wenn erfolgreich, false bei Fehler
    @discardableResult
    func addTag(_ tag: String, to url: URL) -> Bool {
        // aktuelle Tags von der Datei lesen
        guard var currentTags = getTags(from: url) else {
            // wenn keine tags vorhanden sind, erstelle ein neues Array
            return setTags([tag], to: url)
        }
        
        // Prüfen ob Tag bereits existiert
        if currentTags.contains(tag) {
            return true
        }
        
        // Tag zum Array hinzufügen
        currentTags.append(tag)
        
        // aktualisierte Tag-Liste zurückschreiben
        return setTags(currentTags, to: url)
    }
    
    /// Entfernt einen Tag von einer Datei
    /// - Parameters:
    ///     - tag: Der name des Tags
    ///     - url: Die URL der Datei
    /// - Returns: true wenn erfolgreich, false bei Fehler
    @discardableResult
    func removeTag(_ tag: String, from url: URL) -> Bool {
        guard var currentTags = getTags(from: url) else {
            return false
        }
        
        // Tag aus dem Array entfernen
        currentTags.removeAll { $0 == tag }
        
        // Aktualisierte Tag-Liste zurückschreiben
        return setTags(currentTags, to: url)
    }
    
    
    /// Prüft ob eine Datei einen bestimmten Tag hat
    /// - Parameters:
    ///     - tag: Der Name des Tags
    ///     - url: Die URL der Datei
    /// - Returns: true wenn der Tag vorhanden ist, false wenn nicht
    func hasTag(_ tag: String, at url: URL) -> Bool {
        guard let tags = getTags(from: url) else {
            return false
        }
        
        return tags.contains(tag)
    }
    
    
    
    // MARK: - Helper Methods
    
    /// Liest alle Tags von einer Datei
    /// - Parameter url: Die URL der Datei
    /// - Returns: Array mit Tag-Namen, oder nil bei Fehler
    private func getTags(from url: URL) -> [String]? {
        // URLResourceValues ist ein Container für Datei-Metadaten
        guard let resourceValues = try? url.resourceValues(forKeys: [.tagNamesKey]) else {
            print("Fehler beim Lesen der resource Values von: \(url.lastPathComponent)")
            return nil
        }
        
        return resourceValues.tagNames
    }
    
    
    /// Schreibt Tags zu einer Datei
    /// - Parameters:
    ///     - tags: Array mit Tag-Namen
    ///     - url: Die URL der Datei
    /// - Returns: true wenn erfolgreich, false bei Fehler
    private func setTags(_ tags: [String], to url: URL) -> Bool {
        var resourceValues = URLResourceValues()
        resourceValues.tagNames = tags
        
        // wichtig! url muss als var deklariert werden, da setResourcesValues eine mutating Methode ist
        var mutableURL = url
        
        do {
            // Tags zur Datei schreiben
            try mutableURL.setResourceValues(resourceValues)
            return true
        } catch {
            print("Fehler beim Schreiben der Tags zu \(url.lastPathComponent): \(error.localizedDescription)")
            return false
        }
    }
    
}
