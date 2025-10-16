# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LightCull is a macOS SwiftUI application for viewing and managing photo pairs (JPEG + RAW files). It provides zoom, pan, and thumbnail navigation functionality for photographers to cull their image libraries.

## Building and Testing

### Build Commands
- Open project: `open LightCull.xcodeproj`
- Build in Xcode: ⌘B
- Run in Xcode: ⌘R

### Testing
- Run all tests in Xcode: ⌘U
- Test target: `LightCullTests`
- Key test files:
  - `FileServiceTests`: Validates JPEG/RAW pairing and tag reading
  - `ImageViewModelTests`: Tests zoom/pan logic and tag toggling
  - `FinderTagServiceTests`: Tests macOS Finder tag operations
  - `ThumbnailServiceTests`: Tests thumbnail generation and caching
- Test resources: `LightCullTests/TestResources` folder with 5 JPEGs and 3 matching RAF files

## Architecture

### Core State Management Pattern

The app uses a **shared ViewModel pattern** for cross-component state synchronization:

- `ImageViewModel` (ObservableObject) manages zoom/pan state and orchestrates file operations
- Injected from `MainView` into both `ImageViewerView` and toolbar zoom controls
- This ensures toolbar sliders and gesture-based zooming stay synchronized
- Key insight: The ViewModel is created once in MainView with `@StateObject` and passed down as `@ObservedObject`

### Three-Tier Component Structure

1. **MainView** - Root coordinator
   - Owns the shared `ImageViewModel` (@StateObject)
   - Coordinates NavigationSplitView layout
   - Manages folder selection and image pair state
   - Contains zoom toolbar controls
   - Handles all service initialization and dependency injection

2. **View Components** (all in Views/Components/)
   - `ImageViewerView`: Main image display with zoom (1.0-4.0x) and pan gestures
   - `ZoomAndPanGestureView`: Handles trackpad magnification and scroll events
   - `PanGestureView`: Standalone pan gesture component (legacy/alternative)
   - `ThumbnailBarView`: Horizontal scrolling thumbnail strip with selection and multi-select
   - `SidebarView`: Folder selection via NSOpenPanel, displays statistics and metadata
   - `RenameSheetView`: Modal for batch renaming selected images
   - `ThumbnailProgressView`: Progress sheet shown during thumbnail generation

3. **Services & Models**
   - `FileService`: Scans folders for JPEG files, matches with .RAF RAW files by basename, reads Finder tags, computes folder statistics
   - `FinderTagService`: Manages macOS Finder tags (add/remove/check tags on files)
   - `FileMoveService`: Moves image pairs to destination folders (_toDelete, _Archive, _Outtakes) and handles undo
   - `MetadataService`: Extracts EXIF data from images using ImageIO framework
   - `ThumbnailService`: Generates and caches thumbnail images for performance
   - `FileRenameService`: Handles batch renaming of image pairs
   - `ImagePair`: Model representing JPEG+RAW pair (RAW is optional, includes `hasTopTag`, `thumbnailURL`)
   - `ImageMetadata`: Model for EXIF data (camera make/model, focal length, aperture, shutter speed, ISO)
   - `MoveOperation`: Records move operations for undo functionality
   - `FolderStatistics`: Aggregates folder stats (total files, pairs, deletions, tagged images)

### Key Implementation Details

**Zoom Implementation:**
- Uses `@Published` properties in `ImageViewModel` for reactive updates
- Zoom range: 1.0 (fit to window) to 4.0 (400%)
- Step increment: 0.25 (25%)
- Supports: toolbar buttons, slider, keyboard shortcuts (⌘+/⌘-/⌘0), and trackpad magnification gestures
- `ZoomAndPanGestureView` wraps native NSEvent handling for smooth trackpad integration

**Pan Implementation:**
- Only enabled when `zoomScale > minZoom`
- `ZoomAndPanGestureView` captures scroll wheel events for 2-finger pan on trackpad
- Bounds checking in `handleDrag()` and `applyScrollDelta()` prevents panning beyond scaled image edges
- Offset automatically resets to `.zero` when zoom returns to 1.0
- Pan bounds are adjusted when switching images to handle different aspect ratios

**File Pairing Logic:**
- Currently hardcoded to match `.RAF` files (Fujifilm RAW format)
- Matches by basename: `DSCF0100.jpg` pairs with `DSCF0100.RAF`
- Only JPEG files create pairs; orphaned RAW files are ignored
- Files sorted using `localizedStandardCompare` for natural ordering

**Finder Tag Integration:**
- Uses macOS URLResourceValues API with `.tagNamesKey` to read/write tags
- "TOP" tag marks favorite images for culling workflow
- Tags applied to BOTH JPEG and RAW files in a pair
- `FinderTagService` provides: `addTag()`, `removeTag()`, `hasTag()`
- Tag status checked on JPEG file only (both files tagged together)
- **Important**: `setResourceValues()` requires mutable URL (`var`)

