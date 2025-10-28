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

    // MARK: - Duplizieren

    /// Dupliziert das JPEG für Luminar Neo
    /// - Returns: URL des duplizierten JPEGs
    func duplicateJPEGForLuminarNeo(jpegURL: URL) throws -> URL {
        guard isLuminarNeoInstalled() else {
            throw ExternalAppError.appNotInstalled("Luminar Neo")
        }

        let duplicateURL = try createUniqueDuplicateURL(
            originalURL: jpegURL,
            suffix: "ReEditet_LuminarNEO",
            extension: "jpg"
        )

        // Datei kopieren
        try FileManager.default.copyItem(at: jpegURL, to: duplicateURL)

        return duplicateURL
    }

    /// Dupliziert die RAW-Datei für Fuji X Raw Studio
    /// - Returns: URL der duplizierten RAW-Datei
    func duplicateRAWForFujiXRawStudio(rawURL: URL) throws -> URL {
        guard isFujiXRawStudioInstalled() else {
            throw ExternalAppError.appNotInstalled("FUJIFILM X RAW STUDIO")
        }

        let originalExtension = rawURL.pathExtension
        let duplicateURL = try createUniqueDuplicateURL(
            originalURL: rawURL,
            suffix: "ReEditet_FujiXRawStudio",
            extension: originalExtension
        )

        // Datei kopieren
        try FileManager.default.copyItem(at: rawURL, to: duplicateURL)

        return duplicateURL
    }

    // MARK: - Öffnen mit externer App

    /// Öffnet eine Datei mit Luminar Neo
    func openWithLuminarNeo(fileURL: URL, completion: @escaping (Result<Void, ExternalAppError>) -> Void) {
        let appURL = URL(fileURLWithPath: "/Applications/Luminar Neo.app")
        let configuration = NSWorkspace.OpenConfiguration()

        NSWorkspace.shared.open(
            [fileURL],
            withApplicationAt: appURL,
            configuration: configuration
        ) { app, error in
            if let error = error {
                completion(.failure(.failedToOpen(error.localizedDescription)))
            } else {
                completion(.success(()))
            }
        }
    }

    /// Öffnet eine Datei mit Fuji X Raw Studio
    func openWithFujiXRawStudio(fileURL: URL, completion: @escaping (Result<Void, ExternalAppError>) -> Void) {
        let appURL = URL(fileURLWithPath: "/Applications/FUJIFILM X RAW STUDIO.app")

        // Methode 1: Versuche die Datei direkt zu öffnen
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.promptsUserIfNeeded = true

        NSWorkspace.shared.open(
            [fileURL],
            withApplicationAt: appURL,
            configuration: configuration
        ) { app, error in
            if error != nil {
                // Methode 2: Falls fehlgeschlagen, versuche erst die App zu starten
                let launchConfiguration = NSWorkspace.OpenConfiguration()
                launchConfiguration.activates = true

                NSWorkspace.shared.openApplication(at: appURL, configuration: launchConfiguration) { app, launchError in
                    if let launchError = launchError {
                        completion(.failure(.failedToOpen("Fehler beim Starten der App: \(launchError.localizedDescription)")))
                    } else {
                        // App erfolgreich gestartet, warte kurz und versuche dann die Datei zu öffnen
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            let openConfig = NSWorkspace.OpenConfiguration()
                            openConfig.activates = true

                            NSWorkspace.shared.open(
                                [fileURL],
                                withApplicationAt: appURL,
                                configuration: openConfig
                            ) { _, openError in
                                if let openError = openError {
                                    completion(.failure(.failedToOpen("Datei konnte nicht geöffnet werden: \(openError.localizedDescription)")))
                                } else {
                                    completion(.success(()))
                                }
                            }
                        }
                    }
                }
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Private Helper

    /// Erstellt eine eindeutige URL für das Duplikat mit automatischer Nummerierung bei Konflikten
    /// Beispiel: OriginalName(ReEditet_LuminarNEO).jpg, bei Konflikt: OriginalName(ReEditet_LuminarNEO2).jpg, etc.
    private func createUniqueDuplicateURL(originalURL: URL, suffix: String, extension: String) throws -> URL {
        let directory = originalURL.deletingLastPathComponent()
        let originalFilename = originalURL.deletingPathExtension().lastPathComponent

        // Basis-Dateiname: OriginalName(Suffix).extension
        var baseName = "\(originalFilename)(\(suffix))"
        var counter = 2
        var candidateURL = directory.appendingPathComponent(baseName).appendingPathExtension(`extension`)

        // Wenn Datei existiert, füge Nummer hinzu: (Suffix2), (Suffix3), etc.
        while FileManager.default.fileExists(atPath: candidateURL.path) {
            baseName = "\(originalFilename)(\(suffix)\(counter))"
            candidateURL = directory
                .appendingPathComponent(baseName)
                .appendingPathExtension(`extension`)
            counter += 1
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
