//
//  FolderMonitor.swift
//  LightCull
//
//  Created by Claude Code on 28.10.2025.
//

import Foundation

/// Überwacht einen Ordner auf Dateisystem-Änderungen und benachrichtigt über externe Modifikationen
/// Nutzt DispatchSource für effizientes, low-level File System Event Monitoring
class FolderMonitor {
    // MARK: - Properties

    /// Dispatch Source für File System Events
    private var source: DispatchSourceFileSystemObject?

    /// File Descriptor des überwachten Ordners
    private var fileDescriptor: Int32 = -1

    /// Timer für Debouncing von rapid-fire Events
    private var debounceTimer: DispatchWorkItem?

    /// Wartezeit nach letztem Event bevor onChange aufgerufen wird (verhindert multiple Scans)
    private let debounceDelay: TimeInterval = 0.5

    /// Callback der bei Dateisystem-Änderungen aufgerufen wird
    private var onChange: (() -> Void)?

    // MARK: - Public Methods

    /// Startet das Monitoring eines Ordners
    /// - Parameters:
    ///   - url: URL des zu überwachenden Ordners
    ///   - onChange: Callback der bei erkannten Änderungen aufgerufen wird
    func startMonitoring(url: URL, onChange: @escaping () -> Void) {
        // Stoppe existierendes Monitoring falls vorhanden
        stopMonitoring()

        // Speichere Callback
        self.onChange = onChange

        // Öffne File Descriptor für den Ordner (O_EVTONLY = read-only monitoring)
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("FolderMonitor: Konnte File Descriptor für \(url.path) nicht öffnen")
            return
        }

        // Erstelle Dispatch Source für File System Events
        // Überwacht: WRITE (Dateien hinzugefügt), DELETE (gelöscht), EXTEND (geändert)
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .extend],
            queue: DispatchQueue.main
        )

        // Event Handler: wird bei jeder Dateisystem-Änderung aufgerufen
        source?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }

        // Cancel Handler: Cleanup wenn Source gestoppt wird
        source?.setCancelHandler { [weak self] in
            guard let fd = self?.fileDescriptor, fd >= 0 else { return }
            close(fd)
            self?.fileDescriptor = -1
        }

        // Aktiviere den Monitor
        source?.resume()

        print("FolderMonitor: Monitoring gestartet für \(url.lastPathComponent)")
    }

    /// Stoppt das Monitoring
    func stopMonitoring() {
        // Cancele ausstehende Debounce-Timer
        debounceTimer?.cancel()
        debounceTimer = nil

        // Stoppe und cleanup Dispatch Source
        source?.cancel()
        source = nil

        onChange = nil
    }

    // MARK: - Private Methods

    /// Behandelt File System Events mit Debouncing
    private func handleFileSystemEvent() {
        // Cancele vorherigen Timer (resettet Debounce-Wartezeit)
        debounceTimer?.cancel()

        // Erstelle neuen Timer der nach debounceDelay onChange aufruft
        let workItem = DispatchWorkItem { [weak self] in
            self?.onChange?()
        }
        debounceTimer = workItem

        // Schedule Timer
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: workItem)
    }

    // MARK: - Lifecycle

    deinit {
        stopMonitoring()
    }
}
