//
//  CrossPlatformGestureView.swift
//  LightCull
//
//  Responsible for: Cross-platform zoom and pan gestures (macOS + iOS)
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

/// Cross-platform gesture view that works on both macOS and iOS
/// - macOS: Uses NSEvent for trackpad gestures
/// - iOS: Uses native SwiftUI gestures (including swipe navigation)
struct CrossPlatformGestureView<Content: View>: View {
    let content: Content
    let onMagnify: (CGFloat) -> Void
    let onScrollDelta: (CGFloat, CGFloat) -> Void
    let onDoubleTap: (() -> Void)?
    let onSwipeLeft: (() -> Void)?   // NEW: Navigation to next image
    let onSwipeRight: (() -> Void)?  // NEW: Navigation to previous image
    let currentZoomScale: CGFloat     // NEW: Current zoom level for swipe detection

    init(
        onMagnify: @escaping (CGFloat) -> Void,
        onScrollDelta: @escaping (CGFloat, CGFloat) -> Void,
        currentZoomScale: CGFloat = 1.0,
        onDoubleTap: (() -> Void)? = nil,
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onMagnify = onMagnify
        self.onScrollDelta = onScrollDelta
        self.currentZoomScale = currentZoomScale
        self.onDoubleTap = onDoubleTap
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
    }

    var body: some View {
        #if os(macOS)
        // macOS: Use NSEvent-based gestures
        ZStack {
            content

            ZoomAndPanGestureView(
                onMagnify: onMagnify,
                onScrollDelta: onScrollDelta
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(true)
        }
        #elseif os(iOS)
        // iOS: Use native SwiftUI gestures (including swipe navigation)
        IOSGestureView(
            content: content,
            onMagnify: onMagnify,
            onScrollDelta: onScrollDelta,
            currentZoomScale: currentZoomScale,
            onDoubleTap: onDoubleTap,
            onSwipeLeft: onSwipeLeft,
            onSwipeRight: onSwipeRight
        )
        #endif
    }
}

// MARK: - iOS Gesture View

#if os(iOS)
/// iOS-specific gesture view using SwiftUI gestures
struct IOSGestureView<Content: View>: View {
    let content: Content
    let onMagnify: (CGFloat) -> Void
    let onScrollDelta: (CGFloat, CGFloat) -> Void
    let currentZoomScale: CGFloat
    let onDoubleTap: (() -> Void)?
    let onSwipeLeft: (() -> Void)?
    let onSwipeRight: (() -> Void)?

    @State private var lastMagnification: CGFloat = 1.0
    @State private var lastDragTranslation: CGSize = .zero

    // Swipe detection thresholds
    private let minSwipeDistance: CGFloat = 50.0  // Minimum horizontal distance for swipe
    private let maxVerticalDeviation: CGFloat = 30.0  // Maximum vertical movement allowed

    var body: some View {
        content
            // WICHTIG: contentShape macht den gesamten Bereich touch-sensitiv
            .contentShape(Rectangle())
            // Doppeltipp zum Zurücksetzen des Zooms (nur auf iOS)
            .onTapGesture(count: 2) {
                #if DEBUG
                print("🔍 iOS Double-Tap - Reset Zoom")
                #endif
                onDoubleTap?()
            }
            .gesture(
                // Magnification gesture for pinch-to-zoom
                // WICHTIG: Wir verwenden .simultaneously statt .gesture, damit
                // sowohl Zoom als auch Pan gleichzeitig funktionieren
                MagnificationGesture(minimumScaleDelta: 0.0)
                    .onChanged { value in
                        // Calculate the delta from last magnification
                        // iOS MagnificationGesture gibt kumulative Werte (1.0, 1.1, 1.2, ...)
                        // handleMagnification() erwartet einen Multiplikator
                        // Also: value=1.1, last=1.0 → delta=1.1/1.0 = 1.1 (10% Zoom)
                        let delta = value / lastMagnification

                        // Debug: Log zum Testen
                        #if DEBUG
                        print("🔍 iOS Magnify - value: \(value), last: \(lastMagnification), delta: \(delta)")
                        #endif

                        onMagnify(delta)
                        lastMagnification = value
                    }
                    .onEnded { _ in
                        // Reset for next gesture
                        #if DEBUG
                        print("🔍 iOS Magnify ended")
                        #endif
                        lastMagnification = 1.0
                    }
                    // WICHTIG: simultaneously erlaubt beide Gesten parallel
                    .simultaneously(with:
                        // Drag gesture: Panning when zoomed OR Swipe navigation at 100% zoom
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Check if we should handle panning or swipe
                                if currentZoomScale > 1.0 {
                                    // PANNING MODE: When zoomed in
                                    let deltaX = value.translation.width - lastDragTranslation.width
                                    let deltaY = value.translation.height - lastDragTranslation.height

                                    #if DEBUG
                                    // Nur loggen wenn wir tatsächlich bewegen
                                    if abs(deltaX) > 1 || abs(deltaY) > 1 {
                                        print("🔍 iOS Drag (Pan) - deltaX: \(deltaX), deltaY: \(deltaY)")
                                    }
                                    #endif

                                    onScrollDelta(deltaX, deltaY)
                                    lastDragTranslation = value.translation
                                } else {
                                    // SWIPE MODE: At 100% zoom, track translation for swipe detection
                                    // (actual swipe detection happens in onEnded)
                                    lastDragTranslation = value.translation
                                }
                            }
                            .onEnded { value in
                                // Check if we should handle swipe navigation
                                if currentZoomScale == 1.0 {
                                    // SWIPE DETECTION: Only at 100% zoom
                                    let horizontalDistance = value.translation.width
                                    let verticalDistance = abs(value.translation.height)

                                    #if DEBUG
                                    print("🔍 iOS Drag ended - horizontal: \(horizontalDistance), vertical: \(verticalDistance), zoom: \(currentZoomScale)")
                                    #endif

                                    // Check if this was a valid swipe:
                                    // 1. Enough horizontal movement
                                    // 2. Not too much vertical movement
                                    if abs(horizontalDistance) >= minSwipeDistance && verticalDistance <= maxVerticalDeviation {
                                        if horizontalDistance > 0 {
                                            // Swipe RIGHT → Previous image
                                            #if DEBUG
                                            print("🔍 iOS Swipe RIGHT detected")
                                            #endif
                                            onSwipeRight?()
                                        } else {
                                            // Swipe LEFT → Next image
                                            #if DEBUG
                                            print("🔍 iOS Swipe LEFT detected")
                                            #endif
                                            onSwipeLeft?()
                                        }
                                    }
                                } else {
                                    // PANNING ended
                                    #if DEBUG
                                    print("🔍 iOS Drag (Pan) ended")
                                    #endif
                                }

                                // Reset for next gesture
                                lastDragTranslation = .zero
                            }
                    )
            )
    }
}
#endif

#Preview("CrossPlatformGestureView") {
    CrossPlatformGestureView(
        onMagnify: { multiplier in
            print("Magnify: \(multiplier)")
        },
        onScrollDelta: { deltaX, deltaY in
            print("Scroll: \(deltaX), \(deltaY)")
        },
        currentZoomScale: 1.0,
        onDoubleTap: {
            print("Double-Tap: Reset Zoom")
        },
        onSwipeLeft: {
            print("Swipe LEFT: Next Image")
        },
        onSwipeRight: {
            print("Swipe RIGHT: Previous Image")
        }
    ) {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 200, height: 200)
    }
}
