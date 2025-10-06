//
//  FileRenameService.swift
//  LightCull
//
//  Verantwortlich für: Umbenennen von Bild-Dateien mit Präfix
//

import Foundation

class FileRenameService {

    // MARK: - Public Methods

    /// Benennt eine JPEG-Datei um, indem ein Präfix vor den Dateinamen gesetzt wird
    /// - Parameters:
    ///   - jpegURL: Die URL der JPEG-Datei
    ///   - prefix: Das Präfix, das vor den Dateinamen gesetzt werden soll
    /// - Returns: Die neue URL der umbenannten Datei, oder nil bei Fehler
    func renameJPEG(url jpegURL: URL, withPrefix prefix: String) -> URL? {
        // 1. Sicherstellen, dass der Präfix nicht leer ist
        if prefix.isEmpty {
            print("⚠️ Präfix ist leer - kein Umbenennen nötig")
            return jpegURL
        }

        // 2. Alten Dateinamen holen (mit Extension)
        let oldFileName: String = jpegURL.lastPathComponent

        // 3. Neuen Dateinamen bauen: "Präfix_AlterName"
        let newFileName: String = "\(prefix)_\(oldFileName)"

        // 4. Neue URL bauen (im gleichen Ordner wie die alte Datei)
        let folderURL: URL = jpegURL.deletingLastPathComponent()
        let newURL: URL = folderURL.appendingPathComponent(newFileName)

        // 5. Prüfen ob eine Datei mit dem neuen Namen bereits existiert
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: newURL.path) {
            print("❌ Datei existiert bereits: \(newFileName)")
            return nil
        }

        // 6. Datei umbenennen mit FileManager
        do {
            try fileManager.moveItem(at: jpegURL, to: newURL)
            print("✅ JPEG umbenannt: \(oldFileName) → \(newFileName)")
            return newURL
        } catch {
            print("❌ Fehler beim Umbenennen: \(error.localizedDescription)")
            return nil
        }
    }

    /// Benennt eine RAW-Datei um, indem ein Präfix vor den Dateinamen gesetzt wird
    /// - Parameters:
    ///   - rawURL: Die URL der RAW-Datei
    ///   - prefix: Das Präfix, das vor den Dateinamen gesetzt werden soll
    /// - Returns: Die neue URL der umbenannten Datei, oder nil bei Fehler
    func renameRAW(url rawURL: URL, withPrefix prefix: String) -> URL? {
        // Exakt die gleiche Logik wie bei JPEG - nur für RAW-Dateien

        // 1. Sicherstellen, dass der Präfix nicht leer ist
        if prefix.isEmpty {
            print("⚠️ Präfix ist leer - kein Umbenennen nötig")
            return rawURL
        }

        // 2. Alten Dateinamen holen (mit Extension)
        let oldFileName: String = rawURL.lastPathComponent

        // 3. Neuen Dateinamen bauen: "Präfix_AlterName"
        let newFileName: String = "\(prefix)_\(oldFileName)"

        // 4. Neue URL bauen (im gleichen Ordner wie die alte Datei)
        let folderURL: URL = rawURL.deletingLastPathComponent()
        let newURL: URL = folderURL.appendingPathComponent(newFileName)

        // 5. Prüfen ob eine Datei mit dem neuen Namen bereits existiert
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: newURL.path) {
            print("❌ Datei existiert bereits: \(newFileName)")
            return nil
        }

        // 6. Datei umbenennen mit FileManager
        do {
            try fileManager.moveItem(at: rawURL, to: newURL)
            print("✅ RAW umbenannt: \(oldFileName) → \(newFileName)")
            return newURL
        } catch {
            print("❌ Fehler beim Umbenennen: \(error.localizedDescription)")
            return nil
        }
    }

    /// Benennt ein komplettes ImagePair um (JPEG + optional RAW)
    /// - Parameters:
    ///   - pair: Das ImagePair, das umbenannt werden soll
    ///   - prefix: Das Präfix, das vor den Dateinamen gesetzt werden soll
    /// - Returns: Ein neues ImagePair mit den neuen URLs, oder nil bei Fehler
    func renamePair(_ pair: ImagePair, withPrefix prefix: String) -> ImagePair? {
        // 1. JPEG umbenennen
        guard let newJPEGURL: URL = renameJPEG(url: pair.jpegURL, withPrefix: prefix) else {
            print("❌ Fehler beim Umbenennen des JPEG")
            return nil
        }

        // 2. RAW umbenennen (falls vorhanden)
        var newRAWURL: URL? = nil
        if let rawURL = pair.rawURL {
            // RAW-Datei ist vorhanden - auch umbenennen
            newRAWURL = renameRAW(url: rawURL, withPrefix: prefix)

            // Wenn RAW-Umbenennung fehlschlägt, müssen wir JPEG zurück umbenennen
            if newRAWURL == nil {
                print("⚠️ RAW-Umbenennung fehlgeschlagen - mache JPEG-Umbenennung rückgängig")
                // Rückgängig machen: newJPEGURL zurück zu pair.jpegURL
                let fileManager = FileManager.default
                try? fileManager.moveItem(at: newJPEGURL, to: pair.jpegURL)
                return nil
            }
        }

        // 3. Neues ImagePair erstellen mit den neuen URLs
        let newPair = ImagePair(
            jpegURL: newJPEGURL,
            rawURL: newRAWURL,
            hasTopTag: pair.hasTopTag  // Tag-Status bleibt gleich
        )

        return newPair
    }
}
