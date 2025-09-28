//
//  ContentView.swift
//  LightCull
//
//  Created by Kevin Stamp on 23.09.25.
//

import SwiftUI

struct MainView: View {
    @State private var pairs: [ImagePair] = []  // Ergebnisliste
    @State private var folderURL: URL?  // Merkt sich den gewählten Ordner
    
    private let fileService = FileService() // unser Service
    
    init(pairs: [ImagePair] = [], folderURL: URL? = nil) {
        _pairs = State(initialValue: pairs)
        _folderURL = State(initialValue: folderURL)
    }
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR (links)
            sidebarContent
        } detail: {
            // CONTENT AREA (rechts) - hier kommt später Bild oben + Thumbnails unten
            contentArea
        }
    }
    
    // MARK: Sidebar Content
    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("LightCull")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Ordner")
                    .font(.headline)
                    .padding(.horizontal)
                
                Button("Ordner auswählen") {
                    selectFolder()
                }
                .padding(.horizontal)
                
                if let folderURL {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gewählter Ordner:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(folderURL.lastPathComponent)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    .padding(.horizontal)
                }
            }
            
            Divider()
            
            // Info-Bereich
            VStack(alignment: .leading, spacing: 8) {
                Text("Info")
                    .font(.headline)
                    .padding(.horizontal)
                
                if pairs.isEmpty {
                    Text("Keine Bildpaare gefunden")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                } else {
                    Text("Paare: \(pairs.count)")
                        .font(.subheadline)
                        .padding(.horizontal)
                }
            }
            
            
            Spacer()
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
    }
    
    
    // MARK: Content Area
    private var contentArea: some View {
        VStack(spacing: 0) {
            mainImageArea
            thmubnailArea
        }
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: Main Image Area
    private var mainImageArea: some View {
        VStack {
            Text("Bildvorschau")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: Thmubnail Area (Placeholder)
    private var thmubnailArea: some View {
        VStack {
            if pairs.isEmpty {
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
            } else {
                VStack(alignment: .leading, spacing: 8) {
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
                    
                    thumbnailScrollView
                }
            }
        }
        .frame(height: 150) // Feste Höhe für Thumbnail-Bereich
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: Thumbnail ScrollView
    private var thumbnailScrollView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            LazyHStack(spacing: 12) {
                ForEach(pairs) { pair in
                    thumbnailItem(for: pair)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: Thumbnail Item (mit korrektem Aspect Ratio)
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
                    .stroke(Color(.separatorColor), lineWidth: 0.5)
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
    
    
    // MARK: Helper Methods
    
    // Öffnet den macOS Dialog zur Ordnerwahl
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            folderURL = url
            pairs = fileService.findImagePairs(in: url)
        }
    }
}

#Preview("MainView – Mock Data") {
    MainView(
        pairs: [
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2")
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: nil
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: URL(fileURLWithPath: "/mock/image3.arw")
            )
        ],
        folderURL: URL(fileURLWithPath: "/Users/Mock/Pictures")
    )
    .frame(minWidth: 900, minHeight: 600)
}
