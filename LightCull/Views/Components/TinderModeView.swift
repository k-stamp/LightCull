//
//  TinderModeView.swift
//  LightCull
//
//  Tinder-style swipe interface for fast photo culling
//  - Swipe left: Archive image
//  - Swipe right: Keep image (next)
//  - Swipe up: Mark as TOP
//

import SwiftUI
import OSLog

struct TinderModeView: View {
    // MARK: - Bindings

    /// Array of all image pairs in the current folder
    let pairs: [ImagePair]

    /// Callback when user exits Tinder mode
    let onExit: () -> Void

    /// Callback when user swipes left (archive)
    let onArchive: (ImagePair, @escaping () -> Void) -> Void

    /// Callback when user swipes up (toggle TOP tag)
    let onToggleTag: (ImagePair, @escaping () -> Void) -> Void

    /// Callback when user taps undo button
    let onUndo: () -> Void

    // MARK: - State

    /// Current index in the pairs array
    @State private var currentIndex: Int = 0

    /// Drag offset for the current card
    @State private var dragOffset: CGSize = .zero

    /// Rotation angle for the current card (based on horizontal drag)
    @State private var dragRotation: Double = 0

    /// Flag to trigger card removal animation
    @State private var isRemoving: Bool = false

    /// Direction of the swipe (for animation)
    @State private var swipeDirection: SwipeDirection? = nil

    // MARK: - Constants

    /// Threshold for recognizing a swipe
    private let swipeThreshold: CGFloat = 100

    /// Maximum rotation angle (in degrees)
    private let maxRotation: Double = 15

    /// Enum for swipe directions
    enum SwipeDirection {
        case left   // Archive
        case right  // Keep
        case up     // TOP tag
    }

    // MARK: - Computed Properties

    /// Current image pair being displayed
    private var currentPair: ImagePair? {
        guard currentIndex < pairs.count else { return nil }
        return pairs[currentIndex]
    }

    /// Are there any more images left?
    private var hasMoreImages: Bool {
        currentIndex < pairs.count
    }

