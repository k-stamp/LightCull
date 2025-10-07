//
//  SidebarView.swift
//  LightCull
//
//  Responsible for: Folder selection and info display
//

import SwiftUI

struct SidebarView: View {
    @Binding var folderURL: URL?
    @Binding var pairs: [ImagePair]
    
    // NEW: Metadata of the currently selected image
    let currentMetadata: ImageMetadata?
    
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
            
            Divider()
            
            metadataSection
            
            Spacer()
        }
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
    }
    
    // MARK: - Folder Selection Section
    private var folderSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Folder")
                .font(.headline)
                .padding(.horizontal)

            Button("Select Folder") {
                selectFolder()
            }
            .padding(.horizontal)
            
            if let folderURL {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Folder:")
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
                Text("No image pairs found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                Text("Pairs: \(pairs.count)")
                    .font(.subheadline)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Metadata Section (NEW!)

    /// Displays the metadata of the currently selected image
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image Information")
                .font(.headline)
                .padding(.horizontal)

            // If metadata is available, display it
            if let metadata = currentMetadata {
                VStack(alignment: .leading, spacing: 8) {
                    // Filename
                    metadataRow(label: "File", value: metadata.fileName)

                    // File size
                    metadataRow(label: "Size", value: metadata.fileSize)

                    // If EXIF data is available, show divider
                    if hasAnyExifData(metadata) {
                        Divider()
                            .padding(.horizontal)
                    }
                    
                    // Camera information (only if available)
                    if let make = metadata.cameraMake {
                        metadataRow(label: "Make", value: make)
                    }

                    if let model = metadata.cameraModel {
                        metadataRow(label: "Model", value: model)
                    }

                    // Capture parameters (only if available)
                    if let focalLength = metadata.focalLength {
                        metadataRow(label: "Focal Length", value: focalLength)
                    }

                    if let aperture = metadata.aperture {
                        metadataRow(label: "Aperture", value: aperture)
                    }

                    if let shutterSpeed = metadata.shutterSpeed {
                        metadataRow(label: "Exposure", value: shutterSpeed)
                    }
                }
            } else {
                // If no metadata is available, show placeholder
                Text("No image selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    /// Helper function: Creates a row with label and value
    /// This is the typical "Key: Value" pattern you know from Finder
    private func metadataRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled) // Enables copying the value
        }
        .padding(.horizontal)
    }
    
    /// Checks if any EXIF data is available
    /// Useful to decide if we should show a divider
    private func hasAnyExifData(_ metadata: ImageMetadata) -> Bool {
        return metadata.cameraMake != nil ||
               metadata.cameraModel != nil ||
               metadata.focalLength != nil ||
               metadata.aperture != nil ||
               metadata.shutterSpeed != nil
    }
    
    // MARK: - Helper Methods

    /// Opens the macOS dialog for folder selection
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            folderURL = url

            // NEW: MainView will now handle BOTH security access AND loading pairs
            // This prevents blocking the main thread
            onFolderSelected(url)
        }
    }
}

// MARK: - Previews

#Preview("SidebarView - Empty") {
    SidebarView(
        folderURL: .constant(nil),
        pairs: .constant([]),
        currentMetadata: nil,
        onFolderSelected: { _ in }
    )
}

#Preview("SidebarView - With Data") {
    SidebarView(
        folderURL: .constant(URL(fileURLWithPath: "/Users/Mock/Pictures")),
        pairs: .constant([
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/image1.jpg"),
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2"),
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/image2.jpg"),
                rawURL: nil,
                hasTopTag: false
            )
        ]),
        currentMetadata: nil,
        onFolderSelected: { _ in }
    )
}

#Preview("SidebarView - With Metadata") {
    SidebarView(
        folderURL: .constant(URL(fileURLWithPath: "/Users/Mock/Pictures")),
        pairs: .constant([
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/image1.jpg"),
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2"),
                hasTopTag: false
            )
        ]),
        currentMetadata: ImageMetadata(
            fileName: "DSCF0100.JPG",
            fileSize: "2.5 MB",
            cameraMake: "FUJIFILM",
            cameraModel: "X-T5",
            focalLength: "35.0 mm",
            aperture: "f/2.8",
            shutterSpeed: "1/250s"
        ),
        onFolderSelected: { _ in }
    )
}
