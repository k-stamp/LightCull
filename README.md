# LightCull

A fast and intuitive macOS application for viewing and culling photo pairs (JPEG + RAW files). Built with SwiftUI for photographers who want to quickly review and select their best shots.

## Features

- **Smart File Pairing**: Automatically pairs JPEG files with their corresponding RAW files (.RAF format)
- **Advanced Image Viewer**:
  - Zoom from 100% to 400% with smooth scaling
  - Pan support when zoomed in
  - Multiple zoom controls: toolbar buttons, slider, keyboard shortcuts, and trackpad gestures
- **Efficient Culling Workflow**:
  - Mark favorites with the "TOP" Finder tag
  - Tags are applied to both JPEG and RAW files simultaneously
  - Keyboard shortcut (T) for quick tagging
  - **Delete images**: Move unwanted photo pairs to a `_toDelete` folder with undo support
  - Both JPEG and RAW files are deleted together
- **EXIF Metadata Display**: View camera info, focal length, aperture, and shutter speed
- **Thumbnail Navigation**: Quick browsing with a horizontal thumbnail strip
- **Keyboard Shortcuts**:
  - `⌘+` / `⌘-`: Zoom in/out
  - `⌘0`: Reset zoom to 100%
  - `T`: Toggle TOP tag
  - `D` (Delete): Move current image pair to _toDelete folder
  - `⌘Z`: Undo delete operation
  - `← →`: Navigate between images

## Usage

1. **Select a Folder**: Click the folder icon in the sidebar to choose a directory containing your photos
2. **Browse Images**: Click on thumbnails in the bottom bar to view different images
3. **Zoom & Pan**:
   - Use the zoom controls in the toolbar
   - Pinch to zoom on trackpad
   - `⌘+` and `⌘-` keyboard shortcuts
   - Pan with two-finger drag when zoomed in
4. **Culling Workflow**:
   - Press `T` or click the tag button to mark favorites as "TOP"
   - Press `⌫` (Delete) to move unwanted images to the `_toDelete` folder
   - Use `⌘Z` to undo accidental deletions
5. **Review Metadata**: View EXIF information in the sidebar

## Architecture

LightCull uses a clean, testable architecture:

- **Shared ViewModel Pattern**: Ensures zoom/pan state stays synchronized across components
- **Three-Tier Structure**: Separation between MainView (coordinator), View Components, and Services
- **Immutable Data Models**: SwiftUI-friendly state management
- **Dependency Injection**: Services are testable and mockable

## Testing

Run the test suite in Xcode:
```bash
⌘U
```

The project includes comprehensive unit tests for:
- File pairing logic (`FileServiceTests`)
- Zoom/pan behavior (`ImageViewModelTests`)
- Finder tag operations (`FinderTagServiceTests`)

## Supported RAW Formats

Currently supports Fujifilm RAF files. The pairing logic can be extended to support other RAW formats.

## License

[Add your license here]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
