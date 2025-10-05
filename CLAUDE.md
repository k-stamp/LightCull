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
- Test resources: `TestResources` folder with 5 JPEGs and 3 matching RAF files

## Architecture

### Core State Management Pattern

The app uses a **shared ViewModel pattern** for cross-component state synchronization:

- `ImageViewModel` (ObservableObject) manages zoom/pan state
- Injected from `MainView` into both `ImageViewerView` and toolbar zoom controls
- This ensures toolbar sliders and gesture-based zooming stay synchronized
- Key insight: The ViewModel is created once in MainView with `@StateObject` and passed down as `@ObservedObject`

### Three-Tier Component Structure

1. **MainView** - Root coordinator
   - Owns the shared `ImageViewModel` (@StateObject)
   - Coordinates NavigationSplitView layout
   - Manages folder selection and image pair state
   - Contains zoom toolbar controls

2. **View Components** (all in Views/Components/)
   - `SidebarView`: Folder selection via NSOpenPanel, displays pair count
   - `ImageViewerView`: Main image display with zoom (1.0-4.0x) and pan gestures
   - `ThumbnailBarView`: Horizontal scrolling thumbnail strip with selection

3. **Services & Models**
   - `FileService`: Scans folders for JPEG files, matches with .RAF RAW files by basename, reads Finder tags
   - `FinderTagService`: Manages macOS Finder tags (add/remove/check tags on files)
   - `MetadataService`: Extracts EXIF data from images using ImageIO framework
   - `ImagePair`: Model representing JPEG+RAW pair (RAW is optional, includes `hasTopTag` boolean)
   - `ImageMetadata`: Model for EXIF data (camera make/model, focal length, aperture, shutter speed)

### Key Implementation Details

**Zoom Implementation:**
- Uses `@Published` properties in `ImageViewModel` for reactive updates
- Zoom range: 1.0 (fit to window) to 4.0 (400%)
- Step increment: 0.25 (25%)
- Supports: toolbar buttons, slider, keyboard shortcuts (⌘+/⌘-/⌘0), and trackpad magnification gestures

**Pan Implementation:**
- Only enabled when `zoomScale > minZoom`
- Uses `SimultaneousGesture` to allow zoom and pan at the same time
- `DragGesture(minimumDistance: 0)` enables 2-finger pan without clicking
- Bounds checking in `handleDrag()` prevents panning beyond scaled image edges
- Offset automatically resets to `.zero` when zoom returns to 1.0

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

**EXIF Metadata Extraction:**
- Uses `CGImageSource` API to read metadata without loading full image
- Extracts from EXIF dictionary: focal length, aperture (f-number), shutter speed
- Camera make/model stored in TIFF dictionary, not EXIF
- Shutter speed formatted as fraction (1/250s) or decimal (2.5s)
- File size formatted with `ByteCountFormatter` (KB/MB only)

**Security-Scoped Resource Access:**
- Required for sandboxed app to access user-selected folders
- `startAccessingSecurityScopedResource()` called when folder selected
- `stopAccessingSecurityScopedResource()` called on folder change or view disappear
- Access state tracked with `isAccessingSecurityScope` boolean
- **Critical**: Must stop old access before starting new access

### Immutable Data Model Pattern

`ImagePair` is an immutable struct - when tag status changes, a new instance is created:

```swift
// In ImageViewModel.toggleTopTag():
let updatedPair = ImagePair(
    jpegURL: pair.jpegURL,
    rawURL: pair.rawURL,
    hasTopTag: newStatus
)
completion(updatedPair)  // MainView replaces old pair in array
```

This ensures SwiftUI change detection works correctly. When updating pairs:
1. Find index in array using `Equatable` (compares URLs, not hasTopTag)
2. Replace entire pair at that index
3. Update `selectedPair` to maintain UI synchronization

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
- Applies to: `FileService`, `ImageViewModel`

### German Comments

The codebase contains German comments throughout. This is intentional and should be preserved when modifying code. English variable/function names are used, but comments explain logic in German.

## Current Features

- Folder selection and JPEG/RAW pairing (Fujifilm .RAF format)
- Image viewer with AsyncImage loading
- Zoom: 100-400% with multiple input methods (toolbar, slider, keyboard, trackpad)
- Pan: Constrained dragging when zoomed
- Thumbnail bar with selection state
- Keyboard shortcuts: ⌘+/⌘- (zoom), ⌘0 (reset), T (toggle TOP tag), ← → (navigate)
- Finder tag management: Mark images as "TOP" for culling
- EXIF metadata display: Camera info, focal length, aperture, shutter speed
- Security-scoped resource access for sandboxed operation

## Test Resources

The test suite expects a `TestResources` folder containing:
- 5 JPEG files
- 3 matching RAF files (for DSCF0100, DSCF0102, DSCF0103)
- This validates the pairing logic in FileService
