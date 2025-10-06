//
//  FileDeleteService.swift
//  LightCull
//
//  Verantwortlich für: Verschieben von Bildern in den _toDelete Ordner
//

import Foundation

class FileDeleteService {

    // MARK: - Public Methods

    /// Verschiebt ein ImagePair in den _toDelete Ordner
    /// - Parameters:
    ///   - pair: Das ImagePair das verschoben werden soll
    ///   - folderURL: Der Ordner in dem die Bilder aktuell liegen
    /// - Returns: Eine DeleteOperation für Undo, oder nil bei Fehler
    func deletePair(_ pair: ImagePair, in folderURL: URL) -> DeleteOperation? {
        // 1. _toDelete Ordner erstellen (falls er nicht existiert)
        let toDeleteFolderURL: URL = folderURL.appendingPathComponent("_toDelete")
        let didCreateFolder: Bool = ensureToDeleteFolderExists(at: toDeleteFolderURL)

        if didCreateFolder == false {
            print("❌ Konnte _toDelete Ordner nicht erstellen")
            return nil
        }

        // 2. JPEG verschieben
        let jpegFileName: String = pair.jpegURL.lastPathComponent
        let newJpegURL: URL = toDeleteFolderURL.appendingPathComponent(jpegFileName)

        let jpegMoved: Bool = moveFile(from: pair.jpegURL, to: newJpegURL)

        if jpegMoved == false {
            print("❌ JPEG konnte nicht verschoben werden")
            return nil
        }

        print("✅ JPEG verschoben: \(jpegFileName)")

        // 3. RAW verschieben (falls vorhanden)
        var newRawURL: URL? = nil

        if let rawURL = pair.rawURL {
            // Es gibt ein RAW - also verschieben wir es auch
            let rawFileName: String = rawURL.lastPathComponent
            let targetRawURL: URL = toDeleteFolderURL.appendingPathComponent(rawFileName)

            let rawMoved: Bool = moveFile(from: rawURL, to: targetRawURL)

            if rawMoved == false {
                print("❌ RAW konnte nicht verschoben werden")
                // WICHTIG: JPEG wieder zurück verschieben!
                let jpegRestored: Bool = moveFile(from: newJpegURL, to: pair.jpegURL)
                if jpegRestored {
                    print("⚠️ JPEG wurde wieder zurückverschoben")
                }
                return nil
            }

            newRawURL = targetRawURL
            print("✅ RAW verschoben: \(rawFileName)")
        }

        // 4. DeleteOperation erstellen für Undo
        let operation = DeleteOperation(
            originalJpegURL: pair.jpegURL,
            deletedJpegURL: newJpegURL,
            originalRawURL: pair.rawURL,
            deletedRawURL: newRawURL,
            timestamp: Date()
        )

        return operation
    }

    /// Macht eine Delete-Operation rückgängig (verschiebt Dateien zurück)
    /// - Parameter operation: Die DeleteOperation die rückgängig gemacht werden soll
    /// - Returns: true bei Erfolg, false bei Fehler
    func undoDelete(_ operation: DeleteOperation) -> Bool {
        // 1. JPEG zurück verschieben
        let jpegRestored: Bool = moveFile(from: operation.deletedJpegURL, to: operation.originalJpegURL)

        if jpegRestored == false {
            print("❌ JPEG konnte nicht zurückverschoben werden")
            return false
        }

        print("✅ JPEG wiederhergestellt: \(operation.originalJpegURL.lastPathComponent)")

        // 2. RAW zurück verschieben (falls vorhanden)
        if let deletedRawURL = operation.deletedRawURL {
            // Wir müssen auch die original RAW URL haben
            if let originalRawURL = operation.originalRawURL {
                let rawRestored: Bool = moveFile(from: deletedRawURL, to: originalRawURL)

                if rawRestored == false {
                    print("❌ RAW konnte nicht zurückverschoben werden")
                    // WICHTIG: JPEG wieder in _toDelete verschieben!
                    let jpegMovedBack: Bool = moveFile(from: operation.originalJpegURL, to: operation.deletedJpegURL)
                    if jpegMovedBack {
                        print("⚠️ JPEG wurde wieder zurück in _toDelete verschoben")
                    }
                    return false
                }

                print("✅ RAW wiederhergestellt: \(originalRawURL.lastPathComponent)")
            }
        }

        return true
    }

    // MARK: - Private Helper Methods

    /// Stellt sicher dass der _toDelete Ordner existiert
    /// - Parameter url: Die URL des _toDelete Ordners
    /// - Returns: true wenn Ordner existiert oder erstellt wurde, false bei Fehler
    private func ensureToDeleteFolderExists(at url: URL) -> Bool {
        let fileManager = FileManager.default

        // Prüfen ob Ordner bereits existiert
        var isDirectory: ObjCBool = false
        let exists: Bool = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if exists {
            // Ordner existiert bereits
            if isDirectory.boolValue {
                // Es ist wirklich ein Ordner - alles gut!
                return true
            } else {
                // Es existiert eine DATEI mit diesem Namen - Fehler!
                print("❌ '_toDelete' existiert als Datei, nicht als Ordner")
                return false
            }
        }

        // Ordner existiert nicht - also erstellen wir ihn
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
            print("✅ _toDelete Ordner erstellt")
            return true
        } catch {
            print("❌ Fehler beim Erstellen des _toDelete Ordners: \(error.localizedDescription)")
            return false
        }
    }

    /// Verschiebt eine Datei von A nach B
    /// - Parameters:
    ///   - sourceURL: Wo ist die Datei aktuell?
    ///   - destinationURL: Wo soll die Datei hin?
    /// - Returns: true bei Erfolg, false bei Fehler
    private func moveFile(from sourceURL: URL, to destinationURL: URL) -> Bool {
        let fileManager = FileManager.default

        // Prüfen ob Ziel-Datei bereits existiert
        let destinationExists: Bool = fileManager.fileExists(atPath: destinationURL.path)
        if destinationExists {
            print("❌ Ziel-Datei existiert bereits: \(destinationURL.lastPathComponent)")
            return false
        }

        // Datei verschieben
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            print("❌ Fehler beim Verschieben: \(error.localizedDescription)")
            return false
        }
    }
}
