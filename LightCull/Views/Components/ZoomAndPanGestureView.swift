//
//  ZoomAndPanGestureView.swift
//  LightCull
//
//  Responsible for: Native macOS trackpad gestures for both zooming and panning
//

import SwiftUI
import AppKit

/// NSViewRepresentable that captures both zoom (magnify) and pan (scroll) gestures
/// This combines both gestures in a single native view to avoid gesture conflicts
struct ZoomAndPanGestureView: NSViewRepresentable {

    // Callback that fires during zoom gestures
    var onMagnify: (CGFloat) -> Void

    // Callback that fires during scroll (continuous updates for panning)
    var onScrollDelta: (CGFloat, CGFloat) -> Void

    // MARK: - NSViewRepresentable Implementation

    func makeNSView(context: Context) -> GestureHandlingView {
        let view = GestureHandlingView()
        view.onMagnify = onMagnify
        view.onScrollDelta = onScrollDelta
        return view
    }

    func updateNSView(_ nsView: GestureHandlingView, context: Context) {
        // Update callbacks if they change
        nsView.onMagnify = onMagnify
        nsView.onScrollDelta = onScrollDelta
    }

    // MARK: - Custom NSView for Gesture Events

    /// Custom NSView that captures both magnify and scrollWheel events
    class GestureHandlingView: NSView {
        var onMagnify: ((CGFloat) -> Void)?
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

        /// Override magnify to capture two-finger pinch-to-zoom gestures
        override func magnify(with event: NSEvent) {
            // Get magnification delta from the event
            // This is the change in magnification (1.0 = no change, >1.0 = zoom in, <1.0 = zoom out)
            let magnification = event.magnification

            // Nur verarbeiten wenn es echte Magnification gibt
            guard magnification != 0 else { return }

            // Convert delta to multiplier (add 1.0 because delta can be negative)
            // magnification = 0.1 → multiplier = 1.1 (10% increase)
            // magnification = -0.1 → multiplier = 0.9 (10% decrease)
            let multiplier = 1.0 + magnification

            onMagnify?(multiplier)
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
