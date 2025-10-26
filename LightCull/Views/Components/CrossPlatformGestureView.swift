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

    init(
        onMagnify: @escaping (CGFloat) -> Void,
        onScrollDelta: @escaping (CGFloat, CGFloat) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onMagnify = onMagnify
        self.onScrollDelta = onScrollDelta
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
            onScrollDelta: onScrollDelta
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

    @State private var lastMagnification: CGFloat = 1.0
    @State private var lastDragTranslation: CGSize = .zero

    var body: some View {
        content
            .gesture(
                // Magnification gesture for pinch-to-zoom
                MagnificationGesture()
                    .onChanged { value in
                        // Calculate the delta from last magnification
                        // This mimics the macOS NSEvent.magnification behavior
                        let delta = value / lastMagnification
                        onMagnify(delta)
                        lastMagnification = value
                    }
                    .onEnded { _ in
                        // Reset for next gesture
                        lastMagnification = 1.0
                    }
            )
            .simultaneousGesture(
                // Drag gesture for panning (works when zoomed)
                DragGesture()
                    .onChanged { value in
                        // Calculate delta from last translation
                        let deltaX = value.translation.width - lastDragTranslation.width
                        let deltaY = value.translation.height - lastDragTranslation.height

                        onScrollDelta(deltaX, deltaY)
                        lastDragTranslation = value.translation
                    }
                    .onEnded { _ in
                        // Reset for next gesture
                        lastDragTranslation = .zero
                    }
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
        }
    ) {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 200, height: 200)
    }
}
