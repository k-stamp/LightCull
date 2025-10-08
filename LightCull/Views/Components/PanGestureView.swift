//
//  PanGestureView.swift
//  LightCull
//
//  Responsible for: Native macOS two-finger scroll gesture for panning zoomed images
//

import SwiftUI
import AppKit

/// NSViewRepresentable that captures two-finger scroll gestures from trackpad
/// This uses native scrollWheel events for smooth, natural panning
struct PanGestureView: NSViewRepresentable {

    // Callback that fires during scroll (continuous updates)
    var onScrollDelta: (CGFloat, CGFloat) -> Void

    // MARK: - NSViewRepresentable Implementation

    func makeNSView(context: Context) -> ScrollableView {
        let view = ScrollableView()
        view.onScrollDelta = onScrollDelta
        return view
    }

    func updateNSView(_ nsView: ScrollableView, context: Context) {
        // Update callback if it changes
        nsView.onScrollDelta = onScrollDelta
    }

    // MARK: - Custom NSView for ScrollWheel Events

    /// Custom NSView that captures scrollWheel events for panning
    class ScrollableView: NSView {
        var onScrollDelta: ((CGFloat, CGFloat) -> Void)?

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupView()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupView()
        }

        private func setupView() {
            // Enable layer backing for better performance
            wantsLayer = true
        }

        /// Override scrollWheel to capture two-finger scroll gestures
        override func scrollWheel(with event: NSEvent) {
            // Get scroll deltas from the event
            // deltaX: horizontal scroll (left/right)
            // deltaY: vertical scroll (up/down)
            let deltaX = event.scrollingDeltaX
            let deltaY = event.scrollingDeltaY

            // Nur verarbeiten wenn es echte Deltas gibt
            guard deltaX != 0 || deltaY != 0 else { return }

            // Deltas direkt verwenden (ohne Invertierung)
            // macOS scrollWheel liefert die richtigen Werte:
            // - Nach oben wischen (fingers up) = positive deltaY = Bild bewegt sich nach oben
            // - Nach unten wischen (fingers down) = negative deltaY = Bild bewegt sich nach unten
            onScrollDelta?(deltaX, deltaY)
        }

        /// Accept first responder to receive events
        override var acceptsFirstResponder: Bool {
            return true
        }
    }
}
