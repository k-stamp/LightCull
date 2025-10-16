//
//  ThumbnailBarView.swift
//  LightCull
//
//  Responsible for: Thumbnail bar with navigation
//

import SwiftUI
import AppKit  // For NSEvent.modifierFlags (CMD key detection)

struct ThumbnailBarView: View {
    let pairs: [ImagePair]
    @Binding var selectedPair: ImagePair?

    // NEW: Multi-selection for batch operations
    @Binding var selectedPairs: Set<UUID>

    // NEW: Callback for context menu "Rename"
    let onRenameSelected: () -> Void

    // NEW: State for last click (for shift-selection)
    @State private var lastClickedPairID: UUID? = nil

    // MARK: - Computed Properties

    /// Fixed height for the thumbnail bar
    private let fixedHeight: CGFloat = 180

    /// Fixed thumbnail size
    private let thumbnailSize: CGFloat = 100

    /// Current position of the selected image (1-based for UI)
    private var currentPosition: Int? {
        guard let selected = selectedPair,
              let index = pairs.firstIndex(of: selected) else {
            return nil
        }
        return index + 1  // 1-based instead of 0-based
    }

    /// Total number of images (only JPEGs, not counting RAWs)
    private var totalImages: Int {
        return pairs.count
    }

    var body: some View {
        VStack {
            if pairs.isEmpty {
                emptyStateView
            } else {
                thumbnailContentView
            }
        }
        .frame(height: fixedHeight) // Fixed height for thumbnail area
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        Text("Keine Bilder verfügbar")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }
    
    // MARK: - Thumbnail Content
    private var thumbnailContentView: some View {
        thumbnailScrollView
            .overlay(alignment: .topTrailing) {
                // Position indicator in the top-right corner
                positionIndicator
                    .padding([.top, .trailing], 12)
            }
    }
    
    // MARK: - Position Indicator