**Delete/Archive/Outtake with Undo:**
- `FileMoveService` moves image pairs to destination folders (_toDelete, _Archive, _Outtakes)
- Each move operation creates a `MoveOperation` record stored in `ImageViewModel.moveHistory`
- Undo (⌘Z) restores the last moved pair from the destination folder
- Move history is cleared when changing folders
- Both JPEG and RAW files are moved together atomically
- If RAW move fails, JPEG is restored to maintain consistency
- Thumbnails are also moved/restored with their image pairs

**EXIF Metadata Extraction:**
- Uses `CGImageSource` API to read metadata without loading full image
- Extracts from EXIF dictionary: focal length, aperture (f-number), shutter speed, ISO
- Camera make/model stored in TIFF dictionary, not EXIF
- Shutter speed formatted as fraction (1/250s) or decimal (2.5s)
- File size formatted with `ByteCountFormatter` (KB/MB only)

**Thumbnail Generation and Caching:**
- `ThumbnailService` generates 300x300px thumbnails on folder load
- Thumbnails cached to `~/Library/Caches/LightCull/Thumbnails/` (identified by JPEG URL hash)
- Progress sheet displays generation status with current/total count
- Thumbnail URLs stored in `ImagePair.thumbnailURL` for fast access
- Thumbnails moved to `.deleted` subfolder when images are moved (for potential restoration)
- Cache cleared when changing folders

**Security-Scoped Resource Access:**
- Required for sandboxed app to access user-selected folders
- `startAccessingSecurityScopedResource()` called when folder selected
- `stopAccessingSecurityScopedResource()` called on folder change or view disappear
- Access state tracked with `isAccessingSecurityScope` boolean
- **Critical**: Must stop old access before starting new access
- Service calls rely on folder-level access being active

**Thumbnail Bar with Multi-Select:**
- Horizontal scroll view with selectable thumbnails
- Supports multi-select via ⌘-click for batch operations
- Selected pairs tracked in `MainView.selectedPairs: Set<UUID>`
- Resizable height (120-400px) via drag gesture on divider
- Can be toggled on/off with ⌘⌥T or toolbar button

**Batch Rename Functionality:**
- `RenameSheetView` modal allows prefix-based renaming
- Selected images renamed sequentially: `prefix_0001.jpg`, `prefix_0002.jpg`, etc.
- Both JPEG and RAW files renamed together
- Folder rescanned after rename to refresh state

### Immutable Data Model Pattern

`ImagePair` is an immutable struct - when tag status or thumbnails change, a new instance is created:

```swift
// In ImageViewModel.toggleTopTag():
let updatedPair = ImagePair(
    jpegURL: pair.jpegURL,
    rawURL: pair.rawURL,
    hasTopTag: newStatus,
    thumbnailURL: pair.thumbnailURL
)
completion(updatedPair)  // MainView replaces old pair in array
```

This ensures SwiftUI change detection works correctly. When updating pairs:
1. Find index in array using `Equatable` (compares URLs, not hasTopTag)
2. Replace entire pair at that index
3. Update `selectedPair` to maintain UI synchronization (set to nil, then to updated pair)

### Dependency Injection Pattern

Services use constructor injection with default parameters for testability:

```swift
class FileService {
    private let tagService: FinderTagService
    init(tagService: FinderTagService = FinderTagService()) {
        self.tagService = tagService
    }
}
```

This pattern allows:
- Production code uses default instances (`FileService()`)
- Tests inject mocks (`FileService(tagService: mockTagService)`)
- Applies to: `FileService`, `ImageViewModel`, `FileMoveService`

### German Comments

The codebase contains German comments throughout. This is intentional and should be preserved when modifying code. English variable/function names are used, but comments explain logic in German.

## Current Features

- Folder selection and JPEG/RAW pairing (Fujifilm .RAF format)
- Image viewer with AsyncImage loading
- Zoom: 100-400% with multiple input methods (toolbar, slider, keyboard, trackpad)
- Pan: Constrained dragging and scrolling when zoomed
- Thumbnail bar with selection state and multi-select for batch operations
- Thumbnail caching for performance
- Resizable thumbnail bar (120-400px height)
- Keyboard shortcuts:
  - ⌘+/⌘- (zoom), ⌘0 (reset)
  - T (toggle TOP tag)
  - D (move to _toDelete)
  - A (move to _Archive)
  - O (move to _Outtakes)
  - ⌘Z (undo last move)
  - ← → (navigate)
  - ⌘N (rename selected)
  - ⌘⌥T (toggle thumbnail bar)
- Finder tag management: Mark images as "TOP" for culling
- File organization: Move unwanted/archived images to destination folders with undo
- Batch rename: Rename selected images with custom prefix
- EXIF metadata display: Camera info, focal length, aperture, shutter speed, ISO
- Folder statistics: Total files, pairs, deletions, tagged images
- Security-scoped resource access for sandboxed operation

## Test Resources

The test suite expects a `LightCullTests/TestResources` folder containing:
- 5 JPEG files (DSCF0100.JPG through DSCF0104.JPG)
- 3 matching RAF files (for DSCF0100, DSCF0102, DSCF0103)
- This validates the pairing logic in FileService
