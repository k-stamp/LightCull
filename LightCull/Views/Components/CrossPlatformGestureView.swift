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
/// - iOS: Uses native SwiftUI gestures
struct CrossPlatformGestureView<Content: View>: View {
    let content: Content
    let onMagnify: (CGFloat) -> Void
    let onScrollDelta: (CGFloat, CGFloat) -> Void
    let onDoubleTap: (() -> Void)?

    init(
        onMagnify: @escaping (CGFloat) -> Void,
        onScrollDelta: @escaping (CGFloat, CGFloat) -> Void,
        onDoubleTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onMagnify = onMagnify
        self.onScrollDelta = onScrollDelta
        self.onDoubleTap = onDoubleTap
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
        // iOS: Use native SwiftUI gestures
        IOSGestureView(
            content: content,
            onMagnify: onMagnify,
            onScrollDelta: onScrollDelta,
            onDoubleTap: onDoubleTap
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
    let onDoubleTap: (() -> Void)?

    @State private var lastMagnification: CGFloat = 1.0
    @State private var lastDragTranslation: CGSize = .zero

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
                        // Drag gesture for panning (works when zoomed)
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Calculate delta from last translation
                                let deltaX = value.translation.width - lastDragTranslation.width
                                let deltaY = value.translation.height - lastDragTranslation.height

                                #if DEBUG
                                // Nur loggen wenn wir tatsächlich bewegen
                                if abs(deltaX) > 1 || abs(deltaY) > 1 {
                                    print("🔍 iOS Drag - deltaX: \(deltaX), deltaY: \(deltaY)")
                                }
                                #endif

                                onScrollDelta(deltaX, deltaY)
                                lastDragTranslation = value.translation
                            }
                            .onEnded { _ in
                                // Reset for next gesture
                                #if DEBUG
                                print("🔍 iOS Drag ended")
                                #endif
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
        onDoubleTap: {
            print("Double-Tap: Reset Zoom")
        }
    ) {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 200, height: 200)
    }
}
