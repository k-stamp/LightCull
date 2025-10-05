//
//  SidebarView.swift
//  LightCull
//
//  Verantwortlich für: Ordnerauswahl und Info-Anzeige
//

import SwiftUI

struct SidebarView: View {
    @Binding var folderURL: URL?
    @Binding var pairs: [ImagePair]
    
    // NEU: Metadaten des aktuell ausgewählten Bildes
    let currentMetadata: ImageMetadata?
    
    let onFolderSelected: (URL) -> Void
    
    private let fileService = FileService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("LightCull")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Divider()
            
            folderSelectionSection
            
            Divider()
            
            infoSection
            
            Divider()
            
            metadataSection
            
            Spacer()
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
    }
    
    // MARK: - Folder Selection Section
    private var folderSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ordner")
                .font(.headline)
                .padding(.horizontal)
            
            Button("Ordner auswählen") {
                selectFolder()
            }
            .padding(.horizontal)
            
            if let folderURL {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gewählter Ordner:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(folderURL.lastPathComponent)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Info")
                .font(.headline)
                .padding(.horizontal)
            
            if pairs.isEmpty {
                Text("Keine Bildpaare gefunden")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                Text("Paare: \(pairs.count)")
                    .font(.subheadline)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Metadata Section (NEU!)
    
    /// Zeigt die Metadaten des aktuell ausgewählten Bildes an
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bild-Informationen")
                .font(.headline)
                .padding(.horizontal)
            
            // Wenn Metadaten vorhanden sind, zeige sie an
            if let metadata = currentMetadata {
                VStack(alignment: .leading, spacing: 8) {
                    // Dateiname
                    metadataRow(label: "Datei", value: metadata.fileName)
                    
                    // Dateigröße
                    metadataRow(label: "Größe", value: metadata.fileSize)
                    
                    // Wenn EXIF-Daten vorhanden sind, zeige Trennlinie
                    if hasAnyExifData(metadata) {
                        Divider()
                            .padding(.horizontal)
                    }
                    
                    // Kamera-Informationen (nur wenn vorhanden)
                    if let make = metadata.cameraMake {
                        metadataRow(label: "Marke", value: make)
                    }
                    
                    if let model = metadata.cameraModel {
                        metadataRow(label: "Modell", value: model)
                    }
                    
                    // Aufnahme-Parameter (nur wenn vorhanden)
                    if let focalLength = metadata.focalLength {
                        metadataRow(label: "Brennweite", value: focalLength)
                    }
                    
                    if let aperture = metadata.aperture {
                        metadataRow(label: "Blende", value: aperture)
                    }
                    
                    if let shutterSpeed = metadata.shutterSpeed {
                        metadataRow(label: "Belichtung", value: shutterSpeed)
                    }
                }
            } else {
                // Wenn keine Metadaten vorhanden, zeige Platzhalter
                Text("Kein Bild ausgewählt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    /// Hilfsfunktion: Erstellt eine Zeile mit Label und Wert
    /// Das ist das typische "Key: Value" Pattern das du aus dem Finder kennst
    private func metadataRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled) // Ermöglicht das Kopieren des Wertes
        }
        .padding(.horizontal)
    }
    
    /// Prüft ob irgendwelche EXIF-Daten vorhanden sind
    /// Nützlich um zu entscheiden ob wir eine Trennlinie zeigen
    private func hasAnyExifData(_ metadata: ImageMetadata) -> Bool {
        return metadata.cameraMake != nil ||
               metadata.cameraModel != nil ||
               metadata.focalLength != nil ||
               metadata.aperture != nil ||
               metadata.shutterSpeed != nil
    }
    
    // MARK: - Helper Methods
    
    /// Öffnet den macOS Dialog zur Ordnerwahl
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            folderURL = url

            // WICHTIG: Security-Scoped Access ZUERST starten (in MainView)
            onFolderSelected(url)

            // DANN erst die Dateien scannen (benötigt den Access um Tags zu lesen)
            pairs = fileService.findImagePairs(in: url)
        }
    }
}

// MARK: - Previews

#Preview("SidebarView - Empty") {
    SidebarView(
        folderURL: .constant(nil),
        pairs: .constant([]),
        currentMetadata: nil,
        onFolderSelected: { _ in }
    )
}

#Preview("SidebarView - With Data") {
    SidebarView(
        folderURL: .constant(URL(fileURLWithPath: "/Users/Mock/Pictures")),
        pairs: .constant([
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/image1.jpg"),
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2"),
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/image2.jpg"),
                rawURL: nil,
                hasTopTag: false
            )
        ]),
        currentMetadata: nil,
        onFolderSelected: { _ in }
    )
}

#Preview("SidebarView - With Metadata") {
    SidebarView(
        folderURL: .constant(URL(fileURLWithPath: "/Users/Mock/Pictures")),
        pairs: .constant([
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/image1.jpg"),
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2"),
                hasTopTag: false
            )
        ]),
        currentMetadata: ImageMetadata(
            fileName: "DSCF0100.JPG",
            fileSize: "2.5 MB",
            cameraMake: "FUJIFILM",
            cameraModel: "X-T5",
            focalLength: "35.0 mm",
            aperture: "f/2.8",
            shutterSpeed: "1/250s"
        ),
        onFolderSelected: { _ in }
    )
}