    /// How many images are remaining?
    private var remainingCount: Int {
        max(0, pairs.count - currentIndex)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Top bar with exit button and counter
                topBar

                Spacer()

                // Card stack area
                if hasMoreImages {
                    cardStackView
                } else {
                    emptyStateView
                }

                Spacer()

                // Bottom area with undo button
                bottomBar
            }
        }
    }

    // MARK: - Top Bar

    /// Top bar with exit button and image counter
    private var topBar: some View {
        HStack {
            Spacer()

            // Image counter
            Text("\(remainingCount) / \(pairs.count)")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())

            Spacer()

            // Exit button
            Button(action: {
                onExit()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            .padding(.trailing, 20)
        }
        .padding(.top, 50)
    }

    // MARK: - Card Stack

    /// Card stack showing current and next images
    private var cardStackView: some View {
        ZStack {
            // Background cards (next 2 images)
            ForEach(1..<min(3, remainingCount), id: \.self) { offset in
                if let pair = getPair(at: currentIndex + offset) {
                    cardView(for: pair, offset: offset)
                        .zIndex(Double(3 - offset))
                }
            }

            // Current card (top of stack)
            if let pair = currentPair {
                cardView(for: pair, offset: 0)
                    .offset(x: dragOffset.width, y: dragOffset.height)
                    .rotationEffect(.degrees(dragRotation))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                handleDragChanged(gesture)
                            }
                            .onEnded { gesture in
                                handleDragEnded(gesture)
                            }
                    )
                    .zIndex(4)
                    .opacity(isRemoving ? 0 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    /// Creates a card view for an image pair
    private func cardView(for pair: ImagePair, offset: Int) -> some View {
        ZStack {
            // Image
            AsyncImage(url: pair.jpegURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    placeholderView(systemImage: "exclamationmark.triangle")
                case .empty:
                    placeholderView(systemImage: "photo")
                @unknown default:
                    placeholderView(systemImage: "photo")
                }
            }

            // Swipe direction indicator (only for current card during drag)
            if offset == 0 && !isRemoving {
                swipeIndicatorOverlay
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
        .scaleEffect(1 - (CGFloat(offset) * 0.05))
        .offset(y: CGFloat(offset) * 10)
        .opacity(1 - (Double(offset) * 0.2))
    }

    /// Placeholder view shown while image is loading or on error
    private func placeholderView(systemImage: String) -> some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    /// Overlay showing swipe direction hints
    private var swipeIndicatorOverlay: some View {
        ZStack {
            // Left swipe (Archive) - Red overlay
            if dragOffset.width < -80 {
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "archivebox.fill")
                                .font(.system(size: 50))
                            Text("ARCHIVE")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-dragRotation))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(40)
                .background(Color.red.opacity(min(0.6, abs(Double(dragOffset.width)) / 200)))
            }

            // Right swipe (Keep) - Green overlay
            if dragOffset.width > 80 {
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                            Text("KEEP")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-dragRotation))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(40)
                .background(Color.green.opacity(min(0.6, Double(dragOffset.width) / 200)))
            }

            // Up swipe (TOP tag) - Yellow overlay
            if dragOffset.height < -80 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 50))
                            Text("TOP")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(40)
                .background(Color.yellow.opacity(min(0.6, abs(Double(dragOffset.height)) / 200)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Empty State

    /// View shown when no more images are left
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Keine Bilder mehr")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Du hast alle Bilder durchgesehen!")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
    }

    // MARK: - Bottom Bar

    /// Bottom bar with undo button
    private var bottomBar: some View {
        HStack {
            Spacer()

            // Undo button
            Button(action: {
                onUndo()
                // Move back one image if possible
                if currentIndex > 0 {
                    withAnimation {
                        currentIndex -= 1
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.title2)
                    Text("Undo")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .clipShape(Capsule())
                .shadow(radius: 4)
            }
            .padding(.trailing, 20)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Gesture Handlers

    /// Handles drag gesture changes (visual feedback during drag)
    private func handleDragChanged(_ gesture: DragGesture.Value) {
        dragOffset = gesture.translation

        // Calculate rotation based on horizontal drag
        // More drag = more rotation (up to maxRotation)
        let rotationAmount = Double(gesture.translation.width) / 20
        dragRotation = min(max(rotationAmount, -maxRotation), maxRotation)
    }

    /// Handles drag gesture end (commit or cancel swipe)
    private func handleDragEnded(_ gesture: DragGesture.Value) {
        let horizontalSwipe = gesture.translation.width
        let verticalSwipe = gesture.translation.height

        // Determine swipe direction based on threshold
        if horizontalSwipe < -swipeThreshold {
            // Left swipe - Archive
            commitSwipe(direction: .left)
        } else if horizontalSwipe > swipeThreshold {
            // Right swipe - Keep
            commitSwipe(direction: .right)
        } else if verticalSwipe < -swipeThreshold {
            // Up swipe - TOP tag
            commitSwipe(direction: .up)
        } else {
            // Swipe not far enough - snap back
            cancelSwipe()
        }
    }

    /// Commits a swipe action (archive, keep, or tag)
    private func commitSwipe(direction: SwipeDirection) {
        guard let pair = currentPair else { return }

        swipeDirection = direction

        // Animate card out
        withAnimation(.easeInOut(duration: 0.3)) {
            isRemoving = true

            // Exaggerate the final offset for exit animation
            switch direction {
            case .left:
                dragOffset.width = -500
            case .right:
                dragOffset.width = 500
            case .up:
                dragOffset.height = -500
            }
        }

        // After animation, execute action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch direction {
            case .left:
                // Archive the image
                Logger.ui.info("Tinder mode: Archiving \(pair.jpegURL.lastPathComponent)")
                onArchive(pair) {
                    // After archive completes, move to next image
                    resetCardState()
                }

            case .right:
                // Keep the image - just move to next
                Logger.ui.info("Tinder mode: Keeping \(pair.jpegURL.lastPathComponent)")
                resetCardState()

            case .up:
                // Toggle TOP tag
                Logger.ui.info("Tinder mode: Tagging \(pair.jpegURL.lastPathComponent)")
                onToggleTag(pair) {
                    // After tag completes, move to next image
                    resetCardState()
                }
            }
        }
    }

    /// Cancels a swipe (snap back to center)
    private func cancelSwipe() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            dragOffset = .zero
            dragRotation = 0
        }
    }

    /// Resets card state after swipe and moves to next image
    private func resetCardState() {
        // Reset visual state
        dragOffset = .zero
        dragRotation = 0
        isRemoving = false
        swipeDirection = nil

        // Move to next image
        currentIndex += 1
    }

    // MARK: - Helper Methods

    /// Gets an image pair at a specific index (safe)
    private func getPair(at index: Int) -> ImagePair? {
        guard index >= 0 && index < pairs.count else { return nil }
        return pairs[index]
    }
}

// MARK: - Previews

#Preview("Tinder Mode - With Images") {
    TinderModeView(
        pairs: [
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: nil,
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: nil,
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: nil,
                hasTopTag: true
            )
        ],
        onExit: { print("Exit Tinder mode") },
        onArchive: { pair, completion in
            print("Archive: \(pair.jpegURL.lastPathComponent)")
            completion()
        },
        onToggleTag: { pair, completion in
            print("Toggle tag: \(pair.jpegURL.lastPathComponent)")
            completion()
        },
        onUndo: { print("Undo") }
    )
}

#Preview("Tinder Mode - Empty") {
    TinderModeView(
        pairs: [],
        onExit: { print("Exit Tinder mode") },
        onArchive: { _, completion in completion() },
        onToggleTag: { _, completion in completion() },
        onUndo: { print("Undo") }
    )
}
