//
//  ExternalAppService.swift
//  LightCull
//
//  Service für das Öffnen von Bildern in externen Apps (Luminar Neo, Fuji X Raw Studio)
//

#if os(macOS)
import Foundation
import AppKit

class ExternalAppService {

    // MARK: - App-Erkennung

    /// Prüft, ob Luminar Neo installiert ist
    func isLuminarNeoInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: "/Applications/Luminar Neo.app")
    }

    /// Prüft, ob FUJIFILM X RAW STUDIO installiert ist
    func isFujiXRawStudioInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: "/Applications/FUJIFILM X RAW STUDIO.app")
    }

    // MARK: - Öffnen mit Luminar Neo

    /// Dupliziert das JPEG und öffnet es mit Luminar Neo
    func duplicateAndOpenWithLuminarNeo(jpegURL: URL, completion: @escaping (Result<Void, ExternalAppError>) -> Void) {
        // Prüfen ob App installiert ist
        guard isLuminarNeoInstalled() else {
            completion(.failure(.appNotInstalled("Luminar Neo")))
            return
        }

        // Duplikat erstellen mit eindeutigem Namen
        do {
            let duplicateURL = try createUniqueDuplicateURL(
                originalURL: jpegURL,
                suffix: "ReEditet-LuminarNEO",
                extension: "jpg"
            )

            // Datei kopieren
            try FileManager.default.copyItem(at: jpegURL, to: duplicateURL)

            // Mit Luminar Neo öffnen
            let appURL = URL(fileURLWithPath: "/Applications/Luminar Neo.app")
            let configuration = NSWorkspace.OpenConfiguration()

            NSWorkspace.shared.open(
                [duplicateURL],
                withApplicationAt: appURL,
                configuration: configuration
            ) { app, error in
                if let error = error {
                    completion(.failure(.failedToOpen(error.localizedDescription)))
                } else {
                    completion(.success(()))
                }
            }

        } catch {
            completion(.failure(.failedToDuplicate(error.localizedDescription)))
        }
    }

    // MARK: - Öffnen mit Fuji X Raw Studio

    /// Dupliziert die RAW-Datei und öffnet sie mit Fuji X Raw Studio
    func duplicateAndOpenWithFujiXRawStudio(rawURL: URL, completion: @escaping (Result<Void, ExternalAppError>) -> Void) {
        // Prüfen ob App installiert ist
        guard isFujiXRawStudioInstalled() else {
            completion(.failure(.appNotInstalled("FUJIFILM X RAW STUDIO")))
            return
        }

        // Duplikat erstellen mit eindeutigem Namen (behält .RAF extension)
        do {
            let originalExtension = rawURL.pathExtension
            let duplicateURL = try createUniqueDuplicateURL(
                originalURL: rawURL,
                suffix: "ReEditet-FujiXRawStudio",
                extension: originalExtension
            )

            // Datei kopieren
            try FileManager.default.copyItem(at: rawURL, to: duplicateURL)

            // Mit Fuji X Raw Studio öffnen
            let appURL = URL(fileURLWithPath: "/Applications/FUJIFILM X RAW STUDIO.app")
            let configuration = NSWorkspace.OpenConfiguration()

            NSWorkspace.shared.open(
                [duplicateURL],
                withApplicationAt: appURL,
                configuration: configuration
            ) { app, error in
                if let error = error {
                    completion(.failure(.failedToOpen(error.localizedDescription)))
                } else {
                    completion(.success(()))
                }
            }

        } catch {
            completion(.failure(.failedToDuplicate(error.localizedDescription)))
        }
    }

    // MARK: - Private Helper

    /// Erstellt eine eindeutige URL für das Duplikat mit automatischer Nummerierung bei Konflikten
    /// Beispiel: OriginalName-ReEditet-LuminarNEO.jpg, bei Konflikt: -2.jpg, -3.jpg, etc.
    private func createUniqueDuplicateURL(originalURL: URL, suffix: String, extension: String) throws -> URL {
        let directory = originalURL.deletingLastPathComponent()
        let originalFilename = originalURL.deletingPathExtension().lastPathComponent

        // Basis-Dateiname: OriginalName-Suffix.extension
        let baseName = "\(originalFilename)-\(suffix)"
        var counter = 1
        var candidateURL = directory.appendingPathComponent(baseName).appendingPathExtension(`extension`)

        // Wenn Datei existiert, füge Nummer hinzu: -2, -3, etc.
        while FileManager.default.fileExists(atPath: candidateURL.path) {
            counter += 1
            candidateURL = directory
                .appendingPathComponent("\(baseName)-\(counter)")
                .appendingPathExtension(`extension`)
        }

        return candidateURL
    }
}

// MARK: - Error Types

enum ExternalAppError: Error, LocalizedError {
    case appNotInstalled(String)
    case failedToDuplicate(String)
    case failedToOpen(String)

    var errorDescription: String? {
        switch self {
        case .appNotInstalled(let appName):
            return "\(appName) ist nicht installiert. Bitte installieren Sie die App im Programme-Ordner."
        case .failedToDuplicate(let reason):
            return "Fehler beim Duplizieren der Datei: \(reason)"
        case .failedToOpen(let reason):
            return "Fehler beim Öffnen der App: \(reason)"
        }
    }
}

#endif
