//
//  ImageViewerView.swift
//  LightCull
//
//  Responsible for: Main image display with zoom and pan functionality
//

import SwiftUI

struct ImageViewerView: View {
    let selectedImagePair: ImagePair?

    // ViewModel for zoom state management
    // Injected from MainView to keep toolbar and viewer synchronized
    @ObservedObject var viewModel: ImageViewModel

    // Callbacks for navigation between images
    let onPreviousImage: () -> Void
    let onNextImage: () -> Void

    // NEW: Callback for tag toggle
    let onToggleTag: () -> Void

    // NEW: Callback for delete
    let onDeleteImage: () -> Void

    // NEW: Callback for archive
    let onArchiveImage: () -> Void

    // NEW: Callback for outtake
    let onOuttakeImage: () -> Void

    var body: some View {
        ZStack {
            // Main content
            Group {
                if let selectedImagePair {
                    // Image display when an image is selected
                    imageDisplayView(for: selectedImagePair)
                } else {
                    // Empty state when no image is selected
                    emptyStateView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.windowBackgroundColor))

            // Invisible buttons for keyboard shortcuts
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

                // NEW: Keyboard shortcut for tag toggle
                Button("Toggle TOP Tag") { onToggleTag() }
                    .keyboardShortcut("t", modifiers: [])
                    .hidden()

                // NEW: Keyboard shortcut for delete
                Button("Delete Image") { onDeleteImage() }
                    .keyboardShortcut("d", modifiers: [])
                    .hidden()

                // NEW: Keyboard shortcut for archive
                Button("Archive Image") { onArchiveImage() }
                    .keyboardShortcut("a", modifiers: [])
                    .hidden()

                // NEW: Keyboard shortcut for outtake
                Button("Outtake Image") { onOuttakeImage() }
                    .keyboardShortcut("o", modifiers: [])
                    .hidden()
            }
            .frame(width: 0, height: 0)
        }
    }
    
    // MARK: - Image Display

    /// Displays the selected image with zoom functionality
    private func imageDisplayView(for pair: ImagePair) -> some View {
        GeometryReader { geometry in
            AsyncImage(url: pair.jpegURL) { asyncImagePhase in
                switch asyncImagePhase {
                case .empty:
                    // Loading state: ProgressView in the center
                    loadingView

                case .success(let image):
                    // Successfully loaded: Image with zoom and pan functionality
                    zoomableImageView(image: image, availableSize: geometry.size)

                case .failure(_):
                    // Loading error: Display error message
                    errorView(for: pair)

                @unknown default:
                    // Fallback for future AsyncImagePhase cases
                    loadingView
                }
            }
        }
    }


    /// The loaded image with zoom and pan gesture functionality
    private func zoomableImageView(image: Image, availableSize: CGSize) -> some View {
        ZStack {
            // Das eigentliche Bild mit Zoom
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: availableSize.width, maxHeight: availableSize.height)
                // Apply zoom (nur noch viewModel.zoomScale, kein magnificationState mehr)
                .scaleEffect(viewModel.zoomScale)
                // Position: nur noch stored offset (kein dragState mehr)
                .offset(
                    x: viewModel.imageOffset.width,
                    y: viewModel.imageOffset.height
                )
                .position(x: availableSize.width / 2, y: availableSize.height / 2)
                // Adjust pan bounds when image loads (to handle different aspect ratios)
                .onAppear {
                    viewModel.adjustPanBounds(imageSize: availableSize, viewSize: availableSize)
                }

            // Overlay für kombinierte Zoom- und Pan-Gesten
            // Immer aktiv, damit Zoom jederzeit funktioniert
            ZoomAndPanGestureView { magnification in
                // Bei jedem Magnify-Event: Zoom anpassen
                viewModel.handleMagnification(magnification)
            } onScrollDelta: { deltaX, deltaY in
                // Bei jedem Scroll-Event: Delta auf aktuelle Position anwenden
                // (wird im ViewModel ignoriert wenn nicht gezoomt)
                viewModel.applyScrollDelta(
                    deltaX: deltaX,
                    deltaY: deltaY,
                    imageSize: availableSize,
                    viewSize: availableSize
                )
            }
            // WICHTIG: Frame muss gesetzt werden, damit das View Events empfangen kann!
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Allow the view to receive mouse/trackpad events
            .allowsHitTesting(true)
        }
    }
    
    // MARK: - State Views

    /// Display during loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)


            Text("Loading Image...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    /// Display on errors
    private func errorView(for pair: ImagePair) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)


            Text("Loading Error")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("File: \(pair.jpegURL.lastPathComponent)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }


    /// Display when no image is selected
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)


            VStack(spacing: 8) {
                Text("No Image Selected")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("Select an image from the thumbnail bar")
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
        onToggleTag: {},
        onDeleteImage: {},
        onArchiveImage: {},
        onOuttakeImage: {}
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
        onToggleTag: {},
        onDeleteImage: {},
        onArchiveImage: {},
        onOuttakeImage: {}
    )
    .frame(width: 800, height: 600)
}
