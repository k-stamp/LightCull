//
//  ThumbnailBarView.swift
//  LightCull
//
//  Verantwortlich für: Thumbnail-Leiste mit Navigation
//

import SwiftUI

struct ThumbnailBarView: View {
    let pairs: [ImagePair]
    @Binding var selectedPair: ImagePair?
    
    var body: some View {
        VStack {
            if pairs.isEmpty {
                emptyStateView
            } else {
                thumbnailContentView
            }
        }
        .frame(height: 150) // Feste Höhe für Thumbnail-Bereich
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Thumbnail-Leiste")
                    .font(.headline)
                    .padding(.leading)
            }
            
            Text("Keine Bilder verfügbar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        }
    }
    
    // MARK: - Thumbnail Content
    private var thumbnailContentView: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            thumbnailScrollView
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Thumbnail-Leiste")
                .font(.headline)
                .padding(.leading)
            
            Spacer()
            
            Text("\(pairs.count) Bildpaare")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.trailing)
        }
    }
    
    // MARK: - Thumbnail ScrollView
    private var thumbnailScrollView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            LazyHStack(spacing: 12) {
                ForEach(pairs) { pair in
                    thumbnailItem(for: pair)
                        .onTapGesture {
                            selectedPair = pair
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Thumbnail Item
    private func thumbnailItem(for pair: ImagePair) -> some View {
        VStack(spacing: 6) {
            AsyncImage(url: pair.jpegURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color(.quaternaryLabelColor))
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
            }
            .frame(maxWidth: 100, maxHeight: 100)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        selectedPair?.id == pair.id ? Color.accentColor : Color(.separatorColor),
                        lineWidth: selectedPair?.id == pair.id ? 2 : 0.5
                    )
            }
            
            // Dateiname ohne Extension
            Text(pair.jpegURL.deletingPathExtension().lastPathComponent)
                .font(.caption2)
                .lineLimit(1)
                .frame(maxWidth: 100)
            
            // RAW Status
            Text(pair.rawURL != nil ? "RAW✅" : "RAW🚫")
                .font(.caption2)
        }
        .frame(maxWidth: 110)
    }
}

#Preview("ThumbnailBarView - Empty") {
    ThumbnailBarView(
        pairs: [],
        selectedPair: .constant(nil)
    )
}

#Preview("ThumbnailBarView - With Data") {
    ThumbnailBarView(
        pairs: [
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2"),
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: nil,
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: URL(fileURLWithPath: "/mock/image3.arw"),
                hasTopTag: false
            )
        ],
        selectedPair: .constant(nil)
    )
}
