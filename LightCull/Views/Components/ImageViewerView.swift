//
//  ImageViewerView.swift
//  LightCull
//
//  Verantwortlich für: Hauptbildanzeige mit Zoom- und Pan-Funktionalität
//

import SwiftUI

struct ImageViewerView: View {
    let selectedImagePair: ImagePair?

    // ViewModel für Zoom-State Management
    // Wird von MainView injiziert, damit Toolbar und Viewer synchron sind
    @ObservedObject var viewModel: ImageViewModel

    // Callbacks für Navigation zwischen Bildern
    let onPreviousImage: () -> Void
    let onNextImage: () -> Void
    
    // NEU: Callback für Tag-Toggle
    let onToggleTag: () -> Void

    // State für Magnification-Geste
    @GestureState private var magnificationState: CGFloat = 1.0

    // State für Drag-Geste (temporäre Verschiebung während des Draggings)
    @GestureState private var dragState: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Hauptinhalt
            Group {
                if let selectedImagePair {
                    // Bildanzeige wenn ein Bild ausgewählt ist
                    imageDisplayView(for: selectedImagePair)
                } else {
                    // Empty State wenn kein Bild ausgewählt ist
                    emptyStateView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.windowBackgroundColor))
            
            // Unsichtbare Buttons für Keyboard Shortcuts
            VStack {
                Button("Zoom In") { viewModel.zoomIn() }
                    .keyboardShortcut("+", modifiers: .command)
                    .hidden()

                Button("Zoom Out") { viewModel.zoomOut() }
                    .keyboardShortcut("-", modifiers: .command)
                    .hidden()

                Button("Reset Zoom") { viewModel.resetZoom() }
                    .keyboardShortcut("0", modifiers: .command)
                    .hidden()

                Button("Previous Image") { onPreviousImage() }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    .hidden()

                Button("Next Image") { onNextImage() }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    .hidden()

                // NEU: Keyboard Shortcut für Tag-Toggle
                Button("Toggle TOP Tag") { onToggleTag() }
                    .keyboardShortcut("t", modifiers: [])
                    .hidden()
            }
            .frame(width: 0, height: 0)
        }
        // Zoom-State zurücksetzen wenn Bild wechselt
        .onChange(of: selectedImagePair?.id) { _, _ in
            viewModel.resetZoom()
        }
    }
    
    // MARK: - Image Display
    
    /// Zeigt das ausgewählte Bild mit Zoom-Funktionalität an
    private func imageDisplayView(for pair: ImagePair) -> some View {
        GeometryReader { geometry in
            AsyncImage(url: pair.jpegURL) { asyncImagePhase in
                switch asyncImagePhase {
                case .empty:
                    // Ladezustand: ProgressView in der Mitte
                    loadingView
                    
                case .success(let image):
                    // Erfolgreich geladen: Bild mit Zoom- und Pan-Funktionalität
                    zoomableImageView(image: image, availableSize: geometry.size)
                    
                case .failure(_):
                    // Fehler beim Laden: Fehlermeldung anzeigen
                    errorView(for: pair)
                    
                @unknown default:
                    // Fallback für zukünftige AsyncImagePhase cases
                    loadingView
                }
            }
        }
    }
    
    /// Das geladene Bild mit Zoom- und Pan-Gesten-Funktionalität
    private func zoomableImageView(image: Image, availableSize: CGSize) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: availableSize.width, maxHeight: availableSize.height)
            // Zoom anwenden
            .scaleEffect(viewModel.zoomScale * magnificationState)
            // Position: gespeicherter Offset + temporärer Drag
            .offset(
                x: viewModel.imageOffset.width + dragState.width,
                y: viewModel.imageOffset.height + dragState.height
            )
            .position(x: availableSize.width / 2, y: availableSize.height / 2)
            // Kombinierte Gesten: Magnification UND Drag gleichzeitig
            .gesture(
                // SimultaneousGesture erlaubt beide Gesten gleichzeitig
                SimultaneousGesture(
                    // Magnification-Geste für Trackpad-Zoom
                    MagnificationGesture()
                        .updating($magnificationState) { currentState, gestureState, _ in
                            // Während der Geste: temporäre Skalierung
                            gestureState = currentState
                        }
                        .onEnded { finalMagnification in
                            // Am Ende der Geste: finale Skalierung anwenden
                            viewModel.handleMagnification(finalMagnification)
                        },
                    
                    // Drag-Geste für Verschieben mit 2 Fingern (OHNE Klick!)
                    // minimumDistance: 0 bedeutet: kein Klick nötig!
                    DragGesture(minimumDistance: 0)
                        .updating($dragState) { value, gestureState, _ in
                            // Nur verschieben wenn gezoomt
                            guard viewModel.isPanEnabled else { return }
                            
                            // Während der Geste: temporäre Verschiebung
                            gestureState = value.translation
                        }
                        .onEnded { value in
                            // Nur verarbeiten wenn gezoomt
                            guard viewModel.isPanEnabled else { return }
                            
                            // Finale Position berechnen und anwenden
                            let newOffset = CGSize(
                                width: viewModel.imageOffset.width + value.translation.width,
                                height: viewModel.imageOffset.height + value.translation.height
                            )
                            
                            // Mit Grenzen-Überprüfung
                            viewModel.handleDrag(
                                translation: newOffset,
                                imageSize: availableSize,
                                viewSize: availableSize
                            )
                            
                            viewModel.endDrag()
                        }
                )
            )
    }
    
    // MARK: - State Views
    
    /// Anzeige während des Ladens
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Lade Bild...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Anzeige bei Fehlern
    private func errorView(for pair: ImagePair) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Fehler beim Laden")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Datei: \(pair.jpegURL.lastPathComponent)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    /// Anzeige wenn kein Bild ausgewählt ist
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 8) {
                Text("Kein Bild ausgewählt")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("Wähle ein Bild aus der Thumbnail-Leiste aus")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Previews

#Preview("ImageViewerView - Empty State") {
    ImageViewerView(
        selectedImagePair: nil,
        viewModel: ImageViewModel(),
        onPreviousImage: {},
        onNextImage: {},
        onToggleTag: {}
    )
    .frame(width: 800, height: 600)
}

#Preview("ImageViewerView - With Image") {
    ImageViewerView(
        selectedImagePair: ImagePair(
            jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
            rawURL: URL(fileURLWithPath: "/mock/image1.raf"),
            hasTopTag: false
        ),
        viewModel: ImageViewModel(),
        onPreviousImage: {},
        onNextImage: {},
        onToggleTag: {}
    )
    .frame(width: 800, height: 600)
}
