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
                onFolderSelected: handleFolderSelection
            )
        } detail: {
            // CONTENT AREA: Bildvorschau oben + Thumbnails unten
            VStack(spacing: 0) {
                ImageViewerView(selectedImagePair: selectedPair)
                
                ThumbnailBarView(
                    pairs: pairs,
                    selectedPair: $selectedPair
                )
            }
            .background(Color(.controlBackgroundColor))
        }
    }
    
    // MARK: - Event Handlers
    
    /// Wird aufgerufen, wenn ein neuer Ordner ausgewählt wird
    private func handleFolderSelection(_ url: URL) {
        // Hier können wir später zusätzliche Logik hinzufügen,
        // z.B. Caching, Logging, etc.
        selectedPair = pairs.first
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
