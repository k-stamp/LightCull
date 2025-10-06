//
//  ThumbnailBarView.swift
//  LightCull
//
//  Verantwortlich für: Thumbnail-Leiste mit Navigation
//

import SwiftUI
import AppKit  // Für NSEvent.modifierFlags (CMD-Taste Detection)

struct ThumbnailBarView: View {
    let pairs: [ImagePair]
    @Binding var selectedPair: ImagePair?

    // NEU: Multi-Selection für Batch-Operationen
    @Binding var selectedPairs: Set<UUID>

    // NEU: Callback für Context-Menu "Umbenennen"
    let onRenameSelected: () -> Void

    // NEU: State für letzten Click (für Shift-Selection)
    @State private var lastClickedPairID: UUID? = nil

    var body: some View {
        VStack {
            if pairs.isEmpty {
                emptyStateView
            } else {
                thumbnailContentView
            }
        }
        .frame(height: 150) // Feste Höhe für Thumbnail-Bereich
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Thumbnail-Leiste")
                    .font(.headline)
                    .padding(.leading)
            }
            
            Text("Keine Bilder verfügbar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        }
    }
    
    // MARK: - Thumbnail Content
    private var thumbnailContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            thumbnailScrollView
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Thumbnail-Leiste")
                .font(.headline)
                .padding(.leading)
            
            Spacer()
            
