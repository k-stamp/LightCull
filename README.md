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
- **EXIF Metadata Display**: View camera info, focal length, aperture, and shutter speed
- **Thumbnail Navigation**: Quick browsing with a horizontal thumbnail strip
- **Keyboard Shortcuts**:
  - `⌘+` / `⌘-`: Zoom in/out
  - `⌘0`: Reset zoom to 100%
  - `T`: Toggle TOP tag
  - `← →`: Navigate between images

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later (for building from source)

## Installation

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/LightCull.git
   cd LightCull
   ```

2. Open the project in Xcode:
   ```bash
   open LightCull.xcodeproj
   ```

3. Build and run:
   - Press `⌘R` to build and run the application
   - Or press `⌘B` to build only

## Usage

1. **Select a Folder**: Click the folder icon in the sidebar to choose a directory containing your photos
2. **Browse Images**: Click on thumbnails in the bottom bar to view different images
3. **Zoom & Pan**:
   - Use the zoom controls in the toolbar
   - Pinch to zoom on trackpad
   - `⌘+` and `⌘-` keyboard shortcuts
   - Pan with two-finger drag when zoomed in
4. **Tag Favorites**: Press `T` or click the tag button to mark images as "TOP"
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
