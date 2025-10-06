//
//  ImageViewModel.swift
//  LightCull
//
//  Verantwortlich für: State-Management der Bildanzeige (Zoom, Position, etc.)
//

import SwiftUI
import Combine

/// ViewModel für die Bildanzeige mit Zoom-Funktionalität
class ImageViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Aktueller Zoom-Level (1.0 = 100%, 4.0 = 400%)
    @Published var zoomScale: CGFloat = 1.0
    
    /// Position des Bildes beim Zoomen (für Pan-Gesten)
    @Published var imageOffset: CGSize = .zero
    
    
    // MARK: - Dependencies

    private let tagService: FinderTagService
    private let deleteService: FileDeleteService
    
    
    // MARK: - Constants
    
    /// Minimaler Zoom-Level (100% = Fensteranpassung)
    let minZoom: CGFloat = 1.0
    
    /// Maximaler Zoom-Level (400% laut Dokumentation)
    let maxZoom: CGFloat = 4.0
    
    /// Zoom-Schritte für Tastatur-Shortcuts (25%)
    let zoomStep: CGFloat = 0.25
    
    
    // MARK: - Delete History (für Undo)

    // Hier speichern wir alle Delete-Operationen für Undo
    // Das ist ein einfaches Array - das neueste Element ist immer am Ende
    private var deleteHistory: [DeleteOperation] = []


    // MARK: - Initializer

    init(tagService: FinderTagService = FinderTagService(), deleteService: FileDeleteService = FileDeleteService()) {
        self.tagService = tagService
        self.deleteService = deleteService
    }
    
    
    // MARK: - Zoom Actions
    
    /// Erhöht den Zoom-Level um einen Schritt
    func zoomIn() {
        let newScale = min(zoomScale + zoomStep, maxZoom)
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = newScale
        }
    }
    
    /// Verringert den Zoom-Level um einen Schritt
    func zoomOut() {
        let newScale = max(zoomScale - zoomStep, minZoom)
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = newScale
            // Wenn zurück auf 100%, Offset zurücksetzen
            if newScale == minZoom {
                imageOffset = .zero
            }
        }
    }
    
    /// Setzt den Zoom auf 100% (Fensteranpassung) zurück
    func resetZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = minZoom
            imageOffset = .zero
        }
    }
    
    /// Setzt den Zoom auf einen spezifischen Wert (z.B. vom Slider)
    func setZoom(to scale: CGFloat) {
        // Sicherstellen dass der Wert im erlaubten Bereich liegt
        let clampedScale = min(max(scale, minZoom), maxZoom)
        zoomScale = clampedScale
        
        // Wenn zurück auf 100%, Offset zurücksetzen
        if clampedScale == minZoom {
            imageOffset = .zero
        }
    }
    
    /// Behandelt Magnification-Gesten vom Trackpad
    /// - Parameter magnification: Die Änderung der Vergrößerung
    func handleMagnification(_ magnification: CGFloat) {
        // Neue Skala berechnen basierend auf aktueller Skala
        let newScale = zoomScale * magnification
        
        // Im erlaubten Bereich halten
        let clampedScale = min(max(newScale, minZoom), maxZoom)
        
        // Ohne Animation für flüssige Gesten
        zoomScale = clampedScale
        
        // Wenn zurück auf 100%, Offset zurücksetzen
        if clampedScale == minZoom {
            imageOffset = .zero
        }
    }
    
    // MARK: - Pan Actions
    
    /// Behandelt Drag-Gesten zum Verschieben des gezoomten Bildes
    /// - Parameters:
    ///   - translation: Die Verschiebung in Pixeln
    ///   - imageSize: Die Größe des Bildes (für Grenzen-Berechnung)
    ///   - viewSize: Die Größe des View-Bereichs
    func handleDrag(translation: CGSize, imageSize: CGSize, viewSize: CGSize) {
        // Pan nur erlauben wenn gezoomt
        guard zoomScale > minZoom else {
            imageOffset = .zero
            return
        }
        
        // Berechne die Grenzen basierend auf Zoom-Level
        // Das Bild skaliert, also müssen wir die skalierten Dimensionen berücksichtigen
        let scaledImageWidth = imageSize.width * zoomScale
        let scaledImageHeight = imageSize.height * zoomScale
        
        // Maximale Verschiebung in beide Richtungen
        // (Halbe Differenz zwischen skaliertem Bild und View)
        let maxOffsetX = max(0, (scaledImageWidth - viewSize.width) / 2)
        let maxOffsetY = max(0, (scaledImageHeight - viewSize.height) / 2)
        
        // Begrenze den Offset auf die berechneten Maximalwerte
        let clampedX = min(max(translation.width, -maxOffsetX), maxOffsetX)
        let clampedY = min(max(translation.height, -maxOffsetY), maxOffsetY)
        
        imageOffset = CGSize(width: clampedX, height: clampedY)
    }
    
    /// Wird aufgerufen wenn eine Drag-Geste endet
    /// Kann für Schwung-Effekte oder Snap-Verhalten genutzt werden
    func endDrag() {
        // Momentan nichts tun, aber bereit für zukünftige Features
        // wie z.B. Schwung-Animation oder Snap-to-Grid
    }
    
    
    // MARK: - Tagging Actions
    
    /// Togglet den TOP-Tag für ein Bildpaar
    /// - Parameters:
    ///     - pair: das Bildpaar das getaggt werden soll
    ///     - completion: Callback mit dem aktualisierten ImagePair (neuer Tag-Status)
    func toggleTopTag(for pair: ImagePair, completion: @escaping (ImagePair) -> Void) {
        // aktuellen Tag-Status umkehren
        let newTagStatus = !pair.hasTopTag
        
        if newTagStatus {
            addTopTag(to: pair, completion: completion)
        } else {
            removeTopTag(from: pair, completion: completion)
        }
    }
    
    private func addTopTag(to pair: ImagePair, completion: @escaping (ImagePair) -> Void) {
        let jpegSuccess = tagService.addTag("TOP", to: pair.jpegURL)

        var rawSuccess = true
        if let rawURL = pair.rawURL {
            rawSuccess = tagService.addTag("TOP", to: rawURL)
        }

        // Neues ImagePair mit aktualisiertem Tag-Status erstellen
        // Wichtig: Wir erstellen ein NEUES ImagePair, da es ein Struct ist (immutable)
        // Der hasTopTag sollte auf TRUE gesetzt werden, wenn wir erfolgreich getaggt haben
        let updatedPair = ImagePair(
            jpegURL: pair.jpegURL,
            rawURL: pair.rawURL,
            hasTopTag: jpegSuccess && rawSuccess  // TRUE wenn beide Operationen erfolgreich
        )

        // Debug-Ausgabe
        if jpegSuccess && rawSuccess {
            print("✅ TOP-Tag hinzugefügt zu: \(pair.jpegURL.lastPathComponent) - neuer Status: \(updatedPair.hasTopTag)")
        } else {
            print("❌ Fehler beim Hinzufügen des TOP-Tags - jpeg: \(jpegSuccess), raw: \(rawSuccess)")
        }

        // Callback mit aktualisiertem Pair aufrufen
        completion(updatedPair)
    }
    
    private func removeTopTag(from pair: ImagePair, completion: @escaping (ImagePair) -> Void) {
        let jpegSuccess = tagService.removeTag("TOP", from: pair.jpegURL)

        var rawSuccess = true
        if let rawURL = pair.rawURL {
            rawSuccess = tagService.removeTag("TOP", from: rawURL)
        }

        // Nach dem Entfernen sollte hasTopTag IMMER false sein (auch bei Fehler)
        let updatedPair = ImagePair(
            jpegURL: pair.jpegURL,
            rawURL: pair.rawURL,
            hasTopTag: false  // IMMER false nach removeTag
        )

        // Debug-Ausgabe
        if jpegSuccess && rawSuccess {
            print("✅ TOP-Tag entfernt von: \(pair.jpegURL.lastPathComponent) - neuer Status: \(updatedPair.hasTopTag)")
        } else {
            print("❌ Fehler beim Entfernen des TOP-Tags - jpeg: \(jpegSuccess), raw: \(rawSuccess)")
        }

        // Callback mit aktualisiertem Pair aufrufen
        completion(updatedPair)
    }
    
    
    // MARK: - Delete Actions

    /// Verschiebt ein ImagePair in den _toDelete Ordner
    /// - Parameters:
    ///   - pair: Das ImagePair das gelöscht werden soll
    ///   - folderURL: Der Ordner in dem die Bilder liegen
    ///   - completion: Callback wenn die Operation fertig ist (true = Erfolg, false = Fehler)
    func deleteImagePair(pair: ImagePair, in folderURL: URL, completion: @escaping (Bool) -> Void) {
        // Delete-Service aufrufen um die Dateien zu verschieben
        let operation: DeleteOperation? = deleteService.deletePair(pair, in: folderURL)

        // Hat es funktioniert?
        if let operation = operation {
            // Ja! Operation zur History hinzufügen
            deleteHistory.append(operation)
            print("✅ ImagePair gelöscht - History enthält jetzt \(deleteHistory.count) Operationen")

            // Callback mit Erfolg aufrufen
            completion(true)
        } else {
            // Nein - Fehler!
            print("❌ Fehler beim Löschen des ImagePairs")

            // Callback mit Fehler aufrufen
            completion(false)
        }
    }

    /// Macht die letzte Delete-Operation rückgängig
    /// - Parameter completion: Callback wenn die Operation fertig ist (true = Erfolg, false = Fehler)
    func undoLastDelete(completion: @escaping (Bool) -> Void) {
        // Gibt es überhaupt etwas zum Rückgängigmachen?
        if deleteHistory.isEmpty {
            print("⚠️ Keine Delete-Operationen zum Rückgängigmachen")
            completion(false)
            return
        }

        // Letzte Operation aus der History holen
        // removeLast() holt das letzte Element UND entfernt es aus dem Array
        let lastOperation: DeleteOperation = deleteHistory.removeLast()

        print("🔄 Mache Delete rückgängig: \(lastOperation.originalJpegURL.lastPathComponent)")

        // Delete-Service aufrufen um die Dateien zurück zu verschieben
        let success: Bool = deleteService.undoDelete(lastOperation)

        if success {
            print("✅ Undo erfolgreich - History enthält jetzt \(deleteHistory.count) Operationen")
            completion(true)
        } else {
            print("❌ Undo fehlgeschlagen")
            // Bei Fehler die Operation WIEDER zur History hinzufügen
            deleteHistory.append(lastOperation)
            completion(false)
        }
    }

    /// Prüft ob es Delete-Operationen gibt die rückgängig gemacht werden können
    /// - Returns: true wenn Undo möglich ist, false wenn nicht
    func canUndo() -> Bool {
        // Einfach prüfen ob die History leer ist oder nicht
        let hasHistory: Bool = deleteHistory.isEmpty == false
        return hasHistory
    }

    /// Löscht die komplette Delete-History (z.B. bei Ordnerwechsel)
    func clearDeleteHistory() {
        deleteHistory.removeAll()
        print("🗑️ Delete-History gelöscht")
    }


    // MARK: - Computed Properties

    /// Gibt den Zoom-Level als Prozentsatz zurück (für UI-Anzeige)
    var zoomPercentage: Int {
        Int(zoomScale * 100)
    }

    /// Prüft ob maximaler Zoom erreicht ist
    var isMaxZoom: Bool {
        zoomScale >= maxZoom
    }

    /// Prüft ob minimaler Zoom erreicht ist
    var isMinZoom: Bool {
        zoomScale <= minZoom
    }

    /// Prüft ob Pan-Funktionalität verfügbar sein sollte
    var isPanEnabled: Bool {
        zoomScale > minZoom
    }
}