    /// Shows current image position (e.g., "Bild 5 von 23")
    private var positionIndicator: some View {
        Group {
            if let position = currentPosition {
                Text("Bild \(position) von \(totalImages)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.6))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // MARK: - Thumbnail ScrollView
    private var thumbnailScrollView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: true) {
                // VStack to add vertical spacing without affecting scrollbar
                VStack {
                    Spacer()
                        .frame(height: 8)

                    LazyHStack(spacing: 12) {
                        ForEach(pairs) { pair in
                            thumbnailItem(for: pair)
                                .id(pair.id)  // Explizite ID für scrollTo()
                                .onTapGesture {
                                    handleThumbnailClick(for: pair)
                                }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                        .frame(height: 8)
                }
            }
            .scrollIndicators(.visible) // Explicitly show scrollbar
            .onChange(of: selectedPair) { oldValue, newValue in
                // Auto-scroll zu ausgewähltem Thumbnail wenn Selection sich ändert
                if let pair = newValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scrollProxy.scrollTo(pair.id, anchor: .center)
                    }
                }
            }
        }
    }
    
    // MARK: - Thumbnail Item
    private func thumbnailItem(for pair: ImagePair) -> some View {
        VStack(spacing: 6) {
            // NEW: Use thumbnail URL if available, otherwise fall back to JPEG URL
            AsyncImage(url: pair.thumbnailURL ?? pair.jpegURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.quaternaryLabelColor))
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
            }
            .frame(width: thumbnailSize, height: thumbnailSize)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                // Border logic: Blue when multi-selected, accent when single-selected
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        getBorderColor(for: pair),
                        lineWidth: getBorderWidth(for: pair)
                    )
            }
            .overlay(alignment: .topTrailing) {
                // Stern-Badge für TOP-getaggte Bilder (dynamically scaled)
                if pair.hasTopTag {
                    let badgeSize = max(12, min(thumbnailSize * 0.14, 18))
                    let badgePadding = max(4, min(thumbnailSize * 0.06, 8))

                    Image(systemName: "star.fill")
                        .font(.system(size: badgeSize))
                        .foregroundStyle(.yellow)
                        .padding(badgePadding)
                        .background(
                            Circle()
                                .fill(.black.opacity(0.5))
                                .blur(radius: 2)
                        )
                }
            }

            // Filename without extension
            Text(pair.jpegURL.deletingPathExtension().lastPathComponent)
                .font(.caption2)
                .lineLimit(1)
                .frame(maxWidth: thumbnailSize)

            // RAW status
            Text(pair.rawURL != nil ? "RAW✅" : "RAW🚫")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: thumbnailSize + 10)
        // NEW: Context menu for renaming
        .contextMenu {
            contextMenuItems(for: pair)
        }
    }

    // MARK: - Border Logic

    /// Returns the border color for a thumbnail
    /// Blue = multi-selection, accent = single-selection, gray = not selected
    private func getBorderColor(for pair: ImagePair) -> Color {
        // Is this pair in the multi-selection?
        let isMultiSelected: Bool = selectedPairs.contains(pair.id)

        if isMultiSelected {
            // Multi-selection: blue border
            return Color.blue
        } else if selectedPair?.id == pair.id {
            // Single-selection: accent color
            return Color.accentColor
        } else {
            // Not selected: gray separator
            return Color(.separatorColor)
        }
    }

    /// Returns the border width for a thumbnail
    private func getBorderWidth(for pair: ImagePair) -> CGFloat {
        // Is this pair selected (either single or multi)?
        let isMultiSelected: Bool = selectedPairs.contains(pair.id)
        let isSingleSelected: Bool = selectedPair?.id == pair.id

        if isMultiSelected || isSingleSelected {
            // Selected: thicker border
            return 2.0
        } else {
            // Not selected: thin border
            return 0.5
        }
    }

    // MARK: - Context Menu

    /// Returns the context menu items for a thumbnail
    private func contextMenuItems(for pair: ImagePair) -> some View {
        Group {
            Button("Umbenennen...") {
                handleRenameFromContextMenu(for: pair)
            }
        }
    }

    // MARK: - Actions

    /// Called when a thumbnail is clicked
    private func handleThumbnailClick(for pair: ImagePair) {
        // Check which modifier keys are pressed
        // NSEvent.modifierFlags is a macOS feature to check currently pressed keys
        let isCmdPressed: Bool = NSEvent.modifierFlags.contains(.command)
        let isShiftPressed: Bool = NSEvent.modifierFlags.contains(.shift)

        if isShiftPressed {
            // SHIFT is pressed: range selection (like in Finder)
            handleRangeSelection(to: pair)
        } else if isCmdPressed {
            // CMD is pressed: multi-selection toggle
            handleMultiSelectionToggle(for: pair)
        } else {
            // No modifier: normal single-selection
            handleSingleSelection(for: pair)
        }

        // Save last click (for shift-selection)
        lastClickedPairID = pair.id
    }

    /// Handles normal single-selection (without modifier)
    private func handleSingleSelection(for pair: ImagePair) {
        // Set single-selection
        selectedPair = pair

        // Clear multi-selection
        selectedPairs.removeAll()
    }

    /// Handles multi-selection toggle (with CMD)
    private func handleMultiSelectionToggle(for pair: ImagePair) {
        // IMPORTANT: On first CMD+click, we must add the current single-selection
        // to the multi-selection, otherwise it gets lost!
        if selectedPairs.isEmpty && selectedPair != nil {
            // Multi-selection is empty, but single-selection exists
            // -> Add single-selection to multi-selection
            selectedPairs.insert(selectedPair!.id)
        }

        // Is this pair already in the multi-selection?
        let isAlreadySelected: Bool = selectedPairs.contains(pair.id)

        if isAlreadySelected {
            // Yes - remove (toggle off)
            selectedPairs.remove(pair.id)
        } else {
            // No - add (toggle on)
            selectedPairs.insert(pair.id)
        }

        // Clear single-selection (multi-selection is now active)
        selectedPair = nil

        // If multi-selection is now empty, reset single-selection
        if selectedPairs.isEmpty {
            selectedPair = pair
        }
    }

    /// Handles range selection (with SHIFT)
    private func handleRangeSelection(to targetPair: ImagePair) {
        // If no last click is saved, treat as normal selection
        guard let lastID = lastClickedPairID else {
            handleSingleSelection(for: targetPair)
            return
        }

        // Find the indices from last click and current click
        guard let startIndex = pairs.firstIndex(where: { $0.id == lastID }),
              let endIndex = pairs.firstIndex(where: { $0.id == targetPair.id }) else {
            // One of the indices not found - normal selection
            handleSingleSelection(for: targetPair)
            return
        }

        // Determine the range (from small to large)
        let rangeStart: Int = min(startIndex, endIndex)
        let rangeEnd: Int = max(startIndex, endIndex)

        // Clear multi-selection
        selectedPairs.removeAll()

        // Add all pairs in range to multi-selection
        for i in rangeStart...rangeEnd {
            let pair: ImagePair = pairs[i]
            selectedPairs.insert(pair.id)
        }

        // Clear single-selection (multi-selection is active)
        selectedPair = nil
    }

    /// Called when "Rename..." is clicked in the context menu
    private func handleRenameFromContextMenu(for pair: ImagePair) {
        // Ensure this pair is in the multi-selection
        if !selectedPairs.contains(pair.id) {
            // If not, add it
            selectedPairs.insert(pair.id)
        }

        // Call callback
        onRenameSelected()
    }
}

#Preview("ThumbnailBarView - Empty") {
    ThumbnailBarView(
        pairs: [],
        selectedPair: .constant(nil),
        selectedPairs: .constant([]),
        onRenameSelected: { }
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
        onRenameSelected: { }
    )
}
