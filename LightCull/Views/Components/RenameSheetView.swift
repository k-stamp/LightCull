//
//  RenameSheetView.swift
//  LightCull
//
//  Verantwortlich für: Overlay-Dialog zum Umbenennen von Bildern mit Präfix
//

import SwiftUI

struct RenameSheetView: View {
    // Die ausgewählten Bildpaare, die umbenannt werden sollen
    let selectedPairs: [ImagePair]

    // Callback, der aufgerufen wird, wenn Umbenennen geklickt wird
    let onRename: (String) -> Void

    // Callback, der aufgerufen wird, wenn Abbrechen geklickt wird
    let onCancel: () -> Void

    // Der Präfix, den der User eingibt
    @State private var prefix: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // Titel
            headerView

            // Info-Text
            infoView

            // Textfeld für Präfix-Eingabe
            prefixInputView

            // Preview der Umbenennung
            previewView

            // Buttons
            buttonView
        }
        .padding(24)
        .frame(width: 500)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Header

    /// Zeigt den Titel des Dialogs
    private var headerView: some View {
        Text("Bilder umbenennen")
            .font(.title2)
            .fontWeight(.semibold)
    }

    // MARK: - Info

    /// Zeigt Info-Text mit Anzahl der ausgewählten Bilder
    private var infoView: some View {
        Text("\(selectedPairs.count) Bild(er) ausgewählt")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    // MARK: - Präfix-Eingabe

    /// Textfeld für die Eingabe des Präfix
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

    /// Zeigt eine Vorschau der Umbenennung
    private var previewView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vorschau:")
                .font(.headline)

            // Scrollbare Liste mit Vorschau
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    // Wir zeigen maximal 5 Beispiele
                    ForEach(getPreviewItems(), id: \.oldName) { item in
                        previewItem(oldName: item.oldName, newName: item.newName)
                    }

                    // Falls mehr als 5 Bilder ausgewählt sind, zeigen wir "..."
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

    /// Zeigt eine einzelne Zeile der Vorschau
    private func previewItem(oldName: String, newName: String) -> some View {
        HStack(spacing: 8) {
            // Alt
            Text(oldName)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Pfeil
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Neu
            Text(newName)
                .font(.caption)
                .foregroundStyle(.primary)
                .fontWeight(.medium)
        }
    }

    // MARK: - Buttons

    /// Zeigt die Abbrechen- und Umbenennen-Buttons
    private var buttonView: some View {
        HStack(spacing: 12) {
            // Abbrechen-Button
            Button(action: handleCancel) {
                Text("Abbrechen")
                    .frame(maxWidth: .infinity)
            }
            .keyboardShortcut(.escape, modifiers: [])

            // Umbenennen-Button
            Button(action: handleRename) {
                Text("Umbenennen")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(prefix.isEmpty)  // Deaktiviert wenn kein Präfix eingegeben
            .keyboardShortcut(.return, modifiers: [])
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Methods

    /// Gibt eine Liste von Vorschau-Items zurück (maximal 5)
    private func getPreviewItems() -> [(oldName: String, newName: String)] {
        // Wie viele Pairs sollen wir in der Preview zeigen?
        let numberOfItemsToShow: Int = min(selectedPairs.count, 5)

        // Array für die Preview-Items
        var items: [(oldName: String, newName: String)] = []

        // Die ersten 5 Pairs durchgehen
        for i in 0..<numberOfItemsToShow {
            let pair: ImagePair = selectedPairs[i]

            // Alten Namen holen
            let oldName: String = pair.jpegURL.lastPathComponent

            // Neuen Namen berechnen
            let newName: String
            if prefix.isEmpty {
                newName = oldName
            } else {
                newName = "\(prefix)_\(oldName)"
            }

            // Zum Array hinzufügen
            items.append((oldName: oldName, newName: newName))
        }

        return items
    }

    // MARK: - Actions

    /// Wird aufgerufen, wenn der Abbrechen-Button geklickt wird
    private func handleCancel() {
        onCancel()
    }

    /// Wird aufgerufen, wenn der Umbenennen-Button geklickt wird
    private func handleRename() {
        // Sicherstellen, dass der Präfix nicht leer ist
        if prefix.isEmpty {
            return
        }

        // Callback aufrufen mit dem eingegebenen Präfix
        onRename(prefix)
    }
}

// MARK: - Previews

#Preview("RenameSheetView - 1 Bild") {
    RenameSheetView(
        selectedPairs: [
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/mock/DSCF0100.JPG"),
                rawURL: URL(fileURLWithPath: "/mock/DSCF0100.RAF"),
                hasTopTag: false
            )
        ],
        onRename: { prefix in
            print("Umbenennen mit Präfix: \(prefix)")
        },
        onCancel: {
            print("Abbrechen")
        }
    )
}

#Preview("RenameSheetView - Mehrere Bilder") {
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
        onRename: { prefix in
            print("Umbenennen mit Präfix: \(prefix)")
        },
        onCancel: {
            print("Abbrechen")
        }
    )
}
