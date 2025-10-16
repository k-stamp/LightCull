//
//  MainView.swift
//  LightCull
//
//  Main view of the app - coordinates the individual UI components
//

import SwiftUI
import OSLog

struct MainView: View {
    @State private var pairs: [ImagePair] = []
    @State private var folderURL: URL?
    @State private var selectedPair: ImagePair?

    // NEW: Multi-selection for batch operations
    @State private var selectedPairs: Set<UUID> = []

    // NEW: State for rename sheet
    @State private var showRenameSheet: Bool = false

    // NEW: Tracking for security-scoped access
    @State private var isAccessingSecurityScope = false

    // Metadata of the currently selected image
    @State private var currentMetadata: ImageMetadata?

    // NEW: Folder statistics
    @State private var folderStatistics: FolderStatistics?

    // Shared ViewModel for zoom control between viewer and toolbar
    @StateObject private var imageViewModel = ImageViewModel()

    // NEW: Service for managing Finder tags
    private let tagService = FinderTagService()

    // Service for loading metadata
    private let metadataService = MetadataService()

    // NEW: Service for renaming files
    private let renameService = FileRenameService()

    // NEW: Service for thumbnail generation
    private let thumbnailService = ThumbnailService()

    // NEW: State for thumbnail generation progress
    @State private var isGeneratingThumbnails = false
    @State private var thumbnailProgress: (current: Int, total: Int) = (0, 0)

