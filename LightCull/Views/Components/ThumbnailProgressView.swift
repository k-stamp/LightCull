//
//  ThumbnailProgressView.swift
//  LightCull
//
//  Responsible for: Showing progress during thumbnail generation
//

import SwiftUI

struct ThumbnailProgressView: View {
    let currentCount: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Thumbnails werden erstellt...")
                .font(.headline)

            // Progress information
            Text("\(currentCount) von \(totalCount)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Progress bar
            ProgressView(value: Double(currentCount), total: Double(totalCount))
                .progressViewStyle(.linear)
                .frame(width: 300)

            // Percentage display
            Text("\(progressPercentage)%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(width: 400)
    }

    // MARK: - Computed Properties

    /// Calculates the progress as a percentage
    private var progressPercentage: Int {
        // Avoid division by zero
        if totalCount == 0 {
            return 0
        }

        // Calculate percentage
        let percentage: Double = Double(currentCount) / Double(totalCount) * 100.0
        return Int(percentage)
    }
}

// MARK: - Previews

#Preview("ThumbnailProgressView - Start") {
    ThumbnailProgressView(currentCount: 1, totalCount: 100)
}

#Preview("ThumbnailProgressView - Middle") {
    ThumbnailProgressView(currentCount: 50, totalCount: 100)
}

#Preview("ThumbnailProgressView - Almost Done") {
    ThumbnailProgressView(currentCount: 95, totalCount: 100)
}
