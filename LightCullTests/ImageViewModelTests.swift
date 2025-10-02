//
//  ImageViewModelTests.swift
//  LightCullTests
//
//  Unit Tests für die Zoom-Funktionalität des ImageViewModel
//

import XCTest
@testable import LightCull

final class ImageViewModelTests: XCTestCase {
    
    var viewModel: ImageViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        // Vor jedem Test: Neues ViewModel erstellen
        viewModel = ImageViewModel()
    }
    
    override func tearDown() {
        // Nach jedem Test: ViewModel aufräumen
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialZoomScale() {
        // GIVEN: Ein frisch initialisiertes ViewModel
        // WHEN: Nichts
        // THEN: Zoom-Scale sollte 1.0 sein (100%)
        XCTAssertEqual(viewModel.zoomScale, 1.0, "Initial zoom scale sollte 1.0 sein")
    }
    
    func testInitialOffset() {
        // GIVEN: Ein frisch initialisiertes ViewModel
        // WHEN: Nichts
        // THEN: Image-Offset sollte zero sein
        XCTAssertEqual(viewModel.imageOffset, .zero, "Initial offset sollte .zero sein")
    }
    
    func testZoomPercentageCalculation() {
        // GIVEN: ViewModel mit verschiedenen Zoom-Levels
        viewModel.zoomScale = 1.0
        XCTAssertEqual(viewModel.zoomPercentage, 100)
        
        viewModel.zoomScale = 2.5
        XCTAssertEqual(viewModel.zoomPercentage, 250)
        
        viewModel.zoomScale = 4.0
        XCTAssertEqual(viewModel.zoomPercentage, 400)
    }
    
    // MARK: - Zoom In Tests
    
    func testZoomIn() {
        // GIVEN: ViewModel mit Standard-Zoom (1.0)
        XCTAssertEqual(viewModel.zoomScale, 1.0)
        
        // WHEN: ZoomIn wird aufgerufen
        viewModel.zoomIn()
        
        // THEN: Zoom sollte um zoomStep erhöht sein
        XCTAssertEqual(viewModel.zoomScale, 1.25, accuracy: 0.01)
    }
    
    func testZoomInMultipleTimes() {
        // GIVEN: ViewModel mit Standard-Zoom
        // WHEN: ZoomIn wird mehrfach aufgerufen
        viewModel.zoomIn() // 1.25
        viewModel.zoomIn() // 1.50
        viewModel.zoomIn() // 1.75
        
        // THEN: Zoom sollte entsprechend erhöht sein
        XCTAssertEqual(viewModel.zoomScale, 1.75, accuracy: 0.01)
    }
    
    func testZoomInRespectMaxZoom() {
        // GIVEN: ViewModel nahe am Maximum
        viewModel.zoomScale = 3.9
        
        // WHEN: ZoomIn wird aufgerufen
        viewModel.zoomIn()
        
        // THEN: Zoom sollte maxZoom nicht überschreiten
        XCTAssertEqual(viewModel.zoomScale, 4.0, accuracy: 0.01)
        XCTAssertTrue(viewModel.isMaxZoom)
    }
    
    func testZoomInAtMaxZoom() {
        // GIVEN: ViewModel bereits am Maximum
        viewModel.zoomScale = 4.0
        
        // WHEN: ZoomIn wird aufgerufen
        viewModel.zoomIn()
        
        // THEN: Zoom sollte bei maxZoom bleiben
        XCTAssertEqual(viewModel.zoomScale, 4.0)
    }
    
    // MARK: - Zoom Out Tests
    
    func testZoomOut() {
        // GIVEN: ViewModel mit erhöhtem Zoom
        viewModel.zoomScale = 2.0
        
        // WHEN: ZoomOut wird aufgerufen
        viewModel.zoomOut()
        
        // THEN: Zoom sollte um zoomStep verringert sein
        XCTAssertEqual(viewModel.zoomScale, 1.75, accuracy: 0.01)
    }
    
    func testZoomOutMultipleTimes() {
        // GIVEN: ViewModel mit Zoom bei 2.0
        viewModel.zoomScale = 2.0
        
        // WHEN: ZoomOut wird mehrfach aufgerufen
        viewModel.zoomOut() // 1.75
        viewModel.zoomOut() // 1.50
        viewModel.zoomOut() // 1.25
        
        // THEN: Zoom sollte entsprechend verringert sein
        XCTAssertEqual(viewModel.zoomScale, 1.25, accuracy: 0.01)
    }
    
    func testZoomOutRespectMinZoom() {
        // GIVEN: ViewModel nahe am Minimum
        viewModel.zoomScale = 1.1
        
        // WHEN: ZoomOut wird aufgerufen
        viewModel.zoomOut()
        
        // THEN: Zoom sollte minZoom nicht unterschreiten
        XCTAssertEqual(viewModel.zoomScale, 1.0, accuracy: 0.01)
        XCTAssertTrue(viewModel.isMinZoom)
    }
    
    func testZoomOutAtMinZoom() {
        // GIVEN: ViewModel bereits am Minimum
        viewModel.zoomScale = 1.0
        
        // WHEN: ZoomOut wird aufgerufen
        viewModel.zoomOut()
        
        // THEN: Zoom sollte bei minZoom bleiben
        XCTAssertEqual(viewModel.zoomScale, 1.0)
    }
    
    // MARK: - Reset Zoom Tests
    
    func testResetZoom() {
        // GIVEN: ViewModel mit erhöhtem Zoom und Offset
        viewModel.zoomScale = 3.0
        viewModel.imageOffset = CGSize(width: 100, height: 50)
        
        // WHEN: ResetZoom wird aufgerufen
        viewModel.resetZoom()
        
        // THEN: Zoom und Offset sollten zurückgesetzt sein
        XCTAssertEqual(viewModel.zoomScale, 1.0)
        XCTAssertEqual(viewModel.imageOffset, .zero)
    }
    
    // MARK: - Set Zoom Tests
    
    func testSetZoomToValidValue() {
        // GIVEN: ViewModel mit Standard-Zoom
        // WHEN: SetZoom mit gültigem Wert aufgerufen wird
        viewModel.setZoom(to: 2.5)
        
        // THEN: Zoom sollte auf den Wert gesetzt sein
        XCTAssertEqual(viewModel.zoomScale, 2.5, accuracy: 0.01)
    }
    
    func testSetZoomClampsBelowMin() {
        // GIVEN: ViewModel
        // WHEN: SetZoom mit Wert unter Minimum aufgerufen wird
        viewModel.setZoom(to: 0.5)
        
        // THEN: Zoom sollte auf minZoom begrenzt sein
        XCTAssertEqual(viewModel.zoomScale, 1.0)
    }
    
    func testSetZoomClampsAboveMax() {
        // GIVEN: ViewModel
        // WHEN: SetZoom mit Wert über Maximum aufgerufen wird
        viewModel.setZoom(to: 5.0)
        
        // THEN: Zoom sollte auf maxZoom begrenzt sein
        XCTAssertEqual(viewModel.zoomScale, 4.0)
    }
    
    // MARK: - Handle Magnification Tests
    
    func testHandleMagnificationIncrease() {
        // GIVEN: ViewModel mit Zoom bei 2.0
        viewModel.zoomScale = 2.0
        
        // WHEN: Magnification mit 1.5 (150%) aufgerufen wird
        viewModel.handleMagnification(1.5)
        
        // THEN: Zoom sollte auf 3.0 erhöht sein
        XCTAssertEqual(viewModel.zoomScale, 3.0, accuracy: 0.01)
    }
    
    func testHandleMagnificationDecrease() {
        // GIVEN: ViewModel mit Zoom bei 2.0
        viewModel.zoomScale = 2.0
        
        // WHEN: Magnification mit 0.5 (50%) aufgerufen wird
        viewModel.handleMagnification(0.5)
        
        // THEN: Zoom sollte auf 1.0 verringert sein
        XCTAssertEqual(viewModel.zoomScale, 1.0, accuracy: 0.01)
    }
    
    func testHandleMagnificationRespectMaxZoom() {
        // GIVEN: ViewModel mit Zoom bei 3.0
        viewModel.zoomScale = 3.0
        
        // WHEN: Magnification mit 2.0 würde über Maximum gehen
        viewModel.handleMagnification(2.0)
        
        // THEN: Zoom sollte bei maxZoom begrenzt sein
        XCTAssertEqual(viewModel.zoomScale, 4.0)
    }
    
    func testHandleMagnificationRespectMinZoom() {
        // GIVEN: ViewModel mit Zoom bei 2.0
        viewModel.zoomScale = 2.0
        
        // WHEN: Magnification mit 0.3 würde unter Minimum gehen
        viewModel.handleMagnification(0.3)
        
        // THEN: Zoom sollte bei minZoom begrenzt sein
        XCTAssertEqual(viewModel.zoomScale, 1.0)
    }
    
    // MARK: - Computed Properties Tests
    
    func testIsMinZoom() {
        // Test wenn am Minimum
        viewModel.zoomScale = 1.0
        XCTAssertTrue(viewModel.isMinZoom)
        
        // Test wenn über Minimum
        viewModel.zoomScale = 1.5
        XCTAssertFalse(viewModel.isMinZoom)
    }
    
    func testIsMaxZoom() {
        // Test wenn am Maximum
        viewModel.zoomScale = 4.0
        XCTAssertTrue(viewModel.isMaxZoom)
        
        // Test wenn unter Maximum
        viewModel.zoomScale = 3.5
        XCTAssertFalse(viewModel.isMaxZoom)
    }
}
