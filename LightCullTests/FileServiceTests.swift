//
//  LightCullTests.swift
//  LightCullTests
//
//  Created by Kevin Stamp on 23.09.25.
//

import XCTest
@testable import LightCull

final class FileServiceTests: XCTestCase {
    var fileService: FileService!
    var tagService: FinderTagService!
    
    override func setUp() {
        super.setUp()
        tagService = FinderTagService()
        fileService = FileService(tagService: tagService)
    }
    
    override func tearDown() {
        fileService = nil
        tagService = nil
        super.tearDown()
    }
    
    func testFindeImagePairs() {
        // 1. Load folder from test bundle
        let bundle = Bundle(for: type(of: self))
        guard let folderURL = bundle.url(forResource: "TestResources", withExtension: nil) else {
            XCTFail("TestResources folder not found")
            return
        }
        
        // 2. Call method
        let pairs = fileService.findImagePairs(in: folderURL)
        
        // TEST: There are 5 JPEG files
        XCTAssertEqual(pairs.count, 5, "Should find 5 JPEG files")
        
        // TEST: Of those, exactly 3 have matching .RAF
        let pairsWithRaw = pairs.filter {
            $0.rawURL != nil
        }
        XCTAssertEqual(pairsWithRaw.count, 3, "Should find exactly 3 RAW pairs")
        
        // TEST: Ensure that images DSCF0100, DSCF0102 and DSCF0103 have RAW pairs
        let namesWithRaw = pairsWithRaw.map {
            $0.jpegURL.deletingPathExtension().lastPathComponent
        }
        XCTAssertTrue(namesWithRaw.contains("DSCF0100"), "DSCF0100.jpg should have a RAW")
        XCTAssertTrue(namesWithRaw.contains("DSCF0102"), "DSCF0102.jpg should have a RAW")
        XCTAssertTrue(namesWithRaw.contains("DSCF0103"), "DSCF0103.jpg should have a RAW")
    }
    
    func testImagePairsHaveTagStatus() {
        // 1. Create temporary test folder
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFolderURL = tempDirectory.appendingPathComponent("LightCullTest_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: testFolderURL, withIntermediateDirectories: true)
        } catch {
            XCTFail("Could not create temporary folder: \(error)")
            return
        }
        
        // 2. Copy test images from bundle to temp folder
        let bundle = Bundle(for: type(of: self))
        guard let sourceFolder = bundle.url(forResource: "TestResources", withExtension: nil) else {
            XCTFail("TestResources folder not found")
            return
        }
        
        // Copy DSCF0100.JPG and DSCF0101.JPG
        let filesToCopy = ["DSCF0100.JPG", "DSCF0101.JPG"]
        for fileName in filesToCopy {
            let sourceURL = sourceFolder.appendingPathComponent(fileName)
            let destURL = testFolderURL.appendingPathComponent(fileName)
            
            do {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
            } catch {
                XCTFail("Could not copy \(fileName): \(error)")
                return
            }
        }
        
        // 3. Tag a test image (DSCF0100)
        let testImageURL = testFolderURL.appendingPathComponent("DSCF0100.JPG")
        let tagSuccess = tagService.addTag("TOP", to: testImageURL)
        XCTAssertTrue(tagSuccess, "Tag should be added successfully")
        
        // 4. Load ImagePairs
        let pairs = fileService.findImagePairs(in: testFolderURL)
        
        // 5. Find the tagged image
        guard let taggedPair = pairs.first(where: { $0.jpegURL.lastPathComponent == "DSCF0100.JPG" }) else {
            XCTFail("DSCF0100.JPG should be found")
            return
        }
        
        // TEST: The tagged image should have hasTopTag = true
        XCTAssertTrue(taggedPair.hasTopTag, "DSCF0100.JPG should be recognized as tagged")
        
        // 6. Check a non-tagged image
        guard let untaggedPair = pairs.first(where: { $0.jpegURL.lastPathComponent == "DSCF0101.JPG" }) else {
            XCTFail("DSCF0101.JPG should be found")
            return
        }
        
        // TEST: The non-tagged image should have hasTopTag = false
        XCTAssertFalse(untaggedPair.hasTopTag, "DSCF0101.JPG should not be tagged")
        
        // 7. Cleanup: Delete temporary folder
        try? FileManager.default.removeItem(at: testFolderURL)
    }
}
