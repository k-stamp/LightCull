//
//  ThumbnailServiceTests.swift
//  LightCullTests
//
//  Tests for the ThumbnailService
//

import XCTest
@testable import LightCull

final class ThumbnailServiceTests: XCTestCase {

    // The service we are testing
    var thumbnailService: ThumbnailService!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        // Create a new service for each test
        thumbnailService = ThumbnailService()

        // Clear cache before each test
        thumbnailService.clearCache()
    }

    override func tearDown() {
        // Clear cache after each test
        thumbnailService.clearCache()
        thumbnailService = nil
        super.tearDown()
    }

    // MARK: - Tests

    /// Test: clearCache() should delete the cache directory
    func testClearCache() {
        // 1. Get the cache directory URL
        let fileManager = FileManager.default
        let cachesDirectory: URL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let lightCullCache: URL = cachesDirectory.appendingPathComponent("LightCull")

        // 2. Create a test file in the cache
        let currentCache: URL = lightCullCache.appendingPathComponent("current")
        try? fileManager.createDirectory(at: currentCache, withIntermediateDirectories: true, attributes: nil)

        let testFile: URL = currentCache.appendingPathComponent("test.txt")
        try? "test".write(to: testFile, atomically: true, encoding: .utf8)

        // 3. Verify that the file exists
        XCTAssertTrue(fileManager.fileExists(atPath: testFile.path), "Test file should exist before clear")

        // 4. Clear cache
        thumbnailService.clearCache()

        // 5. Verify that the cache directory is gone
        XCTAssertFalse(fileManager.fileExists(atPath: lightCullCache.path), "Cache directory should be deleted")
    }

    /// Test: getThumbnailURL() should return correct cache path
    func testGetThumbnailURL() {
        // 1. Create a sample original URL
        let originalURL: URL = URL(fileURLWithPath: "/Users/test/Photos/DSCF1234.JPG")

        // 2. Get the thumbnail URL
        let thumbnailURL: URL = thumbnailService.getThumbnailURL(for: originalURL)

        // 3. Verify that the filename is correct
        XCTAssertEqual(thumbnailURL.lastPathComponent, "DSCF1234.JPG", "Thumbnail should have same filename as original")

        // 4. Verify that the path contains "LightCull/current"
        XCTAssertTrue(thumbnailURL.path.contains("LightCull/current"), "Thumbnail should be in LightCull/current cache")
    }

    /// Test: generateThumbnails() should create thumbnails for valid images
    func testGenerateThumbnailsWithValidImages() async {
        // 1. Get test resources (from TestResources folder)
        let bundle = Bundle(for: type(of: self))
        guard let resourceURL = bundle.resourceURL?.appendingPathComponent("TestResources") else {
            XCTFail("TestResources folder not found")
            return
        }

        // 2. Find JPEG files in test resources
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) else {
            XCTFail("Could not read TestResources folder")
            return
        }

        let jpegFiles: [URL] = files.filter { url in
            let ext = url.pathExtension.lowercased()
            return ext == "jpg" || ext == "jpeg"
        }

        // 3. Make sure we have at least one JPEG
        XCTAssertGreaterThan(jpegFiles.count, 0, "Should have at least one JPEG in TestResources")

        // 4. Create ImagePairs from JPEGs
        var pairs: [ImagePair] = []
        for jpegURL in jpegFiles {
            let pair = ImagePair(jpegURL: jpegURL, rawURL: nil, hasTopTag: false, thumbnailURL: nil)
            pairs.append(pair)
        }

        // 5. Generate thumbnails
        var progressCalls: Int = 0
        let updatedPairs: [ImagePair] = await thumbnailService.generateThumbnails(for: pairs) { current, total in
            progressCalls = progressCalls + 1
        }

        // 6. Verify that all pairs have thumbnail URLs
        for pair in updatedPairs {
            XCTAssertNotNil(pair.thumbnailURL, "Each pair should have a thumbnail URL")

            // Verify that the thumbnail file exists
            if let thumbnailURL = pair.thumbnailURL {
                XCTAssertTrue(fileManager.fileExists(atPath: thumbnailURL.path), "Thumbnail file should exist: \(thumbnailURL.lastPathComponent)")
            }
        }

        // 7. Verify that progress callback was called
        XCTAssertGreaterThan(progressCalls, 0, "Progress callback should be called at least once")
    }

    /// Test: moveThumbnailToDeleteFolder() should move thumbnail to _toDelete
    func testMoveThumbnailToDeleteFolder() async {
        // 1. Get a test image
        let bundle = Bundle(for: type(of: self))
        guard let resourceURL = bundle.resourceURL?.appendingPathComponent("TestResources") else {
            XCTFail("TestResources folder not found")
            return
        }

        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) else {
            XCTFail("Could not read TestResources folder")
            return
        }

        let jpegFiles: [URL] = files.filter { $0.pathExtension.lowercased() == "jpg" }
        guard let firstJPEG = jpegFiles.first else {
            XCTFail("No JPEG found in TestResources")
            return
        }

        // 2. Generate a thumbnail for it
        let pair = ImagePair(jpegURL: firstJPEG, rawURL: nil, hasTopTag: false, thumbnailURL: nil)
        let updatedPairs: [ImagePair] = await thumbnailService.generateThumbnails(for: [pair]) { _, _ in }

        guard let thumbnailURL = updatedPairs.first?.thumbnailURL else {
            XCTFail("Thumbnail was not generated")
            return
        }

        // 3. Verify thumbnail exists
        XCTAssertTrue(fileManager.fileExists(atPath: thumbnailURL.path), "Thumbnail should exist before move")

        // 4. Move thumbnail to _toDelete
        let success: Bool = thumbnailService.moveThumbnailToDeleteFolder(for: firstJPEG)

        // 5. Verify move was successful
        XCTAssertTrue(success, "Move should succeed")

        // 6. Verify thumbnail is gone from original location
        XCTAssertFalse(fileManager.fileExists(atPath: thumbnailURL.path), "Thumbnail should be gone from original location")

        // 7. Verify thumbnail exists in _toDelete folder
        let cachesDirectory: URL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let toDeleteFolder: URL = cachesDirectory
            .appendingPathComponent("LightCull")
            .appendingPathComponent("current")
            .appendingPathComponent("_toDelete")
        let movedThumbnailURL: URL = toDeleteFolder.appendingPathComponent(thumbnailURL.lastPathComponent)

        XCTAssertTrue(fileManager.fileExists(atPath: movedThumbnailURL.path), "Thumbnail should exist in _toDelete folder")
    }

    /// Test: renameThumbnail() should rename thumbnail in cache
    func testRenameThumbnail() async {
        // 1. Get a test image
        let bundle = Bundle(for: type(of: self))
        guard let resourceURL = bundle.resourceURL?.appendingPathComponent("TestResources") else {
            XCTFail("TestResources folder not found")
            return
        }

        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) else {
            XCTFail("Could not read TestResources folder")
            return
        }

        let jpegFiles: [URL] = files.filter { $0.pathExtension.lowercased() == "jpg" }
        guard let firstJPEG = jpegFiles.first else {
            XCTFail("No JPEG found in TestResources")
            return
        }

        // 2. Generate a thumbnail for it
        let pair = ImagePair(jpegURL: firstJPEG, rawURL: nil, hasTopTag: false, thumbnailURL: nil)
        let updatedPairs: [ImagePair] = await thumbnailService.generateThumbnails(for: [pair]) { _, _ in }

        guard let thumbnailURL = updatedPairs.first?.thumbnailURL else {
            XCTFail("Thumbnail was not generated")
            return
        }

        // 3. Verify thumbnail exists
        XCTAssertTrue(fileManager.fileExists(atPath: thumbnailURL.path), "Thumbnail should exist before rename")

        // 4. Create a new URL (simulate rename)
        let newJPEGURL: URL = firstJPEG.deletingLastPathComponent().appendingPathComponent("RENAMED_\(firstJPEG.lastPathComponent)")

        // 5. Rename thumbnail
        let success: Bool = thumbnailService.renameThumbnail(from: firstJPEG, to: newJPEGURL)

        // 6. Verify rename was successful
        XCTAssertTrue(success, "Rename should succeed")

        // 7. Verify old thumbnail is gone
        XCTAssertFalse(fileManager.fileExists(atPath: thumbnailURL.path), "Old thumbnail should be gone")

        // 8. Verify new thumbnail exists
        let newThumbnailURL: URL = thumbnailService.getThumbnailURL(for: newJPEGURL)
        XCTAssertTrue(fileManager.fileExists(atPath: newThumbnailURL.path), "New thumbnail should exist")
    }
}
