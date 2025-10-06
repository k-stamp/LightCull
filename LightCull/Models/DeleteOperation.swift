//
//  DeleteOperation.swift
//  LightCull
//
//  Speichert Informationen über eine Lösch-Operation für Undo-Funktionalität
//

import Foundation

// Dieses Struct speichert alle Informationen, die wir brauchen, um eine Löschung
// rückgängig zu machen. Es ist wie eine "Erinnerung" an die Verschiebung.
struct DeleteOperation {
    // Die originale URL des JPEG (bevor es verschoben wurde)
    let originalJpegURL: URL

    // Die neue URL des JPEG (im _toDelete Ordner)
    let deletedJpegURL: URL

    // Die originale URL des RAW (bevor es verschoben wurde)
    // Optional, weil nicht jedes Bild ein RAW hat
    let originalRawURL: URL?

    // Die neue URL des RAW (im _toDelete Ordner)
    // Optional, weil nicht jedes Bild ein RAW hat
    let deletedRawURL: URL?

    // Wann wurde das Bild gelöscht? (für Debug-Zwecke)
    let timestamp: Date
}
