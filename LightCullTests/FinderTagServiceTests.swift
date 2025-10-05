//
//  FinderTagServiceTests.swift
//  LightCullTests
//
//  Unit-Tests für den FinderTagService
//

import XCTest
@testable import LightCull

final class FinderTagServiceTests: XCTestCase {
    
    var tagService: FinderTagService!
    var testFileURL: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Service erstellen
        tagService = FinderTagService()
        
        // Temporäre Test-Datei erstellen
        testFileURL = createTemporaryTestFile()
    }
    
    override func tearDown() {
        // Test-Datei aufräumen
        if let url = testFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        tagService = nil
        testFileURL = nil
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    /// Test: Tag erfolgreich zu einer Datei hinzufügen
    func testAddTag_Success() {
        // Given: Eine Datei ohne Tags
        let tag = "TOP"
        
        // When: Tag hinzufügen
        let success = tagService.addTag(tag, to: testFileURL)
        
        // Then: Operation erfolgreich und Tag ist vorhanden
        XCTAssertTrue(success, "Tag sollte erfolgreich hinzugefügt werden")
        XCTAssertTrue(tagService.hasTag(tag, at: testFileURL), "Tag sollte nach dem Hinzufügen vorhanden sein")
    }
    
    /// Test: Mehrere verschiedene Tags hinzufügen
    func testAddMultipleTags_Success() {
        // Given: Eine Datei ohne Tags
        let tag1 = "TOP"
        let tag2 = "Landscape"
        let tag3 = "Portfolio"
        
        // When: Mehrere Tags hinzufügen
        tagService.addTag(tag1, to: testFileURL)
        tagService.addTag(tag2, to: testFileURL)
        tagService.addTag(tag3, to: testFileURL)
        
        // Then: Alle Tags sollten vorhanden sein
        XCTAssertTrue(tagService.hasTag(tag1, at: testFileURL), "Tag 'TOP' sollte vorhanden sein")
        XCTAssertTrue(tagService.hasTag(tag2, at: testFileURL), "Tag 'Landscape' sollte vorhanden sein")
        XCTAssertTrue(tagService.hasTag(tag3, at: testFileURL), "Tag 'Portfolio' sollte vorhanden sein")
    }
    
    /// Test: Gleichen Tag zweimal hinzufügen (Idempotenz)
    func testAddTag_Idempotent() {
        // Given: Eine Datei ohne Tags
        let tag = "TOP"
        
        // When: Gleichen Tag zweimal hinzufügen
        let success1 = tagService.addTag(tag, to: testFileURL)
        let success2 = tagService.addTag(tag, to: testFileURL)
        
        // Then: Beide Operationen erfolgreich, aber Tag nur einmal vorhanden
        XCTAssertTrue(success1, "Erste Operation sollte erfolgreich sein")
        XCTAssertTrue(success2, "Zweite Operation sollte auch erfolgreich sein (idempotent)")
        XCTAssertTrue(tagService.hasTag(tag, at: testFileURL), "Tag sollte vorhanden sein")
        
        // Zusätzlich: Prüfen dass der Tag nicht doppelt vorhanden ist
        // Dafür müssen wir direkt die Tags auslesen
        let resourceValues = try? testFileURL.resourceValues(forKeys: [.tagNamesKey])
        let tags = resourceValues?.tagNames ?? []
        let topTagCount = tags.filter { $0 == tag }.count
        XCTAssertEqual(topTagCount, 1, "Tag sollte nur einmal vorhanden sein, nicht doppelt")
    }
    
    /// Test: Tag erfolgreich entfernen
    func testRemoveTag_Success() {
        // Given: Eine Datei mit einem Tag
        let tag = "TOP"
        tagService.addTag(tag, to: testFileURL)
        
        // When: Tag entfernen
        let success = tagService.removeTag(tag, from: testFileURL)
        
        // Then: Operation erfolgreich und Tag ist nicht mehr vorhanden
        XCTAssertTrue(success, "Tag sollte erfolgreich entfernt werden")
        XCTAssertFalse(tagService.hasTag(tag, at: testFileURL), "Tag sollte nach dem Entfernen nicht mehr vorhanden sein")
    }
    
    /// Test: Tag entfernen der nicht existiert (Idempotenz)
    func testRemoveTag_NonExistentTag_Idempotent() {
        // Given: Eine Datei ohne Tags
        let tag = "TOP"
        
        // When: Nicht-existenten Tag entfernen
        let success = tagService.removeTag(tag, from: testFileURL)
        
        // Then: Operation sollte erfolgreich sein (nichts zu entfernen ist kein Fehler)
        XCTAssertTrue(success, "Operation sollte erfolgreich sein, auch wenn Tag nicht existiert")
        XCTAssertFalse(tagService.hasTag(tag, at: testFileURL), "Tag sollte nicht vorhanden sein")
    }
    
    /// Test: Einen von mehreren Tags entfernen
    func testRemoveTag_OneOfMultiple() {
        // Given: Eine Datei mit mehreren Tags
        let tag1 = "TOP"
        let tag2 = "Landscape"
        let tag3 = "Portfolio"
        
        tagService.addTag(tag1, to: testFileURL)
        tagService.addTag(tag2, to: testFileURL)
        tagService.addTag(tag3, to: testFileURL)
        
        // When: Mittleren Tag entfernen
        tagService.removeTag(tag2, from: testFileURL)
        
        // Then: Nur der entfernte Tag sollte fehlen
        XCTAssertTrue(tagService.hasTag(tag1, at: testFileURL), "Tag 'TOP' sollte noch vorhanden sein")
        XCTAssertFalse(tagService.hasTag(tag2, at: testFileURL), "Tag 'Landscape' sollte entfernt sein")
        XCTAssertTrue(tagService.hasTag(tag3, at: testFileURL), "Tag 'Portfolio' sollte noch vorhanden sein")
    }
    
    /// Test: hasTag gibt false zurück für nicht-vorhandene Tags
    func testHasTag_ReturnsFalseForNonExistentTag() {
        // Given: Eine Datei ohne Tags
        let tag = "TOP"
        
        // When & Then: hasTag sollte false zurückgeben
        XCTAssertFalse(tagService.hasTag(tag, at: testFileURL), "hasTag sollte false für nicht-existenten Tag zurückgeben")
    }
    
    /// Test: hasTag gibt true zurück für vorhandene Tags
    func testHasTag_ReturnsTrueForExistingTag() {
        // Given: Eine Datei mit einem Tag
        let tag = "TOP"
        tagService.addTag(tag, to: testFileURL)
        
        // When & Then: hasTag sollte true zurückgeben
        XCTAssertTrue(tagService.hasTag(tag, at: testFileURL), "hasTag sollte true für existenten Tag zurückgeben")
    }
    
    /// Test: Tags sind Case-Sensitive
    func testTags_AreCaseSensitive() {
        // Given: Eine Datei mit einem Tag in Großbuchstaben
        tagService.addTag("TOP", to: testFileURL)
        
        // When & Then: Kleinbuchstaben-Version sollte NICHT gefunden werden
        XCTAssertTrue(tagService.hasTag("TOP", at: testFileURL), "'TOP' sollte gefunden werden")
        XCTAssertFalse(tagService.hasTag("top", at: testFileURL), "'top' sollte NICHT gefunden werden (case-sensitive)")
    }
    
    // MARK: - Helper Methods
    
    /// Erstellt eine temporäre Test-Datei im System-Temp-Ordner
    private func createTemporaryTestFile() -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "LightCullTest_\(UUID().uuidString).txt"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // Leere Datei erstellen
        let testContent = "Test file for FinderTagService"
        try? testContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
}
