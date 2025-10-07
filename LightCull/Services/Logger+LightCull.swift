//
//  Logger+LightCull.swift
//  LightCull
//
//  Responsible for: Centralized logging configuration using OSLog
//

import OSLog

extension Logger {
    /// Das Subsystem für alle Logger - basiert auf der Bundle ID
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.lightcull.app"

    // MARK: - Logger Categories

    /// Logger für Dateioperationen (Delete, Rename, Move)
    static let fileOps = Logger(subsystem: subsystem, category: "fileOps")

    /// Logger für Finder-Tag-Operationen
    static let tagging = Logger(subsystem: subsystem, category: "tagging")

    /// Logger für Metadaten-Extraktion (EXIF, etc.)
    static let metadata = Logger(subsystem: subsystem, category: "metadata")

    /// Logger für UI-Interaktionen und View-Events
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Logger für Security-scoped resource access
    static let security = Logger(subsystem: subsystem, category: "security")
}
