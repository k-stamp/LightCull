# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LightCull is a macOS SwiftUI application for viewing and managing photo pairs (JPEG + RAW files). It provides zoom, pan, and thumbnail navigation functionality for photographers to cull their image libraries.

## Building and Testing

### Build Commands
Since Xcode is not installed (only Command Line Tools), use Xcode.app directly:
- Open project: `open LightCull.xcodeproj`
- Build in Xcode: ⌘B
- Run in Xcode: ⌘R

### Testing
- Run all tests in Xcode: ⌘U
- Test target: `LightCullTests`
- Test files include resource bundles (TestResources folder with sample JPEG/RAF pairs)

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
   - `FileService`: Scans folders for JPEG files, matches with .RAF RAW files by basename
   - `ImagePair`: Model representing JPEG+RAW pair (RAW is optional)

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

### German Comments

The codebase contains German comments throughout. This is intentional and should be preserved when modifying code. English variable/function names are used, but comments explain logic in German.

## Current Features

- Folder selection and JPEG/RAW pairing
- Image viewer with AsyncImage loading
- Zoom: 100-400% with multiple input methods
- Pan: Constrained dragging when zoomed
- Thumbnail bar with selection state
- Keyboard shortcuts for zoom operations

## Test Resources

The test suite expects a `TestResources` folder containing:
- 5 JPEG files
- 3 matching RAF files (for DSCF0100, DSCF0102, DSCF0103)
- This validates the pairing logic in FileService
