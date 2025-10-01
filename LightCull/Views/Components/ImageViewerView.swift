//
//  ImageViewerView.swift
//  LightCull
//
//  Verantwortlich für: Hauptbildanzeige mit Zoom und Navigation
//

import SwiftUI

struct ImageViewerView: View {
    let selectedImagePair: ImagePair?
    
    var body: some View {
        Group {
            if let selectedImagePair {
                // Bildanzeige wenn ein Bild ausgewählt ist
                imageDisplayView(for: selectedImagePair)
            } else {
                // Empty State wenn kein Bild ausgwählt ist
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
    
    
    // MARK: Image Display
    
    // zeigt das ausgewählte Bild mit automatischer Skalierung
    private func imageDisplayView(for pair: ImagePair) -> some View {
        GeometryReader { geometry in
            AsyncImage(url: pair.jpegURL) { asyncImagePhase in
                switch asyncImagePhase {
                case .empty:
                    // Ladezustand: ProgressView in der Mitte
                    loadingView
                case .success(let image):
                    // Erfolgreich geladen: Bild mit automatischer Sklaierung
                    imageContentView(image: image, availaableSize: geometry.size)
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
    
    
    // Das geladene Bild mit automatischer Fensteranpassung
    private func imageContentView(image: Image, availaableSize: CGSize) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit) // Seitenverhältnis beibehalten, an Fenster anpassen
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .position(x: availaableSize.width / 2, y: availaableSize.height / 2) // zentriert positionieren
    }
    
    
    // MARK: State Views
    
    // Anzeige während des Ladens
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
    
    
    // Anzeige bei Fehlern
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
    
    
    // Anzeige wenn kein Bild ausgewählt ist
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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
}



#Preview("ImageViewerView - Empty") {
    ImageViewerView(selectedImagePair: nil)
}

#Preview("ImageViewerView - With Image") {
    ImageViewerView(
        selectedImagePair: ImagePair(
            jpegURL: URL(fileURLWithPath: "/mock/image1.jpg"),
            rawURL: URL(fileURLWithPath: "/mock/image1.cr2")
        )
    )
}
