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
    
    // Metadaten des aktuell ausgewählten Bildes
    @State private var currentMetadata: ImageMetadata?
    
    // Shared ViewModel für Zoom-Kontrolle zwischen Viewer und Toolbar
    @StateObject private var imageViewModel = ImageViewModel()
    
    // Service zum Laden von Metadaten
    private let metadataService = MetadataService()
    
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
            VStack(spacing: 0) {
                // WICHTIG: ViewModel wird hier weitergegeben!
                ImageViewerView(
                    selectedImagePair: selectedPair,
                    viewModel: imageViewModel,
                    onPreviousImage: selectPreviousImage,
                    onNextImage: selectNextImage
                )
                
                ThumbnailBarView(
                    pairs: pairs,
                    selectedPair: $selectedPair
                )
            }
            .background(Color(.controlBackgroundColor))
            // Toolbar am oberen Fensterrand
            .toolbar {                
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

    /// Wird aufgerufen, wenn ein neuer Ordner ausgewählt wird
    private func handleFolderSelection(_ url: URL) {
        // Hier können wir später zusätzliche Logik hinzufügen,
        // z.B. Caching, Logging, etc.
        selectedPair = pairs.first
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
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2")
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: nil
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: URL(fileURLWithPath: "/mock/image3.arw")
            )
        ],
        folderURL: URL(fileURLWithPath: "/Users/Mock/Pictures")
    )
    .frame(minWidth: 900, minHeight: 600)
}
