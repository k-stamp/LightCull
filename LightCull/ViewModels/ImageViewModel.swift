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
    
    /// Position des Bildes beim Zoomen (für Pan-Gesten, kommt später)
    @Published var imageOffset: CGSize = .zero
    
    // MARK: - Constants
    
    /// Minimaler Zoom-Level (100% = Fensteranpassung)
    let minZoom: CGFloat = 1.0
    
    /// Maximaler Zoom-Level (400% laut Dokumentation)
    let maxZoom: CGFloat = 4.0
    
    /// Zoom-Schritte für Tastatur-Shortcuts (25%)
    let zoomStep: CGFloat = 0.25
    
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
}
