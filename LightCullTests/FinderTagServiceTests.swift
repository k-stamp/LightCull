//
//  FinderTagServiceTests.swift
//  LightCullTests
//
//  Unit tests for FinderTagService
//

import XCTest
@testable import LightCull

final class FinderTagServiceTests: XCTestCase {
    
    var tagService: FinderTagService!
    var testFileURL: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create service
        tagService = FinderTagService()
        
        // Create temporary test file
        testFileURL = createTemporaryTestFile()
    }
    
    override func tearDown() {
        // Clean up test file
        if let url = testFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        tagService = nil
        testFileURL = nil
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    /// Test: Successfully add tag to a file
    func testAddTag_Success() {
        // Given: A file without tags
        let tag = "TOP"

        // When: Add tag
        let success = tagService.addTag(tag, to: testFileURL)

        // Then: Operation successful and tag is present
        XCTAssertTrue(success, "Tag should be added successfully")
        XCTAssertTrue(tagService.hasTag(tag, at: testFileURL), "Tag should be present after adding")
    }
    
    /// Test: Add multiple different tags
    func testAddMultipleTags_Success() {
        // Given: A file without tags
        let tag1 = "TOP"
        let tag2 = "Landscape"
        let tag3 = "Portfolio"

        // When: Add multiple tags
        tagService.addTag(tag1, to: testFileURL)
        tagService.addTag(tag2, to: testFileURL)
        tagService.addTag(tag3, to: testFileURL)

        // Then: All tags should be present
        XCTAssertTrue(tagService.hasTag(tag1, at: testFileURL), "Tag 'TOP' should be present")
        XCTAssertTrue(tagService.hasTag(tag2, at: testFileURL), "Tag 'Landscape' should be present")
        XCTAssertTrue(tagService.hasTag(tag3, at: testFileURL), "Tag 'Portfolio' should be present")
    }
    
    /// Test: Add same tag twice (idempotence)
    func testAddTag_Idempotent() {
        // Given: A file without tags
        let tag = "TOP"

        // When: Add same tag twice
        let success1 = tagService.addTag(tag, to: testFileURL)
        let success2 = tagService.addTag(tag, to: testFileURL)

        // Then: Both operations successful, but tag present only once
        XCTAssertTrue(success1, "First operation should be successful")
        XCTAssertTrue(success2, "Second operation should also be successful (idempotent)")
        XCTAssertTrue(tagService.hasTag(tag, at: testFileURL), "Tag should be present")

        // Additionally: Check that tag is not present twice
        // For this we need to read the tags directly
        let resourceValues = try? testFileURL.resourceValues(forKeys: [.tagNamesKey])
        let tags = resourceValues?.tagNames ?? []
        let topTagCount = tags.filter { $0 == tag }.count
        XCTAssertEqual(topTagCount, 1, "Tag should be present only once, not duplicated")
    }
    
    /// Test: Successfully remove tag
    func testRemoveTag_Success() {
        // Given: A file with a tag
        let tag = "TOP"
        tagService.addTag(tag, to: testFileURL)

        // When: Remove tag
        let success = tagService.removeTag(tag, from: testFileURL)

        // Then: Operation successful and tag is no longer present
        XCTAssertTrue(success, "Tag should be removed successfully")
        XCTAssertFalse(tagService.hasTag(tag, at: testFileURL), "Tag should no longer be present after removal")
    }
    
    /// Test: Remove tag that does not exist (idempotence)
    func testRemoveTag_NonExistentTag_Idempotent() {
        // Given: A file without tags
        let tag = "TOP"

        // When: Remove non-existent tag
        let success = tagService.removeTag(tag, from: testFileURL)

        // Then: Operation should be successful (nothing to remove is not an error)
        XCTAssertTrue(success, "Operation should be successful, even if tag does not exist")
        XCTAssertFalse(tagService.hasTag(tag, at: testFileURL), "Tag should not be present")
    }
    
    /// Test: Remove one of multiple tags
    func testRemoveTag_OneOfMultiple() {
        // Given: A file with multiple tags
        let tag1 = "TOP"
        let tag2 = "Landscape"
        let tag3 = "Portfolio"

        tagService.addTag(tag1, to: testFileURL)
        tagService.addTag(tag2, to: testFileURL)
        tagService.addTag(tag3, to: testFileURL)

        // When: Remove middle tag
        tagService.removeTag(tag2, from: testFileURL)

        // Then: Only the removed tag should be missing
        XCTAssertTrue(tagService.hasTag(tag1, at: testFileURL), "Tag 'TOP' should still be present")
        XCTAssertFalse(tagService.hasTag(tag2, at: testFileURL), "Tag 'Landscape' should be removed")
        XCTAssertTrue(tagService.hasTag(tag3, at: testFileURL), "Tag 'Portfolio' should still be present")
    }
    
    /// Test: hasTag returns false for non-existent tags
    func testHasTag_ReturnsFalseForNonExistentTag() {
        // Given: A file without tags
        let tag = "TOP"

        // When & Then: hasTag should return false
        XCTAssertFalse(tagService.hasTag(tag, at: testFileURL), "hasTag should return false for non-existent tag")
    }
    
    /// Test: hasTag returns true for existing tags
    func testHasTag_ReturnsTrueForExistingTag() {
        // Given: A file with a tag
        let tag = "TOP"
        tagService.addTag(tag, to: testFileURL)

        // When & Then: hasTag should return true
        XCTAssertTrue(tagService.hasTag(tag, at: testFileURL), "hasTag should return true for existing tag")
    }
    
    /// Test: Tags are case-sensitive
    func testTags_AreCaseSensitive() {
        // Given: A file with a tag in uppercase
        tagService.addTag("TOP", to: testFileURL)

        // When & Then: Lowercase version should NOT be found
        XCTAssertTrue(tagService.hasTag("TOP", at: testFileURL), "'TOP' should be found")
        XCTAssertFalse(tagService.hasTag("top", at: testFileURL), "'top' should NOT be found (case-sensitive)")
    }
    
    // MARK: - Helper Methods
    
    /// Creates a temporary test file in the system temp folder
    private func createTemporaryTestFile() -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "LightCullTest_\(UUID().uuidString).txt"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // Create empty file
        let testContent = "Test file for FinderTagService"
        try? testContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
}
