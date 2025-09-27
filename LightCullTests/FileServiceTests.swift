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
    
    override func setUp() {
        super.setUp()
        fileService = FileService()
    }
    
    override func tearDown() {
        fileService = nil
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
}
