//
//  SidebarView.swift
//  LightCull
//
//  Verantwortlich für: Ordnerauswahl und Info-Anzeige
//

import SwiftUI

struct SidebarView: View {
    @Binding var folderURL: URL?
    @Binding var pairs: [ImagePair]
    
    let onFolderSelected: (URL) -> Void
    
    private let fileService = FileService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("LightCull")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Divider()
            
            folderSelectionSection
            
            Divider()
            
            infoSection
            
            Spacer()
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
    }
    
    // MARK: - Folder Selection Section
    private var folderSelectionSection: some View {
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
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
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
    }
    
    // MARK: - Helper Methods
    
    /// Öffnet den macOS Dialog zur Ordnerwahl
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            folderURL = url
            pairs = fileService.findImagePairs(in: url)
            onFolderSelected(url)
        }
    }
}

#Preview("SidebarView - Empty") {
    SidebarView(
        folderURL: .constant(nil),
        pairs: .constant([]),
        onFolderSelected: { _ in }
    )
}

#Preview("SidebarView - With Data") {
    SidebarView(
        folderURL: .constant(URL(fileURLWithPath: "/Users/Mock/Pictures")),
        pairs: .constant([
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/image1.jpg"),
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2")
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/image2.jpg"),
                rawURL: nil
            )
        ]),
        onFolderSelected: { _ in }
    )
}
