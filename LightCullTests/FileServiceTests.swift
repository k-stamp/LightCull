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
        // 1. Ordner aus Test-Bundle laden
        let bundle = Bundle(for: type(of: self))
        guard let folderURL = bundle.url(forResource: "TestResources", withExtension: nil) else {
            XCTFail("TestResources folder not found")
            return
        }
        
        // 2. Methode aufrufen
        let pairs = fileService.findImagePairs(in: folderURL)
        
        // TEST: Es gibt 5 JPEG-Dateien
        XCTAssertEqual(pairs.count, 5, "Es sollten 5 JPEG-Dateien gefunden werden")
        
        // TEST: Davon haben genau 3 ein passendes .RAF
        let pairsWithRaw = pairs.filter {
            $0.rawURL != nil
        }
        XCTAssertEqual(pairsWithRaw.count, 3, "Es sollten genau 3 RAW-Paare gefunden werden")
        
        // TEST: Sicherstellen, dass Bild DSCF0100, DSCF0102 und DSCF0103 RAW-Paare haben
        let namesWithRaw = pairsWithRaw.map {
            $0.jpegURL.deletingPathExtension().lastPathComponent
        }
        XCTAssertTrue(namesWithRaw.contains("DSCF0100"), "DSCF0100.jpg sollte ein RAW haben")
        XCTAssertTrue(namesWithRaw.contains("DSCF0102"), "DSCF0102.jpg sollte ein RAW haben")
        XCTAssertTrue(namesWithRaw.contains("DSCF0103"), "DSCF0103.jpg sollte ein RAW haben")
    }
    
    func testImagePairsHaveTagStatus() {
        // 1. Temporären Test-Ordner erstellen
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFolderURL = tempDirectory.appendingPathComponent("LightCullTest_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: testFolderURL, withIntermediateDirectories: true)
        } catch {
            XCTFail("Konnte temporären Ordner nicht erstellen: \(error)")
            return
        }
        
        // 2. Test-Bilder aus Bundle in temp Ordner kopieren
        let bundle = Bundle(for: type(of: self))
        guard let sourceFolder = bundle.url(forResource: "TestResources", withExtension: nil) else {
            XCTFail("TestResources folder not found")
            return
        }
        
        // Kopiere DSCF0100.JPG und DSCF0101.JPG
        let filesToCopy = ["DSCF0100.JPG", "DSCF0101.JPG"]
        for fileName in filesToCopy {
            let sourceURL = sourceFolder.appendingPathComponent(fileName)
            let destURL = testFolderURL.appendingPathComponent(fileName)
            
            do {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
            } catch {
                XCTFail("Konnte \(fileName) nicht kopieren: \(error)")
                return
            }
        }
        
        // 3. Ein Test-Bild taggen (DSCF0100)
        let testImageURL = testFolderURL.appendingPathComponent("DSCF0100.JPG")
        let tagSuccess = tagService.addTag("TOP", to: testImageURL)
        XCTAssertTrue(tagSuccess, "Tag sollte erfolgreich hinzugefügt werden")
        
        // 4. ImagePairs laden
        let pairs = fileService.findImagePairs(in: testFolderURL)
        
        // 5. Das getaggte Bild finden
        guard let taggedPair = pairs.first(where: { $0.jpegURL.lastPathComponent == "DSCF0100.JPG" }) else {
            XCTFail("DSCF0100.JPG sollte gefunden werden")
            return
        }
        
        // TEST: Das getaggte Bild sollte hasTopTag = true haben
        XCTAssertTrue(taggedPair.hasTopTag, "DSCF0100.JPG sollte als getaggt erkannt werden")
        
        // 6. Ein nicht-getaggtes Bild prüfen
        guard let untaggedPair = pairs.first(where: { $0.jpegURL.lastPathComponent == "DSCF0101.JPG" }) else {
            XCTFail("DSCF0101.JPG sollte gefunden werden")
            return
        }
        
        // TEST: Das nicht-getaggte Bild sollte hasTopTag = false haben
        XCTAssertFalse(untaggedPair.hasTopTag, "DSCF0101.JPG sollte nicht getaggt sein")
        
        // 7. Cleanup: Temporären Ordner löschen
        try? FileManager.default.removeItem(at: testFolderURL)
    }
}
