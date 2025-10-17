//
//  SplitViewContainer.swift
//  LightCull
//
//  Responsible for: Split view mode - displays two images side-by-side for comparison
//

import SwiftUI

struct SplitViewContainer: View {
    // Left image (reference, fixed)
    let leftImagePair: ImagePair?

    // Right image (comparison, changeable)
    let rightImagePair: ImagePair?

    // Shared ViewModel for synchronized zoom/pan
    @ObservedObject var viewModel: ImageViewModel

    // Navigation callbacks (only for right image)
    let onPreviousRightImage: () -> Void
    let onNextRightImage: () -> Void

    // Action callbacks (only for right image)
    let onToggleTag: () -> Void
    let onDeleteImage: () -> Void
    let onArchiveImage: () -> Void
    let onOuttakeImage: () -> Void

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // LEFT SIDE: Reference image (fixed, no interactions)
                ZStack(alignment: .topLeading) {
                    ImageViewerView(
                        selectedImagePair: leftImagePair,
                        viewModel: viewModel,
                        onPreviousImage: { },  // Disabled
                        onNextImage: { },      // Disabled
                        onToggleTag: { },      // Disabled
                        onDeleteImage: { },    // Disabled
                        onArchiveImage: { },   // Disabled
                        onOuttakeImage: { },   // Disabled
                        disableKeyboardShortcuts: true  // No keyboard shortcuts on left
                    )

                    // Label for left side
                    Text("Referenz")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.8))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(8)
                }
                .frame(width: geometry.size.width / 2)

                // DIVIDER: Visual separation
                Divider()
                    .frame(width: 2)
                    .background(Color.gray.opacity(0.5))

                // RIGHT SIDE: Comparison image (navigable, with actions)
                ZStack(alignment: .topLeading) {
                    ImageViewerView(
                        selectedImagePair: rightImagePair,
                        viewModel: viewModel,  // Same ViewModel = synchronized zoom/pan!
                        onPreviousImage: onPreviousRightImage,
                        onNextImage: onNextRightImage,
                        onToggleTag: onToggleTag,
                        onDeleteImage: onDeleteImage,
                        onArchiveImage: onArchiveImage,
                        onOuttakeImage: onOuttakeImage,
                        disableKeyboardShortcuts: false  // Keyboard shortcuts enabled on right
                    )

                    // Label for right side
                    Text("Vergleich")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.8))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(8)
                }
                .frame(width: geometry.size.width / 2)
            }
        }
    }
}

// MARK: - Previews

#Preview("SplitViewContainer - With Images") {
    SplitViewContainer(
        leftImagePair: ImagePair(
            jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
            rawURL: nil,
            hasTopTag: false
        ),
        rightImagePair: ImagePair(
            jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
            rawURL: nil,
            hasTopTag: true
        ),
        viewModel: ImageViewModel(),
        onPreviousRightImage: {},
        onNextRightImage: {},
        onToggleTag: {},
        onDeleteImage: {},
        onArchiveImage: {},
        onOuttakeImage: {}
    )
    .frame(width: 1200, height: 800)
}
