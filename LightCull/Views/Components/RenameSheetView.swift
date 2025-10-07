//
//  RenameSheetView.swift
//  LightCull
//
//  Responsible for: Overlay dialog for renaming images with prefix
//

import SwiftUI

struct RenameSheetView: View {
    // The selected image pairs to be renamed
    let selectedPairs: [ImagePair]

    // Callback that is called when Rename is clicked
    let onRename: (String) -> Void

    // Callback that is called when Cancel is clicked
    let onCancel: () -> Void

    // The prefix that the user enters
    @State private var prefix: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // Title
            headerView

            // Info text
            infoView

            // Text field for prefix input
            prefixInputView

            // Preview of the renaming
            previewView

            // Buttons
            buttonView
        }
        .padding(24)
        .frame(width: 500)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Header

    /// Displays the dialog title
    private var headerView: some View {
        Text("Bilder umbenennen")
            .font(.title2)
            .fontWeight(.semibold)
    }

    // MARK: - Info

    /// Displays info text with the number of selected images
    private var infoView: some View {
        Text("\(selectedPairs.count) Bild(er) ausgewählt")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    // MARK: - Präfix-Eingabe

    /// Text field for entering the prefix
    private var prefixInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Präfix:")
                .font(.headline)

            TextField("z.B. Standesamt", text: $prefix)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Preview

    /// Displays a preview of the renaming
    private var previewView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vorschau:")
                .font(.headline)

            // Scrollable list with preview
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    // We show a maximum of 5 examples
                    ForEach(getPreviewItems(), id: \.oldName) { item in
                        previewItem(oldName: item.oldName, newName: item.newName)
                    }

                    // If more than 5 images are selected, we show "..."
                    if selectedPairs.count > 5 {
                        Text("... und \(selectedPairs.count - 5) weitere")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
            .frame(maxHeight: 150)
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    /// Displays a single line of the preview
    private func previewItem(oldName: String, newName: String) -> some View {
        HStack(spacing: 8) {
            // Old
            Text(oldName)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Arrow
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)

            // New
            Text(newName)
                .font(.caption)
                .foregroundStyle(.primary)
                .fontWeight(.medium)
        }
    }

    // MARK: - Buttons

    /// Displays the Cancel and Rename buttons
    private var buttonView: some View {
        HStack(spacing: 12) {
            // Cancel button
            Button(action: handleCancel) {
                Text("Abbrechen")
                    .frame(maxWidth: .infinity)
            }
            .keyboardShortcut(.escape, modifiers: [])

            // Rename button
            Button(action: handleRename) {
                Text("Umbenennen")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(prefix.isEmpty)  // Disabled when no prefix is entered
            .keyboardShortcut(.return, modifiers: [])
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Methods

    /// Returns a list of preview items (maximum 5)
    private func getPreviewItems() -> [(oldName: String, newName: String)] {
        // How many pairs should we show in the preview?
        let numberOfItemsToShow: Int = min(selectedPairs.count, 5)

        // Array for the preview items
        var items: [(oldName: String, newName: String)] = []

        // Go through the first 5 pairs
        for i in 0..<numberOfItemsToShow {
            let pair: ImagePair = selectedPairs[i]

            // Get old name
            let oldName: String = pair.jpegURL.lastPathComponent

            // Calculate new name
            let newName: String
            if prefix.isEmpty {
                newName = oldName
            } else {
                newName = "\(prefix)_\(oldName)"
            }

            // Add to array
            items.append((oldName: oldName, newName: newName))
        }

        return items
    }

    // MARK: - Actions

    /// Called when the Cancel button is clicked
    private func handleCancel() {
        onCancel()
    }

    /// Called when the Rename button is clicked
    private func handleRename() {
        // Ensure that the prefix is not empty
        if prefix.isEmpty {
            return
        }

        // Call callback with the entered prefix
        onRename(prefix)
    }
}

// MARK: - Previews

#Preview("RenameSheetView - 1 Image") {
    RenameSheetView(
        selectedPairs: [
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/DSCF0100.JPG"),
                rawURL: URL(fileURLWithPath: "/mock/DSCF0100.RAF"),
                hasTopTag: false
            )
        ],
        onRename: { _ in },
        onCancel: { }
    )
}

#Preview("RenameSheetView - Multiple Images") {
    RenameSheetView(
        selectedPairs: [
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/DSCF0100.JPG"),
                rawURL: URL(fileURLWithPath: "/mock/DSCF0100.RAF"),
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/DSCF0101.JPG"),
                rawURL: URL(fileURLWithPath: "/mock/DSCF0101.RAF"),
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/DSCF0102.JPG"),
                rawURL: nil,
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/DSCF0103.JPG"),
                rawURL: URL(fileURLWithPath: "/mock/DSCF0103.RAF"),
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/DSCF0104.JPG"),
                rawURL: URL(fileURLWithPath: "/mock/DSCF0104.RAF"),
                hasTopTag: false
            ),
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/DSCF0105.JPG"),
                rawURL: URL(fileURLWithPath: "/mock/DSCF0105.RAF"),
                hasTopTag: false
            )
        ],
        onRename: { _ in },
        onCancel: { }
    )
}
