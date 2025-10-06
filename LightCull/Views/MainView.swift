//
//  MainView.swift
//  LightCull
//
//  Hauptansicht der App - koordiniert die einzelnen UI-Komponenten
//

import SwiftUI

struct MainView: View {
    @State private var pairs: [ImagePair] = []
    @State private var folderURL: URL?
    @State private var selectedPair: ImagePair?

    // NEU: Multi-Selection für Batch-Operationen
    @State private var selectedPairs: Set<UUID> = []

    // NEU: State für Rename-Sheet
    @State private var showRenameSheet: Bool = false

    // NEU: Tracking für Security-Scoped Access
    @State private var isAccessingSecurityScope = false
    
    // Metadaten des aktuell ausgewählten Bildes
    @State private var currentMetadata: ImageMetadata?
    
    // Shared ViewModel für Zoom-Kontrolle zwischen Viewer und Toolbar
    @StateObject private var imageViewModel = ImageViewModel()
    
    // NEU: Service zum Verwalten von Finder-Tags
    private let tagService = FinderTagService()

    // Service zum Laden von Metadaten
    private let metadataService = MetadataService()

    // NEU: Service zum Umbenennen von Dateien
    private let renameService = FileRenameService()
    
    // Initialisierung für Tests und Previews
    init(pairs: [ImagePair] = [], folderURL: URL? = nil) {
        _pairs = State(initialValue: pairs)
        _folderURL = State(initialValue: folderURL)
    }
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR: Ordnerauswahl und Info
            SidebarView(
                folderURL: $folderURL,
                pairs: $pairs,
                currentMetadata: currentMetadata,
                onFolderSelected: handleFolderSelection
            )
        } detail: {
            // CONTENT AREA: Bildvorschau oben + Thumbnails unten
            ZStack {
                VStack(spacing: 0) {
                    // WICHTIG: ViewModel wird hier weitergegeben!
                    ImageViewerView(
                        selectedImagePair: selectedPair,
                        viewModel: imageViewModel,
                        onPreviousImage: selectPreviousImage,
                        onNextImage: selectNextImage,
                        onToggleTag: handleToggleTag  // NEU: Callback für Tag-Toggle
                    )

                    ThumbnailBarView(
                        pairs: pairs,
                        selectedPair: $selectedPair,
                        selectedPairs: $selectedPairs,
                        onRenameSelected: handleRenameButtonClicked
                    )
                }
                .background(Color(.controlBackgroundColor))

                // NEU: Unsichtbare Buttons für Keyboard Shortcuts
                VStack {
                    Button("Rename Selected") { handleRenameButtonClicked() }
                        .keyboardShortcut("n", modifiers: .command)
                        .hidden()
                }
                .frame(width: 0, height: 0)
            }
            // Toolbar am oberen Fensterrand
            .toolbar {
                // NEU: Tag-Button links in der Toolbar
                ToolbarItem(placement: .navigation) {
                    tagButtonView
                }
                
                ToolbarItem(placement: .primaryAction) {
                    // Zoom-Controls rechts in der Toolbar
                    zoomControlsView
                }
            }
        }
        // Metadaten automatisch laden wenn sich das ausgewählte Bild ändert
        .onChange(of: selectedPair) { oldValue, newValue in
                loadMetadataForSelectedPair(newValue)
        }
        // NEU: Cleanup bei View-Verschwinden
        .onDisappear {
            stopSecurityScopedAccess()
        }
        // NEU: Rename-Sheet anzeigen
        .sheet(isPresented: $showRenameSheet) {
            renameSheetView
        }
    }
    
    // MARK: - Rename Sheet (NEU!)

    /// Rename-Sheet für Batch-Umbenennung
    private var renameSheetView: some View {
        // Die ausgewählten Pairs aus dem Set holen
        let selectedPairsArray: [ImagePair] = getSelectedPairsArray()

        return RenameSheetView(
            selectedPairs: selectedPairsArray,
            onRename: { prefix in
                handleRename(withPrefix: prefix)
            },
            onCancel: {
                handleRenameCancel()
            }
        )
    }

    // MARK: - Tag Button (NEU!)

    /// Tag-Button für die Toolbar
    private var tagButtonView: some View {
        Button(action: {
            handleToggleTag()
        }) {
            Image(systemName: selectedPair?.hasTopTag == true ? "star.fill" : "star")
                .imageScale(.medium)
                .foregroundStyle(selectedPair?.hasTopTag == true ? .yellow : .primary)
        }
        .disabled(selectedPair == nil)
        .help("Als TOP markieren/entfernen (T)")
    }
    
    // MARK: - Zoom Controls
    
    /// Zoom-Slider und Buttons für die Toolbar
    private var zoomControlsView: some View {
        HStack(spacing: 12) {
            // Zoom Out Button
            Button(action: {
                imageViewModel.zoomOut()
            }) {
                Image(systemName: "minus.magnifyingglass")
                    .imageScale(.medium)
            }
            .disabled(imageViewModel.isMinZoom)
            .help("Herauszoomen (⌘-)")
            
            // Zoom-Slider mit Prozentanzeige
            HStack(spacing: 8) {
                // KORREKTUR: Direktes Binding an @Published Property
                Slider(
                    value: $imageViewModel.zoomScale,
                    in: imageViewModel.minZoom...imageViewModel.maxZoom,
                    step: 0.01
                )
                .frame(width: 120)
                .disabled(selectedPair == nil)
                
                Text("\(imageViewModel.zoomPercentage)%")
                    .font(.caption)
                    .monospacedDigit() // Verhindert Springen der Ziffern
                    .frame(minWidth: 45, alignment: .trailing)
                    .foregroundStyle(selectedPair == nil ? .secondary : .primary)
            }
            
            // Zoom In Button
            Button(action: {
                imageViewModel.zoomIn()
            }) {
                Image(systemName: "plus.magnifyingglass")
                    .imageScale(.medium)
            }
            .disabled(imageViewModel.isMaxZoom)
            .help("Hineinzoomen (⌘+)")
            
            // Reset Zoom Button
            Button(action: {
                imageViewModel.resetZoom()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .imageScale(.medium)
            }
            .disabled(imageViewModel.isMinZoom)
            .help("Zoom zurücksetzen (⌘0)")
        }
        .disabled(selectedPair == nil)
    }
    
    // MARK: - Event Handlers
    
    /// Behandelt das Toggling des TOP-Tags für das aktuell ausgewählte Bild
    private func handleToggleTag() {
        guard let currentPair = selectedPair else {
            return
        }

        // ViewModel aufrufen um Tag zu togglen
        imageViewModel.toggleTopTag(for: currentPair) { updatedPair in
            // WICHTIG: UI-Updates MÜSSEN auf dem Main Thread passieren
            DispatchQueue.main.async {
                // Callback: ImagePair im Array aktualisieren
                updateImagePair(updatedPair)
            }
        }
    }
    
    /// Aktualisiert ein ImagePair im pairs-Array
    /// - Parameter updatedPair: Das aktualisierte ImagePair mit neuem Tag-Status
    private func updateImagePair(_ updatedPair: ImagePair) {
        // 1. Index des alten Pairs finden
        // Wir nutzen Equatable (basierend auf URLs), nicht auf hasTopTag!
        guard let index = pairs.firstIndex(where: { $0 == updatedPair }) else {
            print("⚠️ ImagePair nicht im Array gefunden")
            return
        }

        // 2. Altes Pair durch neues ersetzen
        pairs[index] = updatedPair

        // 3. Auch selectedPair aktualisieren (damit UI synchron bleibt)
        // WICHTIG: Wir setzen selectedPair auf nil und dann auf updatedPair
        // Das zwingt SwiftUI, die Änderung zu erkennen und die UI zu aktualisieren
        selectedPair = nil
        selectedPair = updatedPair

        // 4. Debug-Ausgabe
        print("✅ ImagePair aktualisiert: \(updatedPair.jpegURL.lastPathComponent) - hasTopTag: \(updatedPair.hasTopTag)")
    }

    // MARK: - Rename Handlers (NEU!)

    /// Wird aufgerufen, wenn der "Umbenennen"-Button geklickt wird
    private func handleRenameButtonClicked() {
        // Sheet anzeigen
        showRenameSheet = true
    }

    /// Wird aufgerufen, wenn im Rename-Sheet auf "Abbrechen" geklickt wird
    private func handleRenameCancel() {
        // Sheet schließen
        showRenameSheet = false

        // Multi-Selection löschen
        selectedPairs.removeAll()
    }

    /// Wird aufgerufen, wenn im Rename-Sheet auf "Umbenennen" geklickt wird
    private func handleRename(withPrefix prefix: String) {
        // 1. Die ausgewählten Pairs aus dem Set holen
        let selectedPairsArray: [ImagePair] = getSelectedPairsArray()

        // 2. Jedes Pair umbenennen
        for pair in selectedPairsArray {
            // Pair umbenennen mit dem Rename-Service
            let newPair: ImagePair? = renameService.renamePair(pair, withPrefix: prefix)

            if newPair == nil {
                print("⚠️ Fehler beim Umbenennen von: \(pair.jpegURL.lastPathComponent)")
            }
        }

        // 3. Sheet schließen
        showRenameSheet = false

        // 4. Multi-Selection löschen
        selectedPairs.removeAll()

        // 5. Ordner neu scannen (einfachste Lösung - lädt alle Pairs neu)
        if let folder = folderURL {
            rescanFolder(folder)
        }
    }

    /// Gibt ein Array mit den ausgewählten ImagePairs zurück
    private func getSelectedPairsArray() -> [ImagePair] {
        // Leeres Array erstellen
        var result: [ImagePair] = []

        // Durch alle Pairs gehen
        for pair in pairs {
            // Ist dieses Pair im selectedPairs Set?
            if selectedPairs.contains(pair.id) {
                // Ja - zum Result-Array hinzufügen
                result.append(pair)
            }
        }

        return result
    }

    /// Scannt den Ordner neu und aktualisiert die Pairs
    private func rescanFolder(_ folder: URL) {
        // FileService nutzen um Pairs neu zu laden
        let fileService = FileService(tagService: tagService)
        pairs = fileService.findImagePairs(in: folder)

        // Selected Pair zurücksetzen
        selectedPair = nil

        print("✅ Ordner neu gescannt - \(pairs.count) Pairs gefunden")
    }

    // MARK: - Navigation Handlers

    /// Wird aufgerufen, wenn ein neuer Ordner ausgewählt wird
    private func handleFolderSelection(_ url: URL) {
        // WICHTIG: Erst alten Access stoppen
        stopSecurityScopedAccess()
        
        // NEU: Security-Scoped Access für den ausgewählten Ordner starten
        isAccessingSecurityScope = url.startAccessingSecurityScopedResource()
        
        if !isAccessingSecurityScope {
            print("⚠️ Konnte Security-Scoped Access nicht starten für: \(url.path)")
        } else {
            print("✅ Security-Scoped Access gestartet für: \(url.path)")
        }
        
        // Erstes Bild auswählen
        selectedPair = pairs.first
    }
    
    /// Stoppt den Security-Scoped Access für den aktuellen Ordner
    private func stopSecurityScopedAccess() {
        guard isAccessingSecurityScope, let url = folderURL else {
            return
        }
        
        url.stopAccessingSecurityScopedResource()
        isAccessingSecurityScope = false
        print("🛑 Security-Scoped Access gestoppt für: \(url.path)")
    }

    /// Springt zum vorherigen Bild in der Liste
    private func selectPreviousImage() {
        guard let current = selectedPair,
              let currentIndex = pairs.firstIndex(of: current),
              currentIndex > 0 else {
            return
        }
        selectedPair = pairs[currentIndex - 1]
    }

    /// Springt zum nächsten Bild in der Liste
    private func selectNextImage() {
        guard let current = selectedPair,
              let currentIndex = pairs.firstIndex(of: current),
              currentIndex < pairs.count - 1 else {
            return
        }
        selectedPair = pairs[currentIndex + 1]
    }
    
    // MARK: - Metadata Loading
    
    private func loadMetadataForSelectedPair(_ pair: ImagePair?) {
        // Wenn kein Bild ausgewählt ist, Metadaten zurücksetzen
        guard let pair = pair else {
            currentMetadata = nil
            return
        }
        
        currentMetadata = metadataService.extractMetadata(from: pair.jpegURL)
        
        // Debug-Output (kannst du später entfernen)
        if let metadata = currentMetadata {
            print("Metadaten geladen: \(metadata.fileName)")
        } else {
            print("Keine Metadaten verfügbar für: \(pair.jpegURL.lastPathComponent)")
        }
    }
    
    
}

// MARK: - Previews

#Preview("MainView – Empty") {
    MainView()
        .frame(minWidth: 900, minHeight: 600)
}

#Preview("MainView – With Data") {
    MainView(
        pairs: [
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2"),
                hasTopTag: true
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: nil,
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: URL(fileURLWithPath: "/mock/image3.arw"),
                hasTopTag: false
            )
        ],
        folderURL: URL(fileURLWithPath: "/Users/Mock/Pictures")
    )
    .frame(minWidth: 900, minHeight: 600)
}
