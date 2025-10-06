//
//  ImageViewModelTests.swift
//  LightCullTests
//
//  Unit Tests for the zoom functionality of ImageViewModel
//

import XCTest
@testable import LightCull

final class ImageViewModelTests: XCTestCase {
    
    var viewModel: ImageViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        // Before each test: Create new ViewModel
        viewModel = ImageViewModel()
    }
    
    override func tearDown() {
        // After each test: Clean up ViewModel
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialZoomScale() {
        // GIVEN: A freshly initialized ViewModel
        // WHEN: Nothing
        // THEN: Zoom-Scale should be 1.0 (100%)
        XCTAssertEqual(viewModel.zoomScale, 1.0, "Initial zoom scale should be 1.0")
    }
    
    func testInitialOffset() {
        // GIVEN: A freshly initialized ViewModel
        // WHEN: Nothing
        // THEN: Image-Offset should be zero
        XCTAssertEqual(viewModel.imageOffset, .zero, "Initial offset should be .zero")
    }
    
    func testZoomPercentageCalculation() {
        // GIVEN: ViewModel with different zoom levels
        viewModel.zoomScale = 1.0
        XCTAssertEqual(viewModel.zoomPercentage, 100)
        
        viewModel.zoomScale = 2.5
        XCTAssertEqual(viewModel.zoomPercentage, 250)
        
        viewModel.zoomScale = 4.0
        XCTAssertEqual(viewModel.zoomPercentage, 400)
    }
    
    // MARK: - Zoom In Tests
    
    func testZoomIn() {
        // GIVEN: ViewModel with standard zoom (1.0)
        XCTAssertEqual(viewModel.zoomScale, 1.0)

        // WHEN: ZoomIn is called
        viewModel.zoomIn()

        // THEN: Zoom should be increased by zoomStep
        XCTAssertEqual(viewModel.zoomScale, 1.25, accuracy: 0.01)
    }
    
    func testZoomInMultipleTimes() {
        // GIVEN: ViewModel with standard zoom
        // WHEN: ZoomIn is called multiple times
        viewModel.zoomIn() // 1.25
        viewModel.zoomIn() // 1.50
        viewModel.zoomIn() // 1.75

        // THEN: Zoom should be increased accordingly
        XCTAssertEqual(viewModel.zoomScale, 1.75, accuracy: 0.01)
    }
    
    func testZoomInRespectMaxZoom() {
        // GIVEN: ViewModel near maximum
        viewModel.zoomScale = 3.9

        // WHEN: ZoomIn is called
        viewModel.zoomIn()

        // THEN: Zoom should not exceed maxZoom
        XCTAssertEqual(viewModel.zoomScale, 4.0, accuracy: 0.01)
        XCTAssertTrue(viewModel.isMaxZoom)
    }
    
    func testZoomInAtMaxZoom() {
        // GIVEN: ViewModel already at maximum
        viewModel.zoomScale = 4.0

        // WHEN: ZoomIn is called
        viewModel.zoomIn()

        // THEN: Zoom should stay at maxZoom
        XCTAssertEqual(viewModel.zoomScale, 4.0)
    }
    
    // MARK: - Zoom Out Tests
    
    func testZoomOut() {
        // GIVEN: ViewModel with increased zoom
        viewModel.zoomScale = 2.0

        // WHEN: ZoomOut is called
        viewModel.zoomOut()

        // THEN: Zoom should be decreased by zoomStep
        XCTAssertEqual(viewModel.zoomScale, 1.75, accuracy: 0.01)
    }
    
    func testZoomOutMultipleTimes() {
        // GIVEN: ViewModel with zoom at 2.0
        viewModel.zoomScale = 2.0

        // WHEN: ZoomOut is called multiple times
        viewModel.zoomOut() // 1.75
        viewModel.zoomOut() // 1.50
        viewModel.zoomOut() // 1.25

        // THEN: Zoom should be decreased accordingly
        XCTAssertEqual(viewModel.zoomScale, 1.25, accuracy: 0.01)
    }
    
    func testZoomOutRespectMinZoom() {
        // GIVEN: ViewModel near minimum
        viewModel.zoomScale = 1.1

        // WHEN: ZoomOut is called
        viewModel.zoomOut()

        // THEN: Zoom should not go below minZoom
        XCTAssertEqual(viewModel.zoomScale, 1.0, accuracy: 0.01)
        XCTAssertTrue(viewModel.isMinZoom)
    }
    
    func testZoomOutAtMinZoom() {
        // GIVEN: ViewModel already at minimum
        viewModel.zoomScale = 1.0

        // WHEN: ZoomOut is called
        viewModel.zoomOut()

        // THEN: Zoom should stay at minZoom
        XCTAssertEqual(viewModel.zoomScale, 1.0)
    }
    
    // MARK: - Reset Zoom Tests
    
    func testResetZoom() {
        // GIVEN: ViewModel with increased zoom and offset
        viewModel.zoomScale = 3.0
        viewModel.imageOffset = CGSize(width: 100, height: 50)

        // WHEN: ResetZoom is called
        viewModel.resetZoom()

        // THEN: Zoom and offset should be reset
        XCTAssertEqual(viewModel.zoomScale, 1.0)
        XCTAssertEqual(viewModel.imageOffset, .zero)
    }
    
    // MARK: - Set Zoom Tests
    
    func testSetZoomToValidValue() {
        // GIVEN: ViewModel with standard zoom
        // WHEN: SetZoom is called with valid value
        viewModel.setZoom(to: 2.5)

        // THEN: Zoom should be set to the value
        XCTAssertEqual(viewModel.zoomScale, 2.5, accuracy: 0.01)
    }
    
    func testSetZoomClampsBelowMin() {
        // GIVEN: ViewModel
        // WHEN: SetZoom is called with value below minimum
        viewModel.setZoom(to: 0.5)

        // THEN: Zoom should be clamped to minZoom
        XCTAssertEqual(viewModel.zoomScale, 1.0)
    }
    
    func testSetZoomClampsAboveMax() {
        // GIVEN: ViewModel
        // WHEN: SetZoom is called with value above maximum
        viewModel.setZoom(to: 5.0)

        // THEN: Zoom should be clamped to maxZoom
        XCTAssertEqual(viewModel.zoomScale, 4.0)
    }
    
    // MARK: - Handle Magnification Tests
    
    func testHandleMagnificationIncrease() {
        // GIVEN: ViewModel with zoom at 2.0
        viewModel.zoomScale = 2.0

        // WHEN: Magnification is called with 1.5 (150%)
        viewModel.handleMagnification(1.5)

        // THEN: Zoom should be increased to 3.0
        XCTAssertEqual(viewModel.zoomScale, 3.0, accuracy: 0.01)
    }
    
    func testHandleMagnificationDecrease() {
        // GIVEN: ViewModel with zoom at 2.0
        viewModel.zoomScale = 2.0

        // WHEN: Magnification is called with 0.5 (50%)
        viewModel.handleMagnification(0.5)

        // THEN: Zoom should be decreased to 1.0
        XCTAssertEqual(viewModel.zoomScale, 1.0, accuracy: 0.01)
    }
    
    func testHandleMagnificationRespectMaxZoom() {
        // GIVEN: ViewModel with zoom at 3.0
        viewModel.zoomScale = 3.0

        // WHEN: Magnification with 2.0 would exceed maximum
        viewModel.handleMagnification(2.0)

        // THEN: Zoom should be clamped at maxZoom
        XCTAssertEqual(viewModel.zoomScale, 4.0)
    }
    
    func testHandleMagnificationRespectMinZoom() {
        // GIVEN: ViewModel with zoom at 2.0
        viewModel.zoomScale = 2.0

        // WHEN: Magnification with 0.3 would go below minimum
        viewModel.handleMagnification(0.3)

        // THEN: Zoom should be clamped at minZoom
        XCTAssertEqual(viewModel.zoomScale, 1.0)
    }
    
    // MARK: - Computed Properties Tests
    
    func testIsMinZoom() {
        // Test when at minimum
        viewModel.zoomScale = 1.0
        XCTAssertTrue(viewModel.isMinZoom)

        // Test when above minimum
        viewModel.zoomScale = 1.5
        XCTAssertFalse(viewModel.isMinZoom)
    }
    
    func testIsMaxZoom() {
        // Test when at maximum
        viewModel.zoomScale = 4.0
        XCTAssertTrue(viewModel.isMaxZoom)

        // Test when below maximum
        viewModel.zoomScale = 3.5
        XCTAssertFalse(viewModel.isMaxZoom)
    }
}
