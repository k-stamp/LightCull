//
//  ImageViewerView.swift
//  LightCull
//
//  Verantwortlich für: Hauptbildanzeige mit Zoom und Navigation
//

import SwiftUI

struct ImageViewerView: View {
    let selectedImagePair: ImagePair?
    
    var body: some View {
        VStack {
            if let selectedImagePair {
                // Hier wird später die eigentliche Bildanzeige implementiert
                Text("Bildvorschau für:")
                    .font(.title)
                    .foregroundStyle(.secondary)
                
                Text(selectedImagePair.jpegURL.lastPathComponent)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            } else {
                Text("Bildvorschau")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview("ImageViewerView - Empty") {
    ImageViewerView(selectedImagePair: nil)
}

#Preview("ImageViewerView - With Image") {
    ImageViewerView(
        selectedImagePair: ImagePair(
            jpegURL: URL(fileURLWithPath: "/mock/image1.jpg"),
            rawURL: URL(fileURLWithPath: "/mock/image1.cr2")
        )
    )
}