    // Initialization for tests and previews
    init(pairs: [ImagePair] = [], folderURL: URL? = nil) {
        _pairs = State(initialValue: pairs)
        _folderURL = State(initialValue: folderURL)
    }
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR: Folder selection and info
            SidebarView(
                folderURL: $folderURL,
                pairs: $pairs,
                currentMetadata: currentMetadata,
                statistics: folderStatistics,
                onFolderSelected: handleFolderSelection
            )
        } detail: {
            // CONTENT AREA: Image preview on top + thumbnails on bottom
            ZStack {
                VStack(spacing: 0) {
                    // IMPORTANT: ViewModel is passed through here!
                    ImageViewerView(
                        selectedImagePair: selectedPair,
                        viewModel: imageViewModel,
                        onPreviousImage: selectPreviousImage,
                        onNextImage: selectNextImage,
                        onToggleTag: handleToggleTag,  // NEW: Callback for tag toggle
                        onDeleteImage: handleDelete,  // NEW: Callback for delete
                        onArchiveImage: handleArchive,  // NEW: Callback for archive
                        onOuttakeImage: handleOuttake  // NEW: Callback for outtake
                    )

                    ThumbnailBarView(
                        pairs: pairs,
                        selectedPair: $selectedPair,
                        selectedPairs: $selectedPairs,
                        onRenameSelected: handleRenameButtonClicked
                    )
                }
                .background(Color(.controlBackgroundColor))

                // NEW: Invisible buttons for keyboard shortcuts
                VStack {
                    Button("Rename Selected") { handleRenameButtonClicked() }
                        .keyboardShortcut("n", modifiers: .command)
                        .hidden()

                    Button("Undo Delete") { handleUndo() }
                        .keyboardShortcut("z", modifiers: .command)
                        .hidden()
                }
                .frame(width: 0, height: 0)
            }
            // Toolbar at the top edge of the window
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        // Tag button on the left of zoom controls
                        tagButtonView

                        Divider()
                            .frame(height: 20)

                        // Zoom controls on the right
                        zoomControlsView
                    }
                }
            }
        }
        // Automatically load metadata when the selected image changes
        .onChange(of: selectedPair) { oldValue, newValue in
                loadMetadataForSelectedPair(newValue)
        }
        // NEW: Cleanup when view disappears
        .onDisappear {
            stopSecurityScopedAccess()
        }
        // NEW: Clear move history when folder changes
        .onChange(of: folderURL) { oldValue, newValue in
            // Clear the move history when folder changes
            imageViewModel.clearMoveHistory()
        }
        // NEW: Show rename sheet
        .sheet(isPresented: $showRenameSheet) {
            renameSheetView
        }
        // NEW: Show thumbnail progress sheet
        .sheet(isPresented: $isGeneratingThumbnails) {
            thumbnailProgressSheetView
        }
    }
    
    // MARK: - Thumbnail Progress Sheet (NEW!)

    /// Progress sheet for thumbnail generation
    private var thumbnailProgressSheetView: some View {
        ThumbnailProgressView(
            currentCount: thumbnailProgress.current,
            totalCount: thumbnailProgress.total
        )
        .interactiveDismissDisabled(true)  // Cannot be dismissed during generation
    }

    // MARK: - Rename Sheet (NEW!)

    /// Rename sheet for batch renaming
    private var renameSheetView: some View {
        // Get the selected pairs from the set
        let selectedPairsArray: [ImagePair] = getSelectedPairsArray()

        return RenameSheetView(
            selectedPairs: selectedPairsArray,
            onRename: { prefix in
                handleRename(withPrefix: prefix)
            },
            onCancel: {
                handleRenameCancel()
            }
        )
    }

    // MARK: - Tag Button (NEW!)

    /// Tag button for the toolbar
    private var tagButtonView: some View {
        Button(action: {
            handleToggleTag()
        }) {
            Image(systemName: selectedPair?.hasTopTag == true ? "star.fill" : "star")
                .imageScale(.large)
                .foregroundStyle(selectedPair?.hasTopTag == true ? .yellow : .primary)
        }
        .disabled(selectedPair == nil)
        .help("Mark/remove as TOP (T)")
    }
    
    // MARK: - Zoom Controls
    
    /// Zoom slider and buttons for the toolbar
    private var zoomControlsView: some View {
        HStack(spacing: 4) {
            // Zoom Out Button
            Button(action: {
                imageViewModel.zoomOut()
            }) {
                Image(systemName: "minus.magnifyingglass")
                    .imageScale(.large)
            }
            .disabled(imageViewModel.isMinZoom)
            .help("Zoom out (⌘-)")

            // Zoom slider with percentage display
            HStack(spacing: 8) {
                // CORRECTION: Direct binding to @Published property
                Slider(
                    value: $imageViewModel.zoomScale,
                    in: imageViewModel.minZoom...imageViewModel.maxZoom,
                    step: 0.01
                )
                .frame(width: 120)
                .disabled(selectedPair == nil)

                Text("\(imageViewModel.zoomPercentage)%")
                    .font(.body)
                    .monospacedDigit() // Prevents digit jumping
                    .frame(minWidth: 50, alignment: .trailing)
                    .foregroundStyle(selectedPair == nil ? .secondary : .primary)
            }

            // Zoom In Button
            Button(action: {
                imageViewModel.zoomIn()
            }) {
                Image(systemName: "plus.magnifyingglass")
                    .imageScale(.large)
            }
            .disabled(imageViewModel.isMaxZoom)
            .help("Zoom in (⌘+)")

            // Reset Zoom Button
            Button(action: {
                imageViewModel.resetZoom()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .imageScale(.large)
            }
            .disabled(imageViewModel.isMinZoom)
            .help("Reset zoom (⌘0)")
        }
        .disabled(selectedPair == nil)
    }
    
    // MARK: - Event Handlers
    
    /// Handles toggling of the TOP tag for the currently selected image
    private func handleToggleTag() {
        guard let currentPair = selectedPair else {
            return
        }

        // Call ViewModel to toggle tag
        imageViewModel.toggleTopTag(for: currentPair) { updatedPair in
            // IMPORTANT: UI updates MUST happen on the main thread
            DispatchQueue.main.async {
                // Callback: Update ImagePair in the array
                updateImagePair(updatedPair)
            }
        }
    }
    
    /// Updates an ImagePair in the pairs array
    /// - Parameter updatedPair: The updated ImagePair with new tag status
    private func updateImagePair(_ updatedPair: ImagePair) {
        // 1. Find the index of the old pair
        // We use Equatable (based on URLs), not on hasTopTag!
        guard let index = pairs.firstIndex(where: { $0 == updatedPair }) else {
            Logger.ui.notice("ImagePair not found in array")
            return
        }

        // 2. Replace old pair with new one
        pairs[index] = updatedPair

        // 3. Also update selectedPair (to keep UI in sync)
        // IMPORTANT: We set selectedPair to nil and then to updatedPair
        // This forces SwiftUI to detect the change and update the UI
        selectedPair = nil
        selectedPair = updatedPair

        // 4. Update statistics (NEW!)
        refreshStatistics()

        // 5. Debug output
        Logger.ui.info("ImagePair updated: \(updatedPair.jpegURL.lastPathComponent) - hasTopTag: \(updatedPair.hasTopTag)")
    }

    /// Refreshes the folder statistics
    private func refreshStatistics() {
        guard let folder = folderURL else {
            return
        }

        // Reload statistics on background thread
        Task.detached {
            let fileService = await FileService(tagService: FinderTagService())
            let stats = await fileService.getFolderStatistics(in: folder)

            // Update on main thread
            await MainActor.run {
                folderStatistics = stats
            }
        }
    }

    // MARK: - Rename Handlers (NEW!)

    /// Called when the "Rename" button is clicked
    private func handleRenameButtonClicked() {
        // Show sheet
        showRenameSheet = true
    }

    /// Called when "Cancel" is clicked in the rename sheet
    private func handleRenameCancel() {
        // Close sheet
        showRenameSheet = false

        // Clear multi-selection
        selectedPairs.removeAll()
    }

    /// Called when "Rename" is clicked in the rename sheet
    private func handleRename(withPrefix prefix: String) {
        // 1. Get the selected pairs from the set
        let selectedPairsArray: [ImagePair] = getSelectedPairsArray()

        // 2. Rename each pair
        for pair in selectedPairsArray {
            // Rename pair using the rename service
            let newPair: ImagePair? = renameService.renamePair(pair, withPrefix: prefix)

            if newPair == nil {
                Logger.ui.notice("Error renaming: \(pair.jpegURL.lastPathComponent)")
            }
        }

        // 3. Close sheet
        showRenameSheet = false

        // 4. Clear multi-selection
        selectedPairs.removeAll()

        // 5. Rescan folder (simplest solution - reloads all pairs)
        if let folder = folderURL {
            rescanFolder(folder)
        }
    }

    /// Returns an array with the selected ImagePairs
    private func getSelectedPairsArray() -> [ImagePair] {
        // Create empty array
        var result: [ImagePair] = []

        // Go through all pairs
        for pair in pairs {
            // Is this pair in the selectedPairs set?
            if selectedPairs.contains(pair.id) {
                // Yes - add to result array
                result.append(pair)
            }
        }

        return result
    }

    /// Rescans the folder and updates the pairs
    /// - Parameters:
    ///   - folder: The folder to rescan
    ///   - completion: Optional callback after rescan completes (on main thread)
    private func rescanFolder(_ folder: URL, completion: (() -> Void)? = nil) {
        // Show progress sheet
        isGeneratingThumbnails = true
        thumbnailProgress = (current: 0, total: 0)

        // Rescan asynchronously (to prevent blocking main thread)
        Task {
            await loadPairsAndGenerateThumbnails(for: folder)

            // After rescan, call completion on main thread
            await MainActor.run {
                completion?()
            }
        }
    }

    // MARK: - Delete Handlers (NEW!)

    /// Called when the "D" shortcut is pressed
    private func handleDelete() {
        // 1. Is there even a selected image?
        guard let currentPair = selectedPair else {
            Logger.ui.notice("No image selected - cannot delete")
            return
        }

        // 2. Is there a selected folder?
        guard let folder = folderURL else {
            Logger.ui.notice("No folder selected - cannot delete")
            return
        }

        // 3. Remember the index of the current image (for navigation after delete)
        let currentIndex: Int? = pairs.firstIndex(of: currentPair)

        Logger.ui.debug("Deleting image: \(currentPair.jpegURL.lastPathComponent)")

        // 4. Call ViewModel to delete the image
        imageViewModel.deleteImagePair(pair: currentPair, in: folder) { success in
            // Callback is called when delete is finished

            if success {
                // Delete was successful!
                Logger.ui.info("Delete successful")

                // 5. Rescan folder, then select next image in completion
                rescanFolder(folder) {
                    // 6. Select next image AFTER rescan completes
                    selectNextImageAfterDelete(deletedIndex: currentIndex)
                }
            } else {
                // Delete failed
                Logger.ui.error("Delete failed")
            }
        }
    }

    /// Called when the "A" shortcut is pressed
    private func handleArchive() {
        // 1. Is there even a selected image?
        guard let currentPair = selectedPair else {
            Logger.ui.notice("No image selected - cannot archive")
            return
        }

        // 2. Is there a selected folder?
        guard let folder = folderURL else {
            Logger.ui.notice("No folder selected - cannot archive")
            return
        }

        // 3. Remember the index of the current image (for navigation after archive)
        let currentIndex: Int? = pairs.firstIndex(of: currentPair)

        Logger.ui.debug("Archiving image: \(currentPair.jpegURL.lastPathComponent)")

        // 4. Call ViewModel to archive the image
        imageViewModel.archiveImagePair(pair: currentPair, in: folder) { success in
            // Callback is called when archive is finished

            if success {
                // Archive was successful!
                Logger.ui.info("Archive successful")

                // 5. Rescan folder, then select next image in completion
                rescanFolder(folder) {
                    // 6. Select next image AFTER rescan completes
                    selectNextImageAfterDelete(deletedIndex: currentIndex)
                }
            } else {
                // Archive failed
                Logger.ui.error("Archive failed")
            }
        }
    }

    /// Called when the "O" shortcut is pressed
    private func handleOuttake() {
        // 1. Is there even a selected image?
        guard let currentPair = selectedPair else {
            Logger.ui.notice("No image selected - cannot outtake")
            return
        }

        // 2. Is there a selected folder?
        guard let folder = folderURL else {
            Logger.ui.notice("No folder selected - cannot outtake")
            return
        }

        // 3. Remember the index of the current image (for navigation after outtake)
        let currentIndex: Int? = pairs.firstIndex(of: currentPair)

        Logger.ui.debug("Outtaking image: \(currentPair.jpegURL.lastPathComponent)")

        // 4. Call ViewModel to outtake the image
        imageViewModel.outtakeImagePair(pair: currentPair, in: folder) { success in
            // Callback is called when outtake is finished

            if success {
                // Outtake was successful!
                Logger.ui.info("Outtake successful")

                // 5. Rescan folder, then select next image in completion
                rescanFolder(folder) {
                    // 6. Select next image AFTER rescan completes
                    selectNextImageAfterDelete(deletedIndex: currentIndex)
                }
            } else {
                // Outtake failed
                Logger.ui.error("Outtake failed")
            }
        }
    }

    /// Called when the "CMD+Z" shortcut is pressed
    private func handleUndo() {
        // 1. Is there even anything to undo?
        let canUndo: Bool = imageViewModel.canUndo()

        if canUndo == false {
            Logger.ui.notice("Nothing to undo")
            return
        }

        // 2. Is there a selected folder?
        guard let folder = folderURL else {
            Logger.ui.notice("No folder selected - cannot undo")
            return
        }

        Logger.ui.debug("Undoing last move")

        // 3. Call ViewModel to execute the undo
        imageViewModel.undoLastMove { success in
            // Callback is called when undo is finished

            if success {
                // Undo was successful!
                Logger.ui.info("Undo successful")

                // 4. Rescan folder (so the restored image appears)
                rescanFolder(folder)

                // 5. Select the restored image (it's now the last in the list)
                if pairs.isEmpty == false {
                    selectedPair = pairs.last
                }
            } else {
                // Undo failed
                Logger.ui.error("Undo failed")
            }
        }
    }

    /// Selects the next image after a delete
    /// - Parameter deletedIndex: The index of the deleted image (or nil)
    private func selectNextImageAfterDelete(deletedIndex: Int?) {
        // Are there even any images left?
        if pairs.isEmpty {
            // No more images - select nothing
            selectedPair = nil
            Logger.ui.info("No more images in folder")
            return
        }

        // Did we have an index?
        guard let deletedIndex = deletedIndex else {
            // No index - just select the first image
            selectedPair = pairs.first
            return
        }

        // Now we need to decide: Next or previous image?

        // Was the deleted image the last in the list?
        if deletedIndex >= pairs.count {
            // Yes - so select the new last image
            selectedPair = pairs.last
        } else {
            // No - so select the image at the same position
            // (what was previously the next image is now at the same position)
            selectedPair = pairs[deletedIndex]
        }
    }


    // MARK: - Navigation Handlers

    /// Called when a new folder is selected
    private func handleFolderSelection(_ url: URL) {
        // IMPORTANT: First stop old access
        stopSecurityScopedAccess()

        // NEW: Start security-scoped access for the selected folder
        isAccessingSecurityScope = url.startAccessingSecurityScopedResource()

        if !isAccessingSecurityScope {
            Logger.security.notice("Could not start security-scoped access for: \(url.path)")
        } else {
            Logger.security.info("Security-scoped access started for: \(url.path)")
        }

        // NEW: Clear old thumbnail cache
        thumbnailService.clearCache()

        // NEW: Show progress sheet IMMEDIATELY (before any heavy work)
        isGeneratingThumbnails = true
        thumbnailProgress = (current: 0, total: 0)

        // NEW: Start loading pairs AND generating thumbnails (async)
        // This prevents blocking the main thread
        Task {
            await loadPairsAndGenerateThumbnails(for: url)

            // After loading, select first image
            await MainActor.run {
                selectedPair = pairs.first
            }
        }
    }

    /// Loads image pairs from folder and generates thumbnails
    private func loadPairsAndGenerateThumbnails(for folderURL: URL) async {
        Logger.ui.info("Loading pairs from folder: \(folderURL.path)")

        // 1. Load pairs and statistics from folder (on background thread)
        let (loadedPairs, loadedStatistics) = await Task.detached {
            // Create FileService
            let fileService = await FileService(tagService: FinderTagService())

            // Find image pairs (this can take time for large folders)
            let pairs = await fileService.findImagePairs(in: folderURL)

            // Get folder statistics
            let stats = await fileService.getFolderStatistics(in: folderURL)

            await Logger.ui.info("Found \(pairs.count) image pairs")
            return (pairs, stats)
        }.value

        // 2. Update pairs and statistics on main thread
        await MainActor.run {
            pairs = loadedPairs
            // NOTE: selectedPair is NOT set here - caller is responsible for selection
            folderStatistics = loadedStatistics

            // Update progress to show total count
            thumbnailProgress = (current: 0, total: pairs.count)
        }

        // 3. Generate thumbnails (if there are any pairs)
        if loadedPairs.isEmpty == false {
            await generateThumbnailsForCurrentPairs()
        }

        // 4. Hide progress sheet (whether there were pairs or not)
        await MainActor.run {
            isGeneratingThumbnails = false
            Logger.ui.info("Folder loading complete")
        }
    }

    /// Generates thumbnails for all current pairs
    /// NOTE: This function does NOT manage the progress sheet!
    /// The caller is responsible for showing/hiding the sheet.
    private func generateThumbnailsForCurrentPairs() async {
        // 1. Are there even any pairs?
        if pairs.isEmpty {
            Logger.ui.debug("No pairs to generate thumbnails for")
            return
        }

        Logger.ui.info("Starting thumbnail generation for \(pairs.count) pairs")

        // 2. Generate thumbnails (with progress callback)
        let updatedPairs: [ImagePair] = await thumbnailService.generateThumbnails(for: pairs) { current, total in
            // This callback is already executed on MainActor (synchronously)
            // No Task wrapper needed - UI updates happen immediately
            thumbnailProgress = (current: current, total: total)
        }

        // 3. Update pairs array with thumbnail URLs
        await MainActor.run {
            pairs = updatedPairs
            Logger.ui.info("Thumbnail generation complete - \(pairs.count) pairs updated")
        }
    }
    
    /// Stops security-scoped access for the current folder
    private func stopSecurityScopedAccess() {
        guard isAccessingSecurityScope, let url = folderURL else {
            return
        }
        
        url.stopAccessingSecurityScopedResource()
        isAccessingSecurityScope = false
        Logger.security.info("Security-scoped access stopped for: \(url.path)")
    }

    /// Jumps to the previous image in the list
    private func selectPreviousImage() {
        guard let current = selectedPair,
              let currentIndex = pairs.firstIndex(of: current),
              currentIndex > 0 else {
            return
        }
        selectedPair = pairs[currentIndex - 1]
    }

    /// Jumps to the next image in the list
    private func selectNextImage() {
        guard let current = selectedPair,
              let currentIndex = pairs.firstIndex(of: current),
              currentIndex < pairs.count - 1 else {
            return
        }
        selectedPair = pairs[currentIndex + 1]
    }
    
    // MARK: - Metadata Loading
    
    private func loadMetadataForSelectedPair(_ pair: ImagePair?) {
        // If no image is selected, reset metadata
        guard let pair = pair else {
            currentMetadata = nil
            return
        }
        
        currentMetadata = metadataService.extractMetadata(from: pair.jpegURL)

        // Debug output (you can remove this later)
        if let metadata = currentMetadata {
            Logger.ui.debug("Metadata loaded: \(metadata.fileName)")
        } else {
            Logger.ui.debug("No metadata available for: \(pair.jpegURL.lastPathComponent)")
        }
    }
    
    
}

// MARK: - Previews

#Preview("MainView – Empty") {
    MainView()
        .frame(minWidth: 900, minHeight: 600)
}

#Preview("MainView – With Data") {
    MainView(
        pairs: [
            ImagePair(
                jpegURL: URL(fileURLWithPath: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/JPEG.icns"),
                rawURL: URL(fileURLWithPath: "/mock/image1.cr2"),
                hasTopTag: true
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
        folderURL: URL(fileURLWithPath: "/Users/Mock/Pictures")
    )
    .frame(minWidth: 900, minHeight: 600)
}