            Text("\(pairs.count) Bildpaare")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.trailing)
        }
    }
    
    // MARK: - Thumbnail ScrollView
    private var thumbnailScrollView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            LazyHStack(spacing: 12) {
                ForEach(pairs) { pair in
                    thumbnailItem(for: pair)
                        .onTapGesture {
                            handleThumbnailClick(for: pair)
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Thumbnail Item
    private func thumbnailItem(for pair: ImagePair) -> some View {
        VStack(spacing: 6) {
            AsyncImage(url: pair.jpegURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color(.quaternaryLabelColor))
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
            }
            .frame(maxWidth: 100, maxHeight: 100)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                // Border-Logik: Blau wenn multi-selected, Accent wenn single-selected
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        getBorderColor(for: pair),
                        lineWidth: getBorderWidth(for: pair)
                    )
            }

            // Dateiname ohne Extension
            Text(pair.jpegURL.deletingPathExtension().lastPathComponent)
                .font(.caption2)
                .lineLimit(1)
                .frame(maxWidth: 100)

            // RAW Status
            Text(pair.rawURL != nil ? "RAW✅" : "RAW🚫")
                .font(.caption2)
        }
        .frame(maxWidth: 110)
        // NEU: Context-Menu für Umbenennen
        .contextMenu {
            contextMenuItems(for: pair)
        }
    }

    // MARK: - Border Logik

    /// Gibt die Border-Farbe für ein Thumbnail zurück
    /// Blau = Multi-Selection, Accent = Single-Selection, Grau = Nicht ausgewählt
    private func getBorderColor(for pair: ImagePair) -> Color {
        // Ist dieses Pair in der Multi-Selection?
        let isMultiSelected: Bool = selectedPairs.contains(pair.id)

        if isMultiSelected {
            // Multi-Selection: Blauer Rand
            return Color.blue
        } else if selectedPair?.id == pair.id {
            // Single-Selection: Accent-Farbe
            return Color.accentColor
        } else {
            // Nicht ausgewählt: Grauer Separator
            return Color(.separatorColor)
        }
    }

    /// Gibt die Border-Breite für ein Thumbnail zurück
    private func getBorderWidth(for pair: ImagePair) -> CGFloat {
        // Ist dieses Pair ausgewählt (entweder single oder multi)?
        let isMultiSelected: Bool = selectedPairs.contains(pair.id)
        let isSingleSelected: Bool = selectedPair?.id == pair.id

        if isMultiSelected || isSingleSelected {
            // Ausgewählt: Dickerer Rand
            return 2.0
        } else {
            // Nicht ausgewählt: Dünner Rand
            return 0.5
        }
    }

    // MARK: - Context Menu

    /// Gibt die Context-Menu-Items für ein Thumbnail zurück
    private func contextMenuItems(for pair: ImagePair) -> some View {
        Group {
            Button("Umbenennen...") {
                handleRenameFromContextMenu(for: pair)
            }
        }
    }

    // MARK: - Actions

    /// Wird aufgerufen, wenn auf ein Thumbnail geklickt wird
    private func handleThumbnailClick(for pair: ImagePair) {
        // Prüfen welche Modifier-Keys gedrückt sind
        // NSEvent.modifierFlags ist ein macOS-Feature, um aktuell gedrückte Tasten zu prüfen
        let isCmdPressed: Bool = NSEvent.modifierFlags.contains(.command)
        let isShiftPressed: Bool = NSEvent.modifierFlags.contains(.shift)

        if isShiftPressed {
            // SHIFT ist gedrückt: Range-Selection (wie im Finder)
            handleRangeSelection(to: pair)
        } else if isCmdPressed {
            // CMD ist gedrückt: Multi-Selection Toggle
            handleMultiSelectionToggle(for: pair)
        } else {
            // Keine Modifier: Normale Single-Selection
            handleSingleSelection(for: pair)
        }

        // Letzten Click speichern (für Shift-Selection)
        lastClickedPairID = pair.id
    }

    /// Behandelt normale Single-Selection (ohne Modifier)
    private func handleSingleSelection(for pair: ImagePair) {
        // Single-Selection setzen
        selectedPair = pair

        // Multi-Selection löschen
        selectedPairs.removeAll()
    }

    /// Behandelt Multi-Selection Toggle (mit CMD)
    private func handleMultiSelectionToggle(for pair: ImagePair) {
        // WICHTIG: Beim ersten CMD+Click müssen wir die aktuelle Single-Selection
        // zur Multi-Selection hinzufügen, sonst geht sie verloren!
        if selectedPairs.isEmpty && selectedPair != nil {
            // Multi-Selection ist leer, aber Single-Selection existiert
            // -> Single-Selection zur Multi-Selection hinzufügen
            selectedPairs.insert(selectedPair!.id)
        }

        // Ist dieses Pair bereits in der Multi-Selection?
        let isAlreadySelected: Bool = selectedPairs.contains(pair.id)

        if isAlreadySelected {
            // Ja - entfernen (Toggle off)
            selectedPairs.remove(pair.id)
        } else {
            // Nein - hinzufügen (Toggle on)
            selectedPairs.insert(pair.id)
        }

        // Single-Selection löschen (Multi-Selection ist jetzt aktiv)
        selectedPair = nil

        // Wenn Multi-Selection jetzt leer ist, setzen wir Single-Selection zurück
        if selectedPairs.isEmpty {
            selectedPair = pair
        }
    }

    /// Behandelt Range-Selection (mit SHIFT)
    private func handleRangeSelection(to targetPair: ImagePair) {
        // Wenn kein letzter Click gespeichert ist, behandeln wie normale Selection
        guard let lastID = lastClickedPairID else {
            handleSingleSelection(for: targetPair)
            return
        }

        // Finde die Indizes vom letzten Click und vom aktuellen Click
        guard let startIndex = pairs.firstIndex(where: { $0.id == lastID }),
              let endIndex = pairs.firstIndex(where: { $0.id == targetPair.id }) else {
            // Einer der Indizes nicht gefunden - normale Selection
            handleSingleSelection(for: targetPair)
            return
        }

        // Bestimme den Range (von klein nach groß)
        let rangeStart: Int = min(startIndex, endIndex)
        let rangeEnd: Int = max(startIndex, endIndex)

        // Multi-Selection löschen
        selectedPairs.removeAll()

        // Alle Pairs im Range zur Multi-Selection hinzufügen
        for i in rangeStart...rangeEnd {
            let pair: ImagePair = pairs[i]
            selectedPairs.insert(pair.id)
        }

        // Single-Selection löschen (Multi-Selection ist aktiv)
        selectedPair = nil
    }

    /// Wird aufgerufen, wenn "Umbenennen..." im Context-Menu geklickt wird
    private func handleRenameFromContextMenu(for pair: ImagePair) {
        // Sicherstellen, dass dieses Pair in der Multi-Selection ist
        if !selectedPairs.contains(pair.id) {
            // Falls nicht, fügen wir es hinzu
            selectedPairs.insert(pair.id)
        }

        // Callback aufrufen
        onRenameSelected()
    }
}

#Preview("ThumbnailBarView - Empty") {
    ThumbnailBarView(
        pairs: [],
        selectedPair: .constant(nil),
        selectedPairs: .constant([]),
        onRenameSelected: {
            print("Umbenennen geklickt")
        }
    )
}

#Preview("ThumbnailBarView - With Data") {
    ThumbnailBarView(
        pairs: [
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2"),
                hasTopTag: false
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
        selectedPair: .constant(nil),
        selectedPairs: .constant([]),
        onRenameSelected: {
            print("Umbenennen geklickt")
        }
    )
}
